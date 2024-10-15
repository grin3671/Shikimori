# no embed videos urls here. video page must contain html so extractor could
# could extract video data from og meta tags
class VideoExtractor::OpenGraphExtractor < VideoExtractor::BaseExtractor
  # Video.hosting should include these hostings
  # shiki_video should include these hostings too

  URL_REGEX = %r{
    https?://(?:www\.)?(
      (?<hosting>coub).com/view/[\wА-я_-]+#{PARAMS} |
      video.(?<hosting>sibnet).ru/(video[\wА-я_-]+|shell.php\?videoid=[\wА-я_-]+)#{PARAMS}
    )
  }mix
  # (?<hosting>streamable).com/[\wА-я_-]+#{PARAMS} |
  # video.(?<hosting>youmite).ru/embed/[\wА-я_-]+#{PARAMS} |
  # (?<hosting>viuly).io/video/[\wА-я_.-]+#{PARAMS} |
  # (?<hosting>mediafile).online/video/[\wА-я_-]+/[\wА-я_-]+/

  # twitch no long supports og video tags
  # (?:\w+\.)?(?<hosting>twitch).tv(/[\wА-я_-]+/[\wА-я_-]+|/videos)/
    # [\wА-я_-]+#{PARAMS} |

  IMAGE_PROPERTIES = %w[
    meta[property='og:image']
  ]

  VIDEO_PROPERTIES_BY_HOSTING = {
    # viuly: %w[meta[property='og:video:iframe']],
  }

  VIDEO_PROPERTIES = %w[
    meta[name='twitter:player']
    meta[property='og:video:iframe']
    meta[property='og:video']
    meta[property='og:video:url']
  ]

private

  def extract_image_url data
    Url.new(data.first).without_protocol.to_s if data.first
  end

  def extract_player_url data
    Url.new(data.second).without_protocol.to_s if data.second
  end

  def extract_hosting url
    url.match(self.class::URL_REGEX) && $LAST_MATCH_INFO[:hosting].to_sym
  end

  def parse_data content, url
    doc = Nokogiri::HTML content

    og_image = doc.css(IMAGE_PROPERTIES.join(',')).first
    og_video = (
      self.class::VIDEO_PROPERTIES_BY_HOSTING[extract_hosting(url)] ||
        self.class::VIDEO_PROPERTIES
    )
      .map { |v| doc.css(v).first }
      .find(&:present?)

    if og_image && og_video
      [
        og_image[:content],
        og_video[:content] || og_video[:value]
      ]
    end
  end
end
