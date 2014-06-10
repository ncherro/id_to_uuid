module UuidId
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order("created_at DESC") }
    scope :first, -> { order("created_at").first }
    scope :last, -> { order("created_at DESC").first }
  end
end
