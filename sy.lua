-- ??? (nc02-rs)
-- @synthetivv
--
-- we can bring to birth
-- a new world from the
-- ashes of the old

sc = softcut

dirty = false
next_head = 1

regularity = 0

echo_rates = { 1/48, 1/32, 1/24, 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2 }

step_px = 4
history_length = math.ceil(64 / step_px)

sway_length = 172
sway = {}
for y = 1, sway_length do
  sway[y] = math.sin(2 * math.pi * y / sway_length)
end
sway_offset = 0

wind_direction = 0
wind_direction_smooth = 0

global_ticks = 0

--[[
onsets = { -- generated by `aubioonset -t 0.66 -O energy nc02-perc.wav`
  0.000000, 0.427479, 0.495688, 0.999646, 1.496604,
  1.993625, 2.499792, 2.996063, 3.089292, 3.191354,
  3.465250, 4.338583, 4.519729, 4.594812, 4.680313,
  4.745062, 4.915563, 4.995354, 5.134729, 5.343125,
  5.981979, 6.270688, 6.463500, 6.521500, 6.780729,
  7.289479, 7.353229, 7.497542, 7.615104, 7.698021,
  7.857584, 7.950875, 8.077105, 8.157979, 8.261771,
  8.419791, 8.547334, 8.718875,
  10, 11, 12, 13
}
--]]

-- instruments
bd =  { o = 3.465250, l = 0.225, p = 0,    r = 0.37, v = 1,    d = 0.97, e = 0.1, cs = 0.7, cr = false, x = 62 }
--bd =  { o = 3.465250, l = 0.225, p = 0,    r = 0.415, v = 1,    d = 0.97, e = 0.1, cs = 0.7, cr = false, x = 62 }
bdh = { o = 3.465250, l = 0.225, p = 0,    r = 0.44,  v = 1,    d = 0.97, e = 0.1, cs = 0.7, cr = false, x = 70 }
ch =  { o = 1.496604, l = 0.25,  p = -0.2, r = 0.5,   v = 0.45, d = 0.7,  e = 0.2, cs = 0.7, cr = false, x = 56 }
oh =  { o = 1.496604, l = 0.25,  p = -0.2, r = 0.5,   v = 0.5,  d = 1,    e = 0.5, cs = 0.7, cr = false, x = 48 }
hc =  { o = 0,        l = 0.25,  p = 0.3,  r = 0.5,   v = 0.7,  d = 1,    e = 0.6, cs = 0.7, cr = false, x = 78 }
sd =  { o = 0.999646, l = 0.25,  p = 0.2,  r = 0.5,   v = 0.7,  d = 0.98, e = 0.7, cs = 0.7, cr = false, x = 32 }
n1 =  { o = 13.5,     l = 11,    p = -0.1, r = 0.5,   v = 0.2,  d = 1,    e = 0.2, cs = 0,   cr = true,  x = 40 }
n2 =  { o = 11,       l = 11,    p = 0.1,  r = 1,     v = 0.2,  d = 1,    e = 0.1, cs = 0,   cr = true,  x = 86 }
z1 =  { o = 23,       l = 5,     p = 0.4,  r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 94 }
z2 =  { o = 24,       l = 4,     p = 0.4,  r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 94 }
z3 =  { o = 25,       l = 3,     p = 0.4,  r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 94 }
z4 =  { o = 26,       l = 2,     p = 0.4,  r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 94 }
z5 =  { o = 27,       l = 1,     p = 0.4,  r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 94 }
za =  { o = 28.25,    l = 4,     p = -0.4, r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 24 }
zb =  { o = 29.25,    l = 3,     p = -0.4, r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 24 }
zc =  { o = 30.25,    l = 2,     p = -0.4, r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 24 }
zd =  { o = 31.25,    l = 1,     p = -0.4, r = 0.25,  v = 0.7,  d = 1,    e = 0.3, cs = 0,   cr = true,  x = 24 }

sidechain_input = 0
sidechain_input_smooth = 0
sidechain_release = 0.04
sidechain_level = 1
sidechain_depth = 1.2

Voice = {}
Voice.__index = Voice
function Voice.new(buffer)
  local v = setmetatable({}, Voice)
  local head = next_head
  next_head = head + 1

  sc.enable(head, 1)
  sc.buffer(head, buffer)
  sc.pan(head, 0)
  sc.level(head, 1.0)
  sc.loop(head, 0)
  sc.loop_start(head, 1)
  sc.loop_end(head, 2)
  sc.position(head, 0)
  sc.fade_time(head, 0.0025)
  sc.pan_slew_time(head, 0.0001)
  sc.level_slew_time(head, 0.01)
  sc.rate(head, 0.5 / clock.get_beat_sec())
  sc.play(head, 1)
  sc.level_slew_time(head, 0.02)

  for h = 1, 6 do
    sc.level_cut_cut(head, h, 0)
  end

  v.head = head

  return v
