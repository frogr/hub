require "rails_helper"

RSpec.describe Hub::Transformers::ViewFile do
  let(:config) do
    Hub::Config.new({
      "app" => {
        "name" => "SuperApp",
        "tagline" => "The best app ever",
        "description" => "An amazing application"
      },
      "branding" => {
        "logo_text" => "SUPER",
        "footer_text" => "© 2024 SuperApp Inc.",
        "support_email" => "help@superapp.com"
      }
    })
  end
  let(:transformer) { described_class.new(config, dry_run: dry_run) }
  let(:dry_run) { false }

  describe "#transform" do
    let(:temp_dir) { Rails.root.join("tmp", "view_transformer_test") }

    before do
      FileUtils.mkdir_p(temp_dir.join("views"))
      allow(transformer).to receive(:find_files).and_return(view_files)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "with HTML erb files" do
      let(:erb_file) { temp_dir.join("views", "home.html.erb") }
      let(:view_files) { [ erb_file ] }

      before do
        File.write(erb_file, <<~ERB)
          <h1>Welcome to Hub</h1>
          <p>Ship your Rails app faster</p>
          <footer>© <%= Date.current.year %> Hub. All rights reserved.</footer>
          <p>Contact: support@example.com</p>
        ERB
      end

      it "replaces content references" do
        transformer.transform
        content = File.read(erb_file)

        expect(content).to include("Welcome to SuperApp")
        expect(content).to include("The best app ever")
        expect(content).to include("© 2024 SuperApp Inc.")
        expect(content).to include("help@superapp.com")
      end
    end

    context "with partial files" do
      let(:partial_file) { temp_dir.join("views", "_header.html.erb") }
      let(:view_files) { [ partial_file ] }

      before do
        File.write(partial_file, <<~ERB)
          <header>
            <div class="logo">Hub</div>
            <nav>About Hub</nav>
          </header>
        ERB
      end

      it "replaces logo text" do
        transformer.transform
        content = File.read(partial_file)

        expect(content).to include('<div class="logo">SUPER</div>')
        expect(content).to include("About SuperApp")
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }
      let(:erb_file) { temp_dir.join("test.html.erb") }
      let(:view_files) { [ erb_file ] }

      before do
        File.write(erb_file, "Welcome to Hub")
      end

      it "does not modify files" do
        original_content = File.read(erb_file)
        transformer.transform
        expect(File.read(erb_file)).to eq(original_content)
      end
    end
  end

  describe "#update_view_file" do
    let(:temp_file) { Rails.root.join("tmp", "update_view_test.html.erb") }

    before do
      FileUtils.mkdir_p(File.dirname(temp_file))
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it "updates multiple patterns in view file" do
      File.write(temp_file, <<~ERB)
        <%= content_tag :h1, "Welcome to Hub" %>
        <p class="tagline">Ship your Rails app faster</p>
        <div>Hub is great</div>
        <small>Contact support@example.com</small>
      ERB

      transformer.send(:update_view_file, temp_file)
      content = File.read(temp_file)

      expect(content).to include("Welcome to SuperApp")
      expect(content).to include("The best app ever")
      expect(content).to include("SuperApp is great")
      expect(content).to include("help@superapp.com")
    end

    it "preserves ERB tags and HTML structure" do
      File.write(temp_file, <<~ERB)
        <%= link_to "Hub", root_path, class: "text-hub" %>
        <% if user_signed_in? %>
          <p>Welcome to Hub!</p>
        <% end %>
      ERB

      transformer.send(:update_view_file, temp_file)
      content = File.read(temp_file)

      expect(content).to include('<%= link_to "SuperApp"')
      expect(content).to include("class: \"text-hub\"")
      expect(content).to include("<% if user_signed_in? %>")
      expect(content).to include("Welcome to SuperApp!")
    end
  end

  describe "#replacements" do
    it "returns correct replacement patterns for views" do
      replacements = transformer.send(:replacements)

      expect(replacements["Hub"]).to eq("SuperApp")
      expect(replacements["SUPER"]).to eq("SUPER")
      expect(replacements["Ship your Rails app faster"]).to eq("The best app ever")
      expect(replacements["support@example.com"]).to eq("help@superapp.com")
    end

    it "includes dynamic footer text replacements" do
      replacements = transformer.send(:replacements)

      expect(replacements["© 2024 SuperApp Inc."]).to eq("© 2024 SuperApp Inc.")
    end
  end
end
