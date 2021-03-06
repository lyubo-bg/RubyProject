require 'sqlite3'

module MyORM
  class SQLite3
    class << self
      def connection= con
        @@connection = con
      end

      def connection
        @@connection
      end

      def add_object_to_db params
        tablename = params.shift
        names, values = [], []
        params.each do |pair|
          names << pair[0]
          if pair[1].class == String
            values << "'" + pair[1] + "'"
          elsif pair[1] == true
            values << 1
          elsif pair[1] == false
            values << 0
          else
            values << pair[1]
          end
        end
        joined_names, joined_values = names.join(', '), values.join(', ')
        s = "INSERT INTO #{tablename} (#{joined_names}) VALUES (#{joined_values})"
        connection.connection.execute s
        get_id tablename
      end

      def get_full_schema name
        connection.connection.table_info name
      end 

      def table_exists?(name)
        if (connection.connection.table_info name).to_s == '[]'
          return false
        end
        return true
      end

      def get_id tablename
        __get_id (get_primary_key_name(tablename)), tablename
      end

      def get_prop_from_db primary_key, id, name, table_name
        s = "SELECT #{name} FROM #{table_name} WHERE #{primary_key} = #{id}"
        res = @@connection.connection.execute s
        result = []
        res.each { |n| result << n }
        begin
          result[0][0]
        rescue Exception => e
          nil
        end
        
      end

      def destroy primary_key, id, table_name
        @@connection.connection.execute "DELETE FROM #{table_name} WHERE #{primary_key} = #{id}"
      end

      def add_prop_to_db primary_key, id,table_name, prop_name , value                                    
        @@connection.connection.execute "UPDATE #{table_name}
                                        SET #{prop_name} = '#{value}'
                                        WHERE #{primary_key} = #{id}"                                     
      end

      def create_initialize_param (row)
        return row["name"] + ":" if row["notnull"] == "NO" && row["pk"] == 1
        row["name"] + ": nil" 
      end

      private

      def get_primary_key_name tablename
        connection.connection.table_info(tablename).each do |row|
          if row["pk"]
            return row["name"]
          end
        end
      end

      def __get_id primary_key, tablename
        rowid = connection.connection.last_insert_row_id
        query_string = "SELECT #{primary_key} from #{tablename} WHERE rowid = #{rowid}"
        res = connection.connection.execute (query_string)
        res[0][0]
      end
    end
  end
end 