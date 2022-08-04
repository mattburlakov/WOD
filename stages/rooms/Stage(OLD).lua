TextSel = require 'obj/interface/textureselector'
MI = require 'obj/interface/masterInterface'
PI = require 'obj/interface/playerInterface'
PauseMenu = require 'obj/interface/pauseMenu'
ChatBox = require 'obj/interface/chat'

Tile = require 'obj/entities/Tile'
GameObj = require 'obj/entities/gameObject'
lightSource = require 'obj/entities/lightSource'

Stage = Object:extend()

local lightShader_code = [[
  #define MAX_LIGHTS 50

  struct Light{
    vec2 position;
    vec3 diffuse;
    float power;
  };

  extern Light lights[MAX_LIGHTS];
  extern int num_lights;
  extern vec2 screen;

  const float constant = 1.0;
  const float linear = 0.09;
  const float quadratic = 0.032;

  vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
    vec4 pixel = Texel(image, uvs);

    vec2 norm_screen = screen_coords / screen;

    vec3 diffuse = vec3(0);

    for(int i = 0; i < num_lights; i++){
      Light light = lights[i];

      vec2 norm_pos = light.position / screen;

      float distance = length(norm_pos - norm_screen) * light.power;

      float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));

      diffuse += light.diffuse * attenuation;
    }

    diffuse = clamp(diffuse, 0.0, 1.0);

    return pixel * vec4(diffuse, 1.0);
  }
]]

--MULTIPLICATION BY PIXEL

local w = 50
local h = 33

local maxVelocity = 10
local minVelocity = -10
local velocityX = 0
local velocityY = 0
local camAccel = 1.5
local stabilize = 0.25

_gridSize = 64

_objGrid = 2

_texScale = 4
_camPosX = -gw*2
_camPosY = -gh*2

_camWorldPosX = 0
_camWorldPosY = 0

_clientID = 0;

_paused = false
_editMode = false

_camScale = 4

_syncX = gw*(0.5*(_camScale-1))
_syncY = gh*(0.5*(_camScale-1))

local zoom = 1
local currentZoom = 1

love.mouse.setX(0)
love.mouse.setY(0)

function Stage:new()
  camera = Camera(gw/2, gh/2)

  _xPosO, _yPosO = camera:getWorldCoords(gw/2, gh/2, gw*_camScale, gh*_camScale) -- Requires complete coordinate system rework if possible

  _xPosO, _yPosO = 960, 540 -- Base origin coords

  self.main_canvas = love.graphics.newCanvas(gw, gh)
  shader1 = love.graphics.newShader(lightShader_code)

  fw = _gridSize*w
  fh = _gridSize*h

  stageTileArr = {} -- contains tileset
    Stage:tileInitFill()

  stageObjArr = {}
  stageLightArr = {}
  stagePlayerArr = {} -- (players, entities)

  mI = MI()
  pI = PI()

  pMenu = PauseMenu()

  texSel = TextSel()
  chat = ChatBox()

end

-------------------------------------------------
-- function love.wheelmoved(x, y)
--     if y > 0 then
--         zoom = zoom + 0.1
--         currentZoom = currentZoom + 0.1
--
--         camera:zoom(zoom)
--         zoom = zoom - 0.1
--     elseif y < 0 then
--         zoom = zoom - 0.1
--         currentZoom = currentZoom - 0.1
--
--         camera:zoom(zoom)
--         zoom = zoom + 0.1
--     end
-- end
-------------------------------------------------

local packs = 0
local packet = ''
local received = {}
local destination = ''

function Stage:update(dt)
  camera:update(dt)

  _syncX = gw*(0.5*(_camScale-1))
  _syncY = gh*(0.5*(_camScale-1))

  if _data then
    cmd, answ = _data:match("^(%S*) (.*)")

    if cmd == 'mapupdate' and answ ~= nil then

      local destN = answ:match("%b()")
      local destA = answ:match("%b[]")
      local currentNum = answ:match("%b{}")
      local doppel = false
------------
      if received == nil then
        table.insert(received, string.sub(currentNum, 2, string.len(currentNum) - 1))
        for i = 0, #received do
          if received[i] == string.sub(currentNum, 2, string.len(currentNum) - 1) then
            doppel = true
          end
        end

      else

        for i = 0, #received do
          if received[i] == string.sub(currentNum, 2, string.len(currentNum) - 1) then
            doppel = true
          end
        end

        if doppel == false then
          table.insert(received, string.sub(currentNum, 2, string.len(currentNum) - 1))
        end
      end

