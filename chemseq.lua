-- CHEMSEQ

local helpers = require("chemseq/lib/helpers")

engine.name = "PolyPerc"

local state = {particles = {}}

local function math_particle()
    local ops = {"+", "-", "/", "*"}
    return {op = helpers.rand_from_arr(ops)}
end

local function value_particle()
    return {val = helpers.rand_int(0, 127)}
end

local function empty_particle() return {} end

local constructors = {
    math = math_particle,
    note = empty_particle,
    listener = empty_particle,
    value = value_particle
}

function rand_id()
  return math.random(1, 100000)
end

local pw = 4

local function rand_particle(type)
    local types = {"listener",
                    "note",
                    "value",
                    "math"}
    local position = {x = helpers.rand_int(0, 128), y = helpers.rand_int(0, 64)}
    local dir = {x = helpers.rand_int(-1, 1), y = helpers.rand_int(-1, 1)}
    local type = type or helpers.rand_from_arr(types)
    local base = {
        type = type,
        pos = position,
        dir = dir,
        id = rand_id(),
        w = pw,
        h = pw
    }
    local details = constructors[type]()

    return helpers.shallow_merge(base, details) 
end

function init()
    for i=1,10 do
        table.insert(state.particles, rand_particle())
    end
  engine.amp(0.5)
  counter = metro.init()
  counter.time = 0.1
  counter.count = -1
  counter.event = update
  counter:start()
end

function is_pair_of(p1, p2, t1, t2)
  return (p1.type == t1 and p2.type == t2) or (p1.type == t2 and p2.type == t1)
end

function first_type(p1, p2, t)
  if(p1.type == t) then
    return p1, p2
  else
    return p2, p1
  end
end

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function play_note(val)
  engine.hz(midi_to_hz(val))
end

function listener_note_coll(p1, p2)
  local l, n = first_type(p1, p2, "listener")
  if(n.val) then
    play_note(n.val)
    return nil, true
  else
    return nil, false
  end
end

function note_value_coll(p1, p2)
  local n,v = first_type(p1, p2, "note")
  return helpers.shallow_merge(n, {val = v.val}), true
end

function add(v1,v2) 
  return v1 + v2 
end
function sub(v1,v2) 
  return v1 - v2 
end
function div(v1,v2) 
  return v1 / v2 
end
function mult(v1,v2) 
  return v1 * v2 
end

local op_fn = {["+"] = add, ["-"] = sub,  ["/"] = div, ["*"] = mult}
function math_value_coll(p1, p2)
    local m,v = first_type(p1, p2, "math")
    if(m.val1) then
      local fn = op_fn[m.op]
      local value = fn(m.val1, v.val)
      return helpers.shallow_merge(v, {val = value}), true
    else
        return helpers.shallow_merge(m, {val1 = v.val}), true
    end
end

-- listener particles - when trigger wave touches them emit a note
-- note particles - when touch value particle emite wave with that note
-- value particle - interact with note particle and math particle
-- math particle - consume two values and return new one
function on_collision(p1, p2)
  if(is_pair_of(p1, p2, "listener", "note")) then
    return listener_note_coll(p1, p2)
  elseif(is_pair_of(p1, p2, "note", "value")) then
    return note_value_coll(p1, p2)
  elseif(is_pair_of(p1, p2, "math", "value")) then
    return math_value_coll(p1, p2)
  end
  return nil, false
end

function is_colliding(p1, p2)
  if p1.id == p2.id then return false end
  local pos1 = p1.pos
  local pos2 = p2.pos
  return pos1.x < pos1.x + p2.w and
        pos1.x + p1.w > pos2.x and
        pos1.y < pos2.y + p2.h and
        p1.h + pos1.y > pos2.y
end

function remove_collided(collided)
  local new_particles = {}
  for i=1,#state.particles do
    if not collided[i] then
      table.insert(new_particles, state.particles[i])
    end
  end
  state.particles = new_particles
end

function check_collisions()
  local collisions_indexes = {}

  for i=1,#state.particles - 1 do
    local collided = false
    for j=i+1,#state.particles do
      local p1 = state.particles[i]
      local p2 = state.particles[j]
      if is_colliding(p1, p2) then
        local new_particle, remove_old = on_collision(p1, p2)
        if remove_old then
          collisions_indexes[i] = true
          collisions_indexes[j] = true
        end
      end
    end
  end
  
  return collisions_indexes
end

function update_positions()
  for i=1,#state.particles do
    local particle = state.particles[i]
    local pos = particle.pos
    local dir = particle.dir
        
    if pos.x < 0 then
      dir.x = 1
    elseif pos.x > 128 then
      dir.x = -1
    end

    if pos.y < 0 then
      dir.y = 1
    elseif pos.y > 64 then
      dir.y = -1
    end
        
    pos.x = pos.x + dir.x
    pos.y = pos.y + dir.y
  end
end

function update()
  update_positions()
  local collided = check_collisions()
  remove_collided(collided)
  redraw()
end

function redraw()
  screen.clear()
  screen.level(10)
  for i=1,#state.particles do
    local particle = state.particles[i]
    local pos = particle.pos
    local x = pos.x - 2
    local y = pos.y - 2
    if(particle.type == "math") then
      screen.circle(x, y, 4)
    elseif(particle.type == "value") then
      screen.rect(x, y, 2, 4)
    elseif(particle.type == "listener") then
      screen.arc(x, y, 4, 0.1, 3)
    elseif(particle.type == "note") then
      screen.rect(x, y, 4, 2)
    end
    screen.stroke()
  end
  screen.update()
end

function key(n,z)
  redraw()
end

function enc(n,d)
  redraw()
end