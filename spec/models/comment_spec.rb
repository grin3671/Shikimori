describe Comment do
  describe 'relations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :commentable }
    it { is_expected.to belong_to :topic }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :views }
    it { is_expected.to have_many :abuse_requests }
    it { is_expected.to have_many :bans }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :body }
    it { is_expected.to validate_presence_of :user }
    it { is_expected.to validate_presence_of :commentable }
  end

  describe 'callbacks' do
    let(:user) { build_stubbed :user }
    let(:user2) { build_stubbed :user }
    let(:topic) { build_stubbed :entry, user: user }
    let(:comment) { create :comment, user: user, commentable: topic }

    describe '#clean' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :clean }
    end

    describe '#forbid_ban_change' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :forbid_ban_change }
    end

    describe '#check_access' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :check_access }
    end

    describe '#cancel_summary' do
      let(:comment) { build :comment, :summary, body: body }
      before { comment.save }

      context 'long comment' do
        let(:body) { 'x' * Comment::MIN_SUMMARY_SIZE }
        it { expect(comment).to be_summary }
      end

      context 'short comment' do
        let(:body) { 'x' * (Comment::MIN_SUMMARY_SIZE - 1) }
        it { expect(comment).to_not be_summary }
      end
    end

    describe '#increment_comments' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :increment_comments }
    end

    describe '#creation_callbacks' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :creation_callbacks }
    end

    describe '#notify_quotes' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :notify_quotes }
    end

    describe '#decrement_comments' do
      let(:comment) { create :comment }
      after { comment.destroy }
      it { expect(comment).to receive :decrement_comments }
    end

    describe '#destruction_callbacks' do
      let(:comment) { create :comment }
      after { comment.destroy }
      it { expect(comment).to receive :destruction_callbacks }
    end

    describe '#release_the_banhammer!' do
      let(:comment) { build :comment, :with_banhammer }
      after { comment.save }
      it { expect(Banhammer.instance).to receive :release! }
    end

    describe '#remove_replies' do
      let(:comment) { create :comment }
      after { comment.destroy }
      it { expect(comment).to receive :remove_replies }
    end
  end

  describe 'instance methods' do
    let(:user) { build_stubbed :user }
    let(:user2) { build_stubbed :user }
    let(:topic) { build_stubbed :entry, user: user }
    let(:comment) { create :comment, user: user, commentable: topic }

    describe '#html_body' do
      let(:comment) { build :comment, body: body }
      let(:body) { '[b]bold[/b]' }

      it { expect(comment.html_body).to eq '<strong>bold</strong>' }

      describe 'comment in offtopic topic' do
        let(:offtopic_topic_id) { 82468 }
        let(:comment) do
          build :comment,
            body: body,
            commentable_id: offtopic_topic_id,
            commentable_type: Entry.name
        end

        describe 'poster' do
          let(:body) { '[poster]http:///test.com[/poster]' }
          it { expect(comment.html_body).to_not include 'b-poster' }
        end

        describe 'img' do
          let(:body) { '[img w=747 h=1047]http:///test.com[/img]' }
          it { expect(comment.html_body).to_not include 'width=' }
          it { expect(comment.html_body).to_not include 'height=' }
        end

        describe 'image' do
          let(:body) { '[image=149374 9999x9999]' }
          it { expect(comment.html_body).to eq '[image=149374]' }
        end
      end
    end

    describe '#notify_quotes' do
      let(:user) { create :user }
      let(:user2) { create :user }
      let(:topic) { create :topic, user: user }
      let(:user_message) { Message.where(to_id: user.id, from_id: user2.id, kind: MessageType::QuotedByUser) }

      subject { create :comment, :with_notify_quotes, body: text, commentable: topic, user: user2 }

      context 'quote' do
        let(:text) { "[quote=200778;#{user.id};test2]test[/quote]" }
        it { expect{subject}.to change(user_message, :count).by 1 }

        context 'quote by ignored user' do
          let!(:ignore) { create :ignore, user: user, target: user2 }
          it { expect{subject}.to_not change user_message, :count }
        end
      end

      context 'comment' do
        let!(:comment) { create :comment, commentable: topic, user: user }
        let(:text) { "[comment=#{comment.id}]test[/comment]" }
        it { expect{subject}.to change(user_message, :count).by 1 }
      end

      context 'entry' do
        let(:text) { "[entry=#{topic.id}]test[/entry]" }
        it { expect{subject}.to change(user_message, :count).by 1 }
      end

      context 'mention' do
        let(:text) { "[mention=#{user.id}]test[/mention]" }
        it { expect{subject}.to change(user_message, :count).by 1 }
      end

      it 'notification only once' do
        text = "[mention=#{user.id}]test[/mention]"
        expect {
          create :comment, :with_notify_quotes, body: text, commentable: topic, user: user2
          Comment.wo_antispam { create :comment, body: text, commentable: topic, user: user2 }
        }.to change(user_message, :count).by 1
      end

      it 'second notification when first one is read' do
        text = "[mention=#{user.id}]test[/mention]"
        create :comment, :with_notify_quotes, body: text, commentable: topic, user: user2
        Message.last.update_column :read, true

        expect {
          Comment.wo_antispam { create :comment, :with_notify_quotes, body: text, commentable: topic, user: user2 }
        }.to change(user_message, :count).by 1
      end
    end

    describe '#forbid_ban_change' do
      subject! { build :comment, body: "[ban=1]" }
      before { subject.valid? }
      its(:valid?) { is_expected.to be_falsy }

      it { expect(subject.errors.messages[:base].first).to eq I18n.t('activerecord.errors.models.comments.not_a_moderator') }
    end

    describe '#allowed_summary?' do
      let(:comment) { build :comment, commentable: commentable }

      context 'Topic commentable' do
        let(:commentable) { build :topic }
        it { expect(comment).to_not be_allowed_summary }
      end

      context 'Topics::EntryTopics::AnimeTopic commentable' do
        let(:commentable) { build :anime_topic }
        it { expect(comment).to be_allowed_summary }
      end

      context 'Topics::EntryTopics::MangaTopic commentable' do
        let(:commentable) { build :manga_topic }
        it { expect(comment).to be_allowed_summary }
      end
    end

    describe '#mark_offtopic' do
      let!(:comment) { create :comment, is_offtopic: offtopic }
      let!(:inner_comment) do
        create :comment,
          body: "[comment=#{comment.id}]",
          is_offtopic: offtopic
      end

      before { comment.mark_offtopic flag }

      context 'mark offtopic' do
        let(:offtopic) { false }
        let(:flag) { true }

        it { expect(comment.reload).to be_offtopic }
        it { expect(inner_comment.reload).to be_offtopic }
      end

      context 'mark not offtopic' do
        let(:offtopic) { true }
        let(:flag) { false }

        it { expect(comment.reload).not_to be_offtopic }
        it { expect(inner_comment.reload).to be_offtopic }
      end
    end

    describe '#mark_summary' do
      let!(:comment) { create :comment, is_summary: is_summary }
      before { comment.mark_summary flag }

      context 'mark summary' do
        let(:is_summary) { false }
        let(:flag) { true }

        it { expect(comment.reload).to be_summary }
      end

      context 'mark not summary' do
        let(:is_summary) { true }
        let(:flag) { false }

        it { expect(comment.reload).not_to be_summary }
      end
    end
  end
end
