# rubocop:disable all
require_dependency 'traffic_entry'
require_dependency 'calendar_entry'
require_dependency 'site_statistics'

class TestsController < ShikimoriController
  skip_before_action :verify_authenticity_token, only: [:echo]

  DEFAULT_MINIMUM_TITLES = 5
  DEFAULT_MINIMUM_DURATION = 1150
  DEFAULT_MINIMUM_USER_RATES = 750

  def show
    @traffic = Rails.cache.fetch("traffic_#{Time.zone.today}") do
      YandexMetrika.call 18
    end
  rescue Faraday::ConnectionFailed
  end

  def echo
    NamedLogger.echo.info params.to_yaml
    render json: params
  end

  # тест d3 графа
  def d3
    @anime = Anime.find params[:anime_id]
    render :d3, layout: false
  end

  # страница для теста рамок
  def border
  end

  def animes
    @resource = Anime.find(9969).decorate
    @collection_1 = [@resource, Anime.find(31_240).decorate, @resource]
    @collection_2 = [@resource] + Anime
      .where('score > 8 and score < 9')
      .order(id: :desc)
      .limit(5)
      .decorate
  end

  def achievements_notification
  end

  def franchises
    @minimum_titles = (params[:minimum_titles] || DEFAULT_MINIMUM_TITLES).to_i
    @minimum_titles = [10, [1, @minimum_titles].max].min

    @minimum_duration = (params[:minimum_duration] || DEFAULT_MINIMUM_DURATION).to_i
    @minimum_duration = [5000, [50, @minimum_duration].max].min
    unless (@minimum_duration % 50).zero?
      @minimum_duration += 50 - @minimum_duration % 50
    end

    @minimum_user_rates = (params[:minimum_user_rates] || DEFAULT_MINIMUM_USER_RATES).to_i
    @minimum_user_rates = [2500, [50, @minimum_user_rates].max].min
    unless (@minimum_user_rates % 50).zero?
      @minimum_user_rates += 50 - @minimum_user_rates % 50
    end

    cache_key = [@minimum_duration, @minimum_titles, @minimum_user_rates, :v5]

    @matched_collection =
      Rails.cache.fetch %i[matched_franchises] + cache_key, expires_in: 1.week do
        Anime
          .where.not(franchise: nil)
          .select { |anime| Neko::IsAllowed.call anime }
          .sort_by(&:popularity)
          .group_by(&:franchise)
          .select do |_franchise, animes|
            animes.size >= @minimum_titles &&
              animes.sum { |anime| Neko::Duration.call(anime) } >= @minimum_duration
          end
          .each_with_object({}) do |(franchise, animes), memo|
            memo[franchise] = franchise_info animes
          end
          .delete_if { |_franchise, info| info[:user_rates][:text] < @minimum_user_rates }
      end

    @not_matched_collection =
      Rails.cache.fetch %i[not_matched_franchises] + cache_key, expires_in: 1.week do
        NekoRepository.instance
          .select { |v| v.group == Types::Achievement::NekoGroup[:franchise] }
          .map(&:neko_id)
          .map(&:to_s)
          .reject { |franchise| @matched_collection.include? franchise }
          .each_with_object({}) do |franchise, memo|
            memo[franchise] = franchise_info(
              Anime.where(franchise: franchise).select { |anime| Neko::IsAllowed.call anime }
            )
          end
      end
  end

  def momentjs
  end

  def webm
    render :webm, layout: false
  end

  def polls
  end

  def vk_video
    @video = AnimeVideo.find(846_660).decorate
    render :vk_video, layout: false
  end

  def wall
  end

  def ajax
  end

  def colors
  end

  # def d3_data
    # query = Animes::ChronologyQuery.new(Anime.find params[:anime_id])
    # @entries = query.fetch
    # @links = query.links
  # end

  def iframe
  end

  def iframe_inner
    render :iframe_inner, layout: false
  end

private

  def franchise_info animes
    size = animes.size
    duration = animes.sum { |anime| Neko::Duration.call(anime) }
    user_rates = franchise_user_rates animes

    {
      size: { text: size, tooltip: "Titles: #{size}" },
      duration: { text: duration, tooltip: "Duration: #{duration}" },
      user_rates: { text: user_rates, tooltip: "User Rates: #{user_rates}" }
    }
  end

  def franchise_user_rates animes
    @franchise_user_rates ||= {}
    franchise = animes.first.franchise
    cache_key = [franchise, :user_rates_count, :v1]

    @franchise_user_rates[franchise] ||= Rails.cache.fetch cache_key, expires_in: 1.week do
      UserRate
        .where(
          status: %i[completed rewatching watching],
          target_type: Anime.name,
          target_id: animes.map(&:id)
        )
        .size
    end
  end
end
