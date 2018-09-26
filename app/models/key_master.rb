class KeyMaster < ApplicationRecord
  has_many :rate_limiters
  before_save :coalesce_validity_lifetime

  scope :select_limit_parameter, -> {
    select(:id, :threshold, :period)
  }

  scope :invalidate, -> (token) {
    find_by(token: token).update(expires_at: Time.now - 1.seconds)
  }

private
  def coalesce_validity_lifetime
    t = Time.now
    self.created_at ||= t
    self.expires_at ||= t + 1.hour
  end
end
