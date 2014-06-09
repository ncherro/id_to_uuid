module UuidMigration
  module Helpers
    def strip_lines(str)
      str.split("\n").map { |line| line.strip }.select { |line| line.present? }.join("\n")
    end

    def convert_all_ids_to_uuid(legacy_prefix: 'legacy')

      raise legacy_prefix

      # make sure all classes (models) are loaded in memory
      Rails.application.eager_load!
      all_models = ActiveRecord::Base.descendants

      # use this to run queries on the db
      connection = ActiveRecord::Base.connection

      # this will hold the models we are going to change
      models_to_convert = []

      # this stores a reference to converted parent tables - used to prevent
      # redoing uuid conversion in STI situations
      parent_tables_converted = []

      # first, get all models with an integer primary key
      all_models.each do |model|
        table_name = model.table_name
        pk = model.primary_key
        results = connection.execute <<-SQL
          SELECT data_type
          FROM information_schema.columns
          WHERE table_name = '#{table_name}'
          AND column_name = '#{pk}'
        SQL
        if results.first['data_type'] == 'integer'
          # set up our queries
          sql = []
          unless parent_tables_converted.include?(table_name)
            sql << <<-SQL
            ALTER TABLE #{table_name}
            ADD COLUMN #{legacy_prefix}_#{pk} integer
            SQL
            sql << <<-SQL
            UPDATE #{table_name} SET #{legacy_prefix}_#{pk} = #{pk}
            SQL
            sql << <<-SQL
            ALTER TABLE #{table_name}
            ALTER COLUMN #{pk} DROP DEFAULT,
            ALTER COLUMN #{pk} SET DATA TYPE UUID USING(uuid_generate_v4()),
            ALTER COLUMN #{pk} SET DEFAULT uuid_generate_v4()
            SQL
            sql << <<-SQL
            DROP SEQUENCE #{table_name}_#{pk}_seq
            SQL
            parent_tables_converted << table_name
          end
          models_to_convert << {
            model: model,
            children: [],
            sql: sql
          }
        end
      end

      # loop through ALL models and find any belongs_to relationships that
      # reference a model we are going to convert
      all_models.each do |model|
        model.reflect_on_all_associations(:belongs_to).each do |association|
          if association.options[:class_name]
            parent_model = association.options[:class_name].constantize
          else
            parent_model = association.name.to_s.classify.to_s.constantize
          end
          matches = models_to_convert.select do |item|
            item[:model] == parent_model
          end
          matches.each do |match|
            fk = association.foreign_key
            match[:children] << {
              model: model,
              foreign_key: fk
            }
            child_table_name = model.table_name
            match[:sql] << <<-SQL
              ALTER TABLE #{child_table_name}
              ADD COLUMN #{legacy_prefix}_#{fk} integer
            SQL
            match[:sql] << <<-SQL
              UPDATE #{child_table_name} SET #{legacy_prefix}_#{fk} = #{fk}
            SQL
            match[:sql] << <<-SQL
              ALTER TABLE #{child_table_name}
              ALTER COLUMN #{fk} TYPE uuid USING(NULL)
            SQL
            match[:sql] << <<-SQL
              UPDATE #{child_table_name} AS c
              SET #{fk} = p.#{parent_model.primary_key}
              FROM #{parent_model.table_name} AS p
              WHERE c.#{legacy_prefix}_#{fk} = p.#{legacy_prefix}_#{parent_model.primary_key}
            SQL
          end
        end
      end

      models_to_convert.map do |model|
        converted_sql = []
        model[:sql].map do |sql|
          converted_sql << strip_lines(sql)
        end
        model[:sql] = converted_sql
      end

      models_to_convert.each do |model|
        model[:model] = model[:model].name
      end

      # now loop over our sql statements and execute them
      sql = []
      models_to_convert.map { |item| sql += item[:sql] if item[:sql].any? }

      sql.each do |query|
        puts %Q{\nexecute "#{query}"}
      end
    end
  end
end

ActiveRecord::Migration.class_eval do
  include UuidMigration::Helpers
end
