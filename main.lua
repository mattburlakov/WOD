Socket = require 'socket'
io = require 'io'
math = require 'math'

love.window.setMode(0, 0)

_gWidth, _gHeight = love.window.getDesktopDimensions(1)
gw = _gWidth
gh = _gHeight

Object = require 'lib/classic/classic'
Camera = require 'lib/hump/camera'
Shake = require 'obj/Shake'
Timer = require 'lib/hump/timer'
Input = require 'lib/boipushy/Input'

IngameWindow = require 'obj/interface/ingameWindow'
Scroller = require 'obj/interface/scroller'
UberMouse = require 'obj/interface/uberMouse'
Btn = require 'obj/interface/btn'
InputField = require 'obj/interface/inputField'
SelectorList = require 'obj/interface/selector'

StageTest = require 'stages/rooms/Stage'
Menu = require 'stages/rooms/menu'
Hub = require 'stages/rooms/hub'

require 'lib/utilits'

_clientName = 'test_1'
_status = 'Awaiting client connection request'
_clientID = 0

_address = "192.168.196.183"
_port = 55555

_socket = Socket.udp()
_socket:settimeout(0)

_updaterate = 0.1
_t = 0

local dT = 0

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest') --Graphics. 'Nearest' adds pixilated look. Must be at the top
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  uMouse = UberMouse()

  --Global update btn + player movement animation

  --Shadows under objects

  --utilize void

  --106747

  --Player model selection. Player render with small light aura.

  --relocate mastermode btn to hub

  --All obj are interactable and can contain stuff

  current_room = nil
  gotoRoom('Menu')

  input = Input()

  input:bind('escape', 'esc')

  input:bind('return', 'apply')

  input:bind('w', 'moveCameraUp')
  input:bind('a', 'moveCameraLeft')
  input:bind('s', 'moveCameraDown')
  input:bind('d', 'moveCameraRight')

end

function love.update(dt)

  dT = dt

  _t = _t + dt
  if _socket ~= nil then
    if _socket:getsockname() ~= nil then

          _data, msg = _socket:receive()
          if _data then
            Lcmd, Lansw = _data:match("^(%S*) (.*)")
          end

    end
  end

  uMouse:update(dt)


  if current_room then
     current_room:update(dt)
   end

end

function love.draw()
  love.graphics.setLineStyle('rough')
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.print(tostring(Lcmd) .. '\n' .. tostring(Lansw) .. '\n' .. dT)

  if current_room then
    current_room:draw()
  end

  uMouse:draw()

end

function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

function resize(s)
    love.window.setMode(s*gw, s*gh)
    sx, sy = s, s
end



function gotoRoom(room_type, ...)
    current_room = _G[room_type](...)
end
