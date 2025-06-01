module Hub
  class Generator
    def initialize(config)
      @config = config
    end

    def generate!
      update_ruby_files
      update_view_files
      update_stylesheets
      update_config_files
      
      puts "✅ App regenerated! Restart your Rails server."
      true
    rescue => e
      puts "❌ Error: #{e.message}"
      false
    end

    private

    def update_ruby_files
      Dir.glob(Rails.root.join("**/*.rb")).each do |file|
        next if file.include?("lib/hub") || file.include?("node_modules")
        
        content = File.read(file)
        updated = content.gsub("module Hub", "module #{@config.app_class_name}")
                        .gsub("Hub::", "#{@config.app_class_name}::")
        
        File.write(file, updated) if content != updated
      end
    end

    def update_view_files
      Dir.glob(Rails.root.join("app/views/**/*.erb")).each do |file|
        content = File.read(file)
        updated = content.gsub(">Hub<", ">#{@config.app_name}<")
                        .gsub("Welcome to Hub", "Welcome to #{@config.app_name}")
                        .gsub("support@example.com", @config.support_email)
                        .gsub("Ship faster", @config.tagline)
                        .gsub("Rails SaaS starter", @config.description)
                        .gsub("© 2024 Hub. All rights reserved.", @config.footer_text)
        
        File.write(file, updated) if content != updated
      end
    end

    def update_stylesheets
      # Update CSS variables in tailwind config
      css_file = Rails.root.join("app/assets/stylesheets/application.tailwind.css")
      return unless File.exist?(css_file)
      
      content = File.read(css_file)
      
      # Update color variables
      updated = content
      @config.color_variables.each do |var_name, value|
        updated = updated.gsub(/#{Regexp.escape(var_name)}: #[0-9A-Fa-f]{6}/, "#{var_name}: #{value}")
      end
      
      # Update font variables
      updated = updated.gsub(/--font-family: '[^']+';/, "--font-family: '#{@config.font_family}';")
                      .gsub(/--font-family-heading: '[^']+';/, "--font-family-heading: '#{@config.heading_font_family}';")
      
      # Update border radius
      updated = updated.gsub(/--border-radius: [^;]+;/, "--border-radius: #{@config.border_radius};")
      
      File.write(css_file, updated) if content != updated
    end

    def update_config_files
      # Update application.rb
      app_config = Rails.root.join("config/application.rb")
      if File.exist?(app_config)
        content = File.read(app_config)
        updated = content.gsub(/config\.application_name = "[^"]*"/, "config.application_name = \"#{@config.app_name}\"")
        File.write(app_config, updated) if content != updated
      end
      
      # Update environment files
      %w[development.rb production.rb test.rb].each do |env_file|
        path = Rails.root.join("config/environments", env_file)
        next unless File.exist?(path)
        
        content = File.read(path)
        updated = content.gsub(/config\.action_mailer\.default_options = \{ from: "[^"]*" \}/, 
                             "config.action_mailer.default_options = { from: \"#{@config.support_email}\" }")
        File.write(path, updated) if content != updated
      end
      
      # Update locales
      locale_file = Rails.root.join("config/locales/en.yml")
      if File.exist?(locale_file)
        content = File.read(locale_file)
        updated = content.gsub(/application_name: "[^"]*"/, "application_name: \"#{@config.app_name}\"")
                        .gsub(/hello: "[^"]*"/, "hello: \"Welcome to #{@config.app_name}\"")
        File.write(locale_file, updated) if content != updated
      end
    end
  end
end