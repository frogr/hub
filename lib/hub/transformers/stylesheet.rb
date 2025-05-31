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
        update_stylesheet(path)
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

      def update_stylesheet(path)
        content = File.read(path)
        original_content = content.dup

        # Apply replacements in specific order to avoid conflicts
        # 1. CSS variables (most specific, includes full pattern like --color-warning: #F59E0B)
        css_variable_replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        # 2. SCSS variables (e.g., $primary-color: #3B82F6)
        scss_replacements = color_replacements.select { |k, _| k.start_with?("$") }
        scss_replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        # 3. Font replacements
        font_replacements.each do |pattern, replacement|
          content.gsub!(pattern, replacement)
        end

        # 4. Raw hex colors (only if not already replaced)
        # Skip raw hex replacements to avoid conflicts

        if content != original_content
          write_file(path, content)
        end
      end

      def css_variable_replacements
        replacements = {}

        # CSS variable replacements - use exact patterns to avoid conflicts
        # Must be done in specific order to handle overlapping default values
        replacements["--color-primary: #3B82F6"] = "--color-primary: #{config.primary_color}"
        replacements["--color-secondary: #10B981"] = "--color-secondary: #{config.secondary_color}"
        replacements["--color-danger: #EF4444"] = "--color-danger: #{config.danger_color}"
        replacements["--color-success: #10B981"] = "--color-success: #{config.success_color}"
        replacements["--color-info: #3B82F6"] = "--color-info: #{config.info_color}"

        # Handle accent and warning separately since they have same default
        if config.accent_color != "#F59E0B" || config.warning_color != "#F59E0B"
          # Replace them based on context or just do both
          replacements["--color-accent: #F59E0B"] = "--color-accent: #{config.accent_color}"
          replacements["--color-warning: #F59E0B"] = "--color-warning: #{config.warning_color}"
        else
          replacements["--color-accent: #F59E0B"] = "--color-accent: #{config.accent_color}"
          replacements["--color-warning: #F59E0B"] = "--color-warning: #{config.warning_color}"
        end

        replacements["--font-family: Inter"] = "--font-family: #{config.font_family}"
        replacements["--font-family-heading: Inter"] = "--font-family-heading: #{config.heading_font_family}"
        replacements["--border-radius: 0.375rem"] = "--border-radius: #{config.border_radius}"

        replacements
      end

      def font_replacements
        replacements = {}

        # Always provide font replacements mapping from default Inter font
        replacements["Inter"] = config.font_family
        replacements["font-family: Inter"] = "font-family: #{config.font_family}"
        replacements["font-family: 'Inter'"] = "font-family: '#{config.font_family}'"
        replacements['"Inter"'] = "\"#{config.font_family}\""
        replacements["'Inter'"] = "'#{config.font_family}'"
        replacements["$font-stack: Inter"] = "$font-stack: #{config.font_family}"

        if config.heading_font_family != "Inter"
          replacements["font-family-heading: Inter"] = "font-family-heading: #{config.heading_font_family}"
        end

        replacements
      end

      def color_replacements
        replacements = {}

        # Include hex colors and SCSS variable patterns
        replacements["#3B82F6"] = config.primary_color
        replacements["$primary-color: #3B82F6"] = "$primary-color: #{config.primary_color}"

        replacements["#10B981"] = config.secondary_color
        replacements["$secondary-color: #10B981"] = "$secondary-color: #{config.secondary_color}"

        replacements["#EF4444"] = config.danger_color
        replacements["$danger-color: #EF4444"] = "$danger-color: #{config.danger_color}"

        # For #F59E0B, only replace if accent color is different from default
        # This prevents replacing warning color values when they share the same default
        if config.accent_color != "#F59E0B"
          replacements["#F59E0B"] = config.accent_color
          replacements["$accent-color: #F59E0B"] = "$accent-color: #{config.accent_color}"
        end

        replacements
      end
    end
  end
end
