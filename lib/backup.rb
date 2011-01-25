require "#{File.dirname(__FILE__)}/heroku_adapter.rb"
require "#{File.dirname(__FILE__)}/s3_adapter.rb"

module HerokuBackupOrchestrator 
  class BackupFailedError < RuntimeError; end
  
  class BackupHandler
    def initialize
      @heroku = HerokuAdapter.new
      @s3 = S3Adapter.new
    end

    def backup_pg
      begin
        current_backup = @heroku.current_pgbackup_name
        @heroku.destroy_pgbackup(current_backup) if current_backup
        new_backup_info = @heroku.capture_pgbackup_url
        @s3.upload_pgbackup(new_backup_info)
      rescue Exception => e
        raise BackupFailedError, e.message
      end
    end

    def backup
      begin
        current_bundle = @heroku.current_bundle_name
        @heroku.destroy_bundle(current_bundle) if current_bundle
        new_bundle_info = @heroku.capture_bundle
        @s3.upload_bundle(new_bundle_info)
      rescue Exception => e
        raise BackupFailedError, e.message
      end
    end

  end
end