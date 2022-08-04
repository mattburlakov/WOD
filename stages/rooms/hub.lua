Hub = Object:extend()

local entity = 'entity'
local world = {}

local server_input = {}
server_input[1] = InputField()
  server_input[1]:getParameters(server_input[1], 0 + 50, 0 + 50, 200, 30, 'Address', 40)
server_input[2] = InputField()
  server_input[2]:getParameters(server_input[2], 0 + 50, 0 + 105, 200, 30, 'Port', 5)
server_input[3] = InputField()
  server_input[3]:getParameters(server_input[3], 0 + 50, 0 + 155, 200, 30, 'Nickname', 20)

local connectBtn = Btn()
local backBtn = Btn()
local singlePlayerBtn = Btn()

local masterModeBtn = Btn()


function Hub:new()
  connectBtn:getParameters(connectBtn, 0 + 300, 0 + 105, 100, 30, ">Connect_", 0, "returnPressed")
  backBtn:getParameters(backBtn, 0 + 300, 0 + 155, 100, 30, ">Back_", "Menu", "stageChange")
  singlePlayerBtn:getParameters(singlePlayerBtn, 0 + 410, 0 + 105, 100, 30, ">Map_editing_", "Stage", "stageChange")
  masterModeBtn:getParameters(masterModeBtn, 0 + 410 , 0 + 155, 100, 30, ">Master: ", nil, "mastermode") --

end

function Hub:update(dt)
  uMouse:setHover(false)
  backBtn:update(dt)
  masterModeBtn:update(dt)
  singlePlayerBtn:update(dt)
  if connectBtn:returnData() == 0 then
    connectBtn:update(dt)
    server_input[1]:update(dt, server_input[1])
    server_input[2]:update(dt, server_input[2])
    server_input[3]:update(dt, server_input[3])

    if server_input[1].active == true and input:pressed('apply') then
      server_input[1].active = false
      _address = server_input[1]:returnSelfData()
    end
    if server_input[2].active == true and input:pressed('apply') then
      server_input[2].active = false
      _port = server_input[2]:returnSelfData()
    end
    if server_input[3].active == true and input:pressed('apply') then
      server_input[3].active = false
      _clientName = server_input[3]:returnSelfData()
    end
--==============================================================================
  elseif connectBtn:returnData() == 1 then
    if _address ~= nil and _port ~= nil and _socket ~= nil then
      _socket:setpeername(_address, _port)
      if _socket:getsockname() == nil then

      elseif _t > _updaterate then
        local dg = string.format("%s %s", 'connect', _clientName)
        _socket:send(dg)
        connectBtn:setData(connectBtn, 2)
        _t = _t - _updaterate
          -- body...
        end
      end
-------------------------------------------------------------------------------- --WORK IN PROGRESS
  elseif connectBtn:returnData() == 2 then
      if _data then
        cmd, answ = _data:match("^(%S*) (%S*)")
      end

        if cmd == "anwser" then
        _status = answ
        cmd = nil
        answ = nil
          if tonumber(_status) == 1 then
            gotoRoom("Stage")
          elseif tonumber(_status) == 0 then
            _socket:close()
            _socket = Socket.udp()
            connectBtn:setData(connectBtn, 0)
            _status = "No slots available for this address or a connection with your address was not closed" --change to receive error
          end
        end
  else
    connectBtn:setData(connectBtn, 0)
  end
--============================================================================== update function end
end
--------------------------------------------------------------------------------

function Hub:draw()
  server_input[1]:draw()
  server_input[2]:draw()
  server_input[3]:draw()
  connectBtn:draw()
  masterModeBtn:draw()
  backBtn:draw()
  singlePlayerBtn:draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print('Connect to "' .. tostring(_address) .. '" on port "' .. tostring(_port) .. '" as ' .. tostring(_clientName) .. ' ?', 0 + 300, 0 + 55)
  love.graphics.print('Status: ' .. tostring(_status), 0 + 50, 0 + 200)
  love.graphics.print(connectBtn:returnData())
end

return Hub
