class CreatePasswordlessSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :passwordless_sessions do |t|
      t.string :authenticatable_type
      t.integer :authenticatable_id
      t.string :token
      t.string :user_agent
      t.string :remote_addr
      t.datetime :expires_at
      t.datetime :timeout_at
      t.datetime :claimed_at

      t.timestamps
    end

    add_index :passwordless_sessions, [ :authenticatable_type, :authenticatable_id ]
    add_index :passwordless_sessions, :token, unique: true
  end
end
