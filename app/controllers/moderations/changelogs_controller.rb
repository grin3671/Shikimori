class Moderations::ChangelogsController < ModerationsController
  MAX_LOG_LINES = 10_000
  PER_PAGE = 100

  TAIL_COMMAND = "tail -n #{MAX_LOG_LINES}"

  DEFAULT_INCLUDES = { topic: :forum }
  INCLUDES = {
    Comment => nil,
    Topic => %i[forum linked],
    ClubPage => %i[club],
    Critique => [:target, DEFAULT_INCLUDES],
    Review => [:anime, :manga, DEFAULT_INCLUDES]
  }

  before_action :check_access!

  def index
    og page_title: i18n_t('page_title')
    @collection = `ls #{Rails.root.join 'log'} | grep changelog`
      .strip
      .split("\n")
      .filter_map do |v|
        id = v.gsub(/changelog_|\.log/, '')
        _, _, name = item_type_name id

        {
          id:,
          name:
        }
      rescue ActiveRecord::RecordNotFound
      end
      .sort_by { |changelog| changelog[:name] }
  end

  def show # rubocop:disable all
    @item_klass, @item_type, @item_type_name = item_type_name params[:id]

    og page_title: @item_type_name

    breadcrumb i18n_t('page_title'), moderations_changelogs_url

    log_name = Shellwords.shellescape(params[:id]).gsub(/[^\w_]/, '')
    log_file = Rails.root.join "log/changelog_#{log_name}.log"

    raise ActiveRecord::RecordNotFound unless File.exist? log_file

    command =
      if params[:search].present?
        "grep \"#{safe_search}\" #{log_file} | #{TAIL_COMMAND}"
      else
        "#{TAIL_COMMAND} #{log_file}"
      end

    log_lines = `#{command}`.strip.each_line.map(&:strip).reverse

    @collection = QueryObjectBase
      .new(log_lines[PER_PAGE * (page - 1), PER_PAGE])
      .paginated_slice(page, PER_PAGE)
      .lazy_map do |log_entry|
        split = log_entry.split(/(?<=\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\]) /)

        changes = split[1]
          .gsub(/ ?:([a-z_]+)=>/, '"\1":')
          .gsub(/"([a-z_]+)"=>/, '"\1":')
          .gsub(/"action"::(\w+)/, '"action":"\1"')
          .gsub(/(\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2}\.\d{9} \w{3} \+\d{2}:\d{2})/, '"\1"')
          .gsub('[nil, ', '[null, ')
          .gsub(', nil]', ', null]')
          .gsub(/(?<=":)#<\w+(?<model>[\s\S]+)>(?=}\Z)/) do
            '{' +
              $LAST_MATCH_INFO[:model]
                .gsub(/ ([a-z_]+): /, '"\1":')
                .gsub(':nil', ':null') +
              '}'
          end

        details = JSON.parse(changes, symbolize_names: true)

        if details[:model].is_a? String
          details[:model] = JSON.parse(details[:model], symbolize_names: true)
        end

        {
          details:,
          raw: log_entry,
          date: Time.zone.parse(split[0].gsub(/[\[\]]/, '')),
          user_id: details[:user_id],
          model_id: details[:id],
          user: nil,
          model: nil,
          url: nil,
          is_tooltip_url: nil
        }
      end

    @users = User.where(id: @collection.pluck(:user_id)).index_by(&:id)
    unless @item_klass.is_a? Symbol
      @models = @item_klass
        .includes(
          INCLUDES.key?(@item_klass) ?
            INCLUDES[@item_klass] :
            DEFAULT_INCLUDES
        )
        .where(id: @collection.pluck(:model_id))
        .index_by(&:id)
    end

    @collection.each do |changelog|
      changelog[:user] = @users[changelog[:user_id]]
      changelog[:model] = @models[changelog[:model_id]] if @models

      changelog[:url] =
        if changelog[:model]
          model_url changelog[:model]
        elsif !changelog[:model] && changelog[:details][:url]
          changelog[:details][:url]
        end

      if changelog[:model] && changelog[:url]
        changelog[:tooltip_url] =
          tooltip_url changelog[:model]
      end
    end
  end

  def dangerous_actions# rubocop:disable all
    og page_title: 'Журнал опасных действий'

    log_file = Rails.root.join 'log/dangerous_action.log'

    raise ActiveRecord::RecordNotFound unless File.exist? log_file

    command =
      if params[:search].present?
        "grep \"#{safe_search}\" #{log_file} | #{TAIL_COMMAND}"
      else
        "#{TAIL_COMMAND} #{log_file}"
      end

    log_lines = `#{command}`.strip.each_line.map(&:strip).reverse

    @collection = QueryObjectBase
      .new(log_lines[PER_PAGE * (page - 1), PER_PAGE])
      .paginated_slice(page, PER_PAGE)
  end

private

  def check_access!
    authorize! :access_changelog, ApplicationRecord
  end

  def safe_search
    Shellwords
      .shellescape(params[:search])
      .gsub(/\\(=|>)/, '\1')
  end

  def model_url model
    case model
      when Comment then comment_url model
      when ClubPage then club_club_page_path model.club, model
      when Topic then UrlGenerator.instance.topic_url model
      else UrlGenerator.instance.topic_url model.topic
    end
  rescue NoMethodError, ActionController::UrlGenerationError # fix for broken urls in some comes
  end

  def tooltip_url model
    case model
      when Comment then comment_url model
      when ClubPage then nil
      when Topic then topic_tooltip_url model
      else topic_tooltip_url model.topic
    end
  rescue NoMethodError, ActionController::UrlGenerationError # fix for broken urls in some comes
  end

  def item_type_name id # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    is_mass_bans = id == 'mass_bans'
    item_klass = is_mass_bans ?
      id.to_sym :
      id.classify.constantize

    raise ActiveRecord::RecordNotFound if item_klass == Message && !can?(:manage, Message)
    raise ActiveRecord::RecordNotFound if item_klass == :mass_ban && !can?(:mass_ban, User)

    [
      item_klass,
      (id.classify unless is_mass_bans),
      is_mass_bans ?
        'Массовые баны' :
        item_klass.model_name.human(count: '')
    ]
  rescue NameError
    raise ActiveRecord::RecordNotFound
  end
end
