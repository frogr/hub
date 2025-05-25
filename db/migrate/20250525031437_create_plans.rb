class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :stripe_price_id
      t.integer :amount, null: false
      t.string :currency, null: false, default: "usd"
      t.string :interval, null: false
      t.text :features
      t.integer :trial_days, default: 0

      t.timestamps
    end
    add_index :plans, :stripe_price_id, unique: true
  end
end
