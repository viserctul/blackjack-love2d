--- Class for simulating deck of cards.
-- Loads assets needed to display cards and defines interactions.
-- @module cards

cards = {}

--- Table of cards in randomized order to draw from
local shuffled = {}

local suit = {'club', 'spade', 'heart', 'diamond'}
local face = {2,3,4,5,6,7,8,9,10,'J','Q','K','A'}
for i, f in ipairs(face) do
  for j, s in ipairs(suit) do
    local value
    if type(f) == 'number' then
      value = f
    elseif f == 'A' then
      value = 11
    else
      value = 10
    end
    cards[i*4 + j - 4] = {
      img = love.graphics.newImage("assets/cards/"..f..s..".png"),
      val = value
    }
  end
end
cards.reverse = love.graphics.newImage("assets/cards/reverse.png")

--- Reset and reshuffle cards
function cards.shuffle()
  shuffled = {}
  for _, v in ipairs(cards) do
      local pos = math.random(#shuffled+1)
      table.insert(shuffled, pos, v)
  end
end
cards.shuffle()

--- Get random card
-- @treturn card
function cards.getCard()
  return table.remove(shuffled)
end

return cards

