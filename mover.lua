--- Class for queuing cards moves
-- @module mover
mover = {}
local move = {}
local turn = {}

--- Create new move
-- @param obj Object to move
-- @param targetPos Target position to move
-- @param vel Movement velocity
-- @treturn move
function move.new(obj, targetPos, vel)
  local self = {}
  
  self.finished = false
  local tX, tY = targetPos[1], targetPos[2]

  --- Progress animation
  -- @function move.advance
  -- @param dt Time between frames
  function self.advance(dt)
    local distance = math.sqrt((tX - obj.x)^2 + (tY - obj.y)^2)
    if distance < vel * dt then
      obj.x = tX
      obj.y = tY
      self.finished = true
      return
    end

    local angle = math.atan2((tY - obj.y), (tX - obj.x))
    obj.x = obj.x + math.cos(angle) * dt * vel
    obj.y = obj.y + math.sin(angle) * dt * vel
  end

  return self
end

--- Create new turn
-- @param obj Object to turn
-- @param vel Turning speed
-- @treturn turn
function turn.new(obj, vel)
  local self = {}

  self.finished = false
  local angle = 0
  obj.turnScale = 1

  --- Progress animation
  -- @function turn.advance
  -- @param dt Time between frames
  function self.advance(dt)
    local angleNew = angle + dt * vel
    local scaleNew = math.cos(angleNew)
    
    if obj.turnScale * scaleNew < 0 then
      obj.hidden = not obj.hidden
    end
    if math.sin(angle) * math.sin(angleNew) < 0 then
      self.finished = true
      obj.turnScale = 1
      return
    end

    angle = angleNew
    obj.turnScale = scaleNew
  end

  return self
end

--- Create new mover
-- @param moveSpeed Movement velocity
-- @param turnSpeed Turning speed
-- @treturn mover
function mover.new(moveSpeed, turnSpeed)
  local self = {}

  --- Queue of tables of moves
  local Q = {}

  --- Add move to the queue
  -- @function mover.addMove
  -- @param obj Object to move
  -- @param targetPos Target position to move
  function self.addMove(obj, targetPos)
    local m = move.new(obj, targetPos, moveSpeed)
    Q[#Q].moves[obj] = m
  end

  --- Add turn to the queue
  -- @function mover.addTurn
  -- @param obj Object to turn
  function self.addTurn(obj)
    local f = turn.new(obj, turnSpeed)
    Q[#Q].turns[obj] = f
  end

  --- Enqueue moves
  -- @function mover.nq
  function self.nq()
    Q[#Q+1] = {moves={}, turns={}}
  end

  --- Reset the queue
  -- @function mover.reset
  function self.reset()
    Q = {{moves={}, turns={}}}
  end

  --- Are all moves done?
  -- @function mover.done
  -- @treturn boolean
  function self.done()
    return Q[2] == nil
      and next(Q[1].moves) == nil
      and next(Q[1].turns) == nil
  end

  --- Advance moves and remove completed moves from the queue
  -- @function mover.advance
  -- @param dt Time between frames
  function self.advance(dt)
    for _, ms in pairs(Q[1]) do
      for k, m in pairs(ms) do
        m.advance(dt)
        if m.finished then ms[k] = nil end
      end
    end

    if Q[2] ~= nil
      and next(Q[1].moves) == nil
      and next(Q[1].turns) == nil
    then
      table.remove(Q, 1)
    end
  end

  self.reset()
  return self
end

return mover

