class Topics::NewsView < Topics::View
  def container_classes additional = []
    super(
      ['b-news-topic', *additional]
    )
  end

  def show_source?
    decomposed_body.source.present?
  end

  def topic_title
    topic.title
  end

  def topic_title_html
    topic_title
  end

  def action_tag additional = []
    super [
      Topics::Tag.new(
        type: 'news',
        text: i18n_i('news', :one)
      )
    ] + Array(additional)
  end

  def offtopic_tag
    I18n.t 'markers.offtopic' if topic.offtopic?
  end
end
