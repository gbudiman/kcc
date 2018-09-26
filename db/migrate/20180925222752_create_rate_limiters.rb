class CreateRateLimiters < ActiveRecord::Migration[5.2]
  def change
    create_table :rate_limiters, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.belongs_to             :key_master
      t.integer                :status, null: false, default: 0
      t.integer                :nonce, null: false, default: -1
      t.datetime               :access_time, null: false
    end

    add_index :rate_limiters, :status
    add_index :rate_limiters, [:key_master_id, :nonce], unique: false
    add_index :rate_limiters, :access_time, order: { access_time: 'DESC NULLS LAST' }
  end
end
