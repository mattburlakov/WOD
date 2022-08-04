Menu = Object:extend()

  local start = Btn()
  local quitBtn = Btn()


  _masterMode = false

function Menu:new()
    start:getParameters(start, gw/2-50, gh/2-15, 100, 30, ">Enter_", "Hub", "stageChange") --

    quitBtn:getParameters(quitBtn, gw/2-50 , gh/2+25, 100, 30, ">Quit_", nil, "quit") --

end

function Menu:update(dt)
  start:update(dt)

  uMouse:setHover(false)
  quitBtn:update(dt)
  paused = false
end

function Menu:draw()
  start:draw()

  quitBtn:draw()
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.print("ver. 0.1.0", 5, gh - 50)
end

return Menu
