class CreateGatekeepers < ActiveRecord::Migration[5.2]
  def change
    create_table :gatekeepers, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.belongs_to             :key_master
      t.integer                :status, null: false, default: 0
      t.string                 :symfunc, null: true
      t.integer                :nonce, null: false, default: -1
      t.datetime               :access_time, null: false
    end

    add_index :gatekeepers, :status
    add_index :gatekeepers, [:key_master_id, :symfunc, :nonce], unique: false
    add_index :gatekeepers, :access_time, order: { access_time: 'DESC NULLS LAST' }
  end
end
