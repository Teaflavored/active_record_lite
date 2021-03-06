require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

#validate method adds a method to a list of all the methods that would be run


module Validations

  def validate(method)
    define_method "errors" do
      @errors ||= Hash.new
    end
    @validate_methods ||= []
    @validate_methods << method unless @validate_methods.include?(method)
    # obj = self.new(@attributes)
    # obj.send(method)

  end

  def validate_methods
    @validate_methods
  end

  def validate_methods_clear
    @validate_methods = []
  end
end

class SQLObject 
  extend Validations

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
    self.class.attributes
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
    unless self.class.validate_methods.nil?
      @errors = {}
      self.class.validate_methods.each do |method|
        self.send(method)
      end
      raise error_msg.to_s unless @errors.keys.empty?
    # validate :name_cant_be_empty
      self.class.validate_methods_clear
    end

    return insert if self.id.nil?
    update
  end


  def error_msg
    array_of_msg = []
    @errors.each do |key, value|
      array_of_msg << "#{key} #{value}"
    end

    array_of_msg
  end
end



class Cat < SQLObject
  finalize!
  validate :name_cant_be_empty
  validate :id_cant_be_empty

  def name_cant_be_empty
    if self.name.nil? || self.name.length == 0
      errors[:name] = "can't be empty"
    end
  end

  def id_cant_be_empty
    if self.id.nil?
      errors[:id] = "can't be null"
    end
  end
end
