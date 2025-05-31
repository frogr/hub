class GeneratorExecutionService
  attr_reader :config, :dry_run, :logger

  def initialize(config, dry_run: false, logger: Rails.logger)
    @config = config
    @dry_run = dry_run
    @logger = logger
  end

  def execute
    validate_configuration!

    result = generator.generate!

    if result
      log_success
      Result.new(success: true, message: "App regenerated successfully")
    else
      log_failure
      Result.new(success: false, message: "Failed to regenerate app", errors: generator_errors)
    end
  rescue InvalidConfigurationError => e
    # Re-raise InvalidConfigurationError without catching it
    raise
  rescue StandardError => e
    log_exception(e)
    Result.new(success: false, message: "Error during generation", errors: [ e.message ])
  end

  private

  def validate_configuration!
    raise InvalidConfigurationError, "Invalid configuration" unless config.valid?
  end

  def generator
    @generator ||= Hub::Generator.new(config, dry_run: dry_run)
  end

  def generator_errors
    config.errors.full_messages
  end

  def log_success
    logger.info "App regenerated successfully with config: #{config.app_name}"
  end

  def log_failure
    logger.error "Failed to regenerate app: #{generator_errors.join(', ')}"
  end

  def log_exception(exception)
    logger.error "Exception during app generation: #{exception.message}"
    logger.error exception.backtrace.join("\n")
  end

  class Result
    attr_reader :message, :errors

    def initialize(success:, message:, errors: [])
      @success = success
      @message = message
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !success?
    end
  end

  class InvalidConfigurationError < StandardError; end
end
