TexSel = Object:extend()

local objModeBtn = Btn()

local mode = 0

local textures = {}
local xP = gw - 158
local yP = 0
local height = gh - 192
local textureContainer = {}
local tileTextureSheets = {}
local objTextureSheets = {}
local objTypes = {}

local prev_height = 0
local inv_height = 0

local scrollPos = 0

_currentPage = 1
_sheetW = 0
_sheetH = 0

local active = false

local textureWindow = IngameWindow()
  textureWindow:createNewWindow(textureWindow, xP, yP, 128, height)

local tileScroller = Scroller()
  tileScroller:getParameters(tileScroller, gw - 30, 0, 30, height - 50, 64)

  tileSelectorCanvas = love.graphics.newCanvas(128, height - 50)

local tileSelector = SelectorList()
  tileSelector:getParameters(tileSelector, 'pic/tiles', xP - 200, yP, 200, 200, 1)

local objSelector = SelectorList()
  objSelector:getParameters(objSelector, 'pic/obj', xP - 72, yP, 200, height - 50)

_currentTextureName = {}

function TexSel:new()
  tileselected = love.graphics.newImage('pic/HUD/tileSelected.png')

  objModeBtn:getParameters(objModeBtn, xP + 15, height - 40, 100, 30, ">Tile", 0, "texMode")

  TexSel:getTextures('pic/tiles', tileTextureSheets)
  TexSel:getTextures('pic/obj', objTextureSheets, true)
--------------------------------------------------------------------------------
  TexSel:setTextureContainer()
--------------------------------------------------------------------------------
end

function TexSel:getTextures(folder, texture_list, md)
  local items = love.filesystem.getDirectoryItems(folder)
  for _, item in ipairs(items) do
      local file = folder .. '/' .. item
      if love.filesystem.getInfo(file, 'file') then
          table.insert(texture_list, love.graphics.newImage(file))
          table.insert(_currentTextureName, file)
          if md then
            table.insert(objTypes, md)
          end
      elseif love.filesystem.getInfo(file, 'directory') then
        if md then
          TexSel:getTextures(file, texture_list, item)
        else
          TexSel:getTextures(file, texture_list)
        end
      end
  end
end

function TexSel:setTextureContainer()
  TexSel:setQuads()
  _currentTextureID = 1
  _currentTexture = textures[_currentTextureID]
  local counter = 1
  for i = 0, 1 do
    textureContainer[i] = {}
    for j = 0, (_sheetW*_sheetH) / 2 - 1 do
      textureContainer[i][j] = textures[counter]
      counter = counter + 1
    end
  end
end

function TexSel:getObjType(id)
  return objTypes[id]
end

function TexSel:getTileTextureByID(id, page)
  _currentPage = page
  tileSelector:setActiveID(tileSelector, _currentPage)
  TexSel:setTextureContainer()
  return textures[id], tileTextureSheets[page]
end

function TexSel:getObjTextureByID(id)
  return objTextureSheets[id]
end

function TexSel:setQuads()

  if tileTextureSheets[_currentPage] == nil then
    _currentPage = 1
  end

  _sheetW = tileTextureSheets[_currentPage]:getWidth() / 16
  _sheetH = tileTextureSheets[_currentPage]:getHeight() / 16

  local counter = 1
  for i = 1, _sheetW do
    for j = 1, _sheetH do
      textures[counter] = love.graphics.newQuad(16*i - 16, 16*j - 16, 16, 16, tileTextureSheets[_currentPage]:getDimensions())
      counter = counter + 1
    end
  end

  if (counter / 2) * 64 > height - 50 then
    inv_height = (counter/2*64) - (height - 50)
    prev_height = inv_height

    if inv_height > height - 50 then
      local inc_per = ((inv_height / height - 50) / 2 * 100) - ((prev_height / height - 50) / 2 * 100)
      tileScroller.boxHeight = tileScroller.boxHeight - (tileScroller.boxHeight / 100) * inc_per --Rework later

      if tileScroller.boxHeight < tileScroller.minBoxHeight then
        tileScroller.boxHeight = tileScroller.minBoxHeight
      end

      local steps = inv_height / 64 - counter / 2
      tileScroller.scroll_step = (tileScroller.height-tileScroller.boxHeight)/steps

    end
  end

  _currentTextureSheet = tileTextureSheets[_currentPage]
