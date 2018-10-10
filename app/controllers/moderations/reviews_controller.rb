class Moderations::ReviewsController < ModerationsController
  load_and_authorize_resource

  PENDING_PER_PAGE = 15
  PROCESSED_PER_PAGE = 25

  def index
    og page_title: i18n_t('page_title')

    @moderators = User
      .where("roles && '{#{Types::User::Roles[:review_moderator]}}'")
      .where.not(id: User::MORR_ID)
      .sort_by { |v| v.nickname.downcase }

    @processed = QueryObjectBase.new(processed_scope).paginate(@page, PROCESSED_PER_PAGE)
    @pending = pending_scope
  end

  def accept
    @resource.accept current_user
    redirect_back fallback_location: moderations_reviews_url
  end

  def reject
    @resource.reject current_user
    redirect_back fallback_location: moderations_reviews_url
  end

  def cancel
    @resource.cancel current_user
    redirect_back fallback_location: moderations_reviews_url
  end

private

  def processed_scope
    Review
      .where(moderation_state: %i[accepted rejected])
      .where(locale: locale_from_host)
      .includes(:user, :approver, :target, :topics)
      .order(created_at: :desc)
  end

  def pending_scope
    Review
      .where(moderation_state: :pending)
      .where(locale: locale_from_host)
      .includes(:user, :approver, :target, :topics)
      .order(created_at: :desc)
      .limit(PENDING_PER_PAGE)
  end
end
