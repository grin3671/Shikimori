describe CollectionLink do
  describe 'relations' do
    it { is_expected.to belong_to :collection }
    it { is_expected.to belong_to :linked }
    Types::Collection::Kind.values.each do |kind| # rubocop:disable all
      it { is_expected.to belong_to(kind).optional }
    end
  end

  describe 'validations' do
    # it { is_expected.to validate_uniqueness_of(:linked_id).scoped_to(:collection_id) }

    context 'censored' do
      before do
        subject.collection = build :collection, is_censored: is_censored_collection
        subject.linked = build_stubbed :anime, is_censored: true
      end

      context 'non censored collection' do
        let(:is_censored_collection) { false }
        it do
          is_expected.to_not be_valid
          expect(subject.errors[:linked]).to eq [
            I18n.t('activerecord.errors.models.collection_link.attributes.linked.censored')
          ]
        end
      end

      context 'censored collection' do
        let(:is_censored_collection) { true }
        it { is_expected.to be_valid }
      end
    end
  end

  describe 'enumerize' do
    it do
      is_expected
        .to enumerize(:linked_type)
        .in(*Types::Collection::Kind.values.map(&:to_s).map(&:classify))
    end
  end
end
