task :default => :timesheet

task :timesheet do
  ruby "app/timesheet.rb"
end

task :sendlast do
  ruby "app/timesheet.rb --send --uselast"
end

task :send do
  ruby "app/timesheet.rb --send"
end