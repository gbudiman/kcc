class CreateKeyMasters < ActiveRecord::Migration[5.2]
  def change
    create_table :key_masters, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.string                 :token, null: false
      t.integer                :threshold, null: false, default: 10
      t.integer                :period, null: false, default: 60
      t.datetime               :created_at, null: false
      t.datetime               :expires_at, null: false
    end

    add_index :key_masters, :token, unique: true
  end
end
