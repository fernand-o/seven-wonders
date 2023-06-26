require "rspec"

RSpec.describe "A 7 wonders game" do
  subject(:cards) { SevenWonders::CardSetup.new(players: players, age: age, expansions: expansions).cards }

  let(:expansions) { [] }

  context "with base game only" do
    context "with 7 players" do
      let(:players) { 7 }

      context 'in first age' do
        let(:age) { :first }

        it { expect(cards.size).to eq 49 }
        it { expect(cards).to eq (1..49).to_a }
      end

      context 'in second age' do
        let(:age) { :second }

        it { expect(cards.size).to eq 49 }
        it { expect(cards).to eq (50..98).to_a }
      end

      context 'in third age' do
        let(:age) { :third }
        let(:normal_cards) { cards - (141..151).to_a }
        let(:purple_cards) { cards & (141..151).to_a }

        it { expect(cards.size).to eq 49 }
        it { expect(normal_cards).to eq (99..138).to_a }
        it { expect(purple_cards.size).to eq 9 }
        it { expect((141..151).to_a).to include(*purple_cards) }
      end
    end
  end
end

module SevenWonders
  class CardSetup
    def initialize(players: 7, age: :first, expansions: [])
      @players = players
      @age = age
      @expansions = expansions
    end

    def cards
      BaseGame.new(players, age).cards
    end

    private

    attr_reader :players, :age, :expansions
  end

  class Deck
    def initialize(players, age)
      @players = players
      @age = age
    end

    def cards
      base_cards + extra_cards
    end

    protected

    attr_reader :players, :age

    def base_cards
      self.class::CARDS_PER_AGE_AND_PLAYER_COUNT[age][players].to_a
    end
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

    def extra_cards
      age == :third ? PURPLE_CARDS.to_a.sample(players + 2) : []
    end
  end
end


