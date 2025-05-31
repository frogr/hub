class ConfigurationUpdateService
  attr_reader :params, :config, :errors

  def initialize(params, config = Hub::Config.current)
    @params = params
    @config = config
    @errors = []
  end

  def execute
    update_configuration

    if config.valid?
      persist_configuration
      apply_changes if should_apply_changes?
      Result.new(success: true, config: config)
    else
      Result.new(success: false, config: config, errors: config.errors.full_messages)
    end
  rescue StandardError => e
    Result.new(success: false, errors: [ e.message ])
  end

  private

  def update_configuration
    # Only update sections that are actually present in the params
    # This allows partial updates without clearing other sections
    update_nested_attributes(:app) if config_attributes.key?(:app)
    update_nested_attributes(:branding) if config_attributes.key?(:branding)
    update_nested_attributes(:design) if config_attributes.key?(:design)
    update_nested_attributes(:features) if config_attributes.key?(:features)
    update_nested_attributes(:seo) if config_attributes.key?(:seo)
    update_products if params.key?(:products)
  end

  def update_nested_attributes(key)
    config.send("#{key}=", config_attributes[key])
  end

  def update_products
    config.products = ProductsBuilderService.new(params[:products]).build
  end

  def config_attributes
    params[:config_attributes] || {}
  end

  def persist_configuration
    ConfigurationPersistenceService.new(config).save
  end

  def apply_changes
    result = GeneratorExecutionService.new(config).execute
    unless result.success?
      @errors.concat(result.errors)
    end
  end

  def should_apply_changes?
    params[:apply_changes] == "true"
  end

  class Result
    attr_reader :config, :errors

    def initialize(success:, config: nil, errors: [])
      @success = success
      @config = config
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !success?
    end
  end
end
