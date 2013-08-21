#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'prawn'
require 'trollop'
require 'mail'

require 'tmpdir'
require 'erb'
require 'ostruct'

$app_root = File.join(File.dirname(File.expand_path(__FILE__)), "..")
require 'utils'
require 'prawn_ext'

class Timesheet

  CONFIG = load_config

  def initialize
    @opts = Trollop::options(ARGV) do
      version "timesheet 0.0.1 (c) 2013 Matt Greensmith"
      banner <<-EOS.unindent
      
      Timesheet fills out and optionally sends a weekly timesheet to Mainz Brady.
      It defaults to the current week, where a week begins on Monday.

      Usage: timesheet [--send] [--uselast | (--weekof, -[mtwhfsu] <hours>)]

      EOS
      opt :mon, "Monday hours worked", :type => :float, :default => CONFIG['default_hours']['mon']
      opt :tue, "Tuesday hours worked", :type => :float, :default => CONFIG['default_hours']['tue']
      opt :wed, "Wednesday hours worked", :type => :float, :default => CONFIG['default_hours']['wed']
      opt :thu, "Thursday hours worked", :type => :float, :default => CONFIG['default_hours']['thu']
      opt :fri, "Friday hours worked", :type => :float, :default => CONFIG['default_hours']['fri']
      opt :sat, "Saturday hours worked", :type => :float, :default => CONFIG['default_hours']['sat']
      opt :sun, "Sunday hours worked", :type => :float, :default => CONFIG['default_hours']['sun']
      opt :weekof, "Generate timesheet for week that includes yyyy-mm-dd", :type => :string
      opt :lastweek, "Generate timesheet for last week"
      opt :uselast, "Use saved data from last successful run, ignores (weekof,lastweek,mtwhfsu)"
      opt :send, "Sends the generated PDF via email"
    end
  end

  def get_week
    proposed_week = nil
    proposed_week = Date.strptime @opts[:weekof], '%Y/%m/%d' unless @opts[:weekof].nil?
    if @opts[:lastweek] == true and proposed_week.nil? ; proposed_week = Date.today - 7 end
    if proposed_week.nil? ; proposed_week = Date.today end
    proposed_week
  end

  def make_data(monday_date)
    total_hours = 0
    data = {}
    data['date'] = {}
    data['hours'] = {}
    data['start'] = {}
    data['end'] = {}
    days = ['mon','tue','wed','thu','fri','sat','sun']
    days.each do |day|
      unless @opts[day.intern] == 0
        data['date'][day] = (monday_date + days.index(day)).to_s
        data['hours'][day] = @opts[day.intern]
        data['start'][day] = CONFIG['default_start'][day]
        data['end'][day] = CONFIG['default_end'][day]
        total_hours += @opts[day.intern]
      end
    end
    data['total_hours'] = total_hours
    data
  end


  def build_pdf(data)
    Prawn::Document.generate(@output_file, :template => @template_file) do |pdf|
      CONFIG['formdata'].each do |field_name, field_data|
        pdf.fill_cell(field_data, @template_yaml[field_name])
      end
      ['date','hours','start','end'].each do |ftype|
        data[ftype].each do |day, date|
          pdf.fill_cell(date, @template_yaml["#{day}_#{ftype}"])
        end
      end
      pdf.fill_cell(data['total_hours'], @template_yaml['total_reg_hours'])
      pdf.fill_cell(data['total_hours'], @template_yaml['grand_total_hours'])
      pdf.fill_cell(Date.today, @template_yaml['employee_signature_date'])
    end
  end

  def send_mail
    Mail.defaults do
      delivery_method :smtp, config['mail']['options']
    end
    
    namespace = OpenStruct.new local_variables
    message_text = ERB.new(File.open(File.join($app_root, config['mail']['body_template_text'])), 0, "%<>").result(namespace.instance_eval { binding })
    message_html = ERB.new(File.open(File.join($app_root, config['mail']['body_template_html'])), 0, "%<>").result(namespace.instance_eval { binding })
    message_subject = "#{CONFIG['mail']['subject']} #{data['date']['mon']}"
    
    Mail.deliver do
      to CONFIG['mail']['recipient']
      from CONFIG['mail']['sender']
      bcc CONFIG['mail']['bcc']
      subject message_subject
      text_part do
        body message_text
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body message_html
      end
      add_file @output_file
    end
  end

  def run
    if @opts[:uselast]
      data = load_config(CONFIG['lastrun_file'])
    else
      data = make_data(last_monday(get_week))
      save_lastrun(data)  
    end

    @template_file = File.join($app_root, CONFIG['template_file'])
    @template_yaml = load_config(CONFIG['template_yaml'])

    output_file_name = "#{CONFIG['output_file_prefix']}#{DateTime.now.strftime("%Y%m%d.%H%M%S")}.pdf"
    @output_file = @opts[:send] ? File.join($app_root, CONFIG['output_path'], output_file_name) : File.join(Dir.tmpdir, output_file_name)

    build_pdf(data)

    @opts[:send] ? send_mail : `open #{@output_file}`
  end
end
