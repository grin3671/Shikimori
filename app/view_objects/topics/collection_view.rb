class Topics::CollectionView < Topics::UserContentView
  instance_cache :collection, :tags

  def container_classes
    super "b-collection-topic#{' is-spoilers' if collection.is_spoilers?}".strip
  end

  def url options = {}
    if is_mini
      canonical_url
    else
      super
    end
  end

  def canonical_url
    h.collection_url collection
  end

  def html_body
    if preview?
      preview_html
    else
      collection_html
    end
  end

  def action_tag
    tags = []

    tags << Topics::Tag.new(
      type: 'collection',
      text: Collection.model_name.human.downcase
    )

    unless collection.published?
      tags << Topics::Tag.new(
        type: "#{collection.state}-collection",
        text: collection.aasm.human_state.downcase
      )
    end

    if collection.spoilers?
      tags << Topics::Tag.new(
        type: 'spoilers',
        text: I18n.t('topics.header.mini.spoilers').downcase
      )
    end

    super tags
  end

  def offtopic_tag
    super if collection.published?
  end

  def collection
    @topic.linked.decorate
  end

  def prebody?
    tags.any?
  end

  def linked_in_poster?
    false
  end

  def tags
    super.map do |tag|
      Topics::Tag.new(
        type: 'collection-tag',
        text: tag,
        url: h.collections_url(search: "##{tag}")
      )
    end
  end

private

  def preview_html
    h.render(
      partial: 'collections/preview',
      formats: :html, # for /forum.rss
      locals: { collection: collection, topic_view: self }
    )
  end

  def collection_html
    # without specifying format it won't be rendered in api (https://shikimori.one/api/topics/223789)
    h.render(
      partial: 'collections/collection',
      object: collection,
      formats: :html
    )
  end
end
