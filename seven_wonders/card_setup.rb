module SevenWonders
  class CardSetup
    def initialize(player_count: 7, age: :first, expansions: [])
      @player_count = player_count
      @age = age
      @expansions = expansions
    end

    def cards
      base_game_cards + expansions_cards
    end

    private

    attr_reader :player_count, :age, :expansions

    def base_game_cards
      BaseGame.new(player_count, age).cards
    end

    def expansions_cards
      expansions.map do |expansion|
        EXPANSIONS[expansion].new(player_count, age).cards
      end.flatten
    end
  end

  class Deck
    def initialize(player_count, age)
      @player_count = player_count
      @age = age
    end

    protected

    attr_reader :player_count, :age
  end

  class BaseGame < Deck
    CARDS_PER_AGE_AND_PLAYER_COUNT = {
      first: {
        3 => 1..21,
        4 => 1..28,
        5 => 1..35,
        6 => 1..42,
        7 => 1..49
      },
      second: {
        3 => 50..70,
        4 => 50..77,
        5 => 50..84,
        6 => 50..91,
        7 => 50..98
      },
      third: {
        3 => 99..114,
        4 => 99..120,
        5 => 99..126,
        6 => 99..132,
        7 => 99..138
      }
    }

    PURPLE_CARDS = 141..151

    def cards
      CARDS_PER_AGE_AND_PLAYER_COUNT[age][player_count].to_a + purple_cards
    end

    private

    def purple_cards
      age == :third ? PURPLE_CARDS.to_a.sample(player_count + 2) : []
    end
  end

  class CitiesExpansion < Deck
    CARDS_PER_AGE = {
      first: 152..166,
      second: 167..181,
      third: 182..196
    }

    def cards
      CARDS_PER_AGE[age].to_a.sample(player_count)
    end
  end

  EXPANSIONS = {
    cities: CitiesExpansion
  }
end