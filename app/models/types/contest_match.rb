module Types
  module ContestMatch
    State = Types::Strict::Symbol
      .constructor(&:to_sym)
      .enum(:created, :started, :freezed, :finished)
  end
end
