TextSel = require 'obj/interface/textureselector'
MI = require 'obj/interface/masterInterface'
PI = require 'obj/interface/playerInterface'
PauseMenu = require 'obj/interface/pauseMenu'
ChatBox = require 'obj/interface/chat'
propWindow = require 'obj/interface/propWindow'

Tile = require 'obj/entities/Tile'
GameObj = require 'obj/entities/gameObject'
lightSource = require 'obj/entities/lightSource'
Player = require 'obj/entities/player'

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
local h = 50

local maxVelocity = 10
local minVelocity = -10
local velocityX = 0
local velocityY = 0
local camAccel = 1.5
local stabilize = 0.25

_gridSize = 64

_objGrid = 2

_texScale = 4
_camPosX = 0
_camPosY = 0

_camWorldPosX = 0
_camWorldPosY = 0

_paused = false
_editMode = false

_camScale = 4

local zoom = 1
local currentZoom = 1

love.mouse.setX(0)
love.mouse.setY(0)

local pWindow = propWindow()

function Stage:new()
  camera = Camera(0, 0)

  _xPosO, _yPosO = 0, 0 -- Base origin coords

  self.main_canvas = love.graphics.newCanvas(gw, gh)
  shader1 = love.graphics.newShader(lightShader_code)

  fw = _gridSize*w
  fh = _gridSize*h

  updateStr = ''

  stageTileArr = {} -- contains tileset

  stageWallArr = {}

  stageObjArr = {}
  stageLightArr = {}
  stagePlayerArr = {} -- (players, entities)

  mI = MI()
  pI = PI()
  pMenu = PauseMenu()
  texSel = TextSel()
  chat = ChatBox()

end

-----------------------------------------------
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
-----------------------------------------------

local packs = 0
local packet = ''
local received = {}
local destination = ''

insertActions =
{
  tile = function(tileID)
    for i = 0, w - 1 do
      for j = 0, h - 1 do
        if uMouse:mouseInPolygon(0 + _gridSize*i, 0 + _gridSize*j, _gridSize, _gridSize) == true then
          table.insert(stageTileArr, Tile(_gridSize*i, _gridSize*j, tileID, _currentTextureID, _currentPage, _currentTexture, _currentTextureSheet))
        end
      end
    end
    _pressed = false
  end,

  obj = function(objID, objHovC)
    if objHovC <= 1 then

      local objPosX = 0
      local objPosY = 0

      if string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'w' and string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'd' then
        objPosX = _obJWrldMousePosX - (_currentTexture:getWidth())
        objPosY = _obJWrldMousePosY - (_currentTexture:getHeight())
      else
        objPosX = _tilePosX
        objPosY = _tilePosY
      end

      table.insert(stageObjArr, GameObj(objPosX, objPosY, _currentTexture, objID, _currentTextureID, string.sub(texSel:getObjType(_currentTextureID), 1, 1)))
      _pressed = false
    else
      _pressed = false
    end
  end,

  light = function(lightID)
    table.insert(stageLightArr, lightSource(_obJWrldMousePosX -16, _obJWrldMousePosY -16, 10, lightID))
    _pressed = false
  end
}

cmdActions =
{
  mapupdate = function(answ)
    local destN = answ:match("%b()")
    local destA = answ:match("%b[]")
    local currentNum = answ:match("%b{}")
    local doppel = false

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
  end,

  update = function(answ)

  end,

  updateid = function(answ)

  end,

  firstconnect = function(answ)
    _clientID = tonumber(string.sub(answ:match("%b[]"), 2, 2))

    table.insert(stagePlayerArr, Player(0, 0, _clientID, name))

    for i = 1, string.len(answ) - 3 do

      local index = ''
      local xPos = ''
      local yPos = ''
      local count = 0
      local slash = 0

        while string.sub(answ, i + count, i + count) ~= '|' do
          if string.sub(answ, i + count, i + count) == '/' then
            slash = slash + 1
          elseif slash == 0 then
            index = index .. string.sub(answ, i + count, i + count)
          elseif slash == 1 then
            xPos = xPos .. string.sub(answ, i + count, i + count)
          elseif slash == 2 then
            yPos = yPos .. string.sub(answ, i + count, i + count)
          end
          count = count + 1
        end

        if tonumber(index) ~= nil and tonumber(xPos) ~= nil and tonumber(yPos) ~= nil then
          table.insert(stagePlayerArr, Player(tonumber(xPos), tonumber(yPos), tonumber(index)))
        end

      i = i + count
      count = 0
    end
  end,

  playerupdate = function(answ)
      local index = ''
			local xPos = ''
			local yPos = ''
			local i = 1
			local count = 0
			local slash = 0

			while string.sub(answ, i + count, i + count) ~= '|' do
			  if string.sub(answ, i + count, i + count) == '/' then
				slash = slash + 1
			  elseif slash == 0 then
				index = index .. string.sub(answ, i + count, i + count)
			  elseif slash == 1 then
				xPos = xPos .. string.sub(answ, i + count, i + count)
			  elseif slash == 2 then
				yPos = yPos .. string.sub(answ, i + count, i + count)
			  end
			  count = count + 1
			end

			for i = 0, #stagePlayerArr do
				if stagePlayerArr[i] ~= nil then
					if stagePlayerArr[i].ID == tonumber(index) then
						stagePlayerArr[i].xPos = tonumber(xPos)
						stagePlayerArr[i].yPos = tonumber(yPos)
					end
				end
			end
  end,

  addplayer = function(answ)
    local index = ''
    local xPos = ''
    local yPos = ''
    local i = 1
    local count = 0
    local slash = 0

    while string.sub(answ, i + count, i + count) ~= '|' do
      if string.sub(answ, i + count, i + count) == '/' then
      slash = slash + 1
      elseif slash == 0 then
      index = index .. string.sub(answ, i + count, i + count)
      elseif slash == 1 then
      xPos = xPos .. string.sub(answ, i + count, i + count)
      elseif slash == 2 then
      yPos = yPos .. string.sub(answ, i + count, i + count)
      end
      count = count + 1
    end

    table.insert(stagePlayerArr, Player(tonumber(xPos), tonumber(yPos), tonumber(index)))
  end,

  removeplayer = function(answ)
    local counter = 0
    for i = 1, #stagePlayerArr do
      if stagePlayerArr[i] ~= nil then
        if stagePlayerArr[i]:getID() == tonumber(answ) then
          table.remove(stagePlayerArr, i)
          break
        end
      end
    end
  end
}

function Stage:update(dt)
  camera:update(dt)

  if _data then
    cmd, answ = _data:match("^(%S*) (.*)")

    if answ ~= nil and cmdActions[cmd] ~= nil then
      cmdActions[cmd](answ, packs, packet, received, destination)
      _data = nil
    end
  end

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

          _camPosX = math.floor(_camPosX + velocityX)
          _camPosY = math.floor(_camPosY + velocityY)
        end

        for i = 0, w - 1 do
          for j = 0, h - 1 do
            if uMouse:mouseInPolygon(_gridSize*i, _gridSize*j, _gridSize, _gridSize) == true then
              _tilePosX = _gridSize*i
              _tilePosY = _gridSize*j
            end
          end
        end


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


    for i = 0,  #stageTileArr do
      if stageTileArr[i]~= nil then
        stageTileArr[i]:update(dt)
      end
    end

    local tileID = 1
    while stageTileArr[tileID] ~= nil do
      stageTileArr[tileID]:setID(tileID)
      tileID = tileID + 1
    end

    for i = 0, #stageObjArr do
      if stageObjArr[i] ~= nil then
        stageObjArr[i]:update(dt)
      end
    end

    local objHovC = 0

    local objID = 1
    _activeObjID = nil
    while stageObjArr[objID] ~= nil do
      stageObjArr[objID]:setID(objID)
      if stageObjArr[objID]:getActive() == true then
        count = count + 1
        _activeObjID = objID
        propWindow:relocate(stageObjArr[objID]:getPos())
      end
      if stageObjArr[objID].hovering == true then
        objHovC = objHovC + 1
      end
      objID = objID + 1
    end

    if objHovC == 0 then
      _hoversObj = false
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

    local idList = {tile = tileID, obj = objID, light = lightID}


    for i = 0, #stagePlayerArr do
      if stagePlayerArr[i] ~= nil then
        stagePlayerArr[i]:update(dt)
      end
    end

if count > 0 then
  _mouseOnInterface = true
else
  _mouseOnInterface = false
end

count = 0

  if _masterMode == true then
      mI:update(dt)
      if _activeObjID ~= nil then
        pWindow:update(dt)
      end
      if _editMode == true then
        texSel:update(dt)
        if _pressed == true and Stage:mouseInField() == true and _mouseOnInterface == false then
          insertActions[_mode](idList[_mode], objHovC)
        end
      end
  else
      pI:update(dt)
  end
  chat:update(dt)
end

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

  local id
  for k = 0, #stagePlayerArr do
    if stagePlayerArr[k] ~= nil then
      if stagePlayerArr[k].ID == _clientID then
        id = k
      end
    end
  end


  love.graphics.setCanvas(self.main_canvas)
    love.graphics.clear()

    if _editMode == false then
      love.graphics.setShader(shader1)
    end

  	camera:attach()
    camera:lookAt(- _camPosX, - _camPosY)

    for i = 0, #stageTileArr do
      if stageTileArr[i] ~= nil then
        local isVisible = true
        -- for j = 1, #stageWallArr do
        --   if stageWallArr[j] ~= nil then
        --     if stagePlayerArr[id] ~= nil then
        --       if Stage:boxSegmentIntersection(stageWallArr[j].xPos, stageWallArr[j].yPos, stageWallArr[j].width, stageWallArr[j].height,
        --           stagePlayerArr[id].cX, stagePlayerArr[id].cY,
        --           stageTileArr[i].xPos + _gridSize, stageTileArr[i].yPos + _gridSize) ~= nil then
        --           isVisible = false
        --           break
        --       end
        --     end
        --   end
        -- end
        if isVisible == true or _editMode == true then
          stageTileArr[i]:draw()
        end
      end
    end

    love.graphics.setShader()

    love.graphics.setColor(1.0, 1.0, 1.0, 0.1)

    if _mode == 'tile' then
      for i = 0, w - 1 do
        for j = 0, h - 1 do
          if uMouse:mouseInPolygon(0 + _gridSize*i, 0 + _gridSize*j, _gridSize, _gridSize) == true then
            love.graphics.rectangle('fill', 0 + _gridSize*i, 0 + _gridSize*j, _gridSize, _gridSize)
          end
        end
      end
    end

    for i = 0, w - 1 do
      for j = 0, h - 1 do
        love.graphics.rectangle('line', 0 + _gridSize*i, 0 + _gridSize*j, _gridSize, _gridSize)
      end
    end

    if _editMode == false then
      love.graphics.setShader(shader1)
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

    for i = 0, #stageObjArr do
      if stageObjArr[i] ~= nil then
        if stageObjArr[i].type == 'w' then
          if _objTransparency == true then
            love.graphics.setColor(1.0, 1.0, 1.0, 0.3)
          end
        end
        if _editMode == false and stagePlayerArr[id] ~= nil then
          if stageObjArr[i].yPos > stagePlayerArr[id].yPos and stageObjArr[i].type ~= 'p' then

          elseif stageObjArr[i].type == 'p' then
            local isVisible = true
            for j = 1, #stageWallArr do
              if stageWallArr[j] ~= nil then
                if stagePlayerArr[id] ~= nil then
                  if Stage:boxSegmentIntersection(stageWallArr[j].xPos, stageWallArr[j].yPos, stageWallArr[j].width, stageWallArr[j].height,
                      stagePlayerArr[id].cX, stagePlayerArr[id].cY,
                      stageObjArr[i].xPos + stageObjArr[i].texture:getWidth()*_texScale, stageObjArr[i].yPos + stageObjArr[i].texture:getHeight()*_texScale) ~= nil then
                      isVisible = false
                      break
                  end
                end
              end
            end
            if isVisible == true then
              stageObjArr[i]:draw()
            end
          else
            stageObjArr[i]:draw()
          end
        else
          stageObjArr[i]:draw()
        end
        love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
      end
    end

    if stageLightArr ~= nil then
      for i = 0, #stageLightArr do
        if stageLightArr[i] ~= nil then
          if _editMode == true then
            stageLightArr[i]:draw()
          end

          local isVisible = true
          if _editMode == false then
            for j = 1, #stageWallArr do
              if stageWallArr[j] ~= nil then
                if stagePlayerArr[id] ~= nil then
                  if Stage:boxSegmentIntersection(stageWallArr[j].xPos, stageWallArr[j].yPos, stageWallArr[j].width, stageWallArr[j].height,
                      stagePlayerArr[id].cX, stagePlayerArr[id].cY,
                      stageLightArr[i].xPos + 8, stageLightArr[i].yPos + 8) ~= nil then
                      isVisible = false
                      break
                  end
                end
              end
            end
          end

          if isVisible == true then
              shader1:send("screen", {gw, gh})
              shader1:send("num_lights", #stageLightArr)
              shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].position", {stageLightArr[i]:getPos()})
              shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].diffuse", {0.9, 1.0, 1.0})
              shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].power", 50)
          else
              shader1:send("lights["..tostring(stageLightArr[i]:getID()-1).."].diffuse", {0.0, 0.0, 0.0})
          end
        end
      end
    else
      shader1:send("num_lights", 0)
    end

    if stagePlayerArr[id] ~= nil then
      shader1:send("screen", {gw, gh})
      shader1:send("num_lights", #stageLightArr + 1)
      shader1:send("lights["..tostring(#stageLightArr).."].position", {stagePlayerArr[id].cX + _camPosX + gw/2, stagePlayerArr[id].cY + _camPosY + gh/2})
      shader1:send("lights["..tostring(#stageLightArr).."].diffuse", {0.9, 1.0, 1.0})
      shader1:send("lights["..tostring(#stageLightArr).."].power", 95)
  end

    love.graphics.setShader()
    if _editMode == true then
      for i = 1, #stageWallArr do
        if stageWallArr[i] ~= nil then
          love.graphics.line(stageWallArr[i].xPos, stageWallArr[i].yPos, stageWallArr[i].xPos + stageWallArr[i].width, stageWallArr[i].yPos + stageWallArr[i].height)
        end
      end
    end

    if stagePlayerArr ~= nil then
      for i = 1, #stagePlayerArr do
        if stagePlayerArr[i].ID == _clientID then
          stagePlayerArr[i]:draw()
        else
          love.graphics.setShader(shader1)
          stagePlayerArr[i]:draw()
          love.graphics.setShader()
        end
      end
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0) -- restore color settings


    love.graphics.setCanvas()
    camera:detach()

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.main_canvas, 0, 0, 0, sx, sy)
    love.graphics.setBlendMode('alpha')

  chat:draw()

  if _masterMode == true then
    if _activeObjID ~= nil then
      pWindow:draw()
    end
    if _editMode == true then

      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
      if _mode == 'obj' and _currentTexture ~= nil and _paused == false and Stage:mouseInField() == true and _mouseOnInterface == false then

        local objPosX = _mousePosX - (_currentTexture:getWidth())
        local objPosY = _mousePosY - (_currentTexture:getHeight())

        love.graphics.draw(_currentTexture, objPosX , objPosY, 0, _texScale, _texScale)

        if string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'w' and string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'd' then
          love.graphics.line(objPosX + _currentTexture:getWidth()*_texScale/2, 0, objPosX + _currentTexture:getWidth()*_texScale/2, gh)
          love.graphics.line(0, objPosY + _currentTexture:getHeight()*_texScale/2, gw, objPosY + _currentTexture:getHeight()*_texScale/2)
        end
      end
      texSel:draw()
      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    end
    mI:draw()
  else
    pI:draw()
  end

    if _paused == true then
      pMenu:draw()
    end
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.print(
    '_clientID: ' .. _clientID ..
    '\n' .. '_hoversObj: ' .. tostring(_hoversObj) ..
    '\n' .. '_currentClient: ' .. tostring(_currentClient) ..
    '\n' .. 'R: ' .. tostring(_Rpressed) ..
    '\n' .. 'Zoom: ' .. currentZoom .. ' ' .. zoom .. '\n' .. _mousePosX .. ' ' .. _mousePosY ..
    '\n' .. 'Wrld pos: ' .. _wrldMousePosX .. ' ' .. _wrldMousePosY ..
    '\n' .. 'Obj pos: ' .. _obJWrldMousePosX .. ' ' .. _obJWrldMousePosY ..
    '\n' .. 'Page: ' .. tostring(_currentPage) ..
    '\n' .. 'Cam. Pos.: ' .. -_camPosX .. ' ' .. -_camPosY ..
    '\n' .. tostring(_currentTextureSheet) .. ' ' .. tostring(_currentTexture) ..
    '\n' .. tostring(_mode) .. ' !:' .. tostring(Stage:mouseInField()) .. ' ' .. tostring(uMouse:getHover()) ..
    '\n' .. 'Time:' .. tostring(_currentTime) .. '\n' .. packet ..
    '\n' .. 'Packs waiting: ' .. packs ..'\n' .. destination .. '\n' .. tostring(#received) .. '\n' .. tostring(received[0]) ..
    '\n' .. _tilePosX .. ' ' .. _tilePosY, _mousePosX + 40, _mousePosY)
end
--============================================================================== snippet

function Stage:boxSegmentIntersection(l,t,w,h, x1,y1,x2,y2)
  local dx, dy  = x2-x1, y2-y1

  local t0, t1  = 0, 1
  local p, q, r

  for side = 1,4 do
    if     side == 1 then p,q = -dx, x1 - l
    elseif side == 2 then p,q =  dx, l + w - x1
    elseif side == 3 then p,q = -dy, y1 - t
    else                  p,q =  dy, t + h - y1
    end

    if p == 0 then
      if q < 0 then return nil end  -- Segment is parallel and outside the bbox
    else
      r = q / p
      if p < 0 then
        if     r > t1 then return nil
        elseif r > t0 then t0 = r
        end
      else -- p > 0
        if     r < t0 then return nil
        elseif r < t1 then t1 = r
        end
      end
    end
  end

  local ix1, iy1, ix2, iy2 = x1 + t0 * dx, y1 + t0 * dy,
                             x1 + t1 * dx, y1 + t1 * dy

  if ix1 == ix2 and iy1 == iy2 then return ix1, iy1 end
  return ix1, iy1, ix2, iy2
end

--==============================================================================
function Stage:getDistance(x1, x2, y1, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx*dx + dy*dy)
end

function Stage:destroySelf()
  stageTileArr = nil

  stageObjArr = nil
  stageLightArr = nil
  stagePlayerArr = nil

  mI = nil
  pI = nil
  pMenu = nil
  texSel = nil
  chat = nil
end

function Stage:mouseInField()
  if _wrldMousePosX >= _xPosO + gw/2 and
   _wrldMousePosX <= _xPosO + fw + gw/2 and
    _wrldMousePosY >= _yPosO + gh/2 and
      _wrldMousePosY <= _yPosO + fh + gh/2 then
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

function Stage:removeAll()
  Stage:emptyArr(stageTileArr)
  Stage:emptyArr(stageObjArr)
  Stage:emptyArr(stageLightArr)
end

function Stage:emptyArr(arr)
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

    table.insert(stageTileArr, Tile(tonumber(xp), tonumber(yp), tonumber(id), tonumber(txid), tonumber(pg), texSel:getTileTextureByID(tonumber(txid), tonumber(pg))))

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
function Stage:loadStage(data, update)
  if data ~= nil then
    if update ~= true then
      Stage:removeAll()
    end
    local count = 0
    for i = 1, string.len(data) do
      if string.sub(data, i, i) == 'T' or string.sub(data, i, i) == 'O' or string.sub(data, i, i) == 'L' then
        i = loadActions[string.sub(data, i, i)](data, i, count)
      end
    end
    for i = 1, #stageTileArr do
      if stageTileArr[i] ~= nil then
        for j = 1, #stageTileArr do
          if stageTileArr[j] ~= nil then
            if stageTileArr[i].xPos + _gridSize == stageTileArr[j].xPos and
              stageTileArr[i].yPos == stageTileArr[j].yPos then
              stageTileArr[i].connections.right = true
            end
            if stageTileArr[i].xPos - _gridSize == stageTileArr[j].xPos and
              stageTileArr[i].yPos == stageTileArr[j].yPos then
              stageTileArr[i].connections.left = true
            end
            if stageTileArr[i].yPos + _gridSize == stageTileArr[j].yPos and
              stageTileArr[i].xPos == stageTileArr[j].xPos then
              stageTileArr[i].connections.bottom = true
            end
            if stageTileArr[i].yPos - _gridSize == stageTileArr[j].yPos and
              stageTileArr[i].xPos == stageTileArr[j].xPos then
              stageTileArr[i].connections.top = true
            end
          end
        end
      end
    end

    for i = 1, #stageTileArr do
      if stageTileArr[i] ~= nil then
        if stageTileArr[i].connections.top ~= true then
          table.insert(stageWallArr, {xPos = stageTileArr[i].xPos, yPos = stageTileArr[i].yPos, width = _gridSize, height = 1})
        end
        if stageTileArr[i].connections.bottom ~= true then
          table.insert(stageWallArr, {xPos = stageTileArr[i].xPos, yPos = stageTileArr[i].yPos + _gridSize, width = _gridSize, height = 1})
        end
        if stageTileArr[i].connections.left ~= true then
          table.insert(stageWallArr, {xPos = stageTileArr[i].xPos, yPos = stageTileArr[i].yPos, width = 1, height = _gridSize})
        end
        if stageTileArr[i].connections.right ~= true then
          table.insert(stageWallArr, {xPos = stageTileArr[i].xPos + _gridSize, yPos = stageTileArr[i].yPos, width = 1, height = _gridSize})
        end
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

  for i = 0, #stageTileArr do
      if stageTileArr[i] ~= nil then
        local node = 'T' .. stageTileArr[i].ID .. '/' .. stageTileArr[i].xPos .. '/' .. stageTileArr[i].yPos .. '/' .. stageTileArr[i].textureID .. '/' .. stageTileArr[i].texturePage .. '|'
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
