describe Elasticsearch::Query::Collection, :vcr do
  # include_context :disable_vcr
  include_context :chewy_urgent
  include_context :chewy_indexes, %i[collections]
  # include_context :chewy_logger

  subject { described_class.call phrase:, limit: ids_limit }

  let!(:collection_1) { create :collection, name: 'test' }
  let!(:collection_2) { create :collection, name: 'test zxct' }

  let(:ids_limit) { 10 }
  let(:phrase) { 'test' }

  it { is_expected.to have_keys [collection_1.id, collection_2.id] }
end
