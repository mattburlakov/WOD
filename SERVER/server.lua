local Socket = require 'socket'

local udp = Socket.udp()
udp:settimeout(0)
udp:setsockname('192.168.196.183', 55555)

local world = {} -- the empty world-state
local data, msg_or_ip, port_or_nil
local entity, cmd, parms

local running = true

local maxConnections = 5

local connections = {}
local players = {}

local ip, prt = udp:getsockname()

function checkAddress(address)
	local d = true

		for i = 0, #connections do
			if connections[i] ~= nil then
				if connections[i].ip == address then
					d = false
				end
			end
		end

	return d
end

function getName(ipAddr)
	for i = 0, #connections do
		if connections[i] ~= nil then
			if connections[i].ip == ipAddr then
				return connections[i].name
			end
		end
	end
end

function sendToAll(msg, cmd)
	if connections ~= nil then
		for i = 1, #connections do
			if connections[i].ip ~= nil then
				local dg = string.format("%s %s", cmd, msg)
				udp:sendto(dg, tostring(connections[i].ip), connections[i].prt)
				print('Packet send' .. ' caused by "' .. cmd .. '" cmd : ' .. dg)
			end
		end
	end
end

function sendToAllExept(msg, cmd, exIP)
	for i = 1, #connections do
		if connections ~= nil then
			if connections[i].ip ~= exIP then
				local dg = string.format("%s %s", tostring(cmd), msg)
				udp:sendto(dg, tostring(connections[i].ip), connections[i].prt)
				print('Packet send' .. ' caused by ' .. cmd .. '. Sent ' .. #msg .. ' char.')
			end
		end
	end
end

function showAll()
	for i = 1, #connections do
		print(connections[i].ip)
	end
	print('|')
end


function firstconnect(ip, port, index)
	local packet = ''

	for i = 0, #connections do
		if connections[i] ~= nil then
			if connections[i].ip ~= ip then
				packet = packet .. connections[i].id .. '/' .. connections[i].xPos .. '/' .. connections[i].yPos .. '|'
			end
		end
	end

	packet = packet .. '[' .. index .. ']'
	print(string.len(packet))

	local dg = string.format("%s %s", 'firstconnect', packet)
	udp:sendto(dg, ip, port)

end

print ("Beginning server loop on " .. tostring(ip) .. ' ' .. prt)
while running do

  data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data ~= nil then
    ----------------------------------------------------------------------------
	local check = checkAddress(msg_or_ip)
		cmd, parms = data:match("^(%S*) (.*)")
		if cmd == 'connect'  and #connections < 5 and check == true  then

		--udp:sendto(string.format("%d", 1), msg_or_ip,  port_or_nil)
		local name = parms:match("^(%-?[%s]*)")

		  assert(name)
		  --Add connection to array
		  local index = 1
		  while connections[index] ~= nil do
			index = index + 1
		  end


		  table.insert(connections, {name = parms, ip = msg_or_ip, prt = port_or_nil, id = index, xPos = 0, yPos = 0, texture = 1})
		  print('Connected: ' .. tostring(connections[index].name) .. ' From: ' .. tostring(connections[index].ip) .. ' On port: ' .. tostring(connections[index].prt) .. '. Index: ' .. tostring(connections[index].id) .. ' ' .. tostring(check))
		  local anws
		  anws = string.format("%s %d", "anwser", 1)
		  udp:sendto(anws, msg_or_ip, port_or_nil)

		  firstconnect(msg_or_ip, port_or_nil, index)

		  anws = connections[index].id .. '/' .. connections[index].xPos .. '/' .. connections[index].yPos .. '|'
		  sendToAllExept(anws, 'addplayer', msg_or_ip)

		  print('Packet sent to ' .. tostring(msg_or_ip) .. ' ' .. tostring(port_or_nil) .. ':' .. anws )
		  msg = 'Connected : <' .. tostring(connections[index].name) .. '> !'
		  sendToAll(msg, 'chatmsg')

		  showAll()

		  elseif cmd == 'connect' then
			local anws
			anws = string.format("%s %d", "anwser", 0)
			udp:sendto(anws, msg_or_ip, port_or_nil)
			print('Packet sent' .. anws)
	----------------------------------------------------------------------------
		elseif cmd == 'disconnect' then
			for i = 1, #connections do
				if connections[i] ~= nil then
					if connections[i].ip == msg_or_ip then
						msg = 'Disconnected : <' .. tostring(connections[i].ip) .. '> !'
						local index = connections[i].id
						table.remove(connections, i)
						sendToAll(msg, 'chatmsg')
						sendToAll(index, 'removeplayer')
						print(msg)
						break
					end
				end
			end

			showAll()

			--if connections ~= nil then
				--for i = 1, #connections do
					--connections[i].id = i
				--end
			--end

	---------------------------------------------------------------------------- Getting chat messages and sending them to everyone
		elseif cmd == 'chatmsg' then
			print('Received message: ' .. tostring(parms))
			local msg = '<' .. getName(msg_or_ip) .. '> : ' .. tostring(parms)
			sendToAll(msg, 'chatmsg')

	----------------------------------------------------------------------------
		elseif cmd == 'mapretransmit' then
			print('Received: ' .. parms)
			sendToAllExept(parms, 'mapupdate', msg_or_ip)

	----------------------------------------------------------------------------
		elseif cmd == 'playerupdate' then
			local index = ''
			local xPos = ''
			local yPos = ''
			local i = 1
			local count = 0
			local slash = 0

			while string.sub(parms, i + count, i + count) ~= '|' do
			  if string.sub(parms, i + count, i + count) == '/' then
				slash = slash + 1
			  elseif slash == 0 then
				index = index .. string.sub(parms, i + count, i + count)
			  elseif slash == 1 then
				xPos = xPos .. string.sub(parms, i + count, i + count)
			  elseif slash == 2 then
				yPos = yPos .. string.sub(parms, i + count, i + count)
			  end
			  count = count + 1
			end

			for i = 0, #connections do
				if connections[i] ~= nil then
					if connections[i].id == tonumber(index) then
						connections[i].xPos = tonumber(xPos)
						connections[i].yPos = tonumber(yPos)
						print(connections[i].name .. ' moved to ' .. connections[i].xPos .. ' ' .. connections[i].yPos)
					end
				end
			end

			sendToAllExept(parms, cmd, msg_or_ip)

	----------------------------------------------------------------------------
		elseif cmd == 'update' then

		elseif cmd == 'quit' then
			running = false;
		else
			print("Unrecognised command or no slots available:", cmd)
			local anws
			anws = string.format("%s %d", "anwser", 0)
			udp:sendto(anws, msg_or_ip, port_or_nil)
			print('Packet sent')
		end
	elseif msg_or_ip ~= 'timeout' then
		print(msg_or_ip)
	end
socket.sleep(0.01)
end

print "Thank you."
