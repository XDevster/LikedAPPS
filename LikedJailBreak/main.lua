local component = require("component")
local gpu = component.gpu
local fs = component.filesystem
local os = require("os")

local MESSAGE = 'Liked Classic — HACKED BY XDevster !'
local SAFE_PATH = "/data/registry.dat"
local CONTENT = [[{disableRecovery=false,systemConfigured=true,screenSaverDefaultSetted=true,lowPowerSound=true,shadowType="advanced",powerMode="power",soundEnable=true,shadowMode="full",fullBeepDisable=false,diskSound=true,wallpaperBaseColor="lightBlue",bufferType="software",sysmodeVersion=1,primaryScreen="aa925677-731f-4feb-baf7-c629fc92e926",timeZone=0,screenSaverTimer=25}]]
local REFRESH_DELAY = 1

local function safeRemove(path)
  if fs.exists(path) then

    return fs.remove(path)
  end
  return true
end

local function safeWrite(path, text)

  local handle, err = fs.open(path, "w")
  if not handle then
    return false, err
  end
  fs.write(handle, text)
  fs.close(handle)
  return true
end

local logs = {}
local function addLog(msg)
  table.insert(logs, os.date("%H:%M:%S") .. " | " .. tostring(msg))

  if #logs > 200 then
    for i = 1, 50 do table.remove(logs, 1) end
  end
end

local function redraw()
  local w, h = gpu.getResolution()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")

  local x = math.max(1, math.floor((w - #MESSAGE) / 2))
  local y = math.floor(h / 2)
  gpu.set(x, y, MESSAGE)

  local logStartY = y + 1
  local maxLines = h - logStartY
  if maxLines > 0 then
    local startIndex = math.max(1, #logs - maxLines + 1)
    local line = 0
    for i = startIndex, #logs do
      line = line + 1
      local drawY = logStartY + line - 1
      if drawY <= h then
        local txt = logs[i]
        if #txt > w - 2 then txt = txt:sub(1, w - 5) .. "..." end
        gpu.set(2, drawY, txt)
      end
    end
  end
end

addLog("Starting demo sequence.")
addLog("Clearing screen and drawing message.")
redraw()

addLog("Preparing to update: " .. SAFE_PATH)
local ok_remove, rem_err = safeRemove(SAFE_PATH)
if ok_remove then
  addLog("Old file removed (if existed).")
else
  addLog("Failed to remove old file: " .. tostring(rem_err))
end

local ok_write, write_err = safeWrite(SAFE_PATH, CONTENT)
if ok_write then
  addLog("New registry written to " .. SAFE_PATH)
else
  addLog("Failed to write registry: " .. tostring(write_err))
end

addLog("Demo sequence finished — program will remain running until device reboot.")

while true do
  redraw()
  os.sleep(REFRESH_DELAY)
end
