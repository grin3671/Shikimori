describe Elasticsearch::Query::Club, :vcr do
  # include_context :disable_vcr
  include_context :chewy_urgent
  include_context :chewy_indexes, %i[clubs]
  # include_context :chewy_logger

  subject { described_class.call phrase:, limit: ids_limit }

  let!(:club_1) { create :club, name: 'test' }
  let!(:club_2) { create :club, name: 'test zxct' }

  let(:ids_limit) { 10 }
  let(:phrase) { 'test' }

  it { is_expected.to have_keys [club_1.id, club_2.id] }
end
