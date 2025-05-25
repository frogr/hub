module DesignSystemHelper
  # Typography Classes - Consistent, Readable, Large Text
  TEXT_DISPLAY = "text-4xl md:text-5xl lg:text-6xl font-bold leading-tight"
  TEXT_HEADING = "text-2xl md:text-3xl lg:text-4xl font-bold leading-tight"
  TEXT_SUBHEADING = "text-xl md:text-2xl font-semibold leading-relaxed"
  TEXT_BODY = "text-lg leading-relaxed"
  TEXT_BODY_SM = "text-base leading-relaxed"
  TEXT_CAPTION = "text-sm leading-relaxed"

  # Color Classes - High Contrast for Dark Theme
  TEXT_PRIMARY = "text-white"           # White on dark backgrounds
  TEXT_SECONDARY = "text-neutral-100"   # Slightly off-white
  TEXT_MUTED = "text-neutral-400"       # Muted but readable
  TEXT_ACCENT = "text-accent-200"       # Accent color text
  TEXT_SUCCESS = "text-green-400"       # Success text
  TEXT_WARNING = "text-yellow-400"      # Warning text
  TEXT_ERROR = "text-red-400"           # Error text

  # Button Classes
  BTN_BASE = "inline-flex items-center justify-center px-8 py-4 #{TEXT_BODY_SM} font-semibold rounded-xl transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-offset-2 focus:ring-offset-primary-900 disabled:opacity-50 disabled:cursor-not-allowed transform active:scale-[0.98]"
  BTN_PRIMARY = "#{BTN_BASE} bg-gradient-primary #{TEXT_PRIMARY} shadow-lg hover:shadow-xl focus:ring-primary-500/50 hover:brightness-110"
  BTN_SECONDARY = "#{BTN_BASE} bg-primary-700/50 #{TEXT_PRIMARY} border-2 border-primary-600/50 shadow-md hover:shadow-lg focus:ring-primary-500/50 hover:bg-primary-600/50 hover:border-primary-500/50 backdrop-blur-sm"
  BTN_ACCENT = "#{BTN_BASE} bg-gradient-accent #{TEXT_PRIMARY} shadow-lg hover:shadow-xl focus:ring-accent-700/50 hover:brightness-110"
  BTN_GHOST = "#{BTN_BASE} bg-transparent #{TEXT_SECONDARY} hover:bg-primary-700/30 focus:ring-primary-500/50"
  BTN_DANGER = "#{BTN_BASE} bg-red-600 #{TEXT_PRIMARY} shadow-lg hover:shadow-xl focus:ring-red-500/50 hover:bg-red-700"

  # Button Sizes
  BTN_SM = "px-4 py-2 text-sm rounded-lg"
  BTN_LG = "px-8 py-4 text-lg rounded-2xl"
  BTN_XL = "px-10 py-5 text-xl rounded-2xl"

  # Card Classes - Dark Theme, High Contrast
  CARD = "bg-primary-800/80 rounded-2xl shadow-xl border border-primary-700/50 overflow-hidden backdrop-blur-sm"
  CARD_BODY = "p-8 md:p-10"
  CARD_HEADER = "px-8 py-6 md:px-10 md:py-8 border-b border-primary-700/50 bg-gradient-to-b from-primary-700/20 to-transparent"

  # Alert Classes - Better Contrast
  ALERT_BASE = "p-6 rounded-xl border backdrop-blur-sm #{TEXT_BODY_SM}"
  ALERT_SUCCESS = "#{ALERT_BASE} bg-green-900/30 border-green-600/30 #{TEXT_SUCCESS}"
  ALERT_ERROR = "#{ALERT_BASE} bg-red-900/30 border-red-600/30 #{TEXT_ERROR}"
  ALERT_WARNING = "#{ALERT_BASE} bg-yellow-900/30 border-yellow-600/30 #{TEXT_WARNING}"
  ALERT_INFO = "#{ALERT_BASE} bg-blue-900/30 border-blue-600/30 text-blue-400"

  # Form Classes - Large, Readable
  FORM_INPUT = "w-full px-6 py-4 #{TEXT_BODY} bg-primary-800/50 border border-primary-600/50 rounded-xl shadow-sm transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-primary-500/30 focus:border-primary-500 placeholder:text-neutral-500 #{TEXT_PRIMARY} backdrop-blur-sm"
  FORM_LABEL = "block #{TEXT_BODY_SM} font-semibold #{TEXT_SECONDARY} mb-3"
  FORM_ERROR = "#{TEXT_CAPTION} #{TEXT_ERROR} mt-2"

  # Badge Classes - Better Contrast
  BADGE_BASE = "inline-flex items-center px-4 py-2 #{TEXT_CAPTION} font-semibold rounded-full"
  BADGE_PRIMARY = "#{BADGE_BASE} bg-primary-600/50 #{TEXT_PRIMARY} border border-primary-500/50"
  BADGE_SUCCESS = "#{BADGE_BASE} bg-green-800/50 #{TEXT_SUCCESS} border border-green-600/50"
  BADGE_WARNING = "#{BADGE_BASE} bg-yellow-800/50 #{TEXT_WARNING} border border-yellow-600/50"

  # Link Classes - High Contrast
  LINK = "#{TEXT_ACCENT} underline decoration-accent-300 decoration-2 underline-offset-2 hover:decoration-accent-200 hover:text-accent-100 transition-colors duration-200 #{TEXT_BODY_SM}"
  LINK_SUBTLE = "#{TEXT_SECONDARY} no-underline hover:text-accent-200 hover:underline transition-all duration-200 #{TEXT_BODY_SM}"

  # Hero Classes - Large Typography
  HERO = "relative py-24 md:py-32 lg:py-40 overflow-hidden"
  HERO_CONTENT = "relative z-10 max-w-5xl mx-auto text-center px-6 md:px-8"
  HERO_TITLE = "#{TEXT_DISPLAY} #{TEXT_PRIMARY} mb-8 animate-fade-in"
  HERO_SUBTITLE = "#{TEXT_SUBHEADING} #{TEXT_SECONDARY} mb-12 animate-slide-up"

  # Navigation Classes
  NAV_LINK = "px-6 py-3 #{TEXT_BODY_SM} font-medium #{TEXT_SECONDARY} rounded-xl transition-all duration-200 hover:bg-primary-700/50 hover:#{TEXT_PRIMARY}"
  NAV_LINK_ACTIVE = "px-6 py-3 #{TEXT_BODY_SM} font-medium rounded-xl transition-all duration-200 bg-primary-700/50 #{TEXT_PRIMARY}"

  # Section Classes - Large Typography
  SECTION = "py-20 md:py-28 lg:py-32"
  SECTION_TITLE = "#{TEXT_HEADING} #{TEXT_PRIMARY} mb-6"
  SECTION_SUBTITLE = "#{TEXT_SUBHEADING} #{TEXT_SECONDARY} mb-8"

  # Container Classes - Better Spacing
  CONTAINER_NARROW = "max-w-4xl mx-auto px-6 md:px-8"
  CONTAINER_WIDE = "max-w-7xl mx-auto px-6 md:px-8"

  # Other Classes
  DIVIDER = "h-px bg-gradient-to-r from-transparent via-primary-600/50 to-transparent my-12"
  SKELETON = "animate-pulse bg-primary-700/30 rounded"
  SPINNER = "inline-block w-6 h-6 border-2 border-accent-400 border-t-transparent rounded-full animate-spin"

  def btn_primary(size = nil)
    classes = [ BTN_PRIMARY ]
    classes << btn_size_class(size) if size
    classes.join(" ")
  end

  def btn_secondary(size = nil)
    classes = [ BTN_SECONDARY ]
    classes << btn_size_class(size) if size
    classes.join(" ")
  end

  def btn_accent(size = nil)
    classes = [ BTN_ACCENT ]
    classes << btn_size_class(size) if size
    classes.join(" ")
  end

  def btn_ghost(size = nil)
    classes = [ BTN_GHOST ]
    classes << btn_size_class(size) if size
    classes.join(" ")
  end

  def btn_danger(size = nil)
    classes = [ BTN_DANGER ]
    classes << btn_size_class(size) if size
    classes.join(" ")
  end

  private

  def btn_size_class(size)
    case size
    when :sm then BTN_SM
    when :lg then BTN_LG
    when :xl then BTN_XL
    else ""
    end
  end
end
