class Types::PosterType < Types::BaseObject
  field :id, GraphQL::Types::BigInt

  field :original_url, String
  def original_url
    ImageUrlGenerator.instance.cdn_poster_url(
      poster: object,
      derivative: nil
    )
  end

  %i[
    main_2x
    main
    main_alt_2x
    main_alt
    preview_2x
    preview
    preview_alt_2x
    preview_alt
    mini_2x
    mini
    mini_alt_2x
    mini_alt
  ].each do |derivative|
    field :"#{derivative}_url", String
    define_method :"#{derivative}_url" do
      ImageUrlGenerator.instance.cdn_poster_url(
        poster: object,
        derivative: derivative
      )
    end
  end
end
