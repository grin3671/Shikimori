describe Search::Article do
  before do
    allow(Elasticsearch::Query::Article)
      .to receive(:call)
      .with(phrase:, limit: ids_limit)
      .and_return results
  end
  subject { described_class.call scope:, phrase:, ids_limit: }

  describe '#call' do
    let(:scope) { Article.all }
    let(:phrase) { 'zxct' }
    let(:ids_limit) { 2 }

    let(:results) { { article_1.id => 0.123123 } }

    let!(:article_1) { create :article }
    let!(:article_2) { create :article }

    it { is_expected.to eq [article_1] }
  end
end
