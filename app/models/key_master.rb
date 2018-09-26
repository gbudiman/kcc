class KeyMaster < ApplicationRecord
  has_many :rate_limiters

  scope :select_limit_parameter, -> {
    select(:id, :threshold, :period)
  }
end
