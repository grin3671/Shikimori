class Topics::ContestView < Topics::View
  def poster_image_url is_2x
    topic.user.avatar_url is_2x ? 80 : 48
  end

  def show_inner?
    true
  end

  def action_tag
    super Topics::Tag.new(
      type: 'contest',
      text: i18n_i('contest', :one)
    )
  end

  def linked_in_poster?
    false
  end
end
