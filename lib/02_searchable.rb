require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params, class_name = self)

  	where_params = params.keys.map(&:to_s).map { |key| "#{key} = ?"}.join(" AND ")

    query = <<-SQL
    SELECT
    	#{class_name.table_name}.*
    FROM
    	#{class_name.table_name}
    WHERE
    	#{where_params}
    SQL
    all_objects = DBConnection.execute(query, *params.values).map do |hash|
      class_name.new(hash)
    end
    # all_objects = parse_all(DBConnection.execute(query, *params.values))
    Relation.new(all_objects)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end


class Relation
  attr_reader :objects

  def initialize(arr_objects) 
    @objects = arr_objects
  end

  def where(params)
    return Relation.new([]) if @objects.empty?
    SQLObject.where(params, @objects.first.class)
  end
end