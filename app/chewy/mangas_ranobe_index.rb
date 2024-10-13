class MangasRanobeIndex < ApplicationIndex
  NAME_FIELDS = %i[
    name russian english japanese
    synonyms_0 synonyms_1 synonyms_2 synonyms_3 synonyms_4 synonyms_5
    synonyms_6 synonyms_7 synonyms_8
    license_name_ru
  ]

  settings JP_SETTINGS

  define_type Manga do
    NAME_FIELDS.each do |name_field|
      field name_field,
        type: 'keyword',
        index: false,
        value: ->(model) {
          if name_field =~ /^(?<name>\w+)_(?<index>\d)$/
            model.send($LAST_MATCH_INFO[:name])[$LAST_MATCH_INFO[:index].to_i]
          else
            model.send(name_field)
          end
        },
        fields: {
          original: ORIGINAL_FIELD,
          edge_phrase: EDGE_PHRASE_FIELD,
          edge_word: EDGE_WORD_FIELD,
          ngram: NGRAM_FIELD
        }
    end

    # field :weight,
    #   type: 'half_float',
    #   index: false,
    #   value: ->(model, _) { 1.2 } # Relevance::EntryWeight.call model }
  end
end

