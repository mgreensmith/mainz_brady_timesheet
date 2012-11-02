task :default => :timesheet

task :timesheet do
  ruby "app/timesheet.rb"
end

task :install do
  ln_s File.join(File.dirname(File.expand_path(__FILE__)), "app", "timesheet.rb"), "/usr/local/bin/timesheet"
end