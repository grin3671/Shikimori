class Titles::AnimeKeywords
  include Translation

  attr_reader :klass, :season, :kind, :genres, :studios, :publishers

  def initialize( # rubocop:disable Metrics/ParameterLists
    klass:,
    season:,
    kind:,
    genres:,
    studios:,
    publishers:
  )
    @klass = klass
    @season = season
    @kind = kind
    @genres = Array genres
    @studios = Array studios
    @publishers = Array publishers
  end

  def keywords
    keywords = []

    keywords << season_keywords
    keywords << kind_keywords
    keywords << genre_keywords
    keywords << studio_keywords
    keywords << publisher_keywords
    keywords << other_keywords

    keywords.flatten.compact.join(' ').squeeze(' ')
  end

private

  def season_keywords
    return if season.blank?

    Titles::LocalizedSeasonText.new(self, season).title
  end

  def kind_keywords
    case kind
      when 'tv' then i18n_t 'kind.tv'
      when 'movie' then i18n_t 'kind.movie'
      else i18n_t("kind.#{klass.name.downcase}")
    end
  end

  def genre_keywords
    return if genres.blank?

    [i18n_i('genre'), genres.map { |v| "#{v.english} #{v.russian}" }.join(' ')]
  end

  def studio_keywords
    return if studios.blank?

    [i18n_i('studio'), studios.map(&:name).join(' ')]
  end

  def publisher_keywords
    return if publishers.blank?

    [i18n_i('publisher'), publishers.map(&:name).join(' ')]
  end

  def other_keywords
    i18n_t 'other'
  end
end
