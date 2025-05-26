module Hub
  module Transformers
    class Stylesheet < Base
      # Default Hub colors to be replaced
      DEFAULT_COLORS = {
        primary: "#3B82F6",
        secondary: "#10B981",
        accent: "#F59E0B",
        danger: "#EF4444",
        warning: "#F59E0B",
        info: "#3B82F6",
        success: "#10B981"
      }.freeze

      def transform
        log "Transforming stylesheets..."

        css_files = find_files("app/assets/stylesheets/**/*.css") +
                   find_files("app/assets/stylesheets/**/*.scss") +
                   find_files("app/javascript/**/*.css")

        css_files.each do |file|
          transform_file(file)
        end

        # Update CSS custom properties in application layout if present
        update_css_variables_in_layout
      end

      private

      def transform_file(path)
        content = read_file(path)
        original_content = content.dup

        # Replace color values
        replacements = build_color_replacements

        replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        # Replace font families
        if config.font_family != "Inter"
          content.gsub!(/font-family:\s*["']?Inter["']?/i, "font-family: '#{config.font_family}'")
          content.gsub!(/--font-family:\s*["']?Inter["']?/i, "--font-family: '#{config.font_family}'")
        end

        # Replace border radius
        if config.border_radius != "0.375rem"
          content.gsub!(/border-radius:\s*0\.375rem/, "border-radius: #{config.border_radius}")
          content.gsub!(/--border-radius:\s*0\.375rem/, "--border-radius: #{config.border_radius}")
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def build_color_replacements
        replacements = {}

        # Map old colors to new colors
        color_mappings = {
          DEFAULT_COLORS[:primary] => config.primary_color,
          DEFAULT_COLORS[:secondary] => config.secondary_color,
          DEFAULT_COLORS[:accent] => config.accent_color,
          DEFAULT_COLORS[:danger] => config.danger_color,
          DEFAULT_COLORS[:warning] => config.warning_color,
          DEFAULT_COLORS[:info] => config.info_color,
          DEFAULT_COLORS[:success] => config.success_color
        }

        color_mappings.each do |old_color, new_color|
          next if old_color == new_color

          # Match hex colors in various formats
          replacements[/#{Regexp.escape(old_color)}/i] = new_color

          # Also match RGB equivalents if needed
          rgb = hex_to_rgb(old_color)
          if rgb
            replacements[/rgb\(#{rgb[:r]},\s*#{rgb[:g]},\s*#{rgb[:b]}\)/] = new_color
          end
        end

        replacements
      end

      def update_css_variables_in_layout
        layout_path = Rails.root.join("app/views/layouts/application.html.erb")
        return unless File.exist?(layout_path)

        content = read_file(layout_path)
        original_content = content.dup

        # Look for inline style tag with CSS variables
        if content =~ /<style[^>]*>([^<]*:root[^<]*)<\/style>/m
          root_content = $1
          new_root_content = root_content.dup

          config.css_variables.each do |var_name, value|
            new_root_content.gsub!(/#{Regexp.escape(var_name)}:\s*[^;]+;/, "#{var_name}: #{value};")
          end

          if root_content != new_root_content
            content.gsub!(root_content, new_root_content)
          end
        end

        if content != original_content
          write_file(layout_path, content)
        end
      end

      def hex_to_rgb(hex)
        return nil unless hex =~ /\A#([0-9A-Fa-f]{6})\z/

        hex = hex.delete("#")
        {
          r: hex[0..1].to_i(16),
          g: hex[2..3].to_i(16),
          b: hex[4..5].to_i(16)
        }
      end
    end
  end
end
