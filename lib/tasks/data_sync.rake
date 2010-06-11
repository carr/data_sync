namespace :db do
  desc "Refreshes your local development environment to the current production database" 
  task :pull do
    `cap remote_db_runner`
    `rake db:production_data_load --trace`
  end
  
  desc "Dump the current database to a MySQL file" 
  task :database_dump => :environment do
    abcs = ActiveRecord::Base.configurations
    
    case abcs[RAILS_ENV]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
        
        File.open("db/#{RAILS_ENV}_data.sql", "w+") do |f|
          commands = []
          commands << "mysqldump"
          commands << "-h #{abcs[RAILS_ENV]["host"]}"
          commands << "-u #{abcs[RAILS_ENV]["username"]}"
          if abcs[RAILS_ENV]["password"].present?          
            commands << "-p#{abcs[RAILS_ENV]["password"]}"
          end
          commands << "#{abcs[RAILS_ENV]["database"]}"
          commands << " > db/production_data.sql"          
          
          `#{commands.join(' ')}`          
        end
      else
        raise "Task not supported by '#{abcs[RAILS_ENV]['adapter']}'" 
    end
  end

  desc "Loads the production data downloaded into db/production_data.sql into your local development database" 
  task :production_data_load => :environment do
    abcs = ActiveRecord::Base.configurations
    
    case abcs[RAILS_ENV]["adapter"]
      when 'mysql'
        ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
        
        commands = []
        commands << "mysql"
        commands << "-h #{abcs[RAILS_ENV]["host"]}"
        commands << "-u #{abcs[RAILS_ENV]["username"]}"
        if abcs[RAILS_ENV]["password"].present?          
          commands << "-p#{abcs[RAILS_ENV]["password"]}"
        end
        commands << "#{abcs[RAILS_ENV]["database"]}"
        commands << " < db/production_data.sql"                  
        
        `#{commands.join(' ')}`        
      else
        raise "Task not supported by '#{abcs[RAILS_ENV]['adapter']}'" 
    end
  end
end