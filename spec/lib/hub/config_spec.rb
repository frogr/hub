require 'rails_helper'

RSpec.describe Hub::Config do
  describe '.current' do
    it 'returns a config instance' do
      expect(described_class.current).to be_a(Hub::Config)
    end
  end

  describe 'attributes' do
    let(:config) { described_class.new }

    it 'has default values' do
      expect(config.app_name).to eq('Hub')
      expect(config.tagline).to eq('Ship faster')
      expect(config.description).to eq('Rails SaaS starter')
      expect(config.support_email).to eq('support@example.com')
      expect(config.primary_color).to eq('#3B82F6')
      expect(config.passwordless_auth).to be true
      expect(config.stripe_payments).to be true
      expect(config.admin_panel).to be true
      expect(config.products).to eq([])
    end
  end

  describe 'computed properties' do
    let(:config) { described_class.new(app_name: 'My App') }

    it 'generates app_class_name from app_name' do
      expect(config.app_class_name).to eq('MyApp')
    end

    it 'generates logo_text from app_name' do
      expect(config.logo_text).to eq('My App')
    end

    it 'generates footer_text with current year' do
      expect(config.footer_text).to eq("© #{Date.current.year} My App. All rights reserved.")
    end

    it 'uses font_family as heading_font_family by default' do
      expect(config.heading_font_family).to eq('Inter')
    end
  end

  describe 'validations' do
    let(:config) { described_class.new }

    it 'requires app_name' do
      config.app_name = ''
      expect(config).not_to be_valid
      expect(config.errors[:app_name]).to include("can't be blank")
    end

    it 'validates email format' do
      config.support_email = 'invalid'
      expect(config).not_to be_valid
      expect(config.errors[:support_email]).to include('is invalid')
    end

    it 'validates color format' do
      config.primary_color = 'red'
      expect(config).not_to be_valid
      expect(config.errors[:primary_color]).to include('is invalid')
    end
  end

  describe '#css_variables' do
    let(:config) { described_class.new }

    it 'returns CSS variables hash' do
      variables = config.css_variables
      expect(variables['--color-primary']).to eq('#3B82F6')
      expect(variables['--font-family']).to eq('Inter')
      expect(variables['--border-radius']).to eq('0.375rem')
    end
  end

  describe '#save' do
    let(:config) { described_class.new }
    let(:config_path) { Rails.root.join('tmp', 'test_config.yml') }

    before do
      stub_const('Hub::Config::CONFIG_PATH', config_path)
    end

    after do
      FileUtils.rm_f(config_path)
    end

    it 'saves to YAML file' do
      config.save
      expect(File.exist?(config_path)).to be true
      loaded = YAML.load_file(config_path)
      expect(loaded['app_name']).to eq('Hub')
    end
  end
end