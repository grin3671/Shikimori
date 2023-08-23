class Ad < ViewObjectBase # rubocop:disable ClassLength
  # present advertur blocks
  # block_1: [92_129, 2_731],
  # block_2: [92_445, 1_256],
  # block_3: [92_485, nil]

  # CACHE_KEY = Digest::MD5.hexdigest(META_TYPES.to_json)

  attr_reader :banner_type, :policy

  def initialize meta, is_forced: false # rubocop:disable all
    @is_forced = is_forced
    meta = Types::Ad::Meta[:menu_240x400] if switch_to_x240?(meta) && !@is_forced
    meta = Types::Ad::Meta[:menu_300x600] if switch_to_x300?(meta) && !@is_forced

    META_TYPES[Types::Ad::Meta[meta]].each do |type|
      switch_banner Types::Ad::Type[type]
      break if allowed?
    end
  end

  def allowed? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    return true if @is_forced
    return false if h.old_host?

    if h.controller.instance_variable_get controller_key(banner&.dig(:placement))
      false
    else
      policy&.allowed? && (!@rules || @rules.show?)
    end
  end

  def provider
    banner[:provider]
  end

  def placeholder?
    return false if ShikimoriDomain::PROPER_HOST == ShikimoriDomain::NEW_HOST

    Rails.env.development? && !special?
  end

  def platform
    banner[:platform]
  end

  def ad_params
    return unless yandex_direct?

    {
      blockId: banner[:yandex_id],
      renderTo: @banner_type,
      async: true
    }
  end

  def css_class
    "spns_#{@banner_type}"
  end

  def to_html cache_variant = nil
    finalize

    <<-HTML.gsub(/\n|^\ +/, '')
      <div class="b-spns-#{@banner_type}">
        <center>
          #{ad_html cache_variant}
        </center>
      </div>
    HTML
  end

private

  def switch_banner banner_type
    @banner_type = banner_type
    @policy = build_policy if banner
    @rules = build_rules if banner
  end

  def build_policy
    AdsPolicy.new(
      user: h.current_user,
      ad_provider: provider,
      is_disabled: h.cookies["#{css_class}_ad_disabled"].present?
    )
  end

  def build_rules
    return unless banner[:rules]

    Ads::Rules.new banner[:rules], h.cookies[banner[:rules][:cookie]]
  end

  def banner
    BANNERS[@banner_type]
  end

  def yandex_direct?
    provider == Types::Ad::Provider[:yandex_direct]
  end

  def mytarget?
    provider == Types::Ad::Provider[:mytarget]
  end

  def special?
    provider == Types::Ad::Provider[:special]
  end

  def banner?
    banner[:images].present?
  end

  def html?
    banner[:html].present?
  end

  def iframe?
    provider == Types::Ad::Provider[:advertur]
  end

  def ad_html cache_variant # rubocop:disable all
    if placeholder?
      width, height =
        if @banner_type =~ /(?<width>\d+)x(?<height>\d+)/
          [$LAST_MATCH_INFO[:width], $LAST_MATCH_INFO[:height]]
        else
          [500, 500]
        end

      "<div class='ad-placeholder' style='width: #{width}px; " \
        "height: #{height}px;' data-banner_type='#{@banner_type}' >"

    elsif yandex_direct?
      "<div id='#{@banner_type}'></div>"

    elsif mytarget?
      <<-HTML.squish
        <ins
          class="mrg-tag"
          style="display:inline-block;text-decoration: none;"
          data-ad-client="ad-#{banner[:mytarget_id]}"
          data-ad-slot="#{banner[:mytarget_id]}"></ins>
      HTML

    elsif banner?
      image = cache_variant ? banner[:images][cache_variant] : banner[:images].sample

      image_html =
        if image[:src_2x]
          "<img src='#{image[:src]}' srcset='#{image[:src_2x]} 2x' loading='lazy'>"
        else
          "<img src='#{image[:src]}' loading='lazy'>"
        end

      pixel_html = "<img src='#{banner[:pixel]}' border='0' width='1' height='1'>" if banner[:pixel]

      "#{pixel_html}<a href='#{banner[:url] || image[:url]}'>#{image_html}</a>"
    elsif html?
      banner[:html]

    elsif iframe?
      "<iframe src='#{advertur_url}' width='#{banner[:width]}px' height='#{banner[:height]}px'>"

    else
      raise ArgumentError
    end
  end

  def advertur_url
    h.spnsr_url(
      banner[:advertur_id],
      width: banner[:width],
      height: banner[:height],
      container_class: css_class,
      protocol: false
    )
  end

  def switch_to_x240? meta
    [
      Types::Ad::Meta[:menu_300x600]
      # Types::Ad::Meta[:menu_300x250]
    ].include?(meta) && h.current_user&.preferences&.body_width_x1000?
  end

  def switch_to_x300? meta
    [
      Types::Ad::Meta[:menu_240x400]
    ].include?(meta) && h.params[:controller].in?(%w[topics])
  end

  def finalize
    h.controller.instance_variable_set controller_key(banner[:placement]), true

    if @rules
      h.cookies[banner[:rules][:cookie]] = {
        value: @rules.export_shows,
        expires: 1.week.from_now
      }
    end
  end

  def controller_key placement
    :"@is_#{placement}_ad_shown"
  end

  SPECIAL_X300 = {
    provider: Types::Ad::Provider[:special],
    # url: 'https://ads.adfox.ru/707246/goLink?p1=cxdxi&p2=frfe&p5=nqxpb&pr=[RANDOM]',
    # pixel: 'https://ads.adfox.ru/707246/getCode?p1=cxdxi&p2=frfe&pfc=exzsj&pfb=nqxpb&pr=[RANDOM]&ptrc=b',
    # convert -resize 50% app/assets/images/globals/events/2022-06-18/menu_1@2x.jpg app/assets/images/globals/events/2022-06-18/menu_1.jpg
    # images: (1..1).map do |i|
    #   {
    #     src: "/assets/globals/events/2023-02-10/menu_#{i}.jpg",
    #     src_2x: "/assets/globals/events/2023-02-10/menu_#{i}@2x.jpg"
    #   }
    # end,
    url: 'https://alabuga-polytech.ru/?utm_source=kaifooi_sites&utm_medium=banner&utm_campaign=shikimori&utm_content=600x1000',
    images: [{
      src: '/assets/globals/events/2023-08-17/menu_1.webp',
      src_2x: '/assets/globals/events/2023-08-17/menu_1@2x.jpg'
      # url: 'https://redirect.appmetrica.yandex.com/serve/316406067464575159'
    }],
    rules: {
      cookie: 'i7',
      shows_per_week: 480 # 380 # 420 # 540
    },
    placement: Types::Ad::Placement[:menu],
    platform: Types::Ad::Platform[:desktop]
  }
  SPECIAL_X1170 = {
    provider: Types::Ad::Provider[:special],
    # url: 'https://ads.adfox.ru/707246/goLink?p1=cxdxi&p2=frfe&p5=nqxpb&pr=[RANDOM]',
    # pixel: 'https://ads.adfox.ru/707246/getCode?p1=cxdxi&p2=frfe&pfc=exzsj&pfb=nqxpb&pr=[RANDOM]&ptrc=b',
    # convert -resize 50% app/assets/images/globals/events/2022-06-18/menu_1@2x.jpg app/assets/images/globals/events/2022-06-18/menu_1.jpg
    url: 'https://app.adjust.com/d3171d2_ko3lqk1?fallback=https://www.pubgmobile.com&campaign=DragonBall',
    images: (1..1).map do |i|
      {
        src: "/assets/globals/events/2023-08-02/wide_#{i}.webp",
        src_2x: "/assets/globals/events/2023-08-02/wide_#{i}@2x.webp"
      }
    end,
    # images: [{
    #   src: '/assets/globals/events/2022-10-05/wide.jpg',
    #   src_2x: '/assets/globals/events/2022-10-05/wide@2x.jpg'
    # }],
    # images: (1..4).map do |i|
    #   {
    #     src: "/assets/globals/events/2022-11-01/wide_#{i}.jpg",
    #     src_2x: "/assets/globals/events/2022-11-01/wide_#{i}@2x.jpg"
    #   }
    # end,
    # html: (
    #   <<~HTML
    #     <style>
    #       #iframe_special_x1170 {
    #         max-width: 1150px;
    #         width: 100%;
    #         height: 180px;
    #         margin: 0 auto;
    #         overflow: hidden;
    #       }
    #       .spns_special_x1170 {
    #         max-width: 1150px;
    #         margin: 0 auto;
    #         overflow: hidden;
    #       }
    #       .b-spns-special_x1170 {
    #         margin: 0 auto 45px;
    #         overflow: hidden;
    #       }
    #     </style>
    #     <iframe id="iframe_special_x1170" src="/1150x180Dogs.html">
    #   HTML
    # ),
    placement: Types::Ad::Placement[:content],
    platform: Types::Ad::Platform[:desktop]
  }
  SPECIAL_X894 = {
    provider: Types::Ad::Provider[:special],
    url: 'https://startgame.rsv.ru/auth?utm_source=site&utm_medium=app&utm_campaign=rk75&utm_content=shikimori&utm_term=test',
    images: (1..1).map do |i|
      {
        src: "/assets/globals/events/2023-08-22/wide_#{i}.jpg"
        # src_2x: "/assets/globals/events/2023-08-18/wide_#{i}@2x.webp"
      }
    end,
    # images: [{
    #   src: '/assets/globals/events/2023-06-02/inner_1.webp',
    #   url: 'https://imba.shop/catalog/anime-energy?utm_source=shikimori&utm_medium=banner1&utm_campaign=02_06&erid=2Vtzqv5UkDh'
    # }],
    rules: {
      cookie: 'i9',
      shows_per_week: 480 # 380 # 420 # 540
    },
    placement: Types::Ad::Placement[:content],
    platform: Types::Ad::Platform[:desktop]
  }

  BANNERS = {
    Types::Ad::Type[:special_x300] => SPECIAL_X300,
    Types::Ad::Type[:special_x1170] => SPECIAL_X1170,
    Types::Ad::Type[:special_x894] => SPECIAL_X894,
    Types::Ad::Type[:yd_300x600] => {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-2374107-2',
      # yandex_id: 'R-A-438288-1',
      placement: Types::Ad::Placement[:menu],
      platform: Types::Ad::Platform[:desktop]
    },
    Types::Ad::Type[:yd_240x400] => {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-2374107-5',
      # yandex_id: 'R-A-438288-2',
      placement: Types::Ad::Placement[:menu],
      platform: Types::Ad::Platform[:desktop]
    },
    Types::Ad::Type[:yd_1170x200] => {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-2374107-3',
      # yandex_id: 'R-A-438288-3',
      placement: Types::Ad::Placement[:content],
      platform: Types::Ad::Platform[:desktop]
    },
    Types::Ad::Type[:yd_970x90] => {
      provider: Types::Ad::Provider[:yandex_direct],
      yandex_id: 'R-A-2374107-4',
      # yandex_id: 'R-A-438288-4',
      placement: Types::Ad::Placement[:content],
      platform: Types::Ad::Platform[:desktop]
    }
    # Types::Ad::Type[:advrtr_x728] => {
    #   provider: Types::Ad::Provider[:advertur],
    #   advertur_id: 92_445,
    #   width: 728,
    #   height: 90,
    #   placement: Types::Ad::Placement[:content],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:advrtr_240x400] => {
    #   provider: Types::Ad::Provider[:advertur],
    #   advertur_id: 92_129,
    #   width: 240,
    #   height: 400,
    #   placement: Types::Ad::Placement[:menu],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:advrtr_300x250] => {
    #   provider: Types::Ad::Provider[:advertur],
    #   advertur_id: 92_485,
    #   width: 300,
    #   height: 250,
    #   placement: Types::Ad::Placement[:menu],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:mt_300x250] => {
    #   provider: Types::Ad::Provider[:mytarget],
    #   mytarget_id: '239817',
    #   placement: Types::Ad::Placement[:menu],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:mt_240x400] => {
    #   provider: Types::Ad::Provider[:mytarget],
    #   mytarget_id: '239815',
    #   placement: Types::Ad::Placement[:menu],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:mt_300x600] => {
    #   provider: Types::Ad::Provider[:mytarget],
    #   mytarget_id: '239819',
    #   placement: Types::Ad::Placement[:menu],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:mt_728x90] => {
    #   provider: Types::Ad::Provider[:mytarget],
    #   mytarget_id: '239978',
    #   placement: Types::Ad::Placement[:content],
    #   platform: Types::Ad::Platform[:desktop]
    # },
    # Types::Ad::Type[:mt_footer_300x250] => {
    #   provider: Types::Ad::Provider[:mytarget],
    #   mytarget_id: '99457',
    #   placement: Types::Ad::Placement[:footer],
    #   platform: Types::Ad::Platform[:mobile]
    # }
  }

  META_TYPES = {
    # Types::Ad::Meta[:menu_300x250] => [
    #   # Types::Ad::Type[:mt_300x250],
    #   # Types::Ad::Type[:yd_240x400]
    #   # Types::Ad::Type[:advrtr_240x400]
    # ],
    Types::Ad::Meta[:menu_240x400] => [
      Types::Ad::Type[:special_x300], # ALABUGA - rmeove 2023-08-30 18:00
      # Types::Ad::Type[:mt_240x400],
      Types::Ad::Type[:yd_240x400]
      # Types::Ad::Type[:advrtr_240x400]
    ],
    Types::Ad::Meta[:menu_300x600] => [
      Types::Ad::Type[:special_x300], # ALABUGA - rmeove 2023-08-30 18:00
      # Types::Ad::Type[:mt_300x600],
      Types::Ad::Type[:yd_300x600]
      # Types::Ad::Type[:advrtr_240x400],
      # Types::Ad::Type[:advrtr_300x250]
    ],
    Types::Ad::Meta[:horizontal_x200] => [
      Types::Ad::Type[:yd_1170x200]
      # Types::Ad::Type[:advrtr_x728]
    ],
    Types::Ad::Meta[:horizontal_x90] => [
      Types::Ad::Type[:special_x894], # startgame.rsv.ru - remove 2023-08-23 23:59
      # Types::Ad::Type[:mt_728x90],
      # Types::Ad::Type[:advrtr_x728]
      Types::Ad::Type[:yd_970x90]
    ],
    Types::Ad::Meta[:footer] => [
      # Types::Ad::Type[:mt_footer_300x250]
    ],
    Types::Ad::Meta[:special_x1170] => [
      # Types::Ad::Type[:special_x1170] # PUBG - rmeove 2023-08-16 17:00
      # Types::Ad::Type[:yd_1170x200]
    ]
  }
end
