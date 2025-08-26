local component = require("component")
local gpu = component.gpu
local screen = component.list("screen")()
local computer = require("computer")

gpu.bind(screen)
gpu.setResolution(80, 25)

local COLOR_TEXT = 0xFFFFFF
local COLOR_TRACK = 0x0055AA
local COLOR_TRAIN = 0xFFFF00
local COLOR_OBSTACLE = 0xFF3300
local BG_COLOR = 0x99b6ff

local positions = {7, 13, 19}

local function initGame()
  local trainY = positions[2]
  local score = 0
  local obstacles = {}
  local spawnTimer = 0
  return trainY, score, obstacles, spawnTimer
end

local function spawnObstacle(obstacles)
  table.insert(obstacles, {
    x = 80,
    y = positions[math.random(1, #positions)],
    offset = 0
  })
end

local function draw(trainY, score, obstacles)
  gpu.setBackground(BG_COLOR)
  gpu.fill(1, 1, 80, 25, " ")
  gpu.setForeground(COLOR_TRACK)
  for _, y in ipairs(positions) do
    gpu.set(1, y, string.rep("═", 80))
  end
  gpu.setForeground(COLOR_TRAIN)
  gpu.set(5, trainY, "🚂")
  gpu.setForeground(COLOR_OBSTACLE)
  for _, obs in ipairs(obstacles) do
    local xPos = math.floor(obs.x + obs.offset)
    if xPos >= 1 and xPos <= 80 then
      gpu.set(xPos, obs.y, "▓")
    end
  end
  gpu.setForeground(COLOR_TEXT)
  gpu.set(1, 1, "Score: " .. tostring(score))
end

local function moveTrain(trainY, up)
  for i, y in ipairs(positions) do
    if y == trainY then
      if up and i > 1 then
        trainY = positions[i - 1]
      elseif not up and i < #positions then
        trainY = positions[i + 1]
      end
      break
    end
  end
  return trainY
end

local function checkCollision(trainY, obstacles)
  for _, obs in ipairs(obstacles) do
    local xPos = math.floor(obs.x + obs.offset)
    if xPos == 5 and obs.y == trainY then
      return true
    end
  end
  return false
end

local function cleanupObstacles(obstacles, score)
  local remaining = {}
  for _, obs in ipairs(obstacles) do
    if obs.x + obs.offset > 0 then
      table.insert(remaining, obs)
    else
      score = score + 1
    end
  end
  return remaining, score
end

while true do
  local trainY, score, obstacles, spawnTimer = initGame()
  local gameOver = false

  while not gameOver do
    draw(trainY, score, obstacles)
    local signal = {computer.pullSignal(0.03)}
    if signal[1] == "key_down" then
      local key = signal[4]
      if key == 200 then
        trainY = moveTrain(trainY, true)
      elseif key == 208 then
        trainY = moveTrain(trainY, false)
      end
    end

    for _, obs in ipairs(obstacles) do
      obs.offset = obs.offset - 0.5
      if obs.offset <= -1 then
        obs.x = obs.x - 1
        obs.offset = 0
      end
    end

    spawnTimer = spawnTimer + 1
    if spawnTimer >= 15 then
      spawnObstacle(obstacles)
      spawnTimer = 0
    end

    if checkCollision(trainY, obstacles) then
      computer.beep(100, 0.3)
      gameOver = true
    end

    obstacles, score = cleanupObstacles(obstacles, score)
  end

  gpu.setBackground(BG_COLOR)
  gpu.fill(1, 1, 80, 25, " ")
  gpu.setForeground(0xFF0000)
  gpu.set(30, 11, "💥 CRASH! 💥")
  gpu.setForeground(0xFFFFFF)
  gpu.set(30, 13, "Score: " .. tostring(score))
  gpu.set(20, 15, "Press R to Restart or Q to Quit")

  while true do
    local signal = {computer.pullSignal()}
    if signal[1] == "key_down" then
      local key = signal[4]
      if key == 19 then -- R
        break
      elseif key == 16 then -- Q
        gpu.setBackground(0x000000)
        gpu.fill(1,1,80,25," ")
        return
      end
    end
  end
end
