require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

  	where_params = params.keys.map(&:to_s).map { |key| "#{key} = ?"}.join(" AND ")

    query = <<-SQL
    SELECT
    	#{table_name}.*
    FROM
    	#{table_name}
    WHERE
    	#{where_params}
    SQL

    parse_all(DBConnection.execute(query, *params.values))
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
