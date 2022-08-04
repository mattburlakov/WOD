Btn = Object:extend()

function Btn:new()

end

function Btn:getParameters(self, x, y, w, h, t, d, m)     --
  self.xP = x
  self.yP = y

  self = self

  self.data = d

  self.mode = m

  self.btnSizeW = w
  self.btnSizeH = h

  self.text = t
end

local action = {
  stageChange = function(self)
    if _socket:getsockname() ~= nil then
      if self.data == 'Menu' and _socket:getsockname() ~= nil then
        local data = string.format("%s %s", "disconnect", "N/A")
        _socket:send(data)
        _socket:close()
      end
    end
    gotoRoom(self.data)
    _mode = 'tile'
    _pressed = false
    -- _udp = Socket.udp()
    _paused = false
  end,

  mastermode = function()
    if _masterMode == false then
      _masterMode = true
    else
      _masterMode = false
    end

    _pressed = false
  end,

  lightModeSwitch = function(self)
    if _mode ~= 'light' then
      prevMode = _mode
      _mode = 'light'
      self.text = ">Editing_light..."
    else
      _mode = prevMode
      self.text = ">Place_light_"
    end

    _pressed = false
  end,

  texMode = function(self)
    if _mode == 'tile' then
      _mode = 'obj'
      texSel:resetCurrentTexture()
      self.text = ">Obj_"
    else
      _mode = 'tile'
      texSel:resetCurrentTexture()
      self.text = ">Tile_"
    end

    _pressed = false
  end,

  editorSwitch = function()
    if _editMode == false then
      _editMode = true
    else
      _editMode = false
    end

    _pressed = false
  end,

  saveMap = function(self)
    current_room:saveStage(1, self.data)
    mI:updateSelectorList()

  _pressed = false
  end,

  loadMap = function(self)
    local stageData = current_room:getData(self.data)
    current_room:loadStage(stageData)

    _pressed = false
  end,

  sendMap = function(self)
    current_room:saveStage(0, self.data)

    _pressed = false
  end,

  returnPressed = function(self)
    if self.data == 0 then
      Btn:setData(self, 1)
    end

    _pressed = false
  end,

  clearMap = function()
    current_room:removeAll()

    _pressed = false
  end,

  toggleObj = function()
    if _objTransparency == false then
      _objTransparency = true
    else
      _objTransparency = false
    end

    _pressed = false
  end,

  quit = function()
    love.event.quit()
    _pressed = false
  end
}

function Btn:update(dt)

  if Btn:mouseCheck(self) == true and _pressed == true then

    action[self.mode](self)

  end
end

function Btn:draw()
  if Btn:mouseCheck(self) == true then
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end

  love.graphics.rectangle("fill", self.xP, self.yP, self.btnSizeW, self.btnSizeH)
  love.graphics.setColor(0, 0, 0, 1)

  if self.mode ~= 'mastermode' then
    love.graphics.print(self.text, self.xP + 10, self.yP + 10)
  else
    love.graphics.print(self.text .. tostring(_masterMode), self.xP + 10, self.yP + 10)
  end
end

function Btn:mouseCheck(self)
    if _mousePosX >= self.xP and
     _mousePosX <= self.xP + self.btnSizeW and
      _mousePosY >= self.yP and
        _mousePosY <= self.yP + self.btnSizeH and (_paused == false or self.mode == "stageChange") then
          uMouse:setHover(true)
            return true
        else
          return false
    end
end

function Btn:returnData()
  return self.data
end

function Btn:setData(self, d)
  self.data = d
end

return Btn
