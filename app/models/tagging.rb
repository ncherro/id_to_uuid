class Tagging < ActiveRecord::Base
  include UuidId

  belongs_to :tag
  belongs_to :taggable, polymorphic: true
end
