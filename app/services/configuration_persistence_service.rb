class ConfigurationPersistenceService
  attr_reader :config, :config_path

  def initialize(config, config_path = Rails.root.join("config", "hub_config.yml"))
    @config = config
    @config_path = config_path
  end

  def save
    ensure_config_directory_exists
    write_config_file
    true
  rescue StandardError => e
    Rails.logger.error "Failed to save configuration: #{e.message}"
    false
  end

  def load
    return default_config unless File.exist?(config_path)

    loaded_config = YAML.load_file(config_path, permitted_classes: [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess])
    config.assign_attributes(loaded_config)
    config
  rescue StandardError => e
    Rails.logger.error "Failed to load configuration: #{e.message}"
    default_config
  end

  private

  def ensure_config_directory_exists
    FileUtils.mkdir_p(File.dirname(config_path))
  end

  def write_config_file
    File.write(config_path, config_data.to_yaml)
  end

  def config_data
    # Convert to plain hash to avoid YAML serialization issues
    deep_stringify_keys(config.attributes)
  end
  
  def deep_stringify_keys(hash)
    hash.transform_keys(&:to_s).transform_values do |value|
      case value
      when Hash, ActiveSupport::HashWithIndifferentAccess
        deep_stringify_keys(value)
      when Array
        value.map { |v| v.is_a?(Hash) ? deep_stringify_keys(v) : v }
      else
        value
      end
    end
  end

  def default_config
    config
  end
end
