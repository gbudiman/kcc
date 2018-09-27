class CreateServiceMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :service_messages, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.integer                :medium, null: false
      t.string                 :identifier, null: false
      t.integer                :status, null: false
      t.text                   :body, null: false
      t.datetime               :created_at, null: false
    end

    add_index :service_messages, :medium
    add_index :service_messages, :identifier
    add_index :service_messages, :status
    add_index :service_messages, :created_at
  end
end