end

EchoVoice = {}
EchoVoice.__index = EchoVoice

function EchoVoice.new()
  local v = setmetatable(Voice.new(2), EchoVoice)
  local head = v.head
  local pan = 0
  local rate_setting = 5
  local rate = echo_rates[rate_setting]
  local decay = 0.8

  sc.loop_start(head, head)
  sc.loop_end(head, head + 0.0625)
  sc.loop(head, 1)
  sc.position(head, 1)
  sc.rate(head, rate / clock.get_beat_sec())
  sc.level(head, 1)
  sc.rec_level(head, 1)
  sc.pre_level(head, decay)
  sc.rec(head, 1)
  sc.play(head, 1)
  sc.pre_filter_dry(head, 0)
  sc.pre_filter_lp(head, 1)
  sc.pre_filter_fc(head, 10000)
  sc.pre_filter_rq(head, 1)
  sc.post_filter_dry(head, 0)
  sc.post_filter_hp(head, 1)
  sc.post_filter_fc(head, 200)
  sc.post_filter_rq(head, 1)
  sc.rate_slew_time(head, 0.3)
  sc.pan_slew_time(head, 0.3)

  v.pan = pan
  v.rate_setting = rate_setting
  v.rate = rate
  v.decay = decay

  return v
end

function EchoVoice:move(d)
  self.pan = math.max(-1, math.min(1, math.atan(self.pan + d)))
  sc.pan(self.head, self.pan)
end

function EchoVoice:update_rate()
  local deviation = (math.random() - 0.5) * 0.05
  sc.rate(self.head, self.rate * math.pow(2, deviation) / clock.get_beat_sec())
  self:move(wind_direction * 0.01 + math.random() * 0.25 - 0.125)
end

function EchoVoice:update_level()
  sc.pre_level(self.head, self.decay * sidechain_level)
  sc.level(self.head, 1 * sidechain_level)
end

PercVoice = {}
PercVoice.__index = PercVoice

function PercVoice.new()
  local v = setmetatable(Voice.new(1), PercVoice)
  v.tick = 0
  v.step_index = 1
  v.shift = 0
  v.send = 0
  v.flash_level = 0
  v.decay_level = 0
  v.instrument = n1

  -- initialize history
  local history = {}
  for h = 1, history_length do
    history[h] = {
      _l = history_length + 1, -- make this fake "step" long enough that we'll never see it drawn
      _t = false,
      _e = 0,
      i = bd
    }
  end
  v.history = history
  v.history_index = 1

  return v
end

function PercVoice:update_level()
  local beat_sec = clock.get_beat_sec()
  local instrument = self.instrument
  self.decay_level = self.decay_level * instrument.d
  local level = instrument.v * self.decay_level
  if instrument.cr then
    level = level * sidechain_level
  end
  sc.level(self.head, level)
  for e = 1, 2 do
    sc.level_cut_cut(self.head, echoes[e].head, (self.step._e == e and level or 0))
  end
  sidechain_input = sidechain_input + level * instrument.cs
end

function PercVoice:flash_decay()
  if self.flash_level > 0 then
    self.flash_level = math.floor(self.flash_level * 0.6)
    dirty = true
  end
end

function PercVoice:play()
  local step = self.step
  local instrument = step.i
  local head = self.head
  local start = instrument.o
  local length = instrument.l

  sc.rate(head, instrument.r / clock.get_beat_sec())
  sc.loop_start(head, instrument.o)
  sc.loop_end(head, start + length)
  sc.position(head, start)
  sc.level(head, instrument.v)
  sc.pan(head, instrument.p)
  sc.play(head, 1)
  for e = 1, 2 do
    sc.level_cut_cut(head, echoes[e].head, (step._e == e and instrument.v or 0))
  end

  self.instrument = instrument
  self.send = send
  self.decay_level = 1
  self.flash_level = 16
end

function PercVoice:next_step()
  local shift = self.shift
  local step_index = self.step_index % #self.pattern + 1
  local step = self.pattern[step_index]

  -- calculate step length
  local _l = step.l
  if math.random() < math.min(1, step.r + regularity) then
    local reset_shift = math.min(_l - 1, shift)
    _l = _l - reset_shift
    shift = shift - reset_shift
  end
  if math.random() < math.min(1, step.s - regularity) then
    if math.random(0, 1) == 1 then
      _l = _l + 1
      shift = shift + 1
    elseif _l > 1 then
      _l = _l - 1
      shift = shift - 1
    end
  end

  -- calculate trigger probability
  local _t = math.random() < step.t

  -- calculate echo send probability
  local _e = 0
  if math.random() < math.min(1, step.i.e - regularity / 2) then
    _e = math.random(1, 2)
  end

  self.shift = shift
  step._l = _l
  step._t = _t
  step._e = _e
  self.step = step
  self.step_index = step_index

  local history_index = self.history_index % history_length + 1
  local memory = self.history[history_index]
  memory.i = step.i
  memory._l = _l
  memory._t = _t
  memory._e = _e
  self.history_index = history_index

  if _t then
    self:play()
  end
