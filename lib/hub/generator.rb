require_relative "transformers/base"
require_relative "transformers/ruby_file"
require_relative "transformers/view_file"
require_relative "transformers/stylesheet"
require_relative "transformers/configuration_file"

module Hub
  class Generator
    attr_reader :config, :dry_run

    def initialize(config = nil, dry_run: false)
      @config = config || Hub::Config.current
      @dry_run = dry_run
    end

    def generate!
      puts "Starting app regeneration..."
      puts "Dry run mode: #{dry_run ? 'ON' : 'OFF'}"
      puts "-" * 50

      # Validate configuration first
      unless config.valid?
        puts "ERROR: Invalid configuration"
        config.errors.full_messages.each do |message|
          puts "  - #{message}"
        end
        return false
      end

      # Run all transformers in order
      transformers = [
        Transformers::RubyFile,
        Transformers::ViewFile,
        Transformers::Stylesheet,
        Transformers::ConfigurationFile
      ]

      transformers.each do |transformer_class|
        transformer = transformer_class.new(config, dry_run: dry_run)
        transformer.transform
      rescue StandardError => e
        puts "ERROR in #{transformer_class.name}: #{e.message}"
        puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
        return false
      end

      puts "-" * 50
      puts "App regeneration complete!"
      puts "Your app has been customized with the following:"
      puts "  App Name: #{config.app_name}"
      puts "  Primary Color: #{config.primary_color}"
      puts "  Products: #{config.products.size}"

      if dry_run
        puts "\nThis was a dry run. No files were actually modified."
        puts "Run without --dry-run to apply changes."
      else
        puts "\nIMPORTANT: Restart your Rails server to see the changes."
      end

      true
    end

    def self.run!(options = {})
      new(nil, **options).generate!
    end
  end
end
