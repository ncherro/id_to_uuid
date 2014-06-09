class Post < ActiveRecord::Base
  belongs_to :category, class_name: 'Category'
  belongs_to :user
end
