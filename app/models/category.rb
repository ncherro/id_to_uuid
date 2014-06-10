class Category < ActiveRecord::Base
  include UuidId

  belongs_to :parent, class_name: 'Category'
  has_many :posts
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'
  has_many :tags, as: :taggable
end
