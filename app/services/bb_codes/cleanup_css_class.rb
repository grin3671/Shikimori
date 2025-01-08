class BbCodes::CleanupCssClass
  method_object :value

  FORBIDDEN_CSS_CLASSES = %w[
    b-achievements_notifier
    b-admin_panel
    b-appear_marker
    b-broadcast_marker
    b-comments
    b-comments-notifier
    b-fancy_loader
    b-feedback
    b-height_shortener
    b-modal
    b-new_marker
    b-postloader
    b-to-top
    b-video
    ban
    bubbled
    collection_score
    CodeMirror
    CodeMirror-activeline-background
    CodeMirror-cursor
    CodeMirror-dialog
    CodeMirror-fullscreen
    CodeMirror-gutter-background
    CodeMirror-gutter-elt
    CodeMirror-gutter-filler
    CodeMirror-gutter-wrapper
    CodeMirror-gutters
    CodeMirror-hints
    CodeMirror-hscrollbar
    CodeMirror-linebackground
    CodeMirror-matchingtag
    CodeMirror-ruler
    CodeMirror-rulers
    CodeMirror-scrollbar-filler
    CodeMirror-vscrollbar
    comments-loader
    expand
    item-add
    item-cancel
    item-mobile
    item-moderation
    item-quote
    item-reply
    l-footer
    l-menu
    l-page
    l-top_menu-v2
    menu-slide-inner
    menu-slide-outer
    menu-toggler
    mfp-bg
    mfp-container
    mfp-coub
    mfp-webm-holder
    mfp-wrap
    shade
    sortable-drag
    toast-close
    toastify
    toastify-bottom
    toastify-left
    toastify-right
    toastify-rounded
    toastify-top
    tooltip
    tooltip-inner
    turbolinks-progress-bar
  ].sort_by(&:length).reverse # сначала заменять самые длинные совпадения

  CLEANUP_REGEXP = /
    #{FORBIDDEN_CSS_CLASSES.join '|'} |
    \bl-(?<css_class>[\w_\- ]+)
  /mix

  def call
    return @value if @value.blank?

    result = @value.gsub(CLEANUP_REGEXP, '').gsub(/\s\s+/, ' ').strip
    return '' if result.match? CLEANUP_REGEXP

    ERB::Util.h result
  end
end
