Scroller = Object:extend()

  _currentScroller = nil

  function love.wheelmoved(x, y)
    if _currentScroller ~= nil then
      if y > 0 and _currentScroller.active == true then
        _currentScroller.wheel_move = _currentScroller.wheel_move + _currentScroller.scroll_speed

        if _currentScroller.box_y - _currentScroller.scroll_step < _currentScroller.yP + 5 then
          _currentScroller:goUp()
        else
          _currentScroller.box_y = _currentScroller.box_y - _currentScroller.scroll_step
        end

      elseif y < 0 and _currentScroller.active == true then
        _currentScroller.wheel_move = _currentScroller.wheel_move - _currentScroller.scroll_speed

        if _currentScroller.box_y + _currentScroller.scroll_step + _currentScroller.boxHeight > _currentScroller.yP + _currentScroller.height then
          _currentScroller:goDown()
        else
          _currentScroller.box_y = _currentScroller.box_y + _currentScroller.scroll_step
        end

      end
    end
  end

function Scroller:new()

end

function Scroller:getParameters(s, x, y, w, h, sh)
  self = s
  self.width = w
  self.height, self.boxHeight, self.initialHeight = h, h, h
  self.xP, self.box_x = x, x
  self.yP, self.box_y = y, y + 5
  self.minBoxHeight = 50
  self.active = false
  self.wheel_move = 0
  self.scroll_speed = sh
  self.scroll_step = 1
  self.scrollWindow = IngameWindow()
  self.scrollWindow:createNewWindow(self.scrollWindow, self.xP, self.yP, self.width, self.height)
end

function Scroller:update(dt)
  self.scrollWindow:update(dt)

  -- if self.box_y - 5 < self.yP then
  --   self.box_y = self.yP + 5
  -- elseif self.box_y + self.boxHeight - 5 > self.yP + self.height then
  --   self.box_y = self.yP + self.height - self.boxHeight
  -- end

  if self.scrollWindow:mouseInWindow(self.scrollWindow) == true then
    _currentScroller = self
    self.active = true
  else
    self.active = false
  end

end

function Scroller:draw()
    self.scrollWindow:draw()
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.rectangle('fill', self.box_x + 7, self.box_y + 2, self.width - 14, self.boxHeight - 14)
end

function Scroller:goDown()
  self.box_y = self.yP + self.height - self.boxHeight + 5
end

function Scroller:goUp()
  self.box_y = self.yP + 5
end

return Scroller
