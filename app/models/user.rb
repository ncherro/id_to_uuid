class User < ActiveRecord::Base
  include UuidId

  has_many :posts
end
