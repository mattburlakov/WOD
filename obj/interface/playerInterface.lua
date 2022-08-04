PI = Object:extend()

local xP = 0
local yP = gh - 192

local active = false

local playerWindow = IngameWindow()
  playerWindow:createNewWindow(playerWindow, xP, yP, gw/4, 192)

function PI:new()

end

function PI:update(dt)
  playerWindow:update(dt)
  active = playerWindow:checkActive()
end

function PI:draw()
  playerWindow:draw()
end

function PI:getActive()
  return active
end

return PI
