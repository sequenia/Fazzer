# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "/var/www/log/cron_log.log"

every :day, :at => '10:10am' do
  runner "AutoParser.new.save_last_adverts"
end

every :day, :at => '2:10pm' do
  runner "AutoParser.new.save_last_adverts"
end

every :day, :at => '6:10pm' do
  runner "AutoParser.new.save_last_adverts"
end

every :day, :at => '10:10pm' do
  runner "AutoParser.new.save_last_adverts"
end

every :day, :at => '2:10am' do
  runner "AutoParser.new.save_last_adverts"
end

every :day, :at => '4:10am' do
  runner "AutoParser.new.save_last_adverts"
end