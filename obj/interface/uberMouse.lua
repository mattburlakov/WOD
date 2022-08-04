UberMouse = Object:extend()

_tilePosX = 0
_tilePosY = 0

love.mouse.setVisible(false)

local hovering = false

function UberMouse:new()
  mouseIdle = love.graphics.newImage('pic/HUD/mouse_0.png')
  mouseHover = love.graphics.newImage('pic/HUD/mouse_1.png')

  accessAnim = newAnimation(love.graphics.newImage("pic/HUD/mouse_2.png"), 16, 16, 1)
  lightAnim = newAnimation(love.graphics.newImage("pic/HUD/mouse_3.png"), 16, 16, 1)

  _pressed = false
  _Rpressed = false
  _mouseOnInterface = false
  _mode = 'tile'
  _accessingObj = false
  _justAcessed = false
  _accWall = false
  _currentTime = 0
  _hoversObj = false

end

function love.mousereleased(x, y, mouse1) -- released or pressed ?
  if (hovering == true or _mouseOnInput == true) and mouse1 == 1 and _accessingObj == false and _justAcessed == false then
    _pressed = true
  else
    _pressed = false
    _justAcessed = false
  end
  if (hovering == true or _mouseOnInput == true) and mouse1 == 2 and _accessingObj == false then
    _Rpressed = true
  else
    _Rpressed = false
  end
end


function UberMouse:update(dt)

  if _accessingObj == true or _accWall == true then
  accessAnim.currentTime = _currentTime
    if accessAnim.currentTime >= accessAnim.duration then
        accessAnim.currentTime = accessAnim.currentTime - accessAnim.duration
    end
  end

  if _mode == 'light' then
    lightAnim.currentTime = lightAnim.currentTime + dt
      if lightAnim.currentTime >= lightAnim.duration then
          lightAnim.currentTime = lightAnim.currentTime - lightAnim.duration
      end
  end
---------------------- Requires rework
  -- if _editMode == true and _mode == 'obj' and _paused == false and string.sub(tostring(texSel:getObjType(_currentTextureID)), 1, 1) ~= 'w' then
  --
  --     if love.mouse.getX() % _objGrid == 0 then
  --       _mousePosX = love.mouse.getX()
  --       _wrldMousePosX = _mousePosX - _camPosX
  --       _obJWrldMousePosX = _wrldMousePosX - gw/2
  --     end
  --
  --     if love.mouse.getY() % _objGrid == 0 then
  --       _mousePosY = love.mouse.getY()
  --       _wrldMousePosY = _mousePosY - _camPosY
  --       _obJWrldMousePosY = _wrldMousePosY - gh/2
  --     end
  --
  -- else
    _mousePosX = love.mouse.getX()
    _mousePosY = love.mouse.getY()
    _wrldMousePosX = _mousePosX - _camPosX
    _wrldMousePosY = _mousePosY - _camPosY
    _obJWrldMousePosX = _wrldMousePosX - gw/2
    _obJWrldMousePosY = _wrldMousePosY - gh/2

  -- end
----------------------
end

function UberMouse:setHover(b)
  hovering = b
end

function UberMouse:getHover()
  return hovering
end

local animations = {}

function UberMouse:draw()
  love.graphics.setColor(1, 1, 1, 1)
  if _mode == 'light' and _mouseOnInterface == false and _editMode == true and _mouseOnInterface == false then
    local spriteNum = math.floor(lightAnim.currentTime / lightAnim.duration * #lightAnim.quads) + 1
    love.graphics.draw(lightAnim.spriteSheet, lightAnim.quads[spriteNum], _mousePosX - 28, _mousePosY - 28, 0, _texScale, _texScale)
  elseif  hovering == false and _accessingObj == false and _accWall == false then
    love.graphics.draw(mouseIdle, _mousePosX - 28, _mousePosY - 28, 0, _texScale, _texScale)
  elseif (hovering == true or _mouseOnInterface == true) and _accessingObj == false and _accWall == false then
    love.graphics.draw(mouseHover, _mousePosX - 28, _mousePosY - 28, 0, _texScale, _texScale)
  elseif _accessingObj == true or _accWall == true then
    local spriteNum = math.floor(accessAnim.currentTime / accessAnim.duration * #accessAnim.quads) + 1
    love.graphics.draw(accessAnim.spriteSheet, accessAnim.quads[spriteNum], _mousePosX - 28, _mousePosY - 28, 0, _texScale, _texScale)
  end
  -- love.graphics.print(tostring(_mouseOnInterface) .. " " .. tostring(_editMode), _mousePosX, _mousePosY)
end

function UberMouse:mouseInPolygon(x, y, w, h)
  if _obJWrldMousePosX >= x and
    _obJWrldMousePosX <= x + w and
    _obJWrldMousePosY >= y and
    _obJWrldMousePosY <= y + h then
      return true
    else
      return false
    end
end

return UberMouse
