describe YandexMetrika, :vcr do
  subject { described_class.call 18 }

  include_context :timecop, '2023-06-30'

  it do
    is_expected.to have_at_least(500).items
    expect(subject.first).to be_kind_of TrafficEntry
  end
end
