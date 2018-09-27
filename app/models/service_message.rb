class ServiceMessage < ApplicationRecord
  before_save :prepopulate_date, :randomize_message
  enum status: [:pending, :inflight, :succeeded]

  def self.reseed
    random = Random.new
    identifiers = 6.times.map{ |x| random.rand(10000..99999) }

    ActiveRecord::Base.transaction do
      ServiceMessage.destroy_all
      [[:sms, 500, :pending],
       [:sms, 500, :inflight],
       [:sms, 600, :pending, Time.now - 30.minutes],
       [:sms, 600, :pending, Time.now - 29.minutes],
       [:email, 900, :succeeded],
       [:messenger, 333, :pending, Time.now - 30.minutes],
       [:messenger, 333, :pending, Time.now - 28.minutes],
       [:messenger, 333, :pending, Time.now - 25.minutes],
       [:messenger, 333, :succeeded],
      ].each do |k|
        ServiceMessage.create medium: k[0],
                              identifier: k[1],
                              status: k[2],
                              created_at: k[3],
                              body: k[4]
      end
    end
  end

  scope :queue, -> do
    q = """
WITH inflight AS(
  SELECT DISTINCT medium, identifier
    FROM service_messages
    WHERE status = 1
)
SELECT *
  FROM
    (SELECT *,
      RANK() OVER (PARTITION BY medium, identifier ORDER BY created_at ASC) AS rank
      FROM service_messages AS sm
      WHERE status = 0
      AND NOT EXISTS (
        SELECT medium, identifier 
          FROM inflight AS ifl
          WHERE sm.medium = ifl.medium
            AND sm.identifier = ifl.identifier
      )
    ) AS ranked_pending
  WHERE ranked_pending.rank = 1
"""

    return ActiveRecord::Base.connection.execute(q)
  end

  scope :distinct_recipient_pair, -> do
    pluck(:medium, :identifier).uniq
  end

  scope :inflights, -> do
    where(status: :inflight).distinct_recipient_pair
  end

private
  def prepopulate_date
    self.created_at ||= Time.now
  end

  def randomize_message
    self.body ||= SecureRandom.hex(32)
  end
end
