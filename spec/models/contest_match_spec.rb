describe ContestMatch do
  describe 'relations' do
    it { is_expected.to belong_to :round }
    it { is_expected.to belong_to(:left).optional }
    it { is_expected.to belong_to(:right).optional }
  end

  describe 'aasm' do
    subject do
      build :contest_match, state,
        started_on:,
        finished_on:
    end
    let(:started_on) { nil }
    let(:finished_on) { nil }

    context 'created' do
      let(:state) { Types::ContestMatch::State[:created] }

      it { is_expected.to have_state state }

      describe 'transition to started' do
        context 'started_on <= Time.zone.today' do
          let(:started_on) { Time.zone.yesterday }
          it { is_expected.to allow_transition_to :started }
          it { is_expected.to transition_from(state).to(:started).on_event(:start) }
        end

        context 'started_on < Time.zone.today' do
          let(:started_on) {  Time.zone.tomorrow }
          it { is_expected.to_not allow_transition_to :started }
        end
      end

      it { is_expected.to_not allow_transition_to :freezed }
      it { is_expected.to_not allow_transition_to :finished }
    end

    context 'started' do
      let(:state) { Types::ContestMatch::State[:started] }

      it { is_expected.to have_state state }
      it { is_expected.to_not allow_transition_to :created }

      describe 'transition to freezed' do
        context 'finished_on < Time.zone.today' do
          let(:finished_on) { Time.zone.yesterday }
          it { is_expected.to allow_transition_to :freezed }
          it { is_expected.to transition_from(state).to(:freezed).on_event(:freeze) }
          it { is_expected.to_not allow_transition_to :finished }
        end

        context 'finished_on >= Time.zone.today' do
          let(:finished_on) { Time.zone.today }
          it { is_expected.to_not allow_transition_to :freezed }
          it { is_expected.to_not allow_transition_to :finished }
        end
      end
    end

    context 'freezed' do
      let(:state) { Types::ContestMatch::State[:freezed] }

      it { is_expected.to have_state state }
      it { is_expected.to_not allow_transition_to :created }
      it { is_expected.to_not allow_transition_to :started }
      it { is_expected.to allow_transition_to :finished }
    end

    context 'finished' do
      let(:state) { Types::ContestMatch::State[:finished] }

      it { is_expected.to have_state state }
      it { is_expected.to_not allow_transition_to :created }
      it { is_expected.to_not allow_transition_to :started }
      it { is_expected.to_not allow_transition_to :freezed }
    end
  end

  describe 'instance_methods' do
    describe '#winner' do
      let(:match) { build_stubbed :contest_match, state: 'finished' }
      subject { match.winner }

      describe 'left' do
        before { match.winner_id = match.left_id }
        its(:id) { is_expected.to eq match.left.id }
      end

      describe 'right' do
        before { match.winner_id = match.right_id }
        its(:id) { is_expected.to eq match.right.id }
      end

      describe 'no winner' do
        before { match.winner_id = nil }
        it { is_expected.to be_nil }
      end
    end

    describe '#loser' do
      let(:match) { build_stubbed :contest_match, state: 'finished' }
      subject { match.loser }

      describe 'left' do
        before { match.winner_id = match.left_id }
        its(:id) { is_expected.to eq match.right.id }
      end

      describe 'right' do
        before { match.winner_id = match.right_id }
        its(:id) { is_expected.to eq match.left.id }
      end

      describe 'no loser' do
        before do
          match.winner_id = match.left_id
          match.right = nil
        end
        it { is_expected.to be_nil }
      end
    end

    describe '#draw?' do
      context 'not finished' do
        subject { build :contest_match, %i[created started].sample }
        it { is_expected.to_not be_draw }
      end

      context 'finished' do
        subject do
          build :contest_match, :finished,
            left_id:,
            right_id:,
            winner_id:
        end
        let(:left_id) { 1 }
        let(:right_id) { 1 }

        context 'has winner' do
          let(:winner_id) { [left_id, right_id].sample }
          it { is_expected.to_not be_draw }
        end

        context 'no winner' do
          let(:winner_id) { nil }
          it { is_expected.to be_draw }
        end
      end
    end
  end
end
