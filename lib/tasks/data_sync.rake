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

        File.open("db/#{Rails.env}_data.sql", "w+") do |f|
          commands = []
          commands << "mysqldump"
          commands << "-h #{databases[Rails.env]["host"]}"
          commands << "-u #{databases[Rails.env]["username"]}"
          if databases[Rails.env]["password"].present?
            commands << "-p#{databases[Rails.env]["password"]}"
          end
          commands << "#{databases[Rails.env]["database"]}"
          commands << " > db/production_data.sql"

          `#{commands.join(' ')}`
        end
      when 'mongodb'
        commands = []
        commands << "rm -fr #{Rails.root.join('db', 'dump')}"
        commands << "mongodump --db #{databases[Rails.env]['database']} --out #{Rails.root.join('db', 'dump')}"
        commands << "cd #{Rails.root.join('db')}"
        commands << "tar -cjf #{Rails.root.join('db', databases[Rails.env]['database'] + '.tar.bz2')} dump/#{databases[Rails.env]['database']}"
        commands << "rm -fr #{Rails.root.join('db', 'dump')}"

        `#{commands.join(' && ')}`
      else
        raise "Task not supported by '#{databases[Rails.env]['adapter']}'"
    end
  end

  desc "Loads the production data downloaded into db/production_data.sql into your local development database"
  task :production_data_load => :environment do

    databases = YAML::load(File.open(Rails.root.join('config', 'database.yml')))

    case databases[Rails.env]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(databases[Rails.env])

        commands = []
        commands << "mysql"
        if databases[Rails.env]["host"].present?
          commands << "-h #{databases[Rails.env]["host"]}"
        end
        commands << "-u #{databases[Rails.env]["username"]}"
        if databases[Rails.env]["password"].present?
          commands << "-p#{databases[Rails.env]["password"]}"
        end
        commands << "#{databases[Rails.env]["database"]}"
        commands << " < db/production_data.sql"

        result = `#{commands.join(' ')}`

        if result.present?
          puts result
        end
      when 'mongodb'
        commands = []
        commands << "cd #{Rails.root.join('db')}"
        commands << "tar -xjf #{Rails.root.join('db', databases[Rails.env]['database'] + '.tar.bz2')}"
        commands << "mongorestore --db #{databases[Rails.env]['database']} #{Rails.root.join('db', 'dump', databases[Rails.env]['database'])}"
        commands << "rm -fr #{Rails.root.join('db', 'dump')} #{Rails.root.join('db', databases[Rails.env]['database'] + '.tar.bz2')}"
        `#{commands.join(' && ')}`
      else
        raise "Task not supported by '#{databases[Rails.env]['adapter']}'"
    end
  end
end

