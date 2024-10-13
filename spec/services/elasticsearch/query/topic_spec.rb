describe Elasticsearch::Query::Topic, :vcr do
  # include_context :disable_vcr
  include_context :chewy_urgent
  include_context :chewy_indexes, %i[topics]
  # include_context :chewy_logger

  subject do
    described_class.call(
      phrase:,
      limit: ids_limit,
      forum_id:
    )
  end

  let!(:topic_1) do
    create :topic, title: 'test', forum_id:
  end
  let!(:topic_2) do
    create :topic, title: 'test zxct', forum_id:
  end
  let!(:topic_4) do
    create :topic,
      title: 'test',
      forum_id: Topic::FORUM_IDS[Contest.name]
  end

  let(:ids_limit) { 10 }
  let(:phrase) { 'test' }
  let(:forum_id) { Topic::FORUM_IDS[Anime.name] }

  it { is_expected.to have_keys [topic_1.id, topic_2.id] }
end
