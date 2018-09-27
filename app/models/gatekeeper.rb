class Gatekeeper < ApplicationRecord
  belongs_to :key_master
  validates :key_master, presence: true

  enum status: [ :pending, :completed, :failed ]

  before_save :coalesce_access_time

  def self.handshake client_public_key, threshold: 10, period: 1.minute
    server = OpenSSL::PKey::EC.new(ENV['private_key'])
    shared_secret = server.dh_compute_key(client_public_key)

    kms = KeyMaster.find_or_initialize_by token: Base64.encode64(shared_secret)
    kms.threshold = threshold
    kms.period = period
    kms.save!

    return server.public_key 
  end

  scope :access, -> (access_token, symfunc: nil, nonce: 0) do
    resolve_keymaster(access_token, -> (keymaster) do
      cost = compute_cost(keymaster)

      if cost < keymaster.threshold
        rec = record_access(keymaster.id, symfunc, nonce)
        return Concurrent::Promise.execute do
          puts "Performing long running computation... (ID: #{rec.id}, cost: #{sprintf('%.2f', cost)})"
          sleep 7

          rec.status = :completed
          rec.save!
          puts "Promise fulfilled (ID: #{rec.id})"
          Gatekeeper.find(rec.id)
        end 
      else
        raise RateLimiter::Limited, "rate limited, cost: #{cost}"
      end
    end)
  end

  scope :invalidate, -> (access_token) do
    KeyMaster.invalidate(access_token)
  end

  scope :get_state, -> (access_token, symfunc, nonce) do
    resolve_keymaster(access_token, -> (keymaster) do
      where(key_master_id: keymaster.id, symfunc: symfunc, nonce: nonce)
        .order(access_time: :desc).first
    end)
  end

  scope :get_current_usage_cost, -> (access_token) do
    resolve_keymaster(access_token, -> (keymaster) do
      return compute_cost(keymaster)
    end)
  end

  scope :get_quota, -> (access_token) do
    resolve_keymaster(access_token, -> (keymaster) do
      return keymaster.threshold
    end)
  end

  scope :resolve_keymaster, -> (access_token, block) do
    if keymaster = KeyMaster.find_by(token: access_token)
      if Time.now < keymaster.expires_at
        block.call(keymaster)
      else
        raise RateLimiter::ExpiredToken, "Token expires at #{keymaster.expires_at}"
      end
    else 
      raise RateLimiter::InvalidToken, 'No such token'
    end
  end

  scope :compute_cost, -> (keymaster) do
    # Cost formula:
    # b^t / b
    # where b is the decay factor, set to 1000
    # t = delta time within window period
    #     closer to current ~> 1
    #     near the beginning to window ~> 0
    t = Time.now

    cost = 0
    period = keymaster.period
    token = keymaster.token
    get_costs(period: period, token: token, from: t - period.seconds).each do |s|
      delta = period - (t - s.access_time)
      onesie = delta / period
      exp = [(1000 ** onesie) / 1000, 1.0].min # clamp to a max of 1.0
      cost += exp
    end

    return cost
  end

  scope :get_costs, -> (period:, token:, from:) do
    where('access_time >= :t', t: from)
      .joins(:key_master)
      .merge(KeyMaster.where(token: token))
  end

  scope :record_access, -> (key_master_id, symfunc, nonce) do
    Gatekeeper.create! key_master_id: key_master_id, 
                       symfunc: symfunc,
                       nonce: nonce
  end

private
  def coalesce_access_time
    self.access_time ||= Time.now
  end
end