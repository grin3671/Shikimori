class AdsPolicy
  pattr_initialize %i[
    user!
    ad_provider!
    is_disabled!
  ]

  def allowed?
    return false if ENV['IS_LOCAL_RUN']
    return false if @is_disabled

    return true unless @user
    return true if user.admin?
    return true if special? @ad_provider

    !contributor?(@user)
  end

private

  def special? ad_provider
    ad_provider == Types::Ad::Provider[:special]
  end

  def contributor? user
    user.forum_moderator? || user.critique_moderator? ||
      user.version_moderator? || user.version_texts_moderator? ||
      user.version_fansub_moderator? ||
      user.trusted_version_changer? || user.retired_moderator?
  end
end
