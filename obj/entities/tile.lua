Tile = Object:extend()

function Tile:new(x, y, i, txID, pg, t, s)
  self = self
  self.xPos = x
  self.yPos = y
  self.ID = i
  self.textureID = txID
  self.texturePage = pg
  self.texture = t
  self.textureSheet = s
  self.connections = {}
end

function Tile:createTile()


end

function Tile:setTexture(t, s)
  self.texture = t
  self.textureSheet = s
end


function Tile:update(dt)

  if self:mouseCheck(self) and not _mouseOnInterface == true then
        _tilePosX = self.xPos
        _tilePosY = self.yPos
        if _mode == 'tile' then
          self.mouseOnTile = true
          if _editMode == true then
            if _pressed == true then
              table.remove(stageTileArr, self.ID)
              self = nil
              _pressed = false
            end
          end
        end
  else
      self.mouseOnTile = false
  end

  -- if self:mouseCheck(self) and not _mouseOnInterface == true and _mode == 'movePlayer' then
  --       stagePlayerArr[_clientID]:reposition(self.xPos, self.yPos)
  -- end
end

function Tile:draw()
  if self.texture == nil then
    if _editMode == true then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(self.ID .. '\n', self.xPos, self.yPos)
    end
  else
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(self.textureSheet, self.texture, self.xPos, self.yPos, 0, _texScale, _texScale)
  end

  if self.mouseOnTile == true then
    love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
    love.graphics.rectangle('fill', self.xPos, self.yPos, _gridSize, _gridSize)
    love.graphics.setColor(1, 1, 1, 1)
  end

end

function Tile:mouseCheck(self)
  if _obJWrldMousePosX >= self.xPos and
    _obJWrldMousePosX <= self.xPos + _gridSize and
    _obJWrldMousePosY >= self.yPos and
    _obJWrldMousePosY <= self.yPos + _gridSize then
        if _mode == 'tile' then
          uMouse:setHover(true)
        end
        return true
      else
        return false
      end
end

function Tile:getID()
  return self.ID
end

function Tile:setID(id)
  self.ID = id
end

return Tile
