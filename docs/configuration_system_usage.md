# Hub Configuration System Usage Guide

## Overview
The Hub configuration system allows admin users to customize the application's branding, design, features, and products through a web interface.

## Accessing the Configuration Interface

### 1. Make Yourself an Admin
First, you need to have admin privileges. Run this in the Rails console:

```bash
rails console
```

```ruby
# Find your user by email
user = User.find_by(email: "your-email@example.com")

# Make yourself an admin
user.update!(admin: true)
```

### 2. Access the Configuration Page
Once you're an admin:
1. Sign in to the application
2. You'll see a "Config" link in the navigation bar (only visible to admins)
3. Click "Config" to access the configuration interface at `/hub_admin/configuration`

## Using the Configuration Interface

### Available Settings

#### App Configuration
- **App Name**: The name of your application
- **Class Name**: Ruby class name (auto-generated from app name if blank)
- **Tagline**: Short description shown in various places
- **Description**: Longer description for SEO and about pages

#### Branding
- **Logo Text**: Text shown in the logo area
- **Footer Text**: Copyright/footer message
- **Support Email**: Contact email for support

#### Design System
- **Colors**: Primary, secondary, accent, danger, warning, info, success
- **Fonts**: Font family and heading font family
- **Border Radius**: Controls roundedness of UI elements

#### Features
- **Passwordless Auth**: Enable/disable magic link authentication
- **Stripe Payments**: Enable/disable payment processing
- **Admin Panel**: Enable/disable admin features

#### SEO Settings
- **Title Suffix**: Added to all page titles
- **Default Description**: Meta description for pages
- **OG Image**: Open Graph image URL

#### Products/Plans
Add subscription plans with:
- Name
- Stripe Price ID
- Price (in cents, e.g., 2900 = $29.00)
- Billing Period (month/year)
- Features (one per line)

### Applying Changes

1. **Save Only**: Click "Save Configuration" to save without applying
   - Saves to `config/hub_config.yml`
   - Changes are stored but not applied to the app

2. **Save & Apply**: Check "Apply changes immediately" then click "Save Configuration"
   - Saves configuration
   - Regenerates application files with new settings
   - Updates views, stylesheets, and Ruby files

### Important Notes

- **Restart Required**: After applying changes, restart your Rails server to see updates
- **Version Control**: The `hub_config.yml` file should be committed to track configuration changes
- **Backup**: Configuration changes modify multiple files - ensure you have backups or use version control

## Testing Changes

### Dry Run Mode
Test changes without modifying files:

```ruby
rails console
config = Hub::Config.current
generator = Hub::Generator.new(config, dry_run: true)
generator.generate!
```

### Manual Regeneration
Apply configuration from console:

```ruby
rails console
Hub::Generator.run!
```

Or use the provided script:
```bash
bin/regenerate_app
```

## Troubleshooting

### Can't See Config Link
- Ensure you're signed in
- Verify you have admin privileges: `User.find_by(email: "your-email").admin?`

### Changes Not Appearing
- Did you restart the Rails server?
- Check if files were actually modified: `git status`
- Look for errors in the Rails log

### Configuration Not Saving
- Check Rails logs for validation errors
- Ensure `config/` directory is writable
- Verify YAML syntax in `config/hub_config.yml`

## Configuration File Structure

The configuration is stored in `config/hub_config.yml`:

```yaml
app:
  name: "Your App Name"
  class_name: "YourAppName"
  tagline: "Your tagline"
  description: "Your description"

branding:
  logo_text: "YourApp"
  footer_text: "© 2024 YourApp. All rights reserved."
  support_email: "support@yourapp.com"

design:
  primary_color: "#6B46C1"
  secondary_color: "#0F172A"
  # ... other colors
  font_family: "Inter"
  heading_font_family: "Inter"
  border_radius: "0.5rem"

features:
  passwordless_auth: true
  stripe_payments: true
  admin_panel: true

seo:
  default_title_suffix: " | YourApp"
  default_description: "Your app description"
  og_image: "https://yourapp.com/og-image.png"

products:
  - name: "Basic"
    stripe_price_id: "price_xxx"
    price: 1000
    billing_period: "month"
    features:
      - "Feature 1"
      - "Feature 2"
</yaml>
```