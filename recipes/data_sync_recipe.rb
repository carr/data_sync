desc 'Dumps the production database to db/production_data.sql on the remote server'
task :remote_db_dump, :roles => :db, :only => { :primary => true } do
  commands = [
    "cd #{deploy_to}/#{current_dir}",
    "rake RAILS_ENV=production db:database_dump --trace"
  ]

  run commands.join(" && ")
end

desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
task :remote_db_download, :roles => :db, :only => { :primary => true } do
  execute_on_servers(options) do |servers|
    self.sessions[servers.first].sftp.connect do |tsftp|
      tsftp.download! "#{deploy_to}/#{current_dir}/db/production_data.tar.bz2", "db/production_data.tar.bz2"
    end
  end
end

desc 'Cleans up data dump file'
task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
  run "rm #{deploy_to}/#{current_dir}/db/production_data.tar.bz2"
end

desc 'Dumps, downloads and then cleans up the production data dump'
task :remote_db_runner do
  remote_db_dump
  remote_db_download
  remote_db_cleanup
end

desc "Downloads the files in public/system"
task :download_files, :roles => :db, :only => { :primary => true } do
  `mkdir -p public/system`
  execute_on_servers(options) do |servers|
    logger.info "Pulling public/system via rsync"
    `rsync --delete -r #{user}@#{servers.first}:#{deploy_to}/#{current_dir}/public/system/* public/system`
  end
end

