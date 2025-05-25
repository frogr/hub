class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :status, null: false, default: "active"
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, default: false
      t.string :stripe_customer_id
      t.references :plan, foreign_key: true

      t.timestamps
    end
    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
