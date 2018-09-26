class RateLimiter < ApplicationRecord
  belongs_to :key_master
  validates :key_master, presence: true

  enum status: [ :pending, :completed, :failed ]

  def self.handshake client_public_key, threshold: 10, period: 1.minute
    server = OpenSSL::PKey::EC.new(ENV['private_key'])
    shared_secret = server.dh_compute_key(client_public_key)

    kms = KeyMaster.find_or_initialize_by token: Base64.encode64(shared_secret)
    kms.threshold = threshold
    kms.period = period
    kms.save!

    return server.public_key 
  end

  scope :access, -> (access_token) {
    keymasters = KeyMaster.select_limit_parameter.where(token: access_token)

    if limit = keymasters.first
      cost = compute_cost(threshold: limit.threshold, 
                          period: limit.period, 
                          token: access_token)

      if cost < limit.threshold
        
        return Concurrent::Promise.execute do
          rec = record_access(limit.id)  
          puts "Performing long running computation... (ID: #{rec.id})"
          sleep 3

          rec.status = :completed
          rec.save!
          puts "Promise fulfilled (ID: #{rec.id})"
          RateLimiter.find(rec.id)
        end 
      else
        raise RateLimiter::Limited, 'rate limited'
      end
    else
      raise RateLimiter::InvalidToken, 'No such token'
    end
  }

  scope :compute_cost, -> (threshold:, period:, token:) {
    t_zero = Time.now - period.seconds
    where('access_time >= :t', t: t_zero)
      .joins(:key_master)
      .merge(KeyMaster.where(token: token))
      .count
  }

  scope :record_access, -> (key_master_id) {
    RateLimiter.create! key_master_id: key_master_id
  }
end

class RateLimiter::Limited < StandardError
end

class RateLimiter::InvalidToken < StandardError
end