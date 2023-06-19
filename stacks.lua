--- Class for simulating hands of cards
-- @module stacks

stacks = {}

--- Create new stack of cards
-- @param pos Position of the new stack
-- @param deckPos Position of the deck of cards
-- @param cards Deck of cards to take cards from
-- @param mover Mover to use for moving the cards
-- @treturn stack New stack
function stacks.new(pos, deckPos, cards, mover)
  local self = {}

  --- Table of cards in current stack
  -- @table stacks.stack
  local stack = {}
  --- Table of cards in discarded stack.
  -- Needed in order to correctly render cards that are being discarded.
  -- @table stacks.discarded
  local discarded = {}

  local x, y = pos[1], pos[2]
  local dX, dY = deckPos[1], deckPos[2]

  --- Add a card to the stack of cards
  -- @function stacks.add
  -- @param card Card to add to the stack of cards
  -- @treturn card Card added to the stack of cards
  function self.add(card)
    stack[#stack+1] = card
    mover.addMove(card, {x+(#stack-1)*card.img:getWidth()/2, y})
  end

  --- Draw a card from the deck of cards
  -- @function stacks.take
  -- @param card If specified, take this card instead of a new one from the deck
  -- @treturn card Card added to the stack of cards
  function self.take(card)
    if card == nil then
      card = {}
      for k, v in pairs(cards.getCard()) do
        card[k] = v
      end
    end
    self.add(card)
    stack[#stack].x = dX
    stack[#stack].y = dY
    return stack[#stack]
  end

  --- Draw a card from the deck of cards in hidden position
  -- @function stacks.takeHidden
  -- @param card If specified, take this card instead of a new one from the deck
  -- @treturn card Card added to the stack of cards
  function self.takeHidden(card)
    local ret = self.take(card)
    stack[#stack].hidden = true
    return ret
  end

  --- Draw a card from the deck of cards in hidden position, then reveal
  -- @function stacks.takeHiddenReveal
  -- @param card If specified, take this card instead of a new one from the deck
  -- @treturn card Card added to the stack of cards
  function self.takeHiddenReveal(card)
    local ret = self.takeHidden(card)
    mover.nq()
    mover.addTurn(ret)
    return ret
  end

  --- Pop a crd from the stack of cards
  -- @function stacks.pop
  -- @treturn card Popped card
  function self.pop()
    return table.remove(stack)
  end

  --- Reveal all hidden cards in the stack
  -- @function stacks.reveal
  function self.reveal()
    for _, v in ipairs(stack) do
      if v.hidden then mover.addTurn(v) end
    end
  end

  --- Discard cards in the stack
  -- @function stacks.discard
  function self.discard()
    discarded = {}
    for k, v in ipairs(stack) do
      discarded[k] = v
      mover.addMove(v, {dX, dY})
    end
    stack = {}
  end

  --- Render all cards
  -- @function stacks.draw
  function self.draw()
    for _, vs in ipairs({stack,discarded}) do
      for _, v in ipairs(vs) do
        local img
        if v.hidden then img = cards.reverse else img = v.img end
        local scale = v.turnScale or 1
        scale = math.abs(scale)
        love.graphics.draw(img, v.x + (1-scale)*img:getWidth()/2, v.y, 0, scale, 1)
      end
    end
  end

  --- Compute hand value
  -- @function stacks.value
  -- @treturn int Hand value
  function self.value()
    local sum = 0
    local ace = 0
    for _, v in ipairs(stack) do
      if v.val == 11 then
        ace = ace + 1
      end
      sum = sum + v.val
    end

    while sum > 21 and ace > 0 do
      sum = sum - 10
      ace = ace - 1
    end
    return sum
  end

  --- Is blackjack?
  -- @function stacks.blackjack
  -- @treturn boolean
  function self.blackjack()
    return #stack == 2
      and stack[1].val == 11
      and stack[2].val == 10
  end

  return self
end

return stacks

