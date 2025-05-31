module Hub
  module Transformers
    class ConfigurationFile < Base
      def transform
        log "Transforming configuration files..."

        config_files = find_files("config/**/*.rb")

        config_files.each do |file|
          update_config_file(file)
        end

        # Update environment files
        update_environment_files

        # Update locale files
        update_locale_files

        # Update database.yml if needed
        update_database_config

        # Update cable.yml if needed
        update_cable_config
      end

      private

      def update_config_file(path)
        replace_in_file(path, replacements)
      end

      def replacements
        {
          '"Hub"' => "\"#{config.app_name}\"",
          "'Hub'" => "'#{config.app_name}'",
          "module Hub" => "module #{config.app_class_name}",
          "Hub::" => "#{config.app_class_name}::",
          '"Hub Application"' => "\"#{config.app_name} Application\"",
          '"Hub Development"' => "\"#{config.app_name} Development\""
        }
      end

      def update_environment_files
        %w[development.rb production.rb test.rb].each do |env_file|
          path = Rails.root.join("config/environments", env_file)
          next unless File.exist?(path)

          replace_in_file(path, {
            "config.application_name = \"Hub\"" => "config.application_name = \"#{config.app_name}\"",
            "config.app_name = \"Hub\"" => "config.app_name = \"#{config.app_name}\"",
            "Hub Application" => "#{config.app_name} Application",
            "Hub Development" => "#{config.app_name} Development"
          })
        end
      end

      def update_locale_files
        locale_files = find_files("config/locales/**/*.yml")

        locale_files.each do |path|
          content = read_file(path)
          original_content = content.dup

          # Update app name references in YAML
          content.gsub!(/Hub(?=:|\s)/, config.app_name)

          if content != original_content
            write_file(path, content)
          end
        end
      end

      def update_database_config
        # Skip database.yml updates - database names should remain as hub_*
        # to avoid breaking existing deployments and development environments
      end

      def update_cable_config
        # Skip cable.yml updates - channel prefixes should remain as hub_*
        # to avoid breaking existing deployments
      end
    end
  end
end
