require "#{File.dirname(__FILE__)}/lib/backup.rb"
require 'logger'

desc 'Capture a new bundle for your heroku app and upload it to Amazon S3'
task :cron do
  log = Logger.new(STDERR)
  begin
    log.debug("Backing up #{@heroku_app} ...")
    backup_handler = HerokuBackupOrchestrator::BackupHandler.new
    backup_handler.backup_pg
    log.debug("Backup finished successfully")
  rescue HerokuBackupOrchestrator::BackupFailedError
    log.error("Backup failed: #{$!.message}")
  end
end

desc 'Run unit tests'
task :test do
  require 'rubygems'
  require 'test/unit'
  require 'mocha'
  
  test_dir = "#{File.dirname(__FILE__)}/test"
  Dir.open(test_dir).each do |f|
    qualified_filename = File.join(test_dir, f)
    if File.file?(qualified_filename) && f.match(/_test.rb\z/)
      require qualified_filename
    end
  end
end

desc "The default task will invoke the 'test' task"
task :default do
  Rake::Task['test'].invoke
end