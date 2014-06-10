module Migrations
  module UuidMigration
    module Helpers
      def convert_all_ids_to_uuid(legacy_prefix: 'legacy')
        # make sure all classes (models) are loaded in memory
        Rails.application.eager_load!

        # stores queries to run before everything else
        base_queries = []

        # stores the models we are going to change
        models_to_convert = []

        # store a reference to converted parent tables - prevents duplicate
        # conversion in STI situations
        parent_tables_converted = []

        # store a reference to converted child fks - prevents duplicate
        # conversion in STI situations
        child_fks_converted = []

        # get all models with an integer primary key
        all_models.each do |model|
          table_name = model.table_name
          pk = model.primary_key

          data_type = get_data_type(table_name, pk)

          if data_type && data_type == 'integer'
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

        # loop through all models and find any belongs_to relationships that
        # reference a model we are going to convert
        all_models.each do |model|
          model.reflect_on_all_associations(:belongs_to).each do |association|
            if association.options[:polymorphic]
              # convert the polymorphic _id column name to a uuid-/ id-friendly string
              child_table_name = association.active_record.table_name
              fk_id = "#{association.name}_id".to_sym
              fk_type = "#{association.name}_type".to_sym

              next if child_fks_converted.include?("#{child_table_name}.#{legacy_prefix}_#{fk_id}")

              base_queries << <<-SQL
                ALTER TABLE #{child_table_name}
                ADD COLUMN #{legacy_prefix}_#{fk_id} integer
              SQL
              base_queries << <<-SQL
                UPDATE #{child_table_name}
                SET #{legacy_prefix}_#{fk_id} = #{fk_id}
              SQL
              base_queries << <<-SQL
                ALTER TABLE #{child_table_name}
                ALTER COLUMN #{fk_id} SET DATA TYPE character varying(36) USING(NULL)
              SQL

              # get a list of 'has_many's that reference this polymorphic
              # association
              pm_parent_associations = []
              all_models.each do |pm_model|
                pm_parent_associations += pm_model.reflect_on_all_associations(:has_many).select do |pm_association|
                  pm_association.options[:as] == association.name
                end
              end

              pm_parent_associations.each do |pm_association|
                parent_models_to_convert = models_to_convert.select do |item|
                  item[:model] == pm_association.active_record
                end
                parent_models_to_convert.each do |parent_model|
                  parent_model[:sql] << <<-SQL
                    UPDATE #{child_table_name} AS c
                    SET #{fk_id} = p.#{parent_model[:model].primary_key}
                    FROM #{parent_model[:model].table_name} AS p
                    WHERE c.#{legacy_prefix}_#{fk_id} = p.#{legacy_prefix}_#{parent_model[:model].primary_key}
                    AND c.#{fk_type} = '#{parent_model[:model].name}'
                  SQL
                end
              end

              child_fks_converted << "#{child_table_name}.#{legacy_prefix}_#{fk_id}"

              # skip onto the next model
              next
            elsif association.options[:class_name]
              parent_model = association.options[:class_name].constantize
            else
              parent_model = association.name.to_s.classify.to_s.constantize
            end
            children = models_to_convert.select do |item|
              item[:model] == parent_model
            end
            children.each do |match|
              fk = association.foreign_key
              match[:children] << {
                model: model,
                foreign_key: fk
              }
              child_table_name = model.table_name
              unless child_fks_converted.include?("#{child_table_name}.#{legacy_prefix}_#{fk}")
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
                child_fks_converted << "#{child_table_name}.#{legacy_prefix}_#{fk}"
              end
            end
          end
        end

        models_to_convert.map do |model|
          converted_sql = []
          model[:sql].map do |sql|
            converted_sql << sql.split("\n").map{ |line| line.strip }.select{ |line| line.present? }.join("\n")
          end
          model[:sql] = converted_sql
        end

        models_to_convert.each do |model|
          model[:model] = model[:model].name
        end

        # now loop over our sql statements and execute them
        sql = [] + base_queries
        models_to_convert.map { |item| sql += item[:sql] if item[:sql].any? }
        sql.map { |query| execute query }
      end

      def convert_all_uuids_to_ids(legacy_prefix: 'legacy')
        # until this is set up...
        raise ActiveRecord::IrreversibleMigration

        # make sure all classes (models) are loaded in memory
        Rails.application.eager_load!

        all_models.each do |model|
          table_name = model.table_name
          pk = model.primary_key

          data_type = get_data_type(table_name, "#{legacy_prefix}_#{pk}")

          if data_type && data_type == 'uuid'
            # TODO: set this up
          end
        end
      end

      private
      def all_models
        @all_models ||= ActiveRecord::Base.descendants.select do |model|
          model != ActiveRecord::SchemaMigration
        end
      end

      def get_data_type(table, column)
        results = execute <<-SQL
          SELECT data_type
          FROM information_schema.columns
          WHERE table_name = '#{table}'
          AND column_name = '#{column}'
        SQL
        results.first && results.first['data_type'] || false
      end
    end
  end
end

ActiveRecord::Migration.class_eval do
  include Migrations::UuidMigration::Helpers
end
