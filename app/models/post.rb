class Post < ActiveRecord::Base
  belongs_to :category, class_name: 'Category'
  belongs_to :user
  has_many :tags, as: :taggable
end
