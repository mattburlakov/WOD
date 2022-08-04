PauseMenu = Object:extend()

  local exitBtn = Btn()
  local w = 300
  local h = 500

  local pauseWindow = IngameWindow()
    pauseWindow:createNewWindow(pauseWindow, gw/2 - w/2, gh/2 - h/2, w, h)

function PauseMenu:new()
  exitBtn:getParameters(exitBtn, gw/2 - 100/2, gh/2 + 100, 100, 30, ">Disconnect_", 'Menu', "stageChange") --

  title = love.graphics.newImage('pic/interface/paused_title_2.png')
end

function PauseMenu:update(dt)
  exitBtn:update(dt)
end

function PauseMenu:draw()
  love.graphics.setColor(0.0, 0.0, 0.0, 0.5)
  love.graphics.rectangle("fill", 0, 0, gw, gh)
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

  pauseWindow:draw()

  love.graphics.draw(title, gw/2 - title:getWidth()/2 , gh/2 - h/2 + 15)

  exitBtn:draw()
end

return PauseMenu
