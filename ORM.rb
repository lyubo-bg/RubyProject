require "mysql2"

module MyORM
  class Connection

    # The constructor accepts a connection hash 
    # adapter: which database provider you will use 
    # database, host, username & password 
    def initialize(adapter:, database:,host: nil, username: nil, password: nil)
      if(adapter == "mysql2")
        @connection = establish_connection_mysql2(database: database, host: host, username: username, password: password)
      elsif (adapter == 'sqlite3')
        @connection = establish_connection_sqlite
      else
        puts "You have given this adapter: #{adapter}, which is invalid"
      end

    end

    attr_accessor :connection

    #Makes connection with the server
    def establish_connection_mysql2(database:,host:,username:,password:)
      Mysql2::Client.new(:host => host, :username => username, :password => password, :database => database)
    end 

    def establish_connection_sqlite(database:,host:)
      
    end
  end

  class Base
    def initialize(connection)
      @connection = connection
      @name = self.class.name.downcase
      if make_attr_accessor
        puts "Your mapping has been done successfully!"
      else
        puts "Your mapping can't be done the table
        you have chosen probably doesn't exist!"
      end
    end

    attr_accessor :connection, :name

    def make_attr_accessor
      if table_exists? name
        schema = get_partial_schema
        schema.each do |column|
          create_attr(column["Field"])
        end
        return true
      end
      false
    end

    def create_initialize()
      schema = get_full_schema
      constructor_params_arr = []
      schema.each do |row| 
        constructor_params_arr << create_initialize_param row
      end
      constructor_params = constructor_params_arr.join(", ")
      initialize_body = "def initialize(con, #{constructor_params}) 
                           super(con)
                           schema = get_partial_schema
                           schema.each do |row|
                             add_prop_to_db row['Field'].to_s, row['Field'] if row['Field'] 
                           end
                         end"
      self.class_eval(initialize_body)
    end

    def create_initialize_param(row) 
      if row["NULL"] == 'NO'
        row["Field"] + ':'
      else
        row["Field"] + ": nil"
      end
    end

    def create_method( name, &block )
      self.class.send( :define_method, name, &block )
    end

    def create_attr( name )
      create_method( "#{name}=".to_sym ) do |val| 
        instance_variable_set( "@" + name, val)
      end

      create_method( name.to_sym ) do 
        instance_variable_get( "@" + name ) 
      end
    end

    #Gets partial table schema by class name
    def get_partial_schema()
      query_string = "SHOW COLUMNS FROM #{name}"
      result = @connection.connection.query(query_string)
      table_info = []
      result.each do | row |
        temp = {}
        temp["Field"], temp["Type"] = row["Field"], row["Type"]
        table_info << temp
      end
      table_info
    end

    #Gets full table schema by class name
    def get_full_schema()
      query_string = "SHOW COLUMNS FROM #{name}"
      result = @connection.connection.query(query_string)
      result.each { |row| puts row }
    end

    def table_exists?(name)
      begin
        connection.connection.query("show columns from #{name}")
      rescue => ex
        return false
      end
      true
    end
  end

  class BaseUtils
    def self.create_initialize_param(row) 
      if row["NULL"] == 'NO'
        row["Field"] + ':'
      else
        row["Field"] + ": nil"
      end
    end
  end
end