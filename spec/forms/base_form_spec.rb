# frozen_string_literal: true

require 'rails_helper'

class TestForm < BaseForm
  attribute :name, :string
  validates :name, presence: true

  private

  def persist!
    # Test implementation
  end
end

RSpec.describe BaseForm do
  let(:form) { TestForm.new(name: 'Test') }

  describe '.model_name' do
    it 'returns a model name without Form suffix' do
      expect(TestForm.model_name.name).to eq('Test')
    end
  end

  describe '#persisted?' do
    it 'always returns false' do
      expect(form.persisted?).to be false
    end
  end

  describe '#save' do
    context 'with valid attributes' do
      it 'calls persist! and returns true' do
        expect(form).to receive(:persist!)
        expect(form.save).to be true
      end

      it 'wraps persist! in a transaction' do
        expect(ActiveRecord::Base).to receive(:transaction).and_yield
        expect(form).to receive(:persist!)
        form.save
      end
    end

    context 'with invalid attributes' do
      let(:invalid_form) { TestForm.new(name: '') }

      it 'returns false without calling persist!' do
        expect(invalid_form).not_to receive(:persist!)
        expect(invalid_form.save).to be false
      end
    end

    context 'when persist! raises ActiveRecord::RecordInvalid' do
      it 'adds error and returns false' do
        allow(form).to receive(:persist!).and_raise(ActiveRecord::RecordInvalid.new(form))
        expect(form.save).to be false
        expect(form.errors[:base]).to be_present
      end
    end
  end

  describe '#save!' do
    context 'when save succeeds' do
      it 'returns true' do
        allow(form).to receive(:save).and_return(true)
        expect(form.save!).to be true
      end
    end

    context 'when save fails' do
      it 'raises ActiveRecord::RecordInvalid' do
        allow(form).to receive(:save).and_return(false)
        expect { form.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end