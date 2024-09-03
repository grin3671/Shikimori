describe Versions::DescriptionVersion do
  describe 'aasm' do
    let(:version) { build_stubbed :description_version, state }

    describe '#accept_taken' do
      let(:state) { :taken }
      it { expect(version).to be_may_accept_taken }
    end

    describe '#take_accepted' do
      let(:state) { :accepted }
      it { expect(version).to be_may_take_accepted }
    end
  end

  describe '#reevaluate_state' do
    let(:version) do
      create :description_version, state:, item_diff:
    end
    before { version.reevaluate_state }

    context 'description_ru' do
      let(:item_diff) do
        {
          description_ru: [old, new]
        }
      end

      context 'accepted' do
        let(:state) { 'accepted' }

        context 'big changes' do
          let(:old) { 'aaaaaaa aaa' }
          let(:new) { 'aaaaaaa bbb' }

          it { expect(version).to be_accepted }
        end

        context 'small changes' do
          let(:old) { 'aaaaaaaa aa' }
          let(:new) { 'aaaaaaaa bb' }

          it { expect(version).to be_taken }
        end
      end

      context 'taken' do
        let(:state) { 'taken' }

        context 'big changes' do
          let(:old) { 'aaaaaaa aaa' }
          let(:new) { 'aaaaaaa bbb' }

          it { expect(version).to be_accepted }
        end

        context 'small changes' do
          let(:old) { 'aaaaaaaa aa' }
          let(:new) { 'aaaaaaaa bb' }
          it { expect(version).to be_taken }
        end
      end
    end

    context 'description_en' do
      let(:item_diff) do
        {
          description_en: [old, new]
        }
      end
      let(:state) { 'accepted' }

      let(:old) { 'aaaaaaaa aa' }
      let(:new) { 'aaaaaaaa bb' }

      it { expect(version).to be_taken }
    end
  end
end
