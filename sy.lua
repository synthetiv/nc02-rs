-- ??? (nc02-rs)
-- @synthetivv

sc = softcut

dirty = false
next_head = 1

echo_rates = { 1/12, 1/8, 1/6, 1/4, 1/3, 1/2 }

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
bd = { o = 3.465250, l = 0.45, r = 1, v = 1,   d = 0.98, e = 0.1, cs = 0.7, cr = 0 }
ch = { o = 1.496604, l = 0.5,  r = 1, v = 0.7, d = 0.7,  e = 0.2, cs = 0.7, cr = 0 }
oh = { o = 1.496604, l = 0.5,  r = 1, v = 0.7, d = 1,    e = 0.5, cs = 0.7, cr = 0 }
hc = { o = 0,        l = 0.5,  r = 1, v = 1,   d = 1,    e = 0.6, cs = 0.7, cr = 0 }
sd = { o = 0.999646, l = 0.5,  r = 1, v = 1,   d = 0.98, e = 0.7, cs = 0.7, cr = 0 }
n1 = { o = 13.5,     l = 16,   r = 1, v = 0.4, d = 1,    e = 0.2, cs = 0,   cr = 1 }
n2 = { o = 11,       l = 16,   r = 2, v = 0.4, d = 1,    e = 0.1, cs = 0,   cr = 1 }

sidechain_level = 0
sidechain_amount = 0.7
sidechain_factor = 0.2

Voice = {}
Voice.__index = Voice
function Voice.new(buffer)
  local v = setmetatable({}, Voice)
  local head = next_head
  next_head = head + 1

  sc.enable(head, 1)
  sc.buffer(head, buffer)
  sc.level(head, 1.0)
  sc.loop(head, 0)
  sc.loop_start(head, 1)
  sc.loop_end(head, 2)
  sc.position(head, 0)
  sc.fade_time(head, 0.0025)
  sc.level_slew_time(head, 0.01)
  sc.rate(head, 1.0)
  sc.play(head, 1)
  sc.level_slew_time(head, 0.02)

  v.head = head

  return v
end

EchoVoice = {}
EchoVoice.__index = EchoVoice

function EchoVoice.new()
  local v = setmetatable(Voice.new(2), EchoVoice)
  local head = v.head
  local rate = 1/6
  local decay = 0.8

  sc.loop_start(head, 1)
  sc.loop_end(head, 1.0625)
  sc.loop(head, 1)
  sc.position(head, 1)
  sc.rate(head, rate)
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
  sc.post_filter_fc(head, 100)
  sc.post_filter_rq(head, 1)
  sc.rate_slew_time(head, 0.3)

  v.rate = rate
  v.decay = decay

  return v
end

function EchoVoice:update_rate()
  local deviation = (math.random() - 0.5) * 0.05
  sc.rate(echo.head, echo.rate * math.pow(2, deviation))
end

function EchoVoice:update_level()
  sc.pre_level(self.head, self.decay * (1 - sidechain_level))
  sc.level(self.head, 1.6 * (1 - sidechain_level))
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
  return v
end

function PercVoice:update_level()
  local instrument = self.instrument
  self.decay_level = self.decay_level * instrument.d
  local level = instrument.v * self.decay_level * (1 - sidechain_level * instrument.cr)
  sc.level(self.head, level)
  sc.level_cut_cut(self.head, echo.head, self.send * level)
  sidechain_level = math.min(1, sidechain_level + level * instrument.cs)
end

function PercVoice:flash_decay()
  if self.flash_level > 0 then
    self.flash_level = math.floor(self.flash_level * 0.6)
    dirty = true
  end
end

function PercVoice:play(instrument)
  local head = self.head
  local start = instrument.o
  local length = clock.get_beat_sec(instrument.l * instrument.r)
  local send = 0
  if math.random() <= instrument.e then
    send = 1
  end

  sc.rate(head, instrument.r)
  sc.loop_start(head, instrument.o)
  sc.loop_end(head, start + length)
  sc.position(head, start)
  sc.level(head, instrument.v)
  sc.level_cut_cut(head, echo.head, send * instrument.v)
  sc.play(head, 1)

  self.instrument = instrument
  self.send = send
  self.decay_level = 1
  self.flash_level = 16
end