------------
      if destination == '' then
        destination = destA
      end

      if packs ~= tonumber(string.sub(destN, 2, string.len(destN)-1)) and destA == destination and doppel == false then
        packs = packs + 1
        packet = packet .. string.sub(answ, 1, string.len(answ) - string.len(destN))
        if packs == tonumber(string.sub(destN, 2, string.len(destN)-1)) then
          Stage:loadStage(packet)
          packet = ''
          packs = 0
          destination = ''
          received = {}
        end
      end

      cmd = nil
      answ = nil
      _data = nil
    end
  end
--------------------------------------------------------------------------------
  if _paused == false then

    camera.smoother = Camera.smooth.damped(5)

      if _currentInputField == nil or _currentInputField.active == false then

          if velocityX > 0 then
            velocityX = velocityX - stabilize
          elseif velocityX < 0 then
            velocityX = velocityX + stabilize
          end

          if velocityY > 0 then
            velocityY = velocityY - stabilize
          elseif velocityY < 0 then
            velocityY = velocityY + stabilize
          end

          if input:down('moveCameraUp') and _paused == false then
            velocityY = velocityY + camAccel
          end

          if input:down('moveCameraLeft') and _paused == false then
            velocityX = velocityX + camAccel
          end

          if input:down('moveCameraDown') and _paused == false then
            velocityY = velocityY - camAccel
          end

          if input:down('moveCameraRight') and _paused == false then
            velocityX = velocityX - camAccel
          end

          if velocityX > maxVelocity then
            velocityX = maxVelocity
          elseif velocityX < minVelocity then
            velocityX = minVelocity
          end

          if velocityY > maxVelocity then
            velocityY = maxVelocity
          elseif velocityY < minVelocity then
            velocityY = minVelocity
          end

          _camPosX = _camPosX + velocityX
          _camPosY = _camPosY + velocityY
        end

        _camWorldPosX, _camWorldPosY = camera:getWorldCoords(_camPosX, _camPosY) --camera movement
--------------------------------------------------------------------------------

        local count = 0

        if _masterMode == false then
          pI:update(dt)
          if pI:getActive() == true then
            count = count + 1
          end
        end

        if _masterMode == true then
          if mI:getActive() == true then
            count = count + 1
          elseif texSel:getActive() == true then
            count = count + 1
          end

        end

        if chat:getActive() == true then
          count = count + 1
        end

--------------------------------------------------------------------------------
    for i = 0, w-1 do
      for j = 0, h-1 do
        stageTileArr[i][j]:update(dt)
      end
    end

    for i = 0, #stageObjArr do
      if stageObjArr[i] ~= nil then
        stageObjArr[i]:update(dt)
      end
    end

    local objHovC = 0

    local objID = 1
    while stageObjArr[objID] ~= nil do
      stageObjArr[objID]:setID(objID)
      if stageObjArr[objID]:getActive() == true then
        count = count + 1
      end
      if stageObjArr[objID].hovering == true then
        objHovC = objHovC + 1
      end
      objID = objID + 1
    end

    for i = 1, #stageLightArr do
      if stageLightArr[i] ~= nil then
        stageLightArr[i]:update(dt)
      end
    end

    local lightID = 1
    while stageLightArr[lightID] ~= nil do
      stageLightArr[lightID]:setID(lightID)
      lightID = lightID + 1
    end

--------------------------------------------------------------------------------

if count > 0 then
  _mouseOnInterface = true
else
  _mouseOnInterface = false
end

count = 0

--------------------------------------------------------------------------------
    if _masterMode == true then
      mI:update(dt)
      if _editMode == true then
        texSel:update(dt)

        if _pressed == true and Stage:mouseInField() == true and _mouseOnInterface == false and _mode == 'obj' then

          if objHovC <= 1 then

            local objPosX = 0
            local objPosY = 0

            if string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'w' then
              objPosX = _mousePosX - _camPosX -gw*1.5 - (_currentTexture:getWidth())
              objPosY = _mousePosY - _camPosY -gh*1.5 - (_currentTexture:getHeight())
            else
              objPosX = _tilePosX
              objPosY = _tilePosY
              if _currentTexture:getHeight()*_texScale > _gridSize then
                objPosY = objPosY - (_currentTexture:getHeight()*_texScale - _gridSize)
              end
            end



            table.insert(stageObjArr, GameObj(objPosX, objPosY, _currentTexture, objID, _currentTextureID, string.sub(texSel:getObjType(_currentTextureID), 1, 1)))
            _pressed = false
          else

            _pressed = false

          end

        elseif _pressed == true and Stage:mouseInField() == true and _mouseOnInterface == false and _mode == 'light' then
          table.insert(stageLightArr, lightSource(_mousePosX - _camPosX -gw*1.5 -16, _mousePosY - _camPosY -gh*1.5 -16, 10, lightID))
          _pressed = false
        end

      end

    end

    chat:update(dt)
--------------------------------------------------------------------------------
  end
--------------------------------------------------------------------------------
    if _paused == true then
      pMenu:update()
      _mouseOnInterface = true
    end

    if input:pressed('esc') and _paused == false then
      _paused = true
    elseif input:pressed('esc') and _paused == true then
      _paused = false
    end

end
--==============================================================================

function Stage:draw()
  love.graphics.setCanvas(self.main_canvas)
    love.graphics.clear()
--------------------------------------------------------------------------------
    if _editMode == false then
      love.graphics.setShader(shader1)
    end
--------------------------------------------------------------------------------
  	camera:attach(_camPosX, _camPosY, gw*_camScale, gh*_camScale)
--------------------------------------------------------------------------------

      for i = 0, w-1 do -- draw tiles
        for j = 0, h-1 do
          stageTileArr[i][j]:draw()
        end
      end

      for i = 0, #stageObjArr do
        if stageObjArr[i] ~= nil then
          if stageObjArr[i].type == 'w' then
            if _objTransparency == true then
              love.graphics.setColor(1.0, 1.0, 1.0, 0.3)
            end
          end
          stageObjArr[i]:draw()
          love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
        end
      end

      if stageLightArr ~= nil then
        for i = 0, #stageLightArr do
          if stageLightArr[i] ~= nil then
            if _editMode == true then
              stageLightArr[i]:draw()
            end
            shader1:send("screen", {gw, gh})
            shader1:send("num_lights", #stageLightArr)
            shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].position", {stageLightArr[i]:getPos()})
            shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].diffuse", {1.0, 1.0, 1.0})
            shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].power", 128/2)
          else
            shader1:send("num_lights", 0)
          end
        end
      end
--------------------------------------------------------------------------------
        love.graphics.setShader()
--------------------------------------------------------------------------------
      xPosC = _xPosO
      yPosC = _yPosO

      love.graphics.setColor(0.3, 0.3, 0.3, 0.3) --grid color

      for i = 0, w-1 do
        for j = 0, h-1 do
          love.graphics.rectangle("line", xPosC, yPosC, _gridSize, _gridSize)

          yPosC = yPosC + _gridSize
        end
        xPosC = xPosC + _gridSize
        yPosC = _yPosO
      end
--==============================================================================
--==============================================================================

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0) -- restore color settings
--------------------------------------------------------------------------------
    camera:detach()
--------------------------------------------------------------------------------
    love.graphics.setCanvas()

--------------------------------------------------------------------------------
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.main_canvas, 0, 0, 0, sx, sy)
    love.graphics.setBlendMode('alpha')
