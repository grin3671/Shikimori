FactoryGirl.define do
  factory :user do
    sequence(:nickname) { |n| "user_#{n}" }
    email { FactoryGirl.generate :email }
    password '123'
    last_online_at { Time.zone.now }

    can_vote_1 false
    can_vote_2 false
    can_vote_3 false

    notifications User::DEFAULT_NOTIFICATIONS

    locale 'ru'
    locale_from_host 'ru'

    after :build do |user|
      user.class.skip_callback :create, :after, :create_history_entry
      user.class.skip_callback :create, :after, :ensure_api_access_token
      user.class.skip_callback :create, :after, :assign_style
      user.class.skip_callback :create, :after, :send_welcome_message
      user.class.skip_callback :create, :after, :grab_avatar

      user.class.skip_callback :create, :after, :post_elastic
      user.class.skip_callback :update, :after, :put_elastic
      user.class.skip_callback :destroy, :after, :delete_elastic
    end

    trait :with_elasticserach do
      after :build do |user|
        user.class.set_callback :create, :after, :post_elastic
        user.class.set_callback :update, :after, :put_elastic
        user.class.set_callback :destroy, :after, :delete_elastic
      end
    end

    trait :with_assign_style do
      after(:build) { |user| user.send :assign_style }
    end

    trait(:user) { sequence :id, 23_456_789 }
    trait(:guest) { id User::GUEST_ID }
    trait(:admin) { id User::ADMINS.last }
    trait(:moderator) { id User::MODERATORS.last }
    trait(:contests_moderator) { id User::CONTEST_MODERATORS.last }
    trait(:reviews_moderator) { id User::REVIEWS_MODERATORS.last }
    trait(:video_moderator) { id User::VIDEO_MODERATORS.last }
    trait(:versions_moderator) { id User::VERSIONS_MODERATORS.last }
    trait(:banhammer) { id User::BANHAMMER_ID }
    trait(:cosplayer) { id User::COSPLAYER_ID }
    trait(:trusted_video_uploader) { id User::TRUSTED_VIDEO_UPLOADERS.last }
    trait(:trusted_version_changer) { id User::TRUSTED_VERSION_CHANGERS.last }
    trait(:api_video_uploader) { id User::API_VIDEO_UPLOADERS.last }

    trait :version_vermin do
      id User::VERSION_VERMINS.last
    end

    trait :without_password do
      password nil

      after :build do |user|
        user.stub(:password_required?).and_return false
      end
    end

    trait :banned do
      read_only_at { 1.year.from_now - 1.week }
    end
    trait :forever_banned do
      read_only_at { 1.year.from_now + 1.week }
    end
    trait :day_registered do
      created_at { 25.hours.ago }
    end
    trait :week_registered do
      created_at { 8.days.ago }
    end

    trait :with_avatar do
      avatar { File.new "#{Rails.root}/spec/images/anime.jpg" }
    end
  end
end
