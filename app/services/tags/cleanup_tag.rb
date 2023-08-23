class Tags::CleanupTag
  include Singleton

  SPECIAL_WORDS = %w[]

  CLEANUP_REGEXP = /
    \b
    (?:
      s?[ivx\d]+ |
      season |
      сезон |
      episode |
      эпизод |
      серия |
      full\ episode |
      tv |
      movie |
      ova |
      ona |
      amv |
      opening |
      op |
      ed |
      compilation |
      preview |
      spoiler |
      спойлер
    )
    \b |
    [_'"!] |
    \bthe\b
  /mx

  def call tag, fast: false
    fixed_tag = fast ? tag : tag.unaccent

    fixed_tag
      .downcase
      .gsub(CLEANUP_REGEXP, ' ')
      .gsub(/  +/, ' ')
      .strip
  end
end
