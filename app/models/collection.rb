class Collection < ApplicationRecord
  include ClubsConcern
  include AntispamConcern
  include TopicsConcern
  include TagsConcern
  include ModeratableConcern

  boolean_attributes :spoilers, :censored

  antispam(
    per_day: 5,
    user_id_key: :user_id
  )

  acts_as_votable cacheable_strategy: :update_columns
  update_index('collections#collection') { self if saved_change_to_name? }

  after_update :sync_topics_is_censored, if: :saved_change_to_is_censored?

  belongs_to :user,
    touch: Rails.env.test? ? false : :activity_at
  has_many :links, -> { order :id },
    inverse_of: :collection,
    class_name: 'CollectionLink',
    dependent: :destroy
  has_many :collection_roles, dependent: :destroy
  has_many :coauthors, through: :collection_roles, source: :user

  validates :name, :kind, presence: true
  validates :name, length: { maximum: 255 }
  validates :text, length: { maximum: 400_000 }

  enumerize :kind, in: Types::Collection::Kind.values, predicates: true
  # enumerize :state, in: Types::Collection::State.values, predicates: true

  scope :unpublished, -> { where state: :unpublished }
  scope :published, -> { where state: :published }

  scope :available, -> { visible.published }
  scope :publicly_available, -> {
    available.or(where(state: Types::Collection::State[:opened]))
  }

  aasm column: 'state', create_scopes: false do
    state Types::Collection::State[:unpublished], initial: true
    state Types::Collection::State[:published]
    state Types::Collection::State[:private]
    state Types::Collection::State[:opened]

    event :to_published do
      transitions(
        from: [
          Types::Collection::State[:unpublished],
          Types::Collection::State[:private],
          Types::Collection::State[:opened]
        ],
        to: Types::Collection::State[:published]
        # after: :fill_published_at
      )
    end
    event :to_private do
      transitions(
        from: [
          Types::Collection::State[:unpublished],
          Types::Collection::State[:published],
          Types::Collection::State[:opened]
        ],
        to: Types::Collection::State[:private]
      )
    end
    event :to_opened do
      transitions(
        from: [
          Types::Collection::State[:unpublished],
          Types::Collection::State[:published],
          Types::Collection::State[:private]
        ],
        to: Types::Collection::State[:opened]
      )
    end
  end

  def to_param
    "#{id}-#{name.permalinked}"
  end

  def db_type
    if ranobe?
      Types::Collection::Kind[:manga].to_s.capitalize
    else
      kind.capitalize
    end
  end

  # compatibility with DbEntry
  def topic_user
    user
  end

  def description_ru
    text
  end

  def description_en
    text
  end

  def coauthor? user
    collection_role(user).present?
  end

  def collection_role user
    collection_roles.find { |v| v.user_id == user.id }
  end

  def sync_topics_is_censored
    Collections::SyncTopicsIsCensored.call self
  end

# private

  # def fill_published_at
  #   self.published_at ||= Time.zone.now
  # end
end
