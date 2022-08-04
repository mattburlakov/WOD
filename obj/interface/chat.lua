ChatBox = Object:extend()

local xP = gw/2
local yP = gh - 192

local scrollPos = -16

local active = false

local width = gw/2
local height = 192

local chat_canvas

local prev_height = 0
local inv_height = 0

local maxMsg = 50
local log = {}

local chatInput = InputField()
  chatInput:getParameters(chatInput, xP, yP, width, 30, 'Limit is 200 symbols', 200)

local chatWindow = IngameWindow()
  chatWindow:createNewWindow(chatWindow, xP, yP, width, height)

local scroller = Scroller()
  scroller:getParameters(scroller, gw - 30, yP + 30, 30, height - 30, 16)

function ChatBox:new()
  chat_canvas = love.graphics.newCanvas(width - 30, height - 30)
end

function ChatBox:update(dt)
  chatWindow:update(dt)
  scroller:update(dt)

  if chatWindow:checkActive() == true then
    scroller.active = true
    active = true
  elseif scroller.active == true then
    active = true
  else
    active = false
  end

  if inv_height > 160 then
    scrollPos = scrollPos + scroller.wheel_move

    if scrollPos > -16 then
      scrollPos = -16
    elseif -inv_height + 144 > scrollPos then
      scrollPos = -inv_height + 144
    end

  end

    scroller.wheel_move = 0

  chatInput:update(dt, chatInput)

  local msg

  if chatInput.active == true then
    active = true
  end

  if chatInput.active == true and input:pressed('apply') then
    local msg = chatInput.data
    if msg ~= '' and msg ~= ' ' then
      local dg = string.format("%s %s", 'chatmsg', msg)
      _socket:send(dg)
      chatInput.data = ''
      chatInput.active = false
    end
  end

  prev_height = inv_height

  ------------------------------------------------------------------------------receive msg
  if _data then
    cmd, answ = _data:match("^(%S*) (.*)")
  end

      if cmd == 'chatmsg' then
        if #log >= maxMsg then
          table.remove(log, 1)
        else
          inv_height = inv_height + 16
        end

        table.insert(log, answ)

        if inv_height > 160 then
          scrollPos = -inv_height + 144
        end

        if inv_height > 160 then
          local inc_per = ((inv_height / 162) / 2 * 100) - ((prev_height / 162) / 2 * 100)
          scroller.boxHeight = scroller.boxHeight - (scroller.boxHeight / 100) * inc_per --Rework later

          if scroller.boxHeight < scroller.minBoxHeight then
            scroller.boxHeight = scroller.minBoxHeight
          end

          local steps = inv_height / 16 - 10
          scroller.scroll_step = (scroller.height-scroller.boxHeight)/steps

        end

        scroller:goDown()

        cmd = nil
        answ = nil
      end
  ------------------------------------------------------------------------------ canvas update
  local msgYPos = yP + 15

  love.graphics.setCanvas(chat_canvas)

      love.graphics.clear()
      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

      for i = 1, #log do
        if log[i] ~= nil then
          love.graphics.print(i .. '. ' .. tostring(log[i]), 7, scrollPos + 16*i + 2) -- temp : IMPROVE TEXT RENDER
        end
      end

  love.graphics.setCanvas()
  ------------------------------------------------------------------------------

end

function ChatBox:draw()
  chatWindow:draw()
  scroller:draw()
  chatInput:draw()

  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.draw(chat_canvas, xP, yP + 30)
  love.graphics.setBlendMode('alpha')
end

function ChatBox:getActive()
  return active
end

return ChatBox
