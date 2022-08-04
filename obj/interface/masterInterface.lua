MI = Object:extend()

local xP = 0
local yP = gh - 192

local active = false
_name = 'stage'

_objTransparency = false

local editModeBtn = Btn()
local lightMode = Btn()
local saveMapBtn = Btn()
local loadMapBtn = Btn()
local sendMapBtn = Btn()
local playerStateBtn = Btn()
local clearMapBtn = Btn()
local toggleObj = Btn()

local masterWindow = IngameWindow()
  masterWindow:createNewWindow(masterWindow, xP, yP, gw/2, 192)

local mapList = SelectorList()
  mapList:getParameters(mapList, 'stages/saved_data', xP + 246, yP, 200, 192)

local mapName = InputField()
  mapName:getParameters(mapName, xP + 16, yP + 106, 210, 30, 'Stage name to save', 40)

function MI:new()
  editModeBtn:getParameters(editModeBtn, xP + 16, yP + 16, 100, 30, ">Editor_", nil, "editorSwitch") --
  lightMode:getParameters(lightMode, xP + 126, yP + 16, 100, 30, ">Place_light_", nil, "lightModeSwitch") --
  saveMapBtn:getParameters(saveMapBtn, xP + 126, yP + 56, 100, 30, ">Save_map_", _name, "saveMap") --
  loadMapBtn:getParameters(loadMapBtn, xP + 16, yP + 56, 100, 30, ">Load_map_", nil, "loadMap") --
  sendMapBtn:getParameters(sendMapBtn, xP + 16, yP + 146, 100, 30, ">Send_to_all_", nil, "sendMap") --
  clearMapBtn:getParameters(clearMapBtn, xP + 500, yP + 16, 100, 30, ">Clear_", nil, "clearMap") --
  toggleObj:getParameters(toggleObj, xP + 500, yP + 56, 100, 30, ">Transparency_", nil, "toggleObj") --

  mapName:setData(mapList:getName())

end

function MI:update(dt)
  editModeBtn:update(dt)
  saveMapBtn:update(dt)
  loadMapBtn:update(dt)
  sendMapBtn:update(dt)
  clearMapBtn:update(dt)
  toggleObj:update(dt)

  mapList:update(dt)
  if mapList.updated == false then
    loadMapBtn:setData(loadMapBtn, mapList:getData())
    _name= mapList:getName()
  end

  masterWindow:update(dt)
  mapName:update(dt, mapName)

  if mapName.active == true and input:pressed('apply') then
    mapName.active = false
    _name = mapName:returnSelfData()
    if string.sub(_name, string.len(_name) - 4, string.len(_name)) ~= '.map' then
      _name = _name .. '.map'
    end
    saveMapBtn:setData(saveMapBtn, 'stages/saved_data/' .. _name)
  else
    if mapName.active == false and mapName:checkInitial() == true then
      mapName:setData(mapList:getName())
      saveMapBtn:setData(saveMapBtn, 'stages/saved_data/' .. mapName:returnSelfData())
    end
  end

  active = mapName.active
  active = masterWindow:checkActive()

  if _editMode == true then
    lightMode:update(dt)
  end

end

function MI:updateSelectorList()
  mapList:getList(mapList)
  mapList:updateList(mapList)
end

function MI:draw()
  masterWindow:draw()
  mapList:draw()
  mapName:draw()
  editModeBtn:draw()
  lightMode:draw()
  loadMapBtn:draw()
  saveMapBtn:draw()
  sendMapBtn:draw()
  clearMapBtn:draw()
  toggleObj:draw()
end

function MI:getActive()
  return active
end

return MI
