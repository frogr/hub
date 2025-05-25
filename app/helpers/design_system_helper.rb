module DesignSystemHelper
  # Button Classes
  BTN_BASE = "inline-flex items-center justify-center px-6 py-3 text-base font-medium rounded-xl transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transform active:scale-[0.98]"
  BTN_PRIMARY = "#{BTN_BASE} bg-gradient-primary text-white shadow-md hover:shadow-lg focus:ring-primary-500/50 hover:brightness-110"
  BTN_SECONDARY = "#{BTN_BASE} bg-white text-primary-600 border-2 border-primary-200 shadow-sm hover:shadow-md focus:ring-primary-500/50 hover:bg-primary-50 hover:border-primary-300"
  BTN_ACCENT = "#{BTN_BASE} bg-gradient-accent text-white shadow-md hover:shadow-lg focus:ring-accent-700/50 hover:brightness-110"
  BTN_GHOST = "#{BTN_BASE} bg-transparent text-primary-600 hover:bg-primary-50 focus:ring-primary-500/50"
  BTN_DANGER = "#{BTN_BASE} bg-error text-white shadow-md hover:shadow-lg focus:ring-error/50 hover:brightness-110"

  # Button Sizes
  BTN_SM = "px-4 py-2 text-sm rounded-lg"
  BTN_LG = "px-8 py-4 text-lg rounded-2xl"
  BTN_XL = "px-10 py-5 text-xl rounded-2xl"

  # Card Classes
  CARD = "bg-white rounded-2xl shadow-md border border-neutral-100 overflow-hidden transition-all duration-300 hover:shadow-lg"
  CARD_BODY = "p-6 md:p-8"
  CARD_HEADER = "px-6 py-4 md:px-8 md:py-6 border-b border-neutral-100 bg-gradient-to-b from-neutral-50 to-transparent"

  # Alert Classes
  ALERT_BASE = "p-4 rounded-xl border backdrop-blur-sm animate-slide-up"
  ALERT_SUCCESS = "#{ALERT_BASE} bg-success/10 border-success/20 text-success"
  ALERT_ERROR = "#{ALERT_BASE} bg-error/10 border-error/20 text-error"
  ALERT_WARNING = "#{ALERT_BASE} bg-warning/10 border-warning/20 text-warning"
  ALERT_INFO = "#{ALERT_BASE} bg-info/10 border-info/20 text-info"

  # Form Classes
  FORM_INPUT = "w-full px-4 py-3 text-base bg-white border border-neutral-200 rounded-xl shadow-sm transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-primary-500/20 focus:border-primary-500 placeholder:text-neutral-400"
  FORM_LABEL = "block text-sm font-medium text-neutral-700 mb-2"
  FORM_ERROR = "text-sm text-error mt-1"

  # Badge Classes
  BADGE_BASE = "inline-flex items-center px-3 py-1 text-sm font-medium rounded-full"
  BADGE_PRIMARY = "#{BADGE_BASE} bg-primary-100 text-primary-700"
  BADGE_SUCCESS = "#{BADGE_BASE} bg-success/10 text-success"
  BADGE_WARNING = "#{BADGE_BASE} bg-warning/10 text-warning"

  # Link Classes
  LINK = "text-primary-600 underline decoration-primary-300 decoration-2 underline-offset-2 hover:decoration-primary-600 transition-colors duration-200"
  LINK_SUBTLE = "text-neutral-600 no-underline hover:text-primary-600 hover:underline transition-all duration-200"

  # Hero Classes
  HERO = "relative py-20 md:py-32 overflow-hidden"
  HERO_CONTENT = "relative z-10 max-w-4xl mx-auto text-center px-4"
  HERO_TITLE = "text-5xl md:text-6xl font-bold text-primary-900 mb-6 animate-fade-in"
  HERO_SUBTITLE = "text-xl md:text-2xl text-neutral-600 mb-8 animate-slide-up"

  # Navigation Classes
  NAV_LINK = "px-4 py-2 text-base font-medium text-neutral-600 rounded-lg transition-all duration-200 hover:bg-primary-50 hover:text-primary-700"
  NAV_LINK_ACTIVE = "#{NAV_LINK} bg-primary-50 text-primary-700"

  # Section Classes
  SECTION = "py-16 md:py-24"
  SECTION_TITLE = "text-3xl md:text-4xl font-bold text-primary-900 mb-4"
  SECTION_SUBTITLE = "text-lg md:text-xl text-neutral-600"

  # Container Classes
  CONTAINER_NARROW = "max-w-4xl mx-auto px-4"
  CONTAINER_WIDE = "max-w-7xl mx-auto px-4"

  # Other Classes
  DIVIDER = "h-px bg-gradient-to-r from-transparent via-neutral-200 to-transparent my-8"
  SKELETON = "animate-pulse bg-neutral-200 rounded"
  SPINNER = "inline-block w-5 h-5 border-2 border-primary-600 border-t-transparent rounded-full animate-spin"

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
