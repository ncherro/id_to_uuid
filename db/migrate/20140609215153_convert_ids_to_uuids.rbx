require 'migrations/uuid_migration/helpers'

class ConvertIdsToUuids < ActiveRecord::Migration
  def up
    convert_all_ids_to_uuid
  end

  def down
    convert_all_uuids_to_ids
  end
end
