require 'yaml'
require 'date'

def last_monday(date_in)
  case date_in.wday
  when 1..6
    date_in - (date_in.wday - 1)
  when 0
    date_in - 6
  end
end

def load_config(file = "config/config.yaml")
  YAML::load_file(File.join($app_root, file))
end

def save_lastrun(config, file = load_config['lastrun_file'])
  File.open(File.join($app_root, file), "w") {|f| f.write(config.to_yaml) }
end

# Strip leading whitespace
# Use it with a heredoc eg:
# text = <<-EOS.unindent
#	foo
#	   bar
# EOS
class String
  def unindent 
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end