class Topics::Query < QueryObjectBase
  BY_LINKED_CLUB_SQL = <<-SQL.squish
    (#{Topics::ForumQuery::CLUBS_QUERY}) and (
      topics.type not in (
        #{ApplicationRecord.sanitize Topics::ClubUserTopic.name},
        #{ApplicationRecord.sanitize Topics::EntryTopics::ClubTopic.name},
        #{ApplicationRecord.sanitize Topics::EntryTopics::ClubPageTopic.name}
      ) or comments_count != 0
    )
  SQL

  def self.fetch locale, is_censored_forbidden
    query = new Topic
      .includes(:forum, :user, :linked)
      .order(updated_at: :desc)
      .where(locale: locale)

    # .except_ignored(user)
    if is_censored_forbidden
      query.where is_censored: false
    else
      query
    end
  end

  def by_forum forum, user, is_censored_forbidden
    chain Topics::ForumQuery.call(
      scope: except_episodes(@scope, forum),
      forum: forum,
      user: user,
      is_censored_forbidden: is_censored_forbidden
    )
  end

  def by_linked linked
    if linked.is_a? Club
      chain @scope
        .where(
          BY_LINKED_CLUB_SQL,
          club_ids: linked.id,
          club_page_ids: linked.pages.pluck(:id)
        )
    elsif linked
      chain @scope.where(linked: linked)
    else
      self
    end
  end

  # def except_ignored user
    # if user
      # chain @scope.where.not id: user.topic_ignores.map(&:topic_id)
    # else
      # self
    # end
  # end

  def search phrase, forum, user, locale
    chain Topics::SearchQuery.call(
      scope: @scope,
      phrase: phrase,
      forum: forum,
      user: user,
      locale: locale
    )
  end

  def as_views is_preview, is_mini
    transform do |topic|
      Topics::TopicViewFactory.new(is_preview, is_mini).build topic
    end
  end

private

  def except_episodes scope, forum
    if forum == Forum::UPDATES_FORUM || forum&.id == Forum::NEWS_ID
      scope.wo_episodes
    else
      scope.where.not(updated_at: nil)
    end
  end
end