end

function PercVoice:next_tick()
  local tick = self.tick
  local step_index = self.step_index
  local step = self.pattern[step_index]
  tick = tick + 1
  if tick > step._l then
    tick = 1
    self:next_step()
  end
  self.tick = tick
end

function PercVoice:set_pattern(pattern)
  self.pattern = pattern
  local step_index = #pattern
  local step = pattern[step_index]
  step._l = step.l
  self.tick = step.l
  self.step = step
  self.step_index = step_index
end

echoes = {}
for e = 1, 2 do
  echoes[e] = EchoVoice.new()
end

drums = {}
for d = 1, 3 do
  drums[d] = PercVoice.new()
end

drums[1]:set_pattern{
  { t = 1,    i = bd, l = 4, s = 0.25, r = 0.7 },
  { t = 0.33, i = bdh, l = 2, s = 0.25, r = 0.5 },
  { t = 0.05, i = hc, l = 2, s = 0.25, r = 0.5 },
  { t = 1,    i = bd, l = 4, s = 0.25, r = 0.7 },
  { t = 0.1,  i = hc, l = 4, s = 0.25, r = 0.5 }
}

drums[2]:set_pattern{
  { t = 0.2,  i = ch, l = 2, s = 0,    r = 1 },
  { t = 0.8,  i = ch, l = 2, s = 0,    r = 1 },
  { t = 0.2,  i = oh, l = 2, s = 0,    r = 1 },
  { t = 0.8,  i = ch, l = 2, s = 0,    r = 1 }
}

--[[
drums[3]:set_pattern{
  { t = 1,    i = n2, l = 16, s = 0,   r = 0.25 },
  { t = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 },
  { t = 0.2,  i = n2, l = 8,  s = 0,   r = 0.25 },
  { t = 0.7,  i = n2, l = 16, s = 0,   r = 0.25 },
  { t = 1,    i = n2, l = 8,  s = 0,   r = 0.25 },
  { t = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 },
  { t = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 }
}
drums[3]:set_pattern{
  { t = 0.7,  i = n2, l = 1,   s = 0,   r = 0.25 },
  { t = 0.1,  i = sd, l = 0.5, s = 0,   r = 1 },
  { t = 0.5,  i = n1, l = 0.5, s = 0,   r = 0.25 }
}
drums[3]:set_pattern{
  { t = 0.3,  i = n2, l = 4, s = 0,   r = 0.25 },
  { t = 0.1,  i = sd, l = 2, s = 0,   r = 1 },
  { t = 0.3,  i = n1, l = 6, s = 0,   r = 0.25 },
  { t = 0.1,  i = sd, l = 2, s = 0,   r = 1 },
  { t = 0.3,  i = n1, l = 6, s = 0,   r = 0.25 }
}
drums[3]:set_pattern{
  { t = 0.2, i = z1, l = 8, s = 0, r = 1 },
  { t = 0.2, i = za, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z2, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zb, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z3, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zc, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z4, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zd, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z5, l = 16, s = 0, r = 1 },
}
--]]
drums[3]:set_pattern{
  { t = 0.2, i = z1, l = 4, s = 0, r = 1 },
  { t = 0.3, i = n2, l = 4, s = 0, r = 1 },
  { t = 0.2, i = za, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z2, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zb, l = 4, s = 0, r = 1 },
  { t = 0.3, i = n1, l = 4, s = 0, r = 1 },
  { t = 0.2, i = z3, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zc, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z4, l = 8, s = 0, r = 1 },
  { t = 0.2, i = zd, l = 8, s = 0, r = 1 },
  { t = 0.2, i = z5, l = 4, s = 0, r = 1 },
  { t = 0.3,  i = n1, l = 4, s = 0,   r = 0.25 },
  { t = 0.3,  i = n2, l = 3, s = 0,   r = 0.25 },
  { t = 0.1,  i = sd, l = 2, s = 0,   r = 1 }
}

envelope_metro = metro.init()
envelope_metro.time = 0.005
envelope_metro.event = function()
  sidechain_input = 0
  for d = 1, 3 do
    drums[d]:update_level()
  end
  for e = 1, 2 do
    echoes[e]:update_level()
  end
  if sidechain_input > sidechain_input_smooth then
    sidechain_input_smooth = sidechain_input
  else
    sidechain_input_smooth = sidechain_input_smooth + (sidechain_input - sidechain_input_smooth) * sidechain_release
  end
  sidechain_level = math.max(0, 1 - sidechain_input_smooth * sidechain_depth)
  envelope_metro.time = 0.0025 / clock.get_beat_sec()
