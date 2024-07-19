require_relative "./playground"

class PlayingOptions
  def initialize(card_id, city, match)
    @card = Card.new(card_id)
    @city = city
    @match = match
  end

  def call
    [].then do |options|
      # options << sell_option

      chain_option = chaining_options
      if chain_option.any?
        options << chain_option
      else
        options << buying_options
      end

      options.reduce(&:merge)
    end
  end

  attr_reader :card, :match, :city

  def sell_option
    { sell_for_coins: 3 }
  end

  def chaining_options
    chainable_symbol = city.symbols.find { |symbol| symbol == card.chain_with }

    chainable_symbol ? { chain_with: chainable_symbol } : {}
  end

  def buying_options
    missing = missing_resources
    available_coins = match.resources[city.id][:coin]

    can_play_for_free = missing.empty?

    options = { play_for_free: can_play_for_free }

    return options if can_play_for_free 
    # todo: buy_from_leader

    raw_offers = offers_from_traders(missing)

    discount_cards = city.cards.select { |card| card.discount_options }.sort_by do |card| 
      card.discount_options[:priority] == :once ? -1 : 1
    end

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

    # p "MISSING RESOURCES"
    # p missing
    # p "RAW OFFERS"
    # p raw_offers
    # p "OFFERS WITH DISCOUNT"
    # p offers_with_discount
    # p "POSSIBILITIES"
    # p possibilities

    options.merge(buy_from: possibilities)
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
    match.resources.map do |id, resources|
      next unless [city.left_city.id, city.right_city.id].include?(id)

      { id: id, resources: resources }
    end.compact
  end

  def missing_resources
    card.cost.each_with_object({}) do |(resource, amount_required), hash|
      amount_available = match.resources[city.id][resource]
      shortfall = amount_required - amount_available
      hash[resource] = shortfall if shortfall > 0
    end
  end
end
