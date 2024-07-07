class TradingPost
  def self.discount(resource, city, trader_id, match)
    give_discount = basic_resource?(resource) && eligible_trader?(city, trader_id, match) 

    give_discount ? 1 : 0
  end

  def self.basic_resource?(resource)
    [:wood, :stone, :clay, :ore].include?(resource)
  end
end

class EastTradingPost < TradingPost
  def self.eligible_trader?(city, trader_id, match)
    trader_id == city.right_id
  end
end

class WestTradingPost < TradingPost
  def self.eligible_trader?(city, trader_id, match)
    trader_id == city.left_id
  end
end

CARDS = {
  1 => { name: "Lumber Yard", color: :brown, produces: { wood: 1 } },
  2 => { name: "Stone Pit", color: :brown, produces: { stone: 1 } },
  3 => { name: "Clay Pool", color: :brown, produces: { clay: 1 } },
  4 => { name: "Ore Vein", color: :brown, produces: { ore: 1 } },
  5 => { name: "Tree Farm", color: :brown, cost: { coin: 1 }, produces: { wood: 1, clay: 1 } },
  6 => { name: "Excavation", color: :brown, cost: { coin: 1 }, produces: { stone: 1, clay: 1 } },
  7 => { name: "Clay Pit", color: :brown, cost: { coin: 1 }, produces: { ore: 1, clay: 1 } },
  8 => { name: "Timber Yard", color: :brown, cost: { coin: 1 }, produces: { stone: 1, wood: 1 } },
  9 => { name: "Forest Cave", color: :brown, cost: { coin: 1 }, produces: { ore: 1, wood: 1 } },
  10 => { name: "Mine", color: :brown, cost: { coin: 1 }, produces: { ore: 1, stone: 1 } },
  11 => { name: "Glassworks", color: :grey, produces: { glass: 1 } },
  12 => { name: "Press", color: :grey, produces: { papyrus: 1 } },
  13 => { name: "Tavern", color: :yellow },
  14 => { name: "East Trading Post", color: :yellow, discount_options: { frequency: :always, class: EastTradingPost } },
  15 => { name: "West Trading Post", color: :yellow, discount_options: { frequency: :always, class: WestTradingPost } },
  16 => { name: "Marketplace", color: :yellow },
  17 => { name: "Stockade", color: :red, cost: { wood: 1 } },
  18 => { name: "Barracks", color: :red, cost: { ore: 1 } },
  19 => { name: "Guard Tower", color: :red, cost: { clay: 1 } },
  20 => { name: "Theater", color: :blue },
  21 => { name: "Altar", color: :blue },
  22 => { name: "Baths", color: :blue, cost: { stone: 1 } },
  23 => { name: "Pawnshop", color: :blue },
  24 => { name: "Workshop", color: :green, cost: { glass: 1 } },
  25 => { name: "Apothecary", color: :green, cost: { loom: 1 } },
  26 => { name: "Scriptorium", color: :green, cost: { papyrus: 1 } },
  27 => { name: "Observatory", color: :green, cost: { loom: 1 } },
  28 => { name: "TESTCARD", color: :red, cost: { wood: 3, stone: 1 } },
}

WONDERS = {
  1 => { name: "Olympia", resource: :glass },
  2 => { name: "Giza", resource: :loom },
  3 => { name: "Alexandria", resource: :clay }
}

class Card
  attr_reader :id, :name, :color, :cost, :produces, :discount_options

  def initialize(card_id)
    card = CARDS[card_id]
    @id = card_id
    @name = card[:name]
    @color = card[:color]
    @cost = card[:cost] || {}
    @produces = card[:produces] || {}
    @discount_options = card[:discount_options]
  end
end

class Wonder
  attr_reader :initial_resource

  def initialize(wonder_id)
    @initial_resource = WONDERS[wonder_id][:resource]
  end
end

class Match
  attr_reader :resources, :cities

  def initialize
    @resources = {}
    @cities = []
  end

  def start(players_and_wonders)
    shuffled_wonders = players_and_wonders.shuffle
    shuffled_wonders.each_with_index do |hash, index|
      left_id = (index - 1) % shuffled_wonders.size
      right_id = (index + 1) % shuffled_wonders.size

      city = City.new(index, hash[:wonder_id], left_id, right_id)
      @cities << city

      @resources[index] = Hash.new(0)
      add_resource(index, city.wonder.initial_resource, 1)
      add_resource(index, :coin, 5)
    end
  end

  def add_resource(id, resource, amount)
    @resources[id][resource] += amount
  end

  def playing_options(card, city_id)
    PlayingOptions.new(card, city_id, self).call
  end
