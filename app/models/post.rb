class Post < ActiveRecord::Base
  belongs_to :category, class_name: 'Category'
  belongs_to :user
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
end
