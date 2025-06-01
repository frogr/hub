class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.string :event_type
      t.string :event_id
      t.datetime :processed_at

      t.timestamps
    end
    add_index :webhooks, :event_id, unique: true
  end
end