function PercVoice:next_tick()
  local tick = self.tick
  tick = tick + 1
  local step_index = self.step_index
  local step = self.pattern[step_index]
  if tick > (step._l or step.l) then
    tick = 1
    step_index = step_index % #self.pattern + 1
    step = self.pattern[step_index]
    local shift = self.shift
    local _l = step.l
    if math.random() <= step.r then
      _l = _l - shift
      shift = 0
    end
    if math.random() <= step.s then
      if math.random(0, 1) == 1 then
        _l = _l + 1
        shift = shift + 1
      else
        _l = _l - 1
        shift = shift - 1
      end
    end
    self.shift = shift
    step._l = _l
    if math.random() <= step.p then
      self:play(step.i)
    end
    self.step_index = step_index
  end
  self.tick = tick
end

echo = EchoVoice.new()

drums = {}
for d = 1, 3 do
  drums[d] = PercVoice.new()
end

drums[1].pattern = {
  { p = 1,    i = bd, l = 4, s = 0.25, r = 0.7 },
  { p = 0.33, i = bd, l = 2, s = 0.25, r = 0.5 },
  { p = 0.05, i = hc, l = 2, s = 0.25, r = 0.5 },
  { p = 1,    i = bd, l = 4, s = 0.25, r = 0.7 },
  { p = 0.1,  i = hc, l = 4, s = 0.25, r = 0.5 }
}

drums[2].pattern = {
  { p = 0.2,  i = ch, l = 2, s = 0,    r = 1 },
  { p = 0.8,  i = ch, l = 2, s = 0,    r = 1 },
  { p = 0.2,  i = oh, l = 2, s = 0,    r = 1 },
  { p = 0.8,  i = ch, l = 2, s = 0,    r = 1 }
}

--[[
drums[3].pattern = {
  { p = 1,    i = n2, l = 16, s = 0,   r = 0.25 },
  { p = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 },
  { p = 0.2,  i = n2, l = 8,  s = 0,   r = 0.25 },
  { p = 0.7,  i = n2, l = 16, s = 0,   r = 0.25 },
  { p = 1,    i = n2, l = 8,  s = 0,   r = 0.25 },
  { p = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 },
  { p = 0.2,  i = n1, l = 8,  s = 0.1, r = 0.25 }
}
--]]
drums[3].pattern = {
  { p = 0.3,  i = n2, l = 4, s = 0,   r = 0.25 },
  { p = 0.1,  i = sd, l = 2, s = 0,   r = 1 },
  { p = 0.3,  i = n1, l = 6, s = 0,   r = 0.25 },
  { p = 0.1,  i = sd, l = 2, s = 0,   r = 1 },
  { p = 0.3,  i = n1, l = 6, s = 0,   r = 0.25 }
}
--[[
drums[3].pattern = {
  { p = 0.7,  i = n2, l = 1,   s = 0,   r = 0.25 },
  { p = 0.1,  i = sd, l = 0.5, s = 0,   r = 1 },
  { p = 0.5,  i = n1, l = 0.5, s = 0,   r = 0.25 }
}
--]]

envelope_metro = metro.init()
envelope_metro.time = 0.01
envelope_metro.event = function()
  sidechain_level = sidechain_level * sidechain_factor
  for d = 1, 3 do
    drums[d]:update_level()
  end
  echo:update_level()
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
  echo:update_rate()
end

function load_file(filename, buffer, buffer_start)
  local path = _path.code .. 'nc02-rs/lib/' .. filename
  sc.buffer_read_mono(path, 0, buffer_start, -1, 1, buffer) -- -1 = read whole file, I guess?
end

function init()
  load_file('nc02-perc.wav', 1, 0)
  load_file('nc02-tonal.wav', 1, 10)
  params:set('clock_tempo', 120)

  clock.run(function()
    while true do
      clock.sync(0.25) -- 16th notes
      for d = 1, 3 do
        drums[d]:next_tick()
      end
    end
  end)

  clock.run(function()
    while true do
      clock.sync(2)
      if math.random() <= 0.3 then
        echo.rate = echo_rates[math.random(1, 6)]
      end
    end
  end)

  envelope_metro:start()
  redraw_metro:start()
  flutter_metro:start()
end

function enc(n, d)
end

function redraw()
  screen.clear()
  for d = 1, 3 do
    local drum = drums[d]
    local x = 26 + (d - 1) * 32
    screen.level(drum.flash_level)
    screen.rect(x, 27, 10, 10)
    screen.fill()
    for e = 1, 4 do
      screen.level(math.floor(drum.send * drum.flash_level / (e + 1)))
      screen.move(x, 37 + e * 3)
      screen.line_rel(10, 0)
      screen.stroke()
      screen.move(x, 28 - e * 3)
      screen.line_rel(10, 0)
      screen.stroke()
    end
  end
  screen.update()
end

function cleanup()
  redraw_metro:stop()
  envelope_metro:stop()
  flutter_metro:stop()
end
