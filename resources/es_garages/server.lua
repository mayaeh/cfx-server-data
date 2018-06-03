local vehicles = {
	ninef = 2000,
	fmj = 2000,
	adder = 2000
}

local owned = {}

AddEventHandler('onResourceStart', function(res)
	if(res == "es_garages")then
		SetTimeout(2000, function()
			TriggerEvent('es:exposeDBFunctions', function(db)
				TriggerEvent('es:getPlayers', function(players)
					for i in pairs(players)do
						local user = players[i]
						db.getDocumentByRow('es_garages', 'identifier', user.identifier, function(dbuser)
							owned[i] = dbuser.vehicles

							TriggerClientEvent('es_garages:owned', i, owned[i])
						end)
					end
				end)
			end)
		end)
	end
end)

AddEventHandler('es:playerLoaded', function(source, user)
	TriggerEvent('es:exposeDBFunctions', function(db)
		db.getDocumentByRow('es_garages', 'identifier', user.identifier, function(dbuser)
			if(dbuser)then
				owned[source] = dbuser.vehicles
			else
				owned[source] = {}
			end

			TriggerClientEvent('es_garages:owned', source, owned[source])
		end)
	end)
end)

RegisterServerEvent('es_garages:selectVehicle')
AddEventHandler('es_garages:selectVehicle', function(veh)
	if(vehicles[veh])then
		TriggerEvent('es:getPlayerFromId', source, function(user)
			local ownedV = false

			for e in ipairs(owned[source])do
				if(owned[source][e] == veh)then
					ownedV = true
				end
			end

			if not ownedV then
				if(user.money >= vehicles[veh])then
					TriggerClientEvent('es_garages:newOwned', source, veh)
					TriggerClientEvent('es_garages:notify', source, "Vehicle bought")
					user:removeMoney(vehicles[veh])

					TriggerEvent('es:exposeDBFunctions', function(db)
						db.getDocumentByRow('es_garages', 'identifier', user.identifier, function(dbuser)
							dbuser.vehicles[#dbuser.vehicles + 1] = veh
							db.updateDocument('es_garages', dbuser._id, {vehicles = dbuser.vehicles}, function()
								owned[source] = dbuser.vehicles
							end)
						end)
					end)
				else
					TriggerClientEvent('es_garages:notify', source, "Not enough money")
				end
			else
				TriggerClientEvent('es_garages:spawnVehicle', source, veh)
				TriggerClientEvent('es_garages:notify', source, "Owned vehicle spawned")
			end
		end)
	end
end)

TriggerEvent('es:exposeDBFunctions', function(db)
	db.createDatabase('es_garages', function()end)
end)

AddEventHandler('es:newPlayerLoaded', function(source, user)
	TriggerEvent('es:exposeDBFunctions', function(db)
		db.createDocument('es_garages', {identifier = user.identifier, vehicles = {}}, function()end)
	end)	
end)