RDX = nil

TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)

Citizen.CreateThread(function()
	Citizen.Wait(1000)
	local players = RDX.GetPlayers()

	for _,playerId in ipairs(players) do
		local xPlayer = RDX.GetPlayerFromId(playerId)

		MySQL.Async.fetchAll('SELECT status FROM users WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			local data = {}

			if result[1].status then
				data = json.decode(result[1].status)
			end

			xPlayer.set('status', data)
			TriggerClientEvent('rdx_status:load', playerId, data)
		end)
	end
end)

AddEventHandler('rdx:playerLoaded', function(playerId, xPlayer)
	MySQL.Async.fetchAll('SELECT status FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local data = {}

		if result[1].status then
			data = json.decode(result[1].status)
		end

		xPlayer.set('status', data)
		TriggerClientEvent('rdx_status:load', playerId, data)
	end)
end)

AddEventHandler('rdx:playerDropped', function(playerId, reason)
	local xPlayer = RDX.GetPlayerFromId(playerId)
	local status = xPlayer.get('status')

	MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
		['@status']     = json.encode(status),
		['@identifier'] = xPlayer.identifier
	})
end)

AddEventHandler('rdx_status:getStatus', function(playerId, statusName, cb)
	local xPlayer = RDX.GetPlayerFromId(playerId)
	local status  = xPlayer.get('status')

	for i=1, #status, 1 do
		if status[i].name == statusName then
			cb(status[i])
			break
		end
	end
end)

RegisterServerEvent('rdx_status:update')
AddEventHandler('rdx_status:update', function(status)
	local xPlayer = RDX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.set('status', status)
	end
end)

function SaveData()
	local xPlayers = RDX.GetPlayers()

	for i=1, #xPlayers, 1 do
		local xPlayer = RDX.GetPlayerFromId(xPlayers[i])
		local status  = xPlayer.get('status')

		MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
			['@status']     = json.encode(status),
			['@identifier'] = xPlayer.identifier
		})
	end

	SetTimeout(10 * 60 * 1000, SaveData)
end

SaveData()
