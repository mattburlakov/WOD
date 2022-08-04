InputField = Object:extend()

_currentInputField = nil
_utf8 = require("utf8")

function InputField:new()
  love.keyboard.setKeyRepeat(true)
end

function InputField:getParameters(self, x, y, w, h, text, max)
  self = self
  self.active = false

  self.data = ''
  self.initialData = text

  self.maxSymb = max
  self.symb = 0

  self.xPos = x
  self.yPos = y
  self.w = w
  self.h = h

  self.window = IngameWindow()
    self.window:createNewWindow(self.window, self.xPos, self.yPos, self.w, self.h)
end

--------------------------------------------------------------------------------
function love.textinput(t)
    if _currentInputField ~= nil then
        if _currentInputField.active == true and _currentInputField.symb ~= _currentInputField.maxSymb then -- add max line symb parameter!
          _currentInputField.data = _currentInputField.data .. t
          _currentInputField.symb = _currentInputField.symb + 1
        end
    end
end

function love.keypressed(key)
    if _currentInputField ~= nil then
        if key == "backspace" then
          if _currentInputField.active == true then
            local byteoffset = _utf8.offset(_currentInputField.data, -1)
                if byteoffset then
                    _currentInputField.data = string.sub(_currentInputField.data, 1, byteoffset - 1)
                    _currentInputField.symb = _currentInputField.symb - 1
                end
            end
        end
    end
end
--------------------------------------------------------------------------------

function InputField:update(dt, self)
  InputField:mouseCheck(self)
end

function InputField:draw()
  self.window:draw()

  if self.active == true then
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  else
    love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
  end

  if self.data == '' and self.active == false then
    love.graphics.print(self.initialData, self.xPos + 10, self.yPos + 9)
  else
    love.graphics.print(self.data, self.xPos + 10, self.yPos + 9)
  end
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

function InputField:mouseCheck(self)
    if _mousePosX >= self.xPos and
     _mousePosX <= self.xPos + self.w and
      _mousePosY >= self.yPos and
        _mousePosY <= self.yPos + self.h then
          uMouse:setHover(true)
          if _pressed == true then
            self.active = true
            _currentInputField = self
            if self.data == self.initialData then
              self.data = ''
            end
            _pressed = false
          end
          return  true
    else
      if _pressed == true then
        self.active = false
      end
      return false
    end
end

function InputField:returnSelfData()
  return self.data
end

function InputField:setData(d)
  self.initialData = d
  self.data = d
end

function InputField:checkInitial()
  if self.data == self.initialData then
    return true
  end
  return false
end


return InputField
