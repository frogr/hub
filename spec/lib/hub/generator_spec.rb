require 'rails_helper'

RSpec.describe Hub::Generator do
  let(:config) do
    Hub::Config.new(
      app_name: 'TestApp',
      support_email: 'test@example.com',
      primary_color: '#FF0000'
    )
  end
  let(:generator) { described_class.new(config) }

  describe '#generate!' do
    it 'returns true on success' do
      allow(generator).to receive(:update_ruby_files)
      allow(generator).to receive(:update_view_files)
      allow(generator).to receive(:update_stylesheets)
      allow(generator).to receive(:update_config_files)
      allow(generator).to receive(:puts)

      expect(generator.generate!).to be true
    end

    it 'returns false on error' do
      allow(generator).to receive(:update_ruby_files).and_raise(StandardError.new('Test error'))
      allow(generator).to receive(:puts)

      expect(generator.generate!).to be false
    end
  end
end
