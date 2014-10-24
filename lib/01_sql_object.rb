require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
class Relation

  def self.objects
    @objects
  end

  def self.create_relation
    @objects = []
  end

  def self.add_to_relation(new_objects)
    if new_objects.is_a?(Array)
      @objects += new_objects
    else
      @objects += [new_objects]
    end
  end

  attr_reader :relation_objects

  def initialize(list_of_objects = self.class.objects)
    @relation_objects = list_of_objects
  end

  def find(id)
    SQLObject.find(id)
  end
end

class SQLObject 

  def self.columns

    #all_cats returns array with first array being column names
    all_cats = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    SQL

    all_cats.first.map(&:to_sym)
    # ...
  end

  def self.finalize!
    define_method "attributes" do
      @attributes ||= {}
    end

    columns.each do |column|
      define_method "#{column}" do
        self.attributes[column]
      end

      define_method "#{column}=" do |value|
        self.attributes[column] = value
      end
    end
  end

  def initialize(params= {})
    params.each do |column_name, value|
      raise "unknown attribute '#{column_name}'" unless self.class.columns.include?(column_name.to_sym)
      self.send("#{column_name}=", value)
    end
  end

  def self.table_name
    @table_name ||= self.to_s.downcase.pluralize(:en)
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.all
    query = <<-SQL
    SELECT
      *
    FROM
      #{table_name}
    SQL

    parse_all(DBConnection.execute(query))
  end

  def self.parse_all(results)

    results.map do |hash|
      self.new(hash)
    end

  end

  def self.find(id)
    query = <<-SQL
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    LIMIT
      1
    SQL

    self.new(DBConnection.execute(query, id).first)
  end

  def attributes
    # ...
  end

  def attribute_values
    attributes.values
  end

  def insert

    col_names = self.attributes.keys.map(&:to_s)
    value_names = Array.new(col_names.count) { '?' }.join(",")

    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names.join(",")})
    VALUES
      (#{value_names})
    SQL

    DBConnection.execute(query, *self.attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update

    set_rows = self.class.columns.map { |column| "#{column} = ?"}.join(",")
    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_rows}
      WHERE
        #{self.class.table_name}.id = ?
    SQL

    DBConnection.execute(query, *self.attribute_values, self.id)
  end

  def save
    return insert if self.id.nil?
    update
  end

end
