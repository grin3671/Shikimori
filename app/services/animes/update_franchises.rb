class Animes::UpdateFranchises
  method_object

  def initialize
    @processed_ids = { Anime => [], Manga => [], Ranobe => [] }
    @franchises = []
  end

  def call scopes = [Anime, Manga]
    if scopes.first.respond_to? :find_each
      scopes.each { |scope| process scope }
    else
      process scopes
    end
  end

private

  def process scope
    scope.send(scope.respond_to?(:find_each) ? :find_each : :each) do |entry|
      next if @processed_ids[entry.class].include? entry.id

      chronology = Animes::ChronologyQuery.new(entry).fetch
      # ap chronology.map(&:id).join(', ')
      puts "anime_id: #{entry.id} chronology_size: #{chronology.size}" if Rails.env.development?

      if chronology.many?
        add_franchise chronology
      else
        remove_franchise entry
      end
    end
  end

  def add_franchise chronology_entries
    franchise = Animes::FranchiseName.call chronology_entries, @franchises

    chronology_entries.each do |entry|
      @processed_ids[entry.class] << entry.id
      next if entry.franchise == franchise

      if cant_rename? chronology_entries, entry.franchise
        raise "cant't rename `#{entry.franchise}` -> `#{franchise}` because found in NekoRepository"
      end

      puts "rename franchise: `#{entry.franchise}` -> `#{franchise}`" if Rails.env.development?
      entry.update franchise:
    end
  end

  def remove_franchise entry
    @processed_ids[entry.class] << entry.id
    entry.update franchise: nil
  end

  def cant_rename? entries, franchise
    entries.first.anime? &&
      NekoRepository.instance.find(franchise, 1) != Neko::Rule::NO_RULE &&
        no_animes_left_in_franchise?(entries, franchise)
  end

  def no_animes_left_in_franchise? entries, franchise
    Anime
      .where(franchise:)
      .where.not(id: entries.map(&:id))
      .none?
  end
end
