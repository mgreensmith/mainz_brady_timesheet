#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'prawn'
require 'trollop'
require 'mail'

require 'tmpdir'
require 'erb'
require 'ostruct'
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$app_root = File.join(File.dirname(File.expand_path(__FILE__)), "..")
require 'utils'

config = load_config

$opts = Trollop::options do
  version "timesheet 0.0.1 (c) 2012 Matt Greensmith"
  banner <<-EOS.unindent
  
  Timesheet fills out and optionally sends a weekly timesheet to Mainz Brady.
  It defaults to the current week, where a week begins on Monday.

  Usage: timesheet.rb [--send] [--uselast | (--weekof, -[mtwhfsu] <hours>)]

  EOS
  opt :mon, "Monday hours worked", :default => config['default_hours']['mon']
  opt :tue, "Tuesday hours worked", :default => config['default_hours']['tue']
  opt :wed, "Wednesday hours worked", :default => config['default_hours']['wed']
  opt :thu, "Thursday hours worked", :default => config['default_hours']['thu']
  opt :fri, "Friday hours worked", :default => config['default_hours']['fri']
  opt :sat, "Saturday hours worked", :default => config['default_hours']['sat']
  opt :sun, "Sunday hours worked", :default => config['default_hours']['sun']
  opt :weekof, "Generate timesheet for week that includes yyyy-mm-dd", :type => :string
  opt :lastweek, "Generate timesheet for last week"
  opt :uselast, "Use saved data from last successful run, ignores (weekof,lastweek,mtwhfsu)"
  opt :send, "Sends the generated PDF via email"
end

def get_week
  proposed_week = nil
  unless $opts[:weekof].nil? ; proposed_week = Date.strptime $opts[:weekof], '%Y/%m/%d' end
  if $opts[:lastweek] == true and proposed_week.nil? ; proposed_week = Date.today - 7 end
  if proposed_week.nil? ; proposed_week = Date.today end
  proposed_week
end

def make_data(monday_date, config)
  total_hours = 0
  data = {}
  data['date'] = {}
  data['hours'] = {}
  data['start'] = {}
  data['end'] = {}
  days = ['mon','tue','wed','thu','fri','sat','sun']
  days.each do |day|
    unless $opts[day.intern] == 0
      data['date'][day] = (monday_date + days.index(day)).to_s
      data['hours'][day] = $opts[day.intern]
      data['start'][day] = config['default_start'][day]
      data['end'][day] = config['default_end'][day]
      total_hours += $opts[day.intern]
    end
  end
  data['total_hours'] = total_hours
  data
end

def fill_cell(content, f)
  bounding_box([f['x'],f['y']], :width => f['width'], :height => f['height']) do
    #stroke_bounds
    case f['type']
    when "image"
      image File.join($app_root, content),
      :position => :center,
      :vposition => :center,
      :fit => [f['width'], f['height']]
    else
      text_box  content.to_s, 
      :align => :center,
      :valign => :center,
      :overflow => :shrink_to_fit
    end
  end
end

def build_pdf(template_file, template_yaml, config, data, output_file)
  Prawn::Document.generate(output_file, :template => template_file) do
    config['formdata'].each do |field_name, field_data|
      fill_cell(field_data, template_yaml[field_name])
    end
    ['date','hours','start','end'].each do |ftype|
      data[ftype].each do |day, date|
        fill_cell(date, template_yaml["#{day}_#{ftype}"])
      end
    end
    fill_cell(data['total_hours'], template_yaml['total_reg_hours'])
    fill_cell(data['total_hours'], template_yaml['grand_total_hours'])
    fill_cell(Date.today, template_yaml['employee_signature_date'])
  end
end

# MAIN BLOCK
if $opts[:uselast]
  data = load_config(config['lastrun_file'])
else
  data = make_data(last_monday(get_week), config)
  save_lastrun(data)  
end

template_file = File.join($app_root, config['template_file'])
template_yaml = load_config(config['template_yaml'])

output_file_name = "#{config['output_file_prefix']}#{DateTime.now.strftime("%Y%m%d.%H%M%S")}.pdf"
output_file = $opts[:send] ? File.join($app_root, config['output_path'], output_file_name) : File.join(Dir.tmpdir, output_file_name)

build_pdf(template_file, template_yaml, config, data, output_file)

if $opts[:send]
  Mail.defaults do
    delivery_method :smtp, config['mail']['options']
  end
  
  namespace = OpenStruct.new local_variables
  message_text = ERB.new(File.open(File.join($app_root, config['mail']['body_template_text'])), 0, "%<>").result(namespace.instance_eval { binding })
  message_html = ERB.new(File.open(File.join($app_root, config['mail']['body_template_html'])), 0, "%<>").result(namespace.instance_eval { binding })
  message_subject = "#{config['mail']['subject']} #{data['date']['mon']}"
  
  Mail.deliver do
    to config['mail']['recipient']
    from config['mail']['sender']
    bcc config['mail']['bcc']
    subject message_subject
    text_part do
      body message_text
    end

    html_part do
      content_type 'text/html; charset=UTF-8'
      body message_html
    end
    add_file output_file
  end
else
  `open #{output_file}`
end
