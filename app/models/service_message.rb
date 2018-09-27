class ServiceMessage < ApplicationRecord
  before_save :prepopulate_date, :randomize_message
  enum status: [:pending, :inflight, :succeeded]
  enum medium: [:sms, :email, :messenger, :pager, :holo]

  def self.reseed
    random = Random.new
    identifiers = 6.times.map{ |x| random.rand(10000..99999) }

    ActiveRecord::Base.transaction do
      ServiceMessage.destroy_all
      # 100.times do |i|
        
      #   rand_stat = random.rand(0...ServiceMessage.statuses.length)
      #   rand_med = random.rand(0...ServiceMessage.media.length)

      #   s = {
      #     medium: rand_med,
      #     identifier: identifiers[random.rand(0...identifiers.length)],
      #     status: rand_stat,
      #     created_at: Time.now - rand(10..10000).seconds
      #   }


      #   #ap s
      #   t = ServiceMessage.create! s
      #   #ap t
      # end
      ServiceMessage.create medium: :sms, identifier: 500, status: :pending, body: 'is_pending'
      ServiceMessage.create medium: :sms, identifier: 500, status: :inflight, body: 'is_inflight'
      ServiceMessage.create medium: :sms, identifier: 600, status: :pending, body: 'show_this'
    end
  end

  scope :queue, -> do
    q = """
WITH inflight AS(
  SELECT DISTINCT medium, identifier
    FROM service_messages
    WHERE status = 0
)
SELECT * 
  FROM service_messages
  WHERE status = 1
  AND (medium || identifier) NOT IN (SELECT (medium || identifier) FROM inflight)
  ORDER BY created_at ASC
  LIMIT 1"""

    return ActiveRecord::Base.connection.execute(q)
  
  end

private
  def prepopulate_date
    self.created_at ||= Time.now
  end

  def randomize_message
    self.body ||= SecureRandom.hex(32)
  end
end
