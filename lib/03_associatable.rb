require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def primary_key
    if @options[:primary_key].nil?
      :id
    else
      @options[:primary_key]
    end
  end

  def table_name
    model_class.table_name
  end

  def foreign_key
    if @options[:foreign_key].nil? 
      if @self_class_name.nil?
        "#{@name}_id".to_sym
      else
        "#{@self_class_name.singularize.downcase}_id".to_sym
      end
    else
      @options[:foreign_key]
    end
  end

  def class_name
    if @options[:class_name].nil?
      "#{@name}".singularize.camelize
    else
      @options[:class_name].downcase.singularize.camelize
    end
  end

  def model_class
    class_name.constantize
  end
end

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    @name = name
    @options = options
  end
end

class HasManyOptions < AssocOptions
  attr_reader :self_class_name

  def initialize(name, self_class_name, options = {})
    @name = name
    @self_class_name = self_class_name
    @options = options
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method "#{name}" do 
      query = <<-SQL
      SELECT
        *
      FROM
        #{options.table_name}
      WHERE
        #{options.primary_key} = ?
      SQL

      options.model_class.new(DBConnection.execute(query, self.send(options.foreign_key)).first)
    end

    
  end

  def has_many(name, options = {})
    #has_many(
    # :cats
    # foreign_key: :owner_id
    # primary_key: :id
    #  )
    options = HasManyOptions.new(name, self.to_s, options)
    define_method "#{name}" do
      query = <<-SQL
      SELECT
        *
      FROM
        #{options.table_name}
      WHERE
        #{options.foreign_key} = ?
      SQL

      arr_of_hash_obj = DBConnection.execute(query, self.send(options.primary_key))
      p arr_of_hash_obj
      arr_of_hash_obj.map do |hash_obj|
        options.model_class.new(hash_obj)
      end
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
