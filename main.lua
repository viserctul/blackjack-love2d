--- Main love2D project file.
-- Implements game-loop pattern.
-- @module main

math.randomseed(os.time())

--- Initial setup function
-- @param args Cli arguments passed to game
function love.load(args)
  local args_set = {}
  for k, v in ipairs(args) do
    args_set[v] = true
  end
  testing = args_set["--test"] or args_set["-t"]

  loveframes = require 'loveframes'
  mover = require 'mover'
  cards = require 'cards'
  stacks = require 'stacks'

  music = love.audio.newSource('assets/music.ogg', 'static')

  love.graphics.setBackgroundColor(0.2, 0.6, 0)
  loveframes.SetActiveSkin('Orange')
  local font = love.graphics.newFont(22)
  loveframes.GetActiveSkin().controls.text_default_font = font
  loveframes.GetActiveSkin().controls.button_text_font = font

  local x = 140
  local dY, pY = 48, 391
  deckPosX, deckPosY = x+16, (dY+pY)/2
  dealerPos = {x, dY}
  playerPos = {x, pY}
  playerSecPos = {x, pY + 65}
  deckPos = {deckPosX, deckPosY}

  mover = mover.new(1200, 12)
  dealer = stacks.new(dealerPos, deckPos, cards, mover)
  player = stacks.new(playerPos, deckPos, cards, mover)
  playerSec = stacks.new(playerSecPos, deckPos, cards, mover)

  local font = love.graphics.newFont(48)
  local playerHandValue = {}
  local tmp

  tmp = loveframes.Create('text')
  tmp:SetFont(font)
  tmp:SetPos(x - 64, dY + 20)
  local dealerHandValue = tmp

  tmp = loveframes.Create('text')
  tmp:SetFont(font)
  tmp:SetPos(x - 64, pY + 20)
  playerHandValue[1] = tmp

  tmp = loveframes.Create('text')
  tmp:SetFont(font)
  tmp:SetPos(x - 64, pY + 85)
  playerHandValue[2] = tmp

  --- Game state
  -- @field current Function to execute after an action
  -- @field continue Did an action happen?
  -- @field money Player funds and score
  -- @field bets Table describing the state of players bets
  -- @field insurance Has player bet on insurance?
  -- @field buttons Table of handles for buttons
  -- @field active Table of handles of buttons that should be active
  st = {
    current,
    continue = true,
    money = 1000,
    bets = {},
    insurance = false,
    buttons = {
      deal,
      hit,
      stand,
      doubleDown,
      split,
      surrender,
      insurance
    },
    active = {}
  }

  local btn = st.buttons
  function st.btnfun(object, x, y)
    st.continue = true
    st.clicked = object
    for _, v in pairs(btn) do
      v:SetClickable(false)
    end
  end
  local x, y = 320, 200

  tmp = loveframes.Create('text')
  tmp:SetFont(love.graphics.newFont(40))
  tmp:SetPos(x, y-50)
  local scoreValue = tmp

  tmp = loveframes.Create('numberbox')
  tmp:SetIncreaseAmount(100)
  tmp:SetDecreaseAmount(100)
  tmp:SetMinMax(100, 1000)
  tmp:SetSize(100, 40)
  tmp:SetPos(x, y)
  local betAmount = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(100, 40)
  tmp:SetPos(x+100, y)
  tmp:SetText("Deal")
  st.buttons.deal = tmp

  tmp = loveframes.Create('text')
  tmp:SetFont(love.graphics.newFont(30))
  tmp:SetVisible(false)
  tmp:SetPos(x+230, y)
  tmp:SetText("Insured")
  local insuredText = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x, y+40)
  tmp:SetText("Hit")
  st.buttons.hit = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x, y+80)
  tmp:SetText("Stand")
  st.buttons.stand = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x, y+120)
  tmp:SetText("Double Down")
  st.buttons.doubleDown = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x+200, y+40)
  tmp:SetText("Surrender")
  st.buttons.surrender = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x+200, y+80)
  tmp:SetText("Split")
  st.buttons.split = tmp

  tmp = loveframes.Create('button')
  tmp.OnClick = st.btnfun
  tmp:SetClickable(false)
  tmp:SetSize(200, 40)
  tmp:SetPos(x+200, y+120)
  tmp:SetText("Insurance")
  st.buttons.insurance = tmp

  --- End round and prepare to make a new bet
  function st.bet()
    if st.insurance then
      if dealer.blackjack() then
        st.money = st.money + betAmount:GetValue()
      else
        st.money = st.money - betAmount:GetValue()/2
      end
    end
    scoreValue:SetText({"Money: ", st.money})

    betAmount:SetIncreaseAmount(100)
    betAmount:SetDecreaseAmount(100)
    st.active = {btn.deal}
    st.current = st.start
  end

  --- Deal cards and activate buttons for possible actions
  function st.start()
    st.bets = {{
      val = betAmount:GetValue(),
      done = false
    }}
    st.insurance = false
    betAmount:SetIncreaseAmount(0)
    betAmount:SetDecreaseAmount(0)
    insuredText:SetVisible(false)

    dealer.discard()
    player.discard()
    playerSec.discard()
    mover.nq()

    cards.shuffle()
    local p1 = player.takeHiddenReveal()
    local d1 = dealer.takeHiddenReveal()
    dealerHandValue:SetText(dealer.value())
    local p2 = player.takeHiddenReveal()
    dealer.takeHidden()

    playerHandValue[1]:SetText({{color = {0.8,0.8,0}}, player.value()})
    playerHandValue[2]:SetText()

    st.active = {
      btn.hit,
      btn.stand,
      btn.doubleDown,
      btn.surrender
    }
    if p1.val == p2.val then
      table.insert(st.active, btn.split)
    end
    if d1.val == 11 then
      table.insert(st.active, btn.insurance)
    end
    st.current = st.initialTurn
  end

  --- Handle insurance, split and surrender, else execute st.turn
  -- @see st.turn
  function st.initialTurn()
    if st.clicked == btn.insurance then
      st.insurance = true
      insuredText:SetVisible(true)
    elseif st.clicked == btn.split then
      playerSec.add(player.pop())
      st.bets[2] = {}
      for k, v in pairs(st.bets[1]) do
        st.bets[2][k] = v
      end
      playerHandValue[2]:SetText(playerSec.value())
    elseif st.clicked == btn.surrender then
      st.money = st.money - betAmount:GetValue()/2
      st.bet()
      return
    else
      st.turn()
      return
    end

    for k, v in pairs(st.active) do
      if v == st.clicked then
        st.active[k] = nil
      end
    end
    playerHandValue[1]:SetText({{color = {0.8,0.8,0}}, player.value()})
    st.currrent = st.initialTurn
  end

  --- Handle all standard actions, until game concludes
  function st.turn()
    local stack, bet, handValue
    if not st.bets[1].done then
      stack = player
      bet = st.bets[1]
      handValue = playerHandValue[1]
    else
      stack = playerSec
      bet = st.bets[2]
      handValue = playerHandValue[2]
    end

    if st.clicked == btn.hit then
      stack.takeHiddenReveal()
    elseif st.clicked == btn.stand then
      bet.done = true
    elseif st.clicked == btn.doubleDown then
      stack.takeHiddenReveal()
      bet.val = bet.val*2
      bet.done = true
    end

    if stack.value() > 21 then
      handValue:SetText({{color = {0.8,0,0}}, stack.value()})
      bet.done = true
    elseif bet.done then
      handValue:SetText(stack.value())
    else
      handValue:SetText({{color = {0.8,0.8,0}}, stack.value()})
    end
    if st.bets[1].done and st.bets[2] ~= nil and not st.bets[2].done then
      playerHandValue[2]:SetText({{color = {0.8,0.8,0}}, playerSec.value()})
    end

    if st.bets[1].done and (st.bets[2]==nil or st.bets[2].done) then
      mover.nq()
      dealer.reveal()
      mover.nq()
      while dealer.value() < 17 do
        dealer.takeHiddenReveal()
      end
      local dv = dealer.value()
      if dv > 21 then
        dealerHandValue:SetText({{color = {0.8,0,0}}, dv})
      else
        dealerHandValue:SetText(dv)
      end

      local hands = {player, playerSec}
      for i, b in ipairs(st.bets) do
        local pv = hands[i].value()
        local pbj, dbj = hands[i].blackjack(), dealer.blackjack()
        local hv = playerHandValue[i]

        local function won()
          st.money = st.money + b.val
          hv:SetText({{color = {0,1,0}}, hv:GetText()})
        end
        local function lost()
          st.money = st.money - b.val
          hv:SetText({{color = {0.8,0,0}}, hv:GetText()})
        end
        if pbj and not dbj then
          b.val = b.val*1.5
          won()
        elseif not pbj and dbj then
          lost()
        elseif not pbj and not dbj then
          if pv <= 21 and dv > 21 then
            won()
          elseif pv > 21 and dv <= 21 then
            lost()
          elseif pv <= 21 and dv <=21 then
            if pv > dv then
              won()
            elseif pv < dv then
              lost()
            end
          end
        end
      end

      st.bet()
      return
    end

    st.active = {
      btn.hit,
      btn.stand,
      btn.doubleDown
    }
    st.current = st.turn
  end

  st.current = st.bet
end

--- Rendering function
function love.draw()
  loveframes.draw()

  dealer.draw()
  player.draw()
  playerSec.draw()
  love.graphics.draw(cards.reverse, deckPosX, deckPosY)
end

--- Update function
-- @param dt Time between frames
function love.update(dt)
  loveframes.update(dt)

  if mover.done() and st.continue then
    st.continue = false

    if testing then
      local keyset = {}
      for k in pairs(st.active) do
        table.insert(keyset, k)
      end
      st.btnfun(st.active[keyset[math.random(#keyset)]])
    end

    st.current()
    for k, v in pairs(st.active) do
      v:SetClickable(true)
    end
  end
  mover.advance(dt)

  if not music:isPlaying() and not testing then
     love.audio.play(music)
  end
end

function love.mousepressed(x, y, button)
  loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  loveframes.mousereleased(x, y, button)
end

