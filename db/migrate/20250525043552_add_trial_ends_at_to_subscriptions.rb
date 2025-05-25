class AddTrialEndsAtToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :trial_ends_at, :datetime
  end
end