end

redraw_metro = metro.init()
redraw_metro.time = 1/15
redraw_metro.event = function()
  for d = 1, 3 do
    drums[d]:flash_decay()
  end
  if dirty then
    redraw()
  end
end

flutter_metro = metro.init()
flutter_metro.time = 0.3
flutter_metro.event = function()
  for e = 1, 2 do
    echoes[e]:update_rate()
  end
end

function load_file(filename, buffer, buffer_start)
  local path = _path.code .. 'nc02-rs/lib/' .. filename
  sc.buffer_read_mono(path, 0, buffer_start, -1, 1, buffer) -- -1 = read whole file
end

function init()
  load_file('nc02-perc.wav', 1, 0)
  load_file('nc02-tonal.wav', 1, 10)
  load_file('synthetivv.wav', 1, 23)
  params:set('reverb', 0)
  params:set('compressor', 0)
  -- params:set('clock_tempo', 120)

  params:add{
    id = 'regularity',
    name = 'regularity',
    type = 'control',
    controlspec = controlspec.new(-1, 1, 'lin', 0.05, 0),
    action = function(value)
      regularity = value
    end
  }

  clock.run(function()
    while true do
      clock.sync(0.25) -- 16th notes
      for d = 1, 3 do
        drums[d]:next_tick()
        dirty = true
      end
      global_ticks = global_ticks + 1
    end
  end)

  clock.run(function()
    while true do
      clock.sync(2)
      if math.random() < 0.3 then
        for e = 1, 2 do
          local echo = echoes[e]
          local jump = (math.random() - 0.5) * 2 * (2 - regularity)
          echo.rate_setting = math.max(1, math.min(#echo_rates, math.floor(echo.rate_setting + jump + 0.5)))
          echo.rate = echo_rates[echo.rate_setting]
          echo:move(math.random() - 0.5)
        end
        wind_direction = math.random() * 2 - 1
        local stillness = math.atan(2 - math.abs(wind_direction * 2)) * 0.37
        sc.level_cut_cut(echoes[1].head, echoes[2].head, stillness)
        sc.level_cut_cut(echoes[2].head, echoes[1].head, stillness)
      end
    end
  end)

  global_ticks = math.floor(clock.get_beats() * 4)

  envelope_metro:start()
  redraw_metro:start()
  flutter_metro:start()
end

function enc(n, d)
  if n == 1 then
    params:delta('output_level', d)
  elseif n == 2 then
    params:delta('clock_tempo', d)
    global_ticks = math.floor(clock.get_beats() * 4)
  elseif n == 3 then
    params:delta('regularity', d)
  end
end

function get_sway(y, offset_fine, offset_coarse)
  local amount = math.max(0, 65 - y)
  local index = math.floor(y + offset_fine * 11 + offset_coarse * 37 + sway_offset + 0.5)
  local value = sway[index % sway_length + 1]
  return math.floor(amount * (value / 3 + wind_direction_smooth) + 0.5)
end

function redraw()
  screen.clear()
  local beats = clock.get_beats()
  sway_offset = (beats * 2) % sway_length
  wind_direction_smooth = wind_direction_smooth + (wind_direction - wind_direction_smooth) * 0.03
  local fractional_tick = clock.get_beats() * 4 - global_ticks
  for d = 1, 3 do
    local drum = drums[d]
    local y = 64
    for s = 1, history_length do
      local history_index = (drum.history_index - s) % history_length + 1
      local step = drum.history[history_index]
      local x = step.i.x
      local _l = step._l
      if s == 1 then
        y = math.floor(y - (drum.tick + fractional_tick - 0.5) * step_px + 0.5)
      else
        y = y - _l * step_px
      end
      if step._t then
        local level = math.ceil(y / 11)
        if s == 1 then
          screen.level(math.min(16, level + drum.flash_level))
        end
        screen.level(level)
        screen.rect(x + get_sway(y, history_index, d), y, 3, 3)
        screen.fill()
        if step._e > 0 then
          local echo_y = y + step_px + 1
          while level > 1 do
            level = level - 1
            screen.level(level)
            screen.move(x + get_sway(echo_y - step_px + 1, history_index, d), echo_y)
            screen.line_rel(3, 0)
            screen.stroke()
            echo_y = echo_y + 2
          end
        end
      else
        screen.level(1)
        screen.rect(x + 1 + get_sway(y, history_index, d), y + 1, 1, 1)
        screen.fill()
      end
    end
  end
  screen.update()
end

function cleanup()
  redraw_metro:stop()
  envelope_metro:stop()
  flutter_metro:stop()
end
