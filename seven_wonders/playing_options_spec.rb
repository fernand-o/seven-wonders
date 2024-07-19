require "rspec"
require_relative "./playground"
require_relative "./playing_options"

RSpec.describe PlayingOptions do
  subject(:options) { PlayingOptions.new(card_id, city, match).call }

  let(:wonders_and_players) do
    {
      giza: 111,
      olympia: 222,
      halicarnassus: 333,
      rhodos: 444
    }
  end
  let(:match) do 
    Match.new
  end

  before do
    match.start(wonders_and_players)
  end

  context "when the card costs one single resource" do
    context "when the city's wonder has the resource" do
      let(:city) { match.cities[3] } # rhodos
      let(:card_id) { :barracks }

      it "can be played for free" do
        expect(options).to eq({
          play_for_free: true 
        })
      end
    end

    context "when the resource is not available anywhere" do
      let(:city) { match.cities[0] } # giza
      let(:card_id) { :scriptorium }

      it "cant be played" do
        expect(options).to eq({ 
          play_for_free: false,
          buy_from: []
        })
      end
    end

    context "when the city has the resource" do
      let(:city) { match.cities[1] } # olympia
      let(:card_id) { :baths } # costs 1 stone

      before do
        match.play_card(city.id, :stone_pit)
      end

      it "can be played for free" do
        expect(options).to eq({
          play_for_free: true
        })
      end
    end

    context "when a neighbor has the resource" do
      let(:city) { match.cities[1] } # halicarnassus
      let(:card_id) { :baths } # costs 1 stone

      it "can buy from neighbor" do
        expect(options).to eq({
          play_for_free: false,
          buy_from: [
            {
              combination: [
                {
                  final_cost: 2,
                  original_cost: 2,
                  resource: :stone,
                  trader_id: 0 # giza
                }
              ],
              total_cost: 2
            }
          ]
        })
      end
    
      context "when player has a discount card" do
        before do
          match.play_card(city.id, :west_trading_post)
        end

        it "can buy with discount" do
          expect(options).to eq({
            play_for_free: false,
            buy_from: [
              {
                combination: [
                  {
                    discounts: [
                      {
                        card_id: :west_trading_post,
                        value: 1
                      }
                    ],
                    final_cost: 1,
                    original_cost: 2,
                    resource: :stone,
                    trader_id: 0
                  }
                ],
                total_cost: 1
              }
            ]
          })
        end
      end
    end
  end
end
