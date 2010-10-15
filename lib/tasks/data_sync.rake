namespace :db do
  desc "Refreshes your local development environment to the current production database"
  task :pull do
    `cap remote_db_runner`
    `rake db:production_data_load`
  end

  desc "Dump the current database to a MySQL file"
  task :database_dump => :environment do
    databases = YAML::load(File.open(Rails.root.join('config', 'database.yml')))

    case databases[Rails.env]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(databases[Rails.env])

          commands = []

          mysql_dump_command = []
          mysql_dump_command << "mysqldump"
          mysql_dump_command << "-h #{databases[Rails.env]["host"]}"
          mysql_dump_command << "-u #{databases[Rails.env]["username"]}"
          if databases[Rails.env]["password"].present?
            mysql_dump_command << "-p#{databases[Rails.env]["password"]}"
          end
          mysql_dump_command << "#{databases[Rails.env]["database"]}"
          mysql_dump_command << " > #{Rails.root.join('db', 'production_data.sql')}"

          commands << mysql_dump_command.join(' ')
          commands << "cd #{Rails.root.join('db')}"
          commands << "tar -cjf #{Rails.root.join('db', 'production_data.tar.bz2')} production_data.sql"
          commands << "rm -fr #{Rails.root.join('db', 'production_data.sql')}"

          `#{commands.join(' && ')}`
      when 'mongodb'
        port = databases[Rails.env]['port']
        port ||= 27017 # default mongodb port

        commands = []
        commands << "rm -fr #{Rails.root.join('db', 'dump')}"
        commands << "mongodump --host #{databases[Rails.env]['host']} --port #{port} --db #{databases[Rails.env]['database']} --out #{Rails.root.join('db', 'dump')}"
        commands << "cd #{Rails.root.join('db')}"
        commands << "tar -cjf #{Rails.root.join('db', 'production_data.tar.bz2')} dump/#{databases[Rails.env]['database']}"
        commands << "rm -fr #{Rails.root.join('db', 'dump')}"

        `#{commands.join(' && ')}`
      else
        raise "Task doesn't work with '#{databases[Rails.env]['adapter']}'"
    end
  end

  desc "Loads the production data downloaded into db/production_data into your local development database"
  task :production_data_load => :environment do

    databases = YAML::load(File.open(Rails.root.join('config', 'database.yml')))

    unless File.exists? Rails.root.join('db', 'production_data.tar.bz2')
      raise 'Unable to find database dump in db/production_data.tar.bz2'
    end

    case databases[Rails.env]["adapter"]
      when 'mysql'
#        ActiveRecord::Base.establish_connection(databases[Rails.env])

          commands = []
          commands << "cd #{Rails.root.join('db')}"
          commands << "tar -xjf #{Rails.root.join('db', 'production_data.tar.bz2')}"

          mysql_dump_command = []
          mysql_dump_command << "mysql"
          if databases[Rails.env]["host"].present?
            mysql_dump_command << "-h #{databases[Rails.env]["host"]}"
          end
          mysql_dump_command << "-u #{databases[Rails.env]["username"]}"
          if databases[Rails.env]["password"].present?
            mysql_dump_command << "-p#{databases[Rails.env]["password"]}"
          end
          mysql_dump_command << "#{databases[Rails.env]["database"]}"
          mysql_dump_command << " < production_data.sql"
          commands << mysql_dump_command.join(' ')

          commands << "rm -fr #{Rails.root.join('db', 'production_data.tar.bz2')} #{Rails.root.join('db', 'production_data.sql')}"

          `#{commands.join(' && ')}`
      when 'mongodb'
        commands = []
        commands << "cd #{Rails.root.join('db')}"
        commands << "tar -xjf #{Rails.root.join('db', 'production_data.tar.bz2')}"
        commands << "mongorestore --db #{databases[Rails.env]['database']} #{Rails.root.join('db', 'dump', databases[Rails.env]['database'])}"
        commands << "rm -fr #{Rails.root.join('db', 'dump')} #{Rails.root.join('db', 'production_data.tar.bz2')}"
        `#{commands.join(' && ')}`
      else
        raise "Task not supported by '#{databases[Rails.env]['adapter']}'"
    end
  end
end

