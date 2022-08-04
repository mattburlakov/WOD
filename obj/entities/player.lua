Player = Object:extend()

_clientID = 0
_currentClient = nil

function Player:new(x, y, id, tex)
  self = self
  self.xPos = x
  self.yPos = y
  self.ID = id
  if tex then
    self.texture = tex
  else
    self.texture = love.graphics.newImage('pic/player/Tech-0.png')
  end
  self.hover = false
end

function Player:update(dt)
  if self.ID == _clientID then
    self.cX = self.xPos + self.texture:getWidth()*_texScale/2
    self.cY = self.yPos + _gridSize/2
  end
  if Player:mouseCheck(self) == true and ((self.ID == _clientID) or (_masterMode == true)) then
    self.hover = true
    if _pressed == true and _editMode == false and _currentClient == nil then
      _pressed = false
      _currentClient = self.ID
    end
  end

  if self.ID == _currentClient and _editMode == false then
    if _pressed == true and _hoversObj == false  then
      _pressed = false
      Player:reposition(self, _tilePosX, _tilePosY)
      _currentClient = nil
      local dg = string.format("%s %s", 'playerupdate', self.ID .. '/' .. self.xPos .. '/' .. self.yPos .. '|')
      _socket:send(dg)
    elseif _pressed == true and _hoversObj == true then
        _pressed = false
      _currentClient = nil
    end
  end
end

function Player:draw()
  if self.ID == _clientID then
    love.graphics.setColor(1.0, 0.0, 0.0, 1.0) -- tmp
    love.graphics.rectangle('line', self.xPos, self.yPos, 64, 64)
  end
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.draw(self.texture, self.xPos, self.yPos - self.texture:getHeight()*_texScale/2, 0, _texScale, _texScale)
  love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
  love.graphics.print(self.ID .. ' ' .. tostring(_currentClient), self.xPos + 5 + 16, self.yPos + 5 + 16)
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

function Player:reposition(self, x, y)
  self.xPos = x
  self.yPos = y
end

function Player:getID()
  return self.ID
end

function Player:setID(i)
  self.ID = i
end

function Player:mouseCheck(self)
    if _obJWrldMousePosX >= self.xPos and
      _obJWrldMousePosX <= self.xPos + 64 and
      _obJWrldMousePosY >= self.yPos - self.texture:getHeight()*_texScale/2 and
      _obJWrldMousePosY <= self.yPos + self.texture:getHeight()*_texScale/2
    then
      uMouse:setHover(true)
      return true
    else
      self.hover = false
      return false
    end
end


return Player
