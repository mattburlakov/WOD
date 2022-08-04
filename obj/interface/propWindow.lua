propWindow = Object:extend()

local xPos = 0
local yPos = 0
local width = 200
local height = 200
local data = ''

local propInputWin = IngameWindow()
  propInputWin:createNewWindow(propInputWin, xPos, yPos, width, height)

function propWindow:new()

end

function propWindow:update(dt)
  propInputWin:update(dt)
  if propInputWin:checkActive() == true then
    _mouseOnInterface = true
    uMouse:setHover(true)
    if _Rpressed == true then
      _Rpressed = false
      stageObjArr[_activeObjID].active = false
    end
  end
end

function propWindow:draw()
  propInputWin:draw()
  love.graphics.print(tostring(_activeObjID), xPos + 10, yPos + 10)
end

function propWindow:relocate(x, y)
  xPos = x
  yPos = y
  propInputWin:relocate(x, y)
end

return propWindow
