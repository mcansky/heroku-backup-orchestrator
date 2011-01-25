require 'heroku'
require 'heroku/command'
require 'pgbackups/client'
require "#{File.dirname(__FILE__)}/config.rb"

module HerokuBackupOrchestrator 
  class HerokuAdapter
    
    def initialize
      config = HerokuBackupOrchestrator::CONFIG['heroku']
      heroku_user = config['user']
      heroku_pg_user = config['pg_user']
      heroku_password = config['password']
      heroku_pg_password = config['pg_password']
      @client = Heroku::Client.new(heroku_user, heroku_password)
      @client_pg = Heroku::PGBackups::Client.new("http://#{heroku_pg_user}:#{heroku_pg_password}@pgbackups.heroku.com/client")
      @app = config['app']
    end

    def current_pgbackup_name
      info = @client_pg.get_latest_backup
      return info if info
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
      @client_pg.delete_backup(backup_id)
    end

    def capture_bundle
      @client.bundle_capture(@app)    
      while((new_bundle = @client.bundles(@app).first)[:state] != 'complete')
        sleep 5
      end    
      new_bundle_url = @client.bundle_url(@app)
      {:url => new_bundle_url, :name => new_bundle[:name]}
    end
    
    def capture_pgbackup
      db = ENV["DATABASE_URL"]
      db_url = ENV[db]
      @client_pg.create_transfer(db_url, db, nil, "BACKUP", :expire => true)
      return @client_pg.get_latest_backup
    end
  end
end