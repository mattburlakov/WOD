SelectorList = Object:extend()

local elHeight = 30

function SelectorList:new()

end

function SelectorList:getParameters(self, folder, x, y, w, h, side)
  self = self
  self.list = {}
  self.pathList = {}
  self.xP = x
  self.yP = y
  self.width = w
  self.height = h
  self.selectorCanvas = love.graphics.newCanvas(self.width, self.height)

  if side then
    self.side = side
  else
    self.side = 0
  end

  self.scroller = Scroller()
  if self.side == 0 then
    self.scroller:getParameters(self.scroller, self.xP + self.width, self.yP, 30, self.height, elHeight)
  else
    self.scroller:getParameters(self.scroller, self.xP - 30, self.yP, 30, self.height, elHeight)
  end

  self.scrollPos = 0
  self.invHeight = elHeight * #self.list
  self.prevHeight = self.height
  self.updated = false

  self.active = false

  self.listWindow = IngameWindow()
    self.listWindow:createNewWindow(self.listWindow, self.xP, self.yP, self.width, self.height)

  self.activeID = 1

  self.folder = folder

  self:getList(self, self.folder)

  self:updateList(self, self.list)
  self.scrollPos = 0
  self.scroller:goUp()

end

function SelectorList:getList(self, folder)
  if folder then
    local items = love.filesystem.getDirectoryItems(folder)
    local counter = 1
    for _, item in ipairs(items) do
        local file = item
        local path = folder .. '/' .. item
        if love.filesystem.getInfo(path, 'file') and self:hasFile(file) == false then
            table.insert(self.list, file)
            table.insert(self.pathList, path)
        elseif love.filesystem.getInfo(path, 'directory') then
            self:getList(self, path)
        end
        counter = counter + 1
    end
    self.updated = false
  end
end

function SelectorList:hasFile(file)
  for i = 1, #self.list do
    if self.list[i] == file then
      return true
    end
  end
  return false
end

function SelectorList:update(dt)
  self.scroller:update(dt)
  self.listWindow:update(dt)

  if self.invHeight > self.height then
    self.scrollPos = self.scrollPos + self.scroller.wheel_move

    if self.scrollPos > 0 then
      self.scrollPos = 0
    elseif -self.invHeight + self.height > self.scrollPos then
      self.scrollPos = -self.invHeight + self.height
    end
  end

  self.scroller.wheel_move = 0

end

function SelectorList:draw()
  self.listWindow:draw()
  self.scroller:draw()
  love.graphics.setCanvas(self.selectorCanvas)

    love.graphics.clear()
    for i = 1, #self.list do

      if self.list[i] ~= nil then
        if _mousePosX >= self.xP and
           _mousePosX <= self.xP + self.width and
            _mousePosY >= self.yP and
              _mousePosY <= self.yP + elHeight*i then
          uMouse:setHover(true)
          if _pressed == true then
            self.updated = false
            self.activeID = i - self.scrollPos/elHeight
            _pressed = false
          end
        end

        if self.activeID == i then
          love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
        else
          love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        end

        love.graphics.rectangle('fill', 0, self.scrollPos + elHeight*i - elHeight, self.width, elHeight)
        love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
        love.graphics.print(i .. '. ' .. tostring(self.list[i]), 10, self.scrollPos -elHeight + elHeight*i + 7)
      end

    end

  love.graphics.setCanvas()
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.draw(self.selectorCanvas, self.xP, self.yP)
  love.graphics.setBlendMode('alpha')

end

function SelectorList:updateList(self)
  -- self.list = l
  self.invHeight = elHeight * #self.list

  if self.invHeight > self.height then
    self.scrollPos = -self.invHeight + self.height - elHeight
  end

  if self.invHeight > self.height then
    local inc_per = ((self.invHeight / self.height) / 2 * 100) - ((self.prevHeight / self.height) / 2 * 100)
    self.scroller.boxHeight = self.scroller.boxHeight - (self.scroller.boxHeight / 100) * inc_per --Rework later

    if self.scroller.boxHeight < self.scroller.minBoxHeight then
      self.scroller.boxHeight = self.scroller.minBoxHeight
    end

    local steps = ((self.invHeight / elHeight) - (self.height / elHeight))
    self.scroller.scroll_step = (self.scroller.height-self.scroller.boxHeight)/steps

    self.prevHeight = self.invHeight
    self.scroller:goDown()
  end
end

function SelectorList:getData()
  self.updated = true
  return self.pathList[self.activeID]
end

function SelectorList:getName()
  return self.list[self.activeID]
end

function SelectorList:updateActiveID(self, n)
  self.updated = false
  self.activeID = self.activeID + n
end

function SelectorList:setActiveID(self, n)
  self.activeID = n
end

return SelectorList
