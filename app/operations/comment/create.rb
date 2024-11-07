class Comment::Create
  method_object %i[
    params!
    faye!
    is_conversion
    is_forced
  ]

  def call
    comment = Comment.new @params.except(:commentable_id, :commentable_type)
    comment.instance_variable_set :@is_conversion, @is_conversion

    RedisMutex.with_lock(mutex_key, block: 30.seconds, expire: 30.seconds) do
      apply_commentable comment
    end

    if commenting_allowed? comment
      @faye.send @is_forced ? :create! : :create, comment

      if comment.persisted?
        notify_user comment if profile_comment?
        touch_topic comment if topic_comment? || db_entry_comment?
      end
    else
      add_error comment
    end

    comment
  end

private

  def mutex_key
    'comment_' \
      "#{@params[:commentable_id]}_" \
      "#{@params[:commentable_type]}"
  end

  def apply_commentable comment
    return if commentable_klass == NilClass

    if no_topic_generation? commentable_klass
      comment.assign_attributes @params.slice(:commentable_id, :commentable_type)
    else
      comment.commentable = find_or_generate_topic
    end
  end

  def commenting_allowed? comment
    Commentable::AccessPolicy.allowed? comment.commentable, comment.user
  end

  def find_or_generate_topic
    commentable_object.topic || commentable_object.generate_topic
  end

  def notify_user comment
    User::NotifyProfileCommented.call comment
  end

  def touch_topic comment
    comment.commentable.touch
  end

  def add_error comment
    comment.errors.add(
      :base,
      I18n.t('activerecord.errors.models.comments.access_denied')
    )
    raise ActiveRecord::RecordInvalid, comment if @is_forced
  end

  # NOTE: Topic, User, Review or DbEntry
  def commentable_klass
    @params[:commentable_type].constantize
  rescue NameError
    NilClass
  end

  def commentable_object
    @commentable_object ||= commentable_klass.find @params[:commentable_id]
  end

  def no_topic_generation? commentable_klass
    topic_comment? || profile_comment? || commentable_klass == Review
  end

  def topic_comment?
    commentable_klass <= Topic
  end

  def db_entry_comment?
    commentable_klass <= DbEntry
  end

  def profile_comment?
    commentable_klass <= User
  end
end
