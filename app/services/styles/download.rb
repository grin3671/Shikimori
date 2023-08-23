class Styles::Download
  method_object :url

  EXPIRES_IN = 8.hours

  CACHE_VERSION = :v1
  CACHE_KEY = "style_%<url>s_#{CACHE_VERSION}"

  ALLOWED_EXCEPTIONS = Network::FaradayGet::NET_ERRORS

  def call
    content = download_with_cache

    if content.blank?
      NamedLogger.failed_styles_download.info @url
    end

    content
  end

private

  def download_with_cache
    Rails.cache.fetch format(CACHE_KEY, url: @url), url: @url, expires_in: EXPIRES_IN do
      Retryable.retryable tries: 2, on: ALLOWED_EXCEPTIONS, sleep: 1 do
        do_download
      end
    end
  rescue StandardError
    ''
  end

  def do_download
    NamedLogger.download_style.info "#{@url} start"
    response = Network::FaradayGet.call(@url)
    content = response&.body&.force_encoding('utf-8') || ''
    NamedLogger.download_style.info "#{@url} end"

    if response.status == 200 && content.valid_encoding?
      content
    else
      ''
    end
  end
end
