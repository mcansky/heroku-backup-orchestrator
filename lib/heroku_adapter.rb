require 'heroku'
require 'heroku/commands/base'
require "#{File.dirname(__FILE__)}/config.rb"

module HerokuBackupOrchestrator 
  class HerokuAdapter
    
    def initialize
      config = HerokuBackupOrchestrator::CONFIG['heroku']
      heroku_user = config['user']
      heroku_password = config['password']
      @client = Heroku::Client.new(heroku_user, heroku_password)
      @app = config['app']
    end

    def current_pgbackup_name
      info = capture_heroku_command 'pgbackups'
      if heroku_existing_backup?(info)
        last_backup_info = info.split("\n").last.split(" | ")
        last_backup_id = last_backup_info[0]
        last_backup_time = last_backup_info[1]
        return last_backup_id
      end
      return nil
    end

    def current_pgbackup_time
      info = capture_heroku_command 'pgbackups'
      if heroku_existing_backup?(info)
        last_backup_info = info.split("\n").last.split(" | ")
        last_backup_id = last_backup_info[0]
        last_backup_time = last_backup_info[1]
        return last_backup_time
      end
      return nil
    end

    # The name of the first bundle in the bundles array returned
    # from heroku is returned to the caller. Hence, only the
    # single bundle addon is supported.
    def current_bundle_name
      bundles = @client.bundles(@app)
      if !bundles.empty?
        bundles.first[:name]
      else
        nil
      end
    end
    
    def destroy_bundle(name)
      @client.bundle_destroy(@app, name)
    end

    def destroy_pgbackup(backup_id)
      heroku_command 'pgbackups:destroy', backup_id
    end

    def capture_bundle
      @client.bundle_capture(@app)    
      while((new_bundle = @client.bundles(@app).first)[:state] != 'complete')
        sleep 5
      end    
      new_bundle_url = @client.bundle_url(@app)
      {:url => new_bundle_url, :name => new_bundle[:name]}
    end
    
    def capture_pgbackup_url
      heroku_command 'pgbackups:capture'
      return capture_heroku_command 'pgbackups:url'
    end

    private

    def heroku_command(*cmds)
      Heroku::Command::Base.command(*cmds)
    end

    def capture_heroku_command(*cmds)
      stdout = STDOUT
      StringIO.new.tap do |out|
        def out.flush ; end
        $stdout = out
        heroku_command(*cmds)
      end.string.chomp
    ensure
      $stdout = stdout
    end

    def heroku_existing_backup?(info)
      info !~ /no backups/i
    end
  end
end