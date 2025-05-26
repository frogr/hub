module Hub
  module Transformers
    class ConfigurationFile < Base
      def transform
        log "Transforming configuration files..."

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

      def update_environment_files
        %w[development.rb production.rb test.rb].each do |env_file|
          path = Rails.root.join("config/environments", env_file)
          next unless File.exist?(path)

          replace_in_file(path, {
            "config.application_name = \"Hub\"" => "config.application_name = \"#{config.app_name}\"",
            "Hub Application" => "#{config.app_name} Application"
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
        path = Rails.root.join("config/database.yml")
        return unless File.exist?(path)

        content = read_file(path)
        original_content = content.dup

        # Update database names
        old_db_prefix = "hub"
        new_db_prefix = config.app_name.downcase.gsub(/[^a-z0-9]/, "_")

        if old_db_prefix != new_db_prefix
          content.gsub!(/database: #{old_db_prefix}_/, "database: #{new_db_prefix}_")
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def update_cable_config
        path = Rails.root.join("config/cable.yml")
        return unless File.exist?(path)

        content = read_file(path)
        original_content = content.dup

        # Update channel prefix
        old_prefix = "hub"
        new_prefix = config.app_name.downcase.gsub(/[^a-z0-9]/, "_")

        if old_prefix != new_prefix
          content.gsub!(/channel_prefix: #{old_prefix}_/, "channel_prefix: #{new_prefix}_")
        end

        if content != original_content
          write_file(path, content)
        end
      end
    end
  end
end
