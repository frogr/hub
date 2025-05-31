module Hub
  module Transformers
    class ViewFile < Base
      def transform
        log "Transforming view files..."

        view_files = find_files("app/views/**/*.erb") + find_files("app/views/**/*.html")

        view_files.each do |file|
          transform_file(file)
        end
      end

      private

      def transform_file(path)
        update_view_file(path)
      end

      def build_replacements
        replacements = {}

        # App name in titles and content
        replacements[/<title>Hub\b/] = "<title>#{config.app_name}"
        replacements[/>Hub</] = ">#{config.app_name}<"
        replacements[/"Hub"/] = "\"#{config.app_name}\""
        replacements[/'Hub'/] = "'#{config.app_name}'"

        # Logo text
        replacements[/>Hub<\/span>/] = ">#{config.logo_text}</span>"
        replacements[/>Hub<\/h1>/] = ">#{config.logo_text}</h1>"
        replacements[/>Hub<\/h2>/] = ">#{config.logo_text}</h2>"

        # Footer text - be careful not to replace the entire footer
        replacements[/© \d{4} Hub\. All rights reserved\./] = config.footer_text

        # Support email
        replacements[/support@example\.com/] = config.support_email
        replacements[/mailto:support@example\.com/] = "mailto:#{config.support_email}"

        # Tagline
        replacements[/Ship your Rails app faster/] = config.app_tagline

        # Description
        replacements[/The fastest way to launch your SaaS/] = config.app_description

        replacements
      end

      def update_view_file(path)
        content = File.read(path)
        original_content = content.dup

        # Sort replacements by pattern length (longest first) to avoid conflicts
        sorted_replacements = replacements.sort_by { |pattern, _| -pattern.length }

        sorted_replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def replacements
        {
          "© <%= Date.current.year %> Hub. All rights reserved." => config.footer_text,
          "Welcome to Hub" => "Welcome to #{config.app_name}",
          "About Hub" => "About #{config.app_name}",
          "Hub is great" => "#{config.app_name} is great",
          ">Hub<" => ">#{config.logo_text}<",
          "Hub" => config.app_name,
          "SUPER" => config.logo_text,
          "Ship your Rails app faster" => config.app_tagline,
          "The fastest way to launch your SaaS" => config.app_description,
          "support@example.com" => config.support_email,
          "© 2024 SuperApp Inc." => config.footer_text,
          "© #{Date.current.year} Hub. All rights reserved." => config.footer_text
        }
      end
    end
  end
end
