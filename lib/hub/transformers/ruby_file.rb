module Hub
  module Transformers
    class RubyFile < Base
      def transform
        log "Transforming Ruby files..."

        ruby_files = find_files("app/**/*.rb") + find_files("lib/**/*.rb") + find_files("config/**/*.rb")

        ruby_files.each do |file|
          transform_file(file)
        end
      end

      private

      def transform_file(path)
        # Skip this transformer's own files
        return if path.to_s.include?("lib/hub/")

        content = read_file(path)
        original_content = content.dup

        # Build replacements based on current app name vs new app name
        old_class_name = "Hub"
        new_class_name = config.app_class_name

        # Skip if names are the same
        return if old_class_name == new_class_name

        replacements = build_replacements(old_class_name, new_class_name)

        replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def update_ruby_file(path)
        content = File.read(path)
        original_content = content.dup

        replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def replacements
        {
          '"Welcome to Hub"' => "\"Welcome to #{config.app_name}\"",
          '"Hub"' => "\"#{config.app_name}\"",
          "'Hub'" => "'#{config.app_name}'",
          "module Hub" => "module #{config.app_class_name}",
          "Hub::" => "#{config.app_class_name}::",
          "class Hub::" => "class #{config.app_class_name}::"
        }
      end

      def build_replacements(old_name, new_name)
        replacements = {}

        # Module and class definitions
        replacements[/\bmodule #{old_name}\b/] = "module #{new_name}"
        replacements[/\bclass #{old_name}([A-Z])/] = "class #{new_name}\\1"
        replacements[/\b#{old_name}::/] = "#{new_name}::"

        # Constants
        replacements[/\b#{old_name.upcase}_/] = "#{new_name.upcase}_"

        # Special case for application.rb
        replacements[/module #{old_name}\s+class Application/m] = "module #{new_name}\n  class Application"

        # Method calls and references
        replacements[/\b#{old_name}\.([a-z_]+)/] = "#{new_name}.\\1"

        # String references to app name
        replacements["\"#{old_name}\""] = "\"#{config.app_name}\""
        replacements["'#{old_name}'"] = "'#{config.app_name}'"

        replacements
      end
    end
  end
end
