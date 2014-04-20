# TODO: выпилить anime_statuses, :manga_statuses
class UserProfileSerializer < UserSerializer
  attributes :name, :sex, :full_years, :last_online, :last_online_at, :website, :location, :last_online_at
  attributes :banned?, :about, :about_html, :common_info, :last_online, :show_comments?

  attributes :anime_statuses, :manga_statuses, :stats

  def anime_statuses
    object.stats[:statuses][:anime]
  end

  def manga_statuses
    object.stats[:statuses][:manga]
  end

  def website
    (object.object.website || '').sub(/^https?:\/\//, '')
  end

  def stats
    object.stats.except(:graph_statuses)
  end
end
