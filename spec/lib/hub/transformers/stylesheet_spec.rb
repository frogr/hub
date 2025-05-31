require "rails_helper"

RSpec.describe Hub::Transformers::Stylesheet do
  let(:config) do
    Hub::Config.new({
      "design" => {
        "primary_color" => "#FF0000",
        "secondary_color" => "#00FF00",
        "accent_color" => "#0000FF",
        "font_family" => "Roboto",
        "heading_font_family" => "Playfair Display",
        "border_radius" => "0.5rem"
      }
    })
  end
  let(:transformer) { described_class.new(config, dry_run: dry_run) }
  let(:dry_run) { false }

  describe "#transform" do
    let(:temp_dir) { Rails.root.join("tmp", "stylesheet_transformer_test") }

    before do
      FileUtils.mkdir_p(temp_dir.join("stylesheets"))
      allow(transformer).to receive(:find_files).and_return(css_files)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "with CSS files containing variables" do
      let(:css_file) { temp_dir.join("stylesheets", "application.css") }
      let(:css_files) { [ css_file ] }

      before do
        File.write(css_file, <<~CSS)
          :root {
            --color-primary: #3B82F6;
            --color-secondary: #10B981;
            --font-family: Inter;
            --border-radius: 0.375rem;
          }

          body {
            font-family: var(--font-family);
          }
        CSS
      end

      it "updates CSS variables" do
        transformer.transform
        content = File.read(css_file)

        expect(content).to include("--color-primary: #FF0000")
        expect(content).to include("--color-secondary: #00FF00")
        expect(content).to include("--font-family: Roboto")
        expect(content).to include("--border-radius: 0.5rem")
      end
    end

    context "with SCSS files" do
      let(:scss_file) { temp_dir.join("stylesheets", "theme.scss") }
      let(:css_files) { [ scss_file ] }

      before do
        File.write(scss_file, <<~SCSS)
          $primary-color: #3B82F6;
          $font-stack: Inter, sans-serif;

          .btn-primary {
            background: $primary-color;
            font-family: $font-stack;
          }
        SCSS
      end

      it "updates SCSS variables" do
        transformer.transform
        content = File.read(scss_file)

        expect(content).to include("$primary-color: #FF0000")
        expect(content).to include("$font-stack: Roboto, sans-serif")
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }
      let(:css_file) { temp_dir.join("test.css") }
      let(:css_files) { [ css_file ] }

      before do
        File.write(css_file, "--color-primary: #3B82F6;")
      end

      it "does not modify files" do
        original_content = File.read(css_file)
        transformer.transform
        expect(File.read(css_file)).to eq(original_content)
      end
    end
  end

  describe "#update_stylesheet" do
    let(:temp_file) { Rails.root.join("tmp", "update_style_test.css") }

    before do
      FileUtils.mkdir_p(File.dirname(temp_file))
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it "updates all CSS variables" do
      File.write(temp_file, <<~CSS)
        :root {
          --color-primary: #3B82F6;
          --color-secondary: #10B981;
          --color-accent: #F59E0B;
          --color-danger: #EF4444;
          --color-warning: #F59E0B;
          --color-info: #3B82F6;
          --color-success: #10B981;
          --font-family: Inter;
          --font-family-heading: Inter;
          --border-radius: 0.375rem;
        }
      CSS

      transformer.send(:update_stylesheet, temp_file)
      content = File.read(temp_file)

      css_vars = config.css_variables
      css_vars.each do |var, value|
        expect(content).to include("#{var}: #{value}")
      end
    end

    it "handles CSS with comments and complex selectors" do
      File.write(temp_file, <<~CSS)
        /* Primary theme colors */
        :root {
          --color-primary: #3B82F6; /* Blue */
          --font-family: Inter;
        }

        .theme-dark {
          --color-primary: #60A5FA; /* Light blue for dark mode */
        }
      CSS

      transformer.send(:update_stylesheet, temp_file)
      content = File.read(temp_file)

      expect(content).to include("--color-primary: #FF0000; /* Blue */")
      expect(content).to include("--font-family: Roboto;")
      expect(content).to include("--color-primary: #60A5FA; /* Light blue for dark mode */")
    end
  end

  describe "#css_variable_replacements" do
    it "returns all CSS variable replacements" do
      replacements = transformer.send(:css_variable_replacements)

      expect(replacements["--color-primary: #3B82F6"]).to eq("--color-primary: #FF0000")
      expect(replacements["--color-secondary: #10B981"]).to eq("--color-secondary: #00FF00")
      expect(replacements["--font-family: Inter"]).to eq("--font-family: Roboto")
      expect(replacements["--font-family-heading: Inter"]).to eq("--font-family-heading: Playfair Display")
    end
  end

  describe "#font_replacements" do
    it "returns font-specific replacements" do
      replacements = transformer.send(:font_replacements)

      expect(replacements["Inter"]).to eq("Roboto")
      expect(replacements["font-family: Inter"]).to eq("font-family: Roboto")
      expect(replacements["$font-stack: Inter"]).to eq("$font-stack: Roboto")
    end
  end

  describe "#color_replacements" do
    it "returns color-specific replacements" do
      replacements = transformer.send(:color_replacements)

      expect(replacements["#3B82F6"]).to eq("#FF0000")
      expect(replacements["$primary-color: #3B82F6"]).to eq("$primary-color: #FF0000")
    end
  end
end
