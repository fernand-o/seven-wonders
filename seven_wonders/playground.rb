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
  14 => { name: "East Trading Post", color: :yellow },
  15 => { name: "West Trading Post", color: :yellow },
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
  27 => { name: "Observatory", color: :green, cost: { looms: 2 } }
}

WONDERS = {
  1 => { name: "Olympia", resource: :wood },
  2 => { name: "Giza", resource: :stone },
  3 => { name: "Alexandria", resource: :clay }
}

class Card
  attr_reader :name, :color, :cost, :produces

  def initialize(card_id)
    card = CARDS[card_id]
    @name = card[:name]
    @color = card[:color]
    @cost = card[:cost] || {}
    @produces = card[:produces] || {}
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
      city_id = index + 1
      
      left_city_id = (index - 1) % shuffled_wonders.size
      right_city_id = (index + 1) % shuffled_wonders.size

      city = City.new(city_id, hash[:wonder_id], left_city_id, right_city_id)
      @cities << city

      @resources[city_id] = Hash.new(0)
      add_resource(city_id, city.wonder.initial_resource, 1)
    end
  end

  def add_resource(city_id, resource, amount)
    @resources[city_id][resource] += amount
  end
end

class City
  attr_reader :city_id, :wonder, :left_city_id, :right_city_id

  def initialize(id, wonder_id, left_city_id, right_city_id)
    @city_id = id
    @wonder = Wonder.new(wonder_id)

    @cards = []
    @left_city_id = left_city_id
    @right_city_id = right_city_id
  end

  def can_play?(card, match)
    coin_cost = 0

    card.cost.all? do |resource, amount_required|
      amount_available = match.resources[city_id][resource]
      next true if amount_available >= amount_required
      
      shortfall = amount_required - amount_available
      coin_cost += 2 * shortfall

      left_available = match.resources[left_city_id][resource]
      right_available = match.resources[right_city_id][resource]

      total_available_from_neighbors = left_available + right_available
      total_available_from_neighbors > shortfall
    end && match.resources[city_id][:coin] >= coin_cost
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

p match.cities.first.can_play?(cards[0], match) # true
p match.cities.first.can_play?(cards[1], match) # true
p match.cities.first.can_play?(cards[2], match) # true
p match.cities.first.can_play?(cards[18], match) # false # cost 1 ore
p match.cities.first.can_play?(cards[22], match) # true # cost 1 stone
