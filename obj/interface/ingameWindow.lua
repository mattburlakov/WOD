IngameWindow = Object:extend()

local rightBorder = love.graphics.newImage('pic/interface/Window-border-right-2x495.png')
local leftBorder = love.graphics.newImage('pic/interface/Window-border-left-2x495.png')
local upperBorder = love.graphics.newImage('pic/interface/Window-border-upper-495x2.png')
local bottomBorder = love.graphics.newImage('pic/interface/Window-border-bottom-495x2.png')

local UL = love.graphics.newImage('pic/interface/Window-corner-UL-3x3.png')
local UR = love.graphics.newImage('pic/interface/Window-corner-UR-3x3.png')
local BL = love.graphics.newImage('pic/interface/Window-corner-BL-3x3.png')
local BR = love.graphics.newImage('pic/interface/Window-corner-BR-3x3.png')

function IngameWindow:new()

end

function IngameWindow:createNewWindow(self, x, y, w, h)
  self = self
  self.xPos = x
  self.yPos = y
  self.width = w
  self.height = h

  self.windowCanvas = love.graphics.newCanvas(self.width, self.height)

end

function IngameWindow:update(dt)
  IngameWindow:mouseInWindow(self)
end

function IngameWindow:draw()
  love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
  love.graphics.rectangle('fill', self.xPos, self.yPos, self.width, self.height)
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  -- love.graphics.rectangle('line', self.xPos, self.yPos, self.width, self.height)

  love.graphics.setCanvas(self.windowCanvas)
  love.graphics.clear()
    love.graphics.draw(rightBorder, 0 + self.width - rightBorder:getWidth(), 0)
    love.graphics.draw(leftBorder, 0, 0)
    love.graphics.draw(upperBorder, 0, 0)
    love.graphics.draw(bottomBorder, 0, 0 + self.height - bottomBorder:getHeight())

    love.graphics.draw(UL, 0, 0)
    love.graphics.draw(UR, 0 + self.width - UR:getWidth(), 0)
    love.graphics.draw(BL, 0, 0 + self.height - BL:getHeight())
    love.graphics.draw(BR, 0 + self.width - BR:getWidth(), 0 + self.height - BR:getHeight())
  love.graphics.setCanvas()
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.draw(self.windowCanvas, self.xPos, self.yPos)
  love.graphics.setBlendMode('alpha')
end

function IngameWindow:mouseInWindow(self)
  if _mousePosX >= self.xPos and
   _mousePosX <= self.xPos + self.width and
    _mousePosY >= self.yPos and
      _mousePosY <= self.yPos + self.height then
        uMouse:setHover(false)
        self.active = true
        return true
      else
        self.active = false
        return false
  end
end

function IngameWindow:relocate(x, y)
  self.xPos = x
  self.yPos = y
end

function IngameWindow:checkActive()
  return self.active
end

return IngameWindow
