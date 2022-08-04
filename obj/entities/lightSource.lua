lightSource = Object:extend()

local boxSize = 32

function lightSource:new(x, y, p, id)
  self = self
  self.xPos = x
  self.yPos = y
  self.power = p
  self.ID = id
end

function lightSource:getPos()
  return self.xPos + 16 + _camPosX + gw/2, self.yPos + 16 + _camPosY + gh/2
end

function lightSource:update(dt)
  if _mode == 'light' then
    if lightSource:mouseCheck(self) == true and love.mouse.isDown(2) and stageLightArr[self.ID] ~= nil and _editMode == true then
      uMouse:setHover(false)
      _accessingObj = true
      _currentTime = _currentTime + dt
      if _currentTime >= 1 then
        _accessingObj = false
        _currentTime = 0
        table.remove(stageLightArr, self.ID)
        _pressed = false
      end
    elseif lightSource:mouseCheck(self) == false and not love.mouse.isDown(2) then
      uMouse:setHover(true)
      _accessingObj = false
      _currentTime = 0
    end
  end
end

function lightSource:removeSelf(self)
  table.remove(stageLightArr, self.ID)
  self = nil
end

function lightSource:draw()
  if _editMode == true then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', self.xPos, self.yPos, boxSize, boxSize)
    if _editMode == true then
      love.graphics.setColor(0, 0, 1, 1)
      love.graphics.print(self.ID, self.xPos, self.yPos)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function lightSource:setID(id)
  self.ID = id
end

function lightSource:getID()
  return self.ID
end

function lightSource:mouseCheck(self)
  if _obJWrldMousePosX >= self.xPos and
   _obJWrldMousePosX <= self.xPos + boxSize and
    _obJWrldMousePosY >= self.yPos and
      _obJWrldMousePosY <= self.yPos + boxSize then
    uMouse:setHover(true)
    return true
  else
    return false
  end
end

return lightSource
