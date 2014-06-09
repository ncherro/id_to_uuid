require 'uuid_migration/helpers'

class ConvertIdsToUuids < ActiveRecord::Migration
  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
