require 'rspec'
require_relative './card_setup'

RSpec.describe "A 7 wonders game" do
  subject(:cards) { SevenWonders::CardSetup.new(player_count: players, age: age, expansions: expansions).cards }

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

  context "with cities expansion" do
    let(:expansions) { [:cities] }

    context "with 7 players" do
      let(:players) { 7 }

      context 'in first age' do
        let(:age) { :first }

        it { expect(cards.size).to eq 56 }
        it { expect((152..166).to_a).to include(*cards[49..]) }
      end

      context 'in second age' do
        let(:age) { :second }

        it { expect(cards.size).to eq 56 }
        it { expect((167..181).to_a).to include(*cards[49..]) }
      end

      context 'in third age' do
        let(:age) { :third }

        it { expect(cards.size).to eq 56 }
        it { expect((182..196).to_a).to include(*cards[49..]) }
      end
    end
  end
end