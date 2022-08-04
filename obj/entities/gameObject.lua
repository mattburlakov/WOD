gameObj = Object:extend()

_activeObjID = nil

function gameObj:new(x, y, t, id, txID, type)
  self = self
  self.xPos = x
  self.yPos = y
  self.texture = t
  self.ID = id
  self.tile = 0
  if type then
    if type ~= 'nil' then
      self.type = type
    else
      self.type = 'p'
    end
  end
  self.textureID = txID
  --self.texturePage = 1
  self.info = ''
  self.active = false
  self.hovering = false

end

function gameObj:getPos()
  return self.xPos, self.yPos
end

function gameObj:update(dt)

  gameObj:mouseCheck(self)

  if _mode == 'obj' and _editMode == true then
    if gameObj:mouseCheck(self) == true then
      if love.mouse.isDown(1) and stageObjArr[self.ID] ~= nil then
        _currentTime = _currentTime + dt
       if self.type ~= 'w' then
         _accessingObj = true
         _pressed = false
       else
         _accWall = true
         _accessingObj = false
       end
        if _currentTime >= 1 then
          _accessingObj = false
          _accWall = false
          _currentTime = 0
          table.remove(stageObjArr, self.ID)
          _pressed = false
          _justAcessed = true
        end
      elseif gameObj:mouseCheck(self) == false and not love.mouse.isDown(1) then
        uMouse:setHover(true)
        _accessingObj = false
        _currentTime = 0
      end
    end
  end

  if _Rpressed == true and self.type ~= 'w' and gameObj:mouseCheck(self) == true then
    _Rpressed = false
    if self.active == false then
      self.active = true
    else
      self.active = false
    end
  elseif _Rpressed == true and self.active == true then
    self.active = false
    _Rpressed = false
  end

end

function gameObj:draw()

  if self.texture ~= nil then
    local yPos
    if self.type ~= 'p' then
      yPos = self.yPos - (self.texture:getHeight()*_texScale - _gridSize)
    else
      yPos = self.yPos
    end
    love.graphics.draw(self.texture, self.xPos, yPos, 0, _texScale, _texScale)
    if _editMode == true then
      love.graphics.setColor(1.0, 0.0, 0.0, 1.0)
      love.graphics.print(self.ID .. '\n' .. tostring(self.type) .. '\n' .. tostring(self.active) .. '\n' .. tostring(self.hovering), self.xPos, self.yPos)
      love.graphics.setColor(1.0, 0.0, 0.0, 0.5)
      if self.type ~= 'w' and self.type ~= 'd' then
        love.graphics.line(self.xPos + self.texture:getWidth()*_texScale/2, _yPosO, self.xPos + self.texture:getWidth()*_texScale/2, _yPosO + fh)
        love.graphics.line(_xPosO, self.yPos + self.texture:getHeight()*_texScale/2, _xPosO + fw , self.yPos + self.texture:getHeight()*_texScale/2)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

end

function gameObj:setID(id)
  self.ID = id
end

function gameObj:getID()
  return self.ID
end

function gameObj:getActive()
  return self.active
end

function gameObj:getData()
  return self.info
end

function gameObj:getDimensions()
  return self.texture:getWidth()*_texScale, self.texture:getHeight()*_texScale
end

function gameObj:getPos()
  return self.xPos + _camPosX + gw/2, self.yPos + _camPosY + gh/2 + self.texture:getHeight()*_texScale
end

function gameObj:setData(i)
  self.info = i
end


function gameObj:mouseCheck(self)
  local trdcondition = self.yPos
  local frthcondition = self.yPos + self.texture:getHeight()*_texScale

  if self.type == 'w' then
    trdcondition = self.yPos - self.texture:getHeight()*_texScale + _gridSize
    frthcondition = self.yPos + _gridSize
  end

  if _obJWrldMousePosX >= self.xPos and
    _obJWrldMousePosX <= self.xPos + self.texture:getWidth()*_texScale and
    _obJWrldMousePosY >= trdcondition and
    _obJWrldMousePosY <= frthcondition
  then
    if _mode == 'obj' then
      uMouse:setHover(true)
    end

    self.hovering = true

    _hoversObj = false

        if self.type == 'w' then
          if _obJWrldMousePosX >= self.xPos and
            _obJWrldMousePosX <= self.xPos + _gridSize and
            _obJWrldMousePosY >= self.yPos and
            _obJWrldMousePosY <= self.yPos + _gridSize
          then
            _hoversObj = true
          end
        end

    return true
  else
    self.hovering = false
    return false
  end
end

return gameObj