end

class PlayingOptions
  def initialize(card, city, match)
    @card = card
    @city = city
    @match = match
  end

  def call
    [].tap do |options|
      options << sell_option

      chain_option = chaining_options
      if chain_option.any?
        options << chain_option
      else
        options << buying_options
      end

      options.map(&:merge)
    end
  end

  attr_reader :card, :match, :city

  def sell_option
    { sell_for_coins: 3 }
  end

  def chaining_options
    card.color == :green ? { chain_with: :observatory } : {}
  end

  def buying_options
    missing = missing_resources
    available_coins = match.resources[city.id][:coin]

    return { play_for_free: true } if missing.empty?
    # todo: buy_from_leader

    raw_offers = offers_from_traders(missing)

    # city_cards = city.cards
    city_cards = [
      Card.new(13), # tavern
      Card.new(14), # east trading post
      # Card.new(15), # west trading post
    ]
    
    discount_cards = city_cards.select { |card| card.discount_options }.sort_by do |card| 
      card.discount_options[:priority] == :once ? -1 : 1
    end

    p "DISCOUNT CARDS"
    p discount_cards

    offers_with_discount = raw_offers.map do |offer|
      new_offer = offer.dup
      discount_cards.each do |card|
        discount = card.discount_options[:class].discount(offer[:resource], city, offer[:trader_id], match)

        if discount > 0
          new_offer[:discounts] ||= []
          new_offer[:discounts] << { value: discount, card_id: card.id }
          new_offer[:final_cost] -= discount
        end
      end

      new_offer
    end

    possibilities = []
    offers_with_discount.count.times do |i|
      offers_with_discount.combination(i + 1).each do |combination|
        miss = missing.dup
        ignore_combination = false
        combination_cost = 0

        combination.each do |offer|
          if miss[offer[:resource]] > 0
            miss[offer[:resource]] -= 1
            combination_cost += offer[:final_cost]

            if combination_cost > available_coins
              ignore_combination = true
              break
            end
          else
            # if the resource is already fulfilled, ignore the combination
            ignore_combination = true
            break
          end
        end

        next if ignore_combination

        if miss.values.all? { |v| v <= 0 }
          possibilities << { combination: combination, total_cost: combination_cost }
        end
      end
    end

    p "MISSING RESOURCES"
    p missing
    p "RAW OFFERS"
    p raw_offers
    p "OFFERS WITH DISCOUNT"
    p offers_with_discount
    p "POSSIBILITIES"
    p possibilities

    { buy_from: possibilities }
  end

  # this will generate 1 offer for each available resource form each trader
  # so if a trader has 2 wood and 1 stone, it will generate 2 offers for wood and 1 offer for stone
  # (if if is a missing resource ofc)
  def offers_from_traders(missing)
    offers = []
    traders.each do |trader|
      trader[:resources].each do |resource, amount|
        if missing.keys.include?(resource)
          amount.times do
            offers << { trader_id: trader[:id], resource: resource, original_cost: 2, final_cost: 2 }
          end
        end
      end
    end
    offers
  end

  # traders by default would be the two direct neighbors
  # some expasions include a third neighbor as trader
  # and also leaders that can be traders
  def traders
    # (hardcoded for now)
    [
      {
        id: 0,
        resources: { wood: 2, glass: 1 },
      },
      {
        id: 2,
        resources: { wood: 2, glass: 1, stone: 1 }
      }
    ]
  end

  def missing_resources
    card.cost.each_with_object({}) do |(resource, amount_required), hash|
      amount_available = match.resources[city.id][resource]
      shortfall = amount_required - amount_available
      hash[resource] = shortfall if shortfall > 0
    end
  end
end

class City
  attr_reader :id, :wonder, :left_id, :right_id

  def initialize(id, wonder_id, left_id, right_id)
    @id = id

    @wonder = Wonder.new(wonder_id)
    @cards = []

    @left_id = left_id
    @right_id = right_id
  end
end

players = [
  { wonder_id: 1, player_id: 111 },
  { wonder_id: 2, player_id: 222 },
  { wonder_id: 3, player_id: 333 }
]

match = Match.new
match.start(players)

cards = CARDS.keys.map do |id|
  Card.new(id)
end

# p PlayingOptions.new(cards[0], match.cities.first, match).call
# p PlayingOptions.new(cards[24], match.cities.first, match).call
# p PlayingOptions.new(cards[22], match.cities.first, match).call
# p PlayingOptions.new(cards[17], match.cities.first, match).call



p PlayingOptions.new(cards[27], match.cities[1], match).call