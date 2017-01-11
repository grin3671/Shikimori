class AnimeOnline::VideoPlayer
  include Draper::ViewHelpers
  prepend ActiveCacher.instance

  vattr_initialize :anime
  instance_cache :nav, :current_video, :videos, :anime_video_episodes,
    :episode_topic_view, :cache_key

  PREFERENCES_KIND = 'anime_video_kind'
  PREFERENCES_HOSTING = 'anime_video_hosting'
  PREFERENCES_AUTHOR = 'anime_video_author'

  def nav
    AnimeOnline::VideoPlayerNavigation.new self
  end

  def current_video
    video =
      if video_id > 0
        videos.find { |v| v.id == video_id }
      else
        try_select_by(
          h.cookies[PREFERENCES_KIND],
          h.cookies[PREFERENCES_HOSTING],
          h.cookies[PREFERENCES_AUTHOR]
        )
      end

    if !video && h.params[:video_id]
      video = AnimeVideo.find_by(id: h.params[:video_id])
    end

    video&.decorate
  end

  def videos
    videos = @anime.anime_videos
      .includes(:author)
      .where(episode: current_episode)
      # .select { |v| all? || v.allowed? }
      # .select { |v| compatible?(v) }

    videos = videos.available unless all?

    AnimeOnline::FilterSovetRomantica.call(videos)
      .map(&:decorate)
      .sort_by(&:sort_criteria)
  end

  def videos_by_kind
    return {} if videos.blank?

    videos
      .uniq(&:uniq_criteria)
      .sort_by(&:sort_criteria)
      .group_by { |anime_video| anime_video.kind_text }
  end

  def anime_video_episodes
    AnimeOnline::AnimeVideoEpisodes.call(@anime)
  end

  def current_episode
    if h.params[:episode]
      h.params[:episode].to_i
    else
      1
    end
  end

  def episode_url episode = self.current_episode
    h.play_video_online_index_url @anime, episode, h.params[:all]
  end

  def prev_url
    episode = episodes.reverse.find { |v| v < current_episode }
    episode ||= episodes.last
    episode_url episode if episode

  end

  def next_url
    episode = episodes.find { |v| v > current_episode }
    episode ||= episodes.first
    episode_url episode if episode
  end

  def report_url kind
    h.moderation_anime_video_reports_url(
      'anime_videos_report[kind]' => kind,
      'anime_videos_report[anime_video_id]' => current_video.id,
      'anime_videos_report[user_id]' => h.current_user.try(:id) || User::GUEST_ID,
      'anime_videos_report[message]' => ''
    )
  end

  def episode_title
    if current_episode.zero?
      "Прочее"
    else
      "Эпизод #{current_episode}"
    end
  end

  def same_videos
    return [] unless current_video
    videos.group_by(&:uniq_criteria)[current_video.uniq_criteria] || []
  end

  # список типов коллекции видео
  def kinds videos
    videos
      .map(&:kind)
      .uniq
      .map { |v| I18n.t "enumerize.anime_video.kind.#{v}" }
      .uniq
      .join(', ')
  end

  # список хостингов коллекции видео
  def hostings videos
    videos
      .map(&:hosting)
      .uniq
      .sort_by { |v| AnimeVideoDecorator::HOSTINGS_ORDER[v] || v }
      .join(', ')
  end

  def new_report
    AnimeVideoReport.new(
      anime_video_id: current_video.id,
      user_id: h.current_user.try(:id) || User::GUEST_ID,
      state: 'pending',
      kind: 'broken'
    )
  end

  def new_video_url
    h.new_video_online_url(
      'anime_video[anime_id]' => @anime.id,
      'anime_video[source]' => Site::DOMAIN,
      'anime_video[state]' => 'uploaded',
      'anime_video[kind]' => 'fandub',
      'anime_video[language]' => 'russian',
      'anime_video[quality]' => 'tv',
      'anime_video[episode]' => current_episode
    )
  end

  def remember_video_preferences
    if current_video && current_video.persisted? && current_video.valid?
      h.cookies[PREFERENCES_KIND] = current_video.kind
      h.cookies[PREFERENCES_HOSTING] = current_video.hosting
      h.cookies[PREFERENCES_AUTHOR] = cleanup_author_name(current_video.author_name)
    end
  end

  # def compatible? video
    # !(h.mobile?) ||
      # !!(h.request.user_agent =~ /android/i) ||
      # video.vk? || video.smotret_anime?
  # end

  def episode_topic_view
    topic = @anime.object.news_topics.find_by(
      action: :episode,
      value: current_episode,
      locale: :ru
    )

    Topics::TopicViewFactory.new(true, false).build topic if topic
  end

  def cache_key
    [@anime.id, @anime.anime_videos.cache_key, :v6]
  end

private

  def episodes
    anime_video_episodes.map(&:episode)
  end

  def try_select_by kind, hosting, fixed_author_name
    by_kind = videos.select { |v| v.kind == kind }
    by_hosting = by_kind.select { |v| v.hosting == hosting }
    by_author = by_hosting.select { |v| cleanup_author_name(v.author_name) == fixed_author_name }

    by_author.first || by_hosting.first || by_kind.first || videos.first
  end

  def all?
    h.params[:all] && h.current_user.try(:video_moderator?)
  end

  def video_id
    h.params[:video_id].to_i
  end

  def cleanup_author_name name
    (name || '').sub(/(?<!^)\(.*\)/, '').strip
  end
end
