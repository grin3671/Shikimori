class DbEntries::MergeIntoOther
  include Sidekiq::Worker
  sidekiq_options queue: :dangerous_actions

  Type = Types::Coercible::String
    .enum(Anime.name, Manga.name, Character.name, Person.name)

  def perform type, from_id, to_id, user_id
    NamedLogger.dangerous_action.info "#{type}##{from_id} -> #{type}#{to_id} User##{user_id}"

    klass = Type[type].constantize

    DbEntry::MergeIntoOther.call(entry: klass.find(from_id), other: klass.find(to_id))
  rescue ActiveRecord::RecordNotFound
  end
end
