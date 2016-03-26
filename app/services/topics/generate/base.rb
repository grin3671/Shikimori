# frozen_string_literal: true

class Topics::Generate::Base < ServiceObjectBase
  pattr_initialize :model, :user

  attr_implement :call, :topic_attributes

private

  def faye_service
    FayeService.new user, ''
  end

  def topic
    topic_klass.new topic_attributes
  end

  def topic_klass
    "Topics::EntryTopics::#{model.class.name}Topic".constantize
  end

  def topic_attributes
    {
      forum_id: forum_id,
      generated: true,
      linked: model,
      user: user,
      created_at: model.created_at,
      updated_at: model.updated_at
    }
  end

  def forum_id
    Topic::FORUM_IDS[model.class.name]
  end
end
