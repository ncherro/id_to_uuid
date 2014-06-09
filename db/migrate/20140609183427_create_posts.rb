class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.belongs_to :category, index: true
      t.belongs_to :user, index: true

      t.string :type, index: true

      t.timestamps
    end
  end
end
