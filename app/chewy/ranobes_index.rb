class RanobesIndex < ApplicationIndex
  NAME_FIELDS = %i[
    name russian english japanese
    synonyms_0 synonyms_1 synonyms_2 synonyms_3 synonyms_4 synonyms_5
  ]

  KIND_WEIGHT = {
    novel: 1.2
  }

  settings DEFAULT_SETTINGS

  define_type Manga.where(type: Ranobe.name) do
    NAME_FIELDS.each do |name_field|
      field(name_field, {
        type: :keyword,
        index: :not_analyzed,
        value: -> {}
      }) do
        field :original, array_index_field(name_field, ORIGINAL_FIELD)
        field :edge, array_index_field(name_field, EDGE_FIELD)
        field :ngram, array_index_field(name_field, NGRAM_FIELD)
      end
    end
    # field :score, type: :half_float, index: false
    # field :year, type: :half_float, index: false
    field :kind_weight,
      type: :half_float,
      index: false,
      value: -> (model, _) { EntryWeight.call model }
  end
end