end
--==============================================================================
function TexSel:update(dt)
  textureWindow:update(dt)
  active = textureWindow:checkActive()


  if _mode == 'tile' then

    tileSelector:update(dt)

    _sheetW = tileTextureSheets[_currentPage]:getWidth() / 16
    _sheetH = tileTextureSheets[_currentPage]:getHeight() / 16

    _currentPage = tileSelector.activeID

    if inv_height > height - 50 then
      scrollPos = scrollPos + tileScroller.wheel_move

      if scrollPos > -164 then
        scrollPos = -64
      elseif -inv_height + height - 50 > scrollPos then
        scrollPos = -inv_height + height - 50
      end

    end
      tileScroller.wheel_move = 0

    if tileSelector.listWindow:checkActive() == true then
      active = true
    end

    tileScroller:update()

    if tileSelector.updated == false then
      TexSel:setTextureContainer()
      tileSelector.updated = true
    end
  end

  TexSel:mouseOnTextureCheck()

  if _mode == 'obj' then
    objSelector:update(dt)

    if objSelector.listWindow:checkActive() == true then
      active = true
    end

    if objSelector.updated == false then
      _currentTextureID = objSelector.activeID
      _currentTexture = objTextureSheets[_currentTextureID]
      objSelector.updated = true
    end


  end

  objModeBtn:update(dt)

end
--==============================================================================
function TexSel:draw()
--------------------------------------------------------------------------------
  if _mode == 'tile' then

    xP = gw - 158
    textureWindow.xPos = xP
    textureWindow.width = 158
    textureWindow:draw()

    tileSelector:draw()
    tileScroller:draw()

    love.graphics.setCanvas(tileSelectorCanvas)
    love.graphics.clear()

    local counter = 1;
      for i = 0, 1 do
        for j = 0, (_sheetW*_sheetH)/2 - 1 do
          if textureContainer[i][j] ~= nil then
            love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
              love.graphics.draw(_currentTextureSheet, textureContainer[i][j], 0 + 64*i, -scrollPos + 64*j, 0, _texScale, _texScale)
            else
              love.graphics.print(tostring(inv_height), 0 + 64*i, -scrollPos + 64*j)
          end
          if counter == _currentTextureID then
            love.graphics.draw(tileselected, 0 + 64*i, -scrollPos + 64*j, 0, 4, 4)
          end
          counter = counter + 1
        end
      end
    love.graphics.setCanvas()

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(tileSelectorCanvas, xP, 0)
    love.graphics.setBlendMode('alpha')


  end
--------------------------------------------------------------------------------
  if _mode == 'obj' then

    xP = gw - 230
    textureWindow.xPos = xP
    textureWindow.width = 230
    textureWindow:draw()

    objSelector:draw()

  end
--------------------------------------------------------------------------------
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

    objModeBtn:draw()

end
--==============================================================================
function TexSel:resetCurrentTexture()
  if _mode == 'tile' then
    _currentTexture = textureContainer[0][0]
    _currentTextureSheet = tileTextureSheets[1]
    _currentTextureID = 1
  else
    _currentTexture = objTextureSheets[1]
  end
end
--==============================================================================
function TexSel:mouseOnTextureCheck()
--------------------------------------------------------------------------------
  if _mode == 'tile' then
    local counter = 1
    for i = 1, 2 do
      for j = 1, (_sheetW*_sheetH/2) do

        if _mousePosX >= xP and
         _mousePosX <= xP + i*64 and
          _mousePosY >= yP -scrollPos and
            _mousePosY <= yP + j*64 -scrollPos
            and
            yP + j*64 -scrollPos <= height - 50
            then


              uMouse:setHover(true)
              if  _pressed == true  then
                _currentTexture = textures[counter]
                _currentTextureID = counter
                _pressed = false
                goto done
              end
        end
        counter = counter + 1
      end
    end
--------------------------------------------------------------------------------
  else
    active = false
  end

  ::done::

  if _mode == 'light' and _mouseOnInterface == false then
    uMouse:setHover(true)
  end
--------------------------------------------------------------------------------
end

function TexSel:getActive()
  return active
end

return TexSel
