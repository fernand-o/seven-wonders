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
    trader_id == city.right_city.id
  end
end

class WestTradingPost < TradingPost
  def self.eligible_trader?(city, trader_id, match)
    trader_id == city.left_city.id
  end
end

CARDS = {
  lumber_yard: { name: "Lumber Yard", color: :brown, produces: { wood: 1 } },
  stone_pit: { name: "Stone Pit", color: :brown, produces: { stone: 1 } },
  clay_pool: { name: "Clay Pool", color: :brown, produces: { clay: 1 } },
  ore_vein: { name: "Ore Vein", color: :brown, produces: { ore: 1 } },
  tree_farm: { name: "Tree Farm", color: :brown, cost: { coin: 1 }, produces: { wood: 1, clay: 1 } },
  excavation: { name: "Excavation", color: :brown, cost: { coin: 1 }, produces: { stone: 1, clay: 1 } },
  clay_pit: { name: "Clay Pit", color: :brown, cost: { coin: 1 }, produces: { ore: 1, clay: 1 } },
  timber_yard: { name: "Timber Yard", color: :brown, cost: { coin: 1 }, produces: { stone: 1, wood: 1 } },
  forest_cave: { name: "Forest Cave", color: :brown, cost: { coin: 1 }, produces: { ore: 1, wood: 1 } },
  mine: { name: "Mine", color: :brown, cost: { coin: 1 }, produces: { ore: 1, stone: 1 } },
  glassworks: { name: "Glassworks", color: :grey, produces: { glass: 1 } },
  press: { name: "Press", color: :grey, produces: { papyrus: 1 } },
  tavern: { name: "Tavern", color: :yellow },
  east_trading_post: { name: "East Trading Post", color: :yellow, discount_options: { frequency: :always, class: EastTradingPost } },
  west_trading_post: { name: "West Trading Post", color: :yellow, discount_options: { frequency: :always, class: WestTradingPost } },
  marketplace: { name: "Marketplace", color: :yellow },
  stockade: { name: "Stockade", color: :red, cost: { wood: 1 } },
  barracks: { name: "Barracks", color: :red, cost: { ore: 1 } },
  guard_tower: { name: "Guard Tower", color: :red, cost: { clay: 1 } },
  theater: { name: "Theater", color: :blue },
  altar: { name: "Altar", color: :blue },
  baths: { name: "Baths", color: :blue, cost: { stone: 1 } },
  pawnshop: { name: "Pawnshop", color: :blue },
  workshop: { name: "Workshop", color: :green, cost: { glass: 1 } },
  apothecary: { name: "Apothecary", color: :green, cost: { loom: 1 } },
  scriptorium: { name: "Scriptorium", color: :green, cost: { papyrus: 1 } },
  observatory: { name: "Observatory", color: :green, cost: { loom: 1 } },
  testcard: { name: "TESTCARD", color: :red, cost: { wood: 3, stone: 1 } }
}

WONDERS = {
  giza: { name: "Giza", resource: :stone },
  babylon: { name: "Babylon", resource: :clay },
  olympia: { name: "Olympia", resource: :wood },
  rhodos: { name: "Rhodos", resource: :ore },
  ephesos: { name: "Ephesos", resource: :papyrus },
  halicarnassus: { name: "Halicarnassus", resource: :loom },
  alexandria: { name: "Alexandria", resource: :glass }
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

  def start(wonders_and_players_ids)
    player_count = wonders_and_players_ids.keys.size
    player_count.times do |index|
      wonder_id = wonders_and_players_ids.keys[index]
      left_id = (index - 1) % player_count
      right_id = (index + 1) % player_count

      add_city(index, wonder_id, left_id, right_id)
    end
  end

  def play_card(city_id, card_id)
    card = Card.new(card_id)
    city = @cities[city_id]
    city.add_card(card)

    card.produces.each do |resource, amount|
      add_resource(city_id, resource, amount)
    end
  end

  def add_resource(id, resource, amount)
    @resources[id][resource] += amount
  end

  def playing_options(card, city_id)
    PlayingOptions.new(card, city_id, self).call
  end

  private 

  def add_city(id, wonder_id, left_id, right_id)
    city = City.new(id, wonder_id, left_id, right_id, self)
    @cities << city

    @resources[id] = Hash.new(0)
    add_resource(id, city.wonder.initial_resource, 1)
    add_resource(id, :coin, 5)
  end
end

class City
  attr_reader :id, :wonder, :cards, :symbols

  def initialize(id, wonder_id, left_id, right_id, match)
    @id = id

    @wonder = Wonder.new(wonder_id)
    @cards = []
    @symbols = []
    @match = match

    @left_id = left_id
    @right_id = right_id
  end

  def add_card(card)
    @cards << card
  end

  def left_city
    @match.cities[@left_id]
  end

  def right_city
    @match.cities[@right_id]
  end
end

# players = [
#   { wonder_id: :giza, player_id: 111 },
#   { wonder_id: :olympia, player_id: 222 },
#   { wonder_id: :halicarnassus, player_id: 333 }
# ]

# match = Match.new
# match.start(players)

# cards = CARDS.keys.map do |id|
#   Card.new(id)
# end

# p PlayingOptions.new(cards[0], match.cities.first, match).call
# p PlayingOptions.new(cards[24], match.cities.first, match).call
# p PlayingOptions.new(cards[22], match.cities.first, match).call
# p PlayingOptions.new(cards[17], match.cities.first, match).call



# p PlayingOptions.new(cards[27], match.cities[1], match).call