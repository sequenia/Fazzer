require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"
 
module Capybara::Poltergeist
  Client.class_eval do
    def start
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      @pid = Process.spawn(*command.map(&:to_s), pgroup: true)
      ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
    end
 
    def stop
      if pid
        puts 'STOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOP!'
        kill_phantomjs
        ObjectSpace.undefine_finalizer(self)
      end
    end
  end
end