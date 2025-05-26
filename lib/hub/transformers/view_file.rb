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
        content = read_file(path)
        original_content = content.dup

        # Build replacements
        replacements = build_replacements

        replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        if content != original_content
          write_file(path, content)
        end
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
    end
  end
end
