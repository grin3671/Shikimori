module DomainsConcern
  extend ActiveSupport::Concern

  included do
    helper_method :shikimori?, :old_host?, :new_host?
    before_action :force_301_redirect_with_magic_link
    before_action :force_301_redirect_for_guests
  end

  def shikimori?
    ShikimoriDomain::HOSTS.include? request.host
  end

  def old_host?
    request.host == ShikimoriDomain::OLD_HOST
  end

  def new_host?
    request.host == ShikimoriDomain::NEW_HOST ||
      Rails.env.development? ||
      ENV['USER'] == 'morr'
  end

  def force_301_redirect_with_magic_link # rubocop:disable AbcSize
    return if Rails.env.test?
    return unless domain_redirects_appliable?
    return unless user_signed_in?
    return if !request.get? || request.xhr?

    redirect_to request.protocol + ShikimoriDomain::PROPER_HOST +
      users_magic_link_path(
        token: Users::LoginToken.encode(current_user),
        redirect_url: request.url.sub(/.*?#{request.host}/, '')
      )
  end

  def force_301_redirect_for_guests
    return if Rails.env.test?
    return unless domain_redirects_appliable?
    return if user_signed_in?
    return if request.host == ShikimoriDomain::BANNED_HOST

    redirect_to request.url.sub(request.host, ShikimoriDomain::PROPER_HOST),
      status: :moved_permanently
  end

  def domain_redirects_appliable?
    request.host != ShikimoriDomain::PROPER_HOST &&
      request.get? &&
      !request.xhr?
  end
end