--------------------------------------------------------------------------------
  chat:draw()

  if _masterMode == true then
    if _editMode == true then

      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
      if _mode == 'obj' and _currentTexture ~= nil and _paused == false and Stage:mouseInField() == true and _mouseOnInterface == false then

        local objPosX = _mousePosX - (_currentTexture:getWidth())
        local objPosY = _mousePosY - (_currentTexture:getHeight())

        love.graphics.draw(_currentTexture, objPosX , objPosY, 0, _texScale, _texScale)

        if string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'w' then
          love.graphics.line(objPosX + _currentTexture:getWidth()*_texScale/2, 0, objPosX + _currentTexture:getWidth()*_texScale/2, gh)
          love.graphics.line(0, objPosY + _currentTexture:getHeight()*_texScale/2, gw, objPosY + _currentTexture:getHeight()*_texScale/2)
        end
      end
      texSel:draw()
      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
      love.graphics.print('Zoom: ' .. currentZoom .. ' ' .. zoom .. '\n' .. tostring(texSel.getActive()) .. ' || ' .. _mousePosX .. '\n' .. _mousePosY .. '\n' .. 'Page: ' .. tostring(_currentPage) .. '\n' .. 'Cam. Pos.: ' .. -_camWorldPosX .. ' ' .. -_camWorldPosY .. '\n' .. _xPosO + gw*(0.5*(_camScale-1)) .. ' ' .. _yPosO + gh*(0.5*(_camScale-1)) .. '\n' .. tostring(_currentTextureSheet) .. ' ' .. tostring(_currentTexture) .. '\n' .. tostring(_mode) .. ' !:' .. tostring(Stage:mouseInField()) .. ' ' .. tostring(uMouse:getHover()) .. '\n' .. 'Time:' .. tostring(_currentTime) .. '\n' .. packet .. '\nPacks waiting: ' .. packs ..'\n' .. destination .. '\n' .. tostring(#received) .. '\n' .. tostring(received[0]) .. '\n' .. _tilePosX .. ' ' .. _tilePosY, _mousePosX + 40, _mousePosY)
    end
    mI:draw()
  else
    pI:draw()
  end

    if _paused == true then
      pMenu:draw()
    end
--------------------------------------------------------------------------------
end
--==============================================================================

function Stage:tileInitFill()
  idC = 0

  for i = 0, w-1 do
    stageTileArr[i] = {}
    for j = 0, h-1 do
      stageTileArr[i][j] = Tile()
      stageTileArr[i][j]:createTile(stageTileArr[i][j], _xPosO + _gridSize*i, _yPosO + _gridSize*j, idC)
      idC = idC + 1
    end
  end
end

function Stage:mouseInField()
  if -_camWorldPosX + _mousePosX >= _xPosO + _syncX and
   -_camWorldPosX + _mousePosX <= _xPosO + fw + _syncX and
    -_camWorldPosY + _mousePosY >= _yPosO + _syncY and
      -_camWorldPosY + _mousePosY <= _yPosO + fh + _syncY then
        if _mouseOnInterface == false then
          uMouse:setHover(true)
        end
        return true
  else
    if _mouseOnInterface == true then
      -- uMouse:setHover(false)
    else
      uMouse:setHover(false)
    end
    return false

  end
end

function Stage:receiveUDPData()

end

function Stage:removeAll()
  for i = 0, w-1 do -- draw tiles
    for j = 0, h-1 do
      if stageTileArr[i][j].texture ~= nil then
        stageTileArr[i][j].texture = nil
      end
    end
  end
  Stage:recDelete(stageObjArr)
  Stage:recDelete(stageLightArr)
end

function Stage:recDelete(arr)
  if arr ~= nil then
    while arr[1] ~= nil do
      table.remove(arr, 1)
    end
  end
end
--------------------------------------------------------------------------------
local loadActions =
{
  T = function(data, i, count)
    i = i + 1
    local slash = 0
    local id = ''
    local xp = ''
    local yp = ''
    local txid = ''
    local pg = ''
    while string.sub(data, i + count, i + count) ~= '|' do
      if string.sub(data, i + count, i + count) == '/' then
        slash = slash + 1
      elseif slash == 0 then
        id = id .. string.sub(data, i + count, i + count)
      elseif slash == 1 then
        xp = xp .. string.sub(data, i + count, i + count)
      elseif slash == 2 then
        yp = yp .. string.sub(data, i + count, i + count)
      elseif slash == 3 then
        txid = txid .. string.sub(data, i + count, i + count)
      elseif slash == 4 then
        pg = pg .. string.sub(data, i + count, i + count)
      end
      count = count + 1
    end

    i = i - 1

      for g = 0, w-1 do
        for k = 0, h-1 do
          if stageTileArr[g][k].ID == tonumber(id) then
            stageTileArr[g][k].textureID = tonumber(txid)
            stageTileArr[g][k].texturePage = tonumber(pg)
            stageTileArr[g][k]:setTexture(texSel:getTileTextureByID(tonumber(txid), tonumber(pg)))
          end
        end
      end

    i = i + count
    count = 0
    return i
  end,

  O = function(data, i, count)
    i = i + 1
    local slash = 0
    local id = ''
    local xp = ''
    local yp = ''
    local txid = ''
    local pg = ''
    while string.sub(data, i + count, i + count) ~= '|' do
      if string.sub(data, i + count, i + count) == '/' then
        slash = slash + 1
      elseif slash == 0 then
        id = id .. string.sub(data, i + count, i + count)
      elseif slash == 1 then
        xp = xp .. string.sub(data, i + count, i + count)
      elseif slash == 2 then
        yp = yp .. string.sub(data, i + count, i + count)
      elseif slash == 3 then
        txid = txid .. string.sub(data, i + count, i + count)
      elseif slash == 4 then
        pg = pg .. string.sub(data, i + count, i + count)
      end
      count = count + 1
    end

    i = i - 1

    table.insert(stageObjArr, GameObj(tonumber(xp), tonumber(yp), texSel:getObjTextureByID(tonumber(txid)), tonumber(id), tonumber(txid), pg))

    i = i + count
    count = 0
    return i
  end,

  L = function(data, i, count)
    i = i + 1
    local slash = 0

    local id = ''
    local xp = ''
    local yp = ''

    while string.sub(data, i + count, i + count) ~= '|' do
      if string.sub(data, i + count, i + count) == '/' then
        slash = slash + 1
      elseif slash == 0 then
        id = id .. string.sub(data, i + count, i + count)
      elseif slash == 1 then
        xp = xp .. string.sub(data, i + count, i + count)
      elseif slash == 2 then
        yp = yp .. string.sub(data, i + count, i + count)
      end
      count = count + 1
    end

    i = i - 1

    table.insert(stageLightArr, lightSource(tonumber(xp), tonumber(yp), 10, tonumber(id)))

    i = i + count
    count = 0
    return i
  end
}
--------------------------------------------------------------------------------
function Stage:loadStage(data)
  if data ~= nil then
    Stage:removeAll()
    local count = 0
    for i = 1, string.len(data) do
      if string.sub(data, i, i) == 'T' or string.sub(data, i, i) == 'O' or string.sub(data, i, i) == 'L' then
        i = loadActions[string.sub(data, i, i)](data, i, count)
      end
    end
  end
end
--------------------------------------------------------------------------------
function Stage:getData(path)
  if path then
    local file = io.open(path, "r")
    local data = file:read("*a")
    print(data)
    file:close()
    return data
  end
end

function Stage:saveStage(sendBool, name)
  local tileStr = ''
  local objStr = ''
  local lightStr = ''

  local sendArr = {}

  local counter = 1
  local counter2 = 1

  for i = 0, w-1 do
    for j = 0, h-1 do
      if stageTileArr[i][j].texture ~= nil then
        local node = 'T' .. stageTileArr[i][j].ID .. '/' .. stageTileArr[i][j].xPos .. '/' .. stageTileArr[i][j].yPos .. '/' .. stageTileArr[i][j].textureID .. '/' .. stageTileArr[i][j].texturePage .. '|'
        tileStr = tileStr .. node
        if counter == 1 then
          table.insert(sendArr, node)
          counter = counter + 1
        else
          sendArr[counter2] = sendArr[counter2] .. node
          counter = counter + 1
          if counter >= 30 then
            counter = 1
            counter2 = counter2 + 1
          end
        end
      end
    end
  end

  for i = 0, #stageObjArr do
    if stageObjArr[i] ~= nil then
      local node = 'O' .. stageObjArr[i].ID .. '/' .. stageObjArr[i].xPos .. '/' .. stageObjArr[i].yPos .. '/' .. stageObjArr[i].textureID .. '/' .. tostring(stageObjArr[i].type) .. '|'
      objStr = objStr .. node
      if counter == 1 then
        table.insert(sendArr, node)
        counter = counter + 1
      else
        sendArr[counter2] = sendArr[counter2] .. node
        counter = counter + 1
        if counter >= 30 then
          counter = 1
          counter2 = counter2 + 1
        end
      end
    end
  end

  for i = 0, #stageLightArr do
    if stageLightArr[i] ~= nil then
      local node = 'L' .. stageLightArr[i].ID .. '/' .. stageLightArr[i].xPos .. '/' .. stageLightArr[i].yPos .. '|'
      lightStr = lightStr .. node
      if counter == 1 then
        table.insert(sendArr, node)
        counter = counter + 1
      else
        sendArr[counter2] = sendArr[counter2] .. node
        counter = counter + 1
        if counter >= 30 then
          counter = 1
          counter2 = counter2 + 1
        end
      end
    end
  end

  if sendBool == 1 then
    file = io.open(name, "w+")
    file:write(tileStr .. objStr .. lightStr)
    file:close()
  elseif sendBool == 0 then --requires unique identificators
    for i = 1, #sendArr do
      local dg = string.format("%s %s", 'mapretransmit', sendArr[i] .. '(' .. tostring(#sendArr) .. ')' .. '[' .. tostring(_name) .. ']' .. '{' .. i .. '}')
      _socket:send(dg)
    end
  end

end
