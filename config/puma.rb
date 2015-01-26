workers Integer(ENV['PUMA_WORKERS'] || 3)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 16)

directory '/var/www/apps/Fazzer/current'

bind 'unix:///var/www/apps/Fazzer/socket/.puma.sock'

pidfile '/var/www/apps/Fazzer/run/puma.pid'

stdout_redirect '/var/www/apps/Fazzer/log/puma.stdout.log', '/var/www/apps/Fazzer/log/puma.stderr.log', true

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 8080
environment ENV['RACK_ENV'] || 'production'

on_worker_boot do
  # worker specific setup
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['MAX_THREADS'] || 16
    ActiveRecord::Base.establish_connection(config)
  end
end