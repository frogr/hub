# frozen_string_literal: true

class BaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  def self.model_name
    ActiveModel::Name.new(self, nil, name.gsub(/Form$/, ""))
  end

  def persisted?
    false
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      persist!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def save!
    raise ActiveRecord::RecordInvalid, self unless save
    true
  end

  private

  def persist!
    raise NotImplementedError, "#{self.class} must implement #persist!"
  end
end
