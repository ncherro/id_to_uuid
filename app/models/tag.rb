class Tag < ActiveRecord::Base
  include UuidId

  has_many :taggings, dependent: :destroy
end
