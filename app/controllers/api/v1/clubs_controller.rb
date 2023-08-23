class Api::V1::ClubsController < Api::V1Controller
  load_and_authorize_resource :club, only: %i[update]

  before_action :fetch_club, except: %i[index]

  LIMIT = 30

  before_action only: %i[update join leave] do
    doorkeeper_authorize! :clubs if doorkeeper_token.present?
  end

  caches_action :animes, :mangas, :characters, :members, :images,
    cache_path: proc {
      "#{@club.cache_key_with_version}|#{params[:action]}|#{params[:page]}|#{params[:limit]}"
    }

  api :GET, '/clubs', 'List clubs'
  param :page, :pagination, required: false
  param :limit, :number, required: false, desc: "#{LIMIT} maximum"
  param :search, String,
    required: false,
    allow_blank: true
  def index
    page = [params[:page].to_i, 1].max
    limit = [[params[:limit].to_i, 1].max, LIMIT].min

    @collection = Clubs::Query.fetch(current_user, false)
      .search(params[:search])
      .paginate_n1(page, limit)

    respond_with @collection
  end

  # AUTO GENERATED LINE: REMOVE THIS TO PREVENT REGENARATING
  api :GET, '/clubs/:id', 'Show a club'
  def show
    if @collection
      respond_with @collection, each_serializer: ClubProfileSerializer
    else
      respond_with @club, serializer: ClubProfileSerializer
    end
  end

  api :PATCH, '/clubs/:id', 'Update a club'
  api :PUT, '/clubs/:id', 'Update a club'
  description 'Requires `clubs` oauth scope'
  param :club, Hash do
    param :name, String
    param :description, String
    param :display_images, :boolean
    param :comment_policy, Types::Club::CommentPolicy.values.map(&:to_s)
    param :topic_policy, Types::Club::TopicPolicy.values.map(&:to_s)
    param :image_upload_policy, Types::Club::ImageUploadPolicy.values.map(&:to_s)
  end
  error code: 422
  def update
    Club::Update.call @resource, [], update_params, nil, current_user

    if @resource.errors.none?
      respond_with @resource.decorate, serializer: ClubProfileSerializer
    else
      respond_with @resource
    end
  end

  api :GET, '/clubs/:id/animes', "Show club's animes"
  param :page, :pagination, required: false
  param :limit, :number,
    required: false,
    desc: "#{ClubDecorator::LINKED_PER_PAGE[:animes]} maximum"
  def animes
    respond_with @club.paginated_animes
  end

  api :GET, '/clubs/:id/mangas', "Show club's mangas"
  param :limit, :number,
    required: false,
    desc: "#{ClubDecorator::LINKED_PER_PAGE[:mangas]} maximum"
  param :page, :pagination, required: false
  def mangas
    respond_with @club.paginated_mangas
  end

  api :GET, '/clubs/:id/ranobe', "Show club's ranobe"
  param :page, :pagination, required: false
  param :limit, :number,
    required: false,
    desc: "#{ClubDecorator::LINKED_PER_PAGE[:ranobe]} maximum"
  def ranobe
    respond_with @club.paginated_ranobe
  end

  api :GET, '/clubs/:id/characters', "Show club's characters"
  param :page, :pagination, required: false
  param :limit, :number,
    required: false,
    desc: "#{ClubDecorator::LINKED_PER_PAGE[:characters]} maximum"
  def characters
    respond_with @club.paginated_characters
  end

  api :GET, '/clubs/:id/collections'
  param :page, :pagination, required: false
  param :limit, :number,
    required: false,
    desc: "#{ClubDecorator::LINKED_PER_PAGE[:collections]} maximum"
  def collections
    @topic_views = @club.paginated_collections.map do |collection|
      Topics::TopicViewFactory.new(false, false).build collection.maybe_topic
    end

    respond_with @topic_views, each_serializer: TopicSerializer
  end

  api :GET, '/clubs/:id/clubs'
  param :page, :pagination, required: false
  param :limit, :number, required: false, desc: "#{LIMIT} maximum"
  def clubs
    respond_with @club.paginated_clubs
  end

  api :GET, '/clubs/:id/members', "Show club's members"
  param :page, :pagination, required: false
  param :limit, :number, required: false, desc: '100 maximum'
  def members
    params[:limit] ||= 100
    page = [params[:page].to_i, 1].max
    limit = [[params[:limit].to_i, 1].max, 100].min

    scope = QueryObjectBase
      .new(
        @club.object.member_roles.includes(:user).order(created_at: :desc)
      )
      .paginate_n1(page, limit)
      .map(&:user)

    respond_with scope
  end

  api :GET, '/clubs/:id/images', "Show club's images"
  param :page, :pagination, required: false
  param :limit, :number, required: false, desc: '100 maximum'
  def images
    params[:limit] ||= 100
    page = [params[:page].to_i, 1].max
    limit = [[params[:limit].to_i, 1].max, 100].min

    scope = QueryObjectBase
      .new(
        @club.object.images
      )
      .order(created_at: :desc)
      .paginate_n1(page, limit)

    respond_with scope
  end

  api :POST, '/clubs/:id/join', 'Join a club'
  description 'Requires `clubs` oauth scope'
  def join
    authorize! :join, @club
    @club.join current_user
    head :ok
  end

  api :POST, '/clubs/:id/leave', 'Leave a club'
  description 'Requires `clubs` oauth scope'
  def leave
    authorize! :leave, @club
    @club.leave current_user
    head :ok
  end

private

  def fetch_club
    ids = params[:id].split(',')

    if ids.one?
      fetch_single ids[0]
    else
      fetch_collection ids
    end
  end

  def fetch_single id
    @club = Club
      .find(id)
      .decorate

    raise ActiveRecord::RecordNotFound unless can? :see_club, @club
  end

  def fetch_collection ids
    @collection = Club
      .where(id: ids)
      .limit(LIMIT)
      .decorate
      .select { |club| can? :see_club, club }
  end

  def update_params
    params
      .require(:club)
      .permit(*::ClubsController::UPDATE_PARAMS)
  end
end
