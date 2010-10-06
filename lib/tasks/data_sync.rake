namespace :db do
  desc "Refreshes your local development environment to the current production database" 
  task :pull do
    `cap remote_db_runner`
    `rake db:production_data_load`
  end
  
  desc "Dump the current database to a MySQL file" 
  task :database_dump => :environment do
    abcs = ActiveRecord::Base.configurations

    case abcs[Rails.env]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(abcs[Rails.env])
        
        File.open("db/#{Rails.env}_data.sql", "w+") do |f|
          commands = []
          commands << "mysqldump"
          commands << "-h #{abcs[Rails.env]["host"]}"
          commands << "-u #{abcs[Rails.env]["username"]}"
          if abcs[Rails.env]["password"].present?          
            commands << "-p#{abcs[Rails.env]["password"]}"
          end
          commands << "#{abcs[Rails.env]["database"]}"
          commands << " > db/production_data.sql"          
          
          `#{commands.join(' ')}`          
        end
      else
        raise "Task not supported by '#{abcs[Rails.env]['adapter']}'" 
    end
  end

  desc "Loads the production data downloaded into db/production_data.sql into your local development database" 
  task :production_data_load => :environment do

    abcs = ActiveRecord::Base.configurations

    case abcs[Rails.env]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(abcs[Rails.env])
        
        commands = []
        commands << "mysql"
        if abcs[Rails.env]["host"].present?
          commands << "-h #{abcs[Rails.env]["host"]}"
        end
        commands << "-u #{abcs[Rails.env]["username"]}"
        if abcs[Rails.env]["password"].present?          
          commands << "-p#{abcs[Rails.env]["password"]}"
        end
        commands << "#{abcs[Rails.env]["database"]}"
        commands << " < db/production_data.sql"                  

        result = `#{commands.join(' ')}`        

        if result.present?
          puts result
        end
      else
        raise "Task not supported by '#{abcs[Rails.env]['adapter']}'" 
    end
  end
end
