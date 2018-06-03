local garages = {
	{ ['x'] = 455.40682983398, ['y'] = -1016.9927368164, ['z'] = 28.412754058838 },
}

local menu = {
	{
		name = "Sports",
		vehicles = {
			{
				name = "9F",
				price = 2000,
				model = "ninef",
			}
		}
	},
	{
		name = "Super",
		vehicles = {
			{
				name = "Adder",
				price = 2000,
				model = "adder",
			},
			{
				name = "FMJ",
				price = 2000,
				model = "fmj",
			}
		}
	}
}

local inGarage = false
local currentMenu = "menu"
local selected = 0
local owned = {}

function DisplayHelpText(str)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentScaleform(str)
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

function drawText(top, left, size, str, color, font, center)
	SetTextFont(font or 0)
	SetTextScale(1, size)
	SetTextColour(color[1], color[2], color[3], color[4])
	if center then SetTextCentre(true) end
	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(tostring(str))
	EndTextCommandDisplayText(left, top)
end

RegisterNetEvent('es_garages:notify')
AddEventHandler('es_garages:notify', function(str)
	SetNotificationTextEntry("STRING")
	AddTextComponentSubstringPlayerName(str)
	DrawNotification(false, false)
end)

RegisterNetEvent('es_garages:owned')
AddEventHandler('es_garages:owned', function(tab)
	for i in ipairs(tab) do
		owned[tab[i]] = true

		Citizen.Trace(tab[i] .. "\n")
	end
end)

RegisterNetEvent('es_garages:spawnVehicle')
AddEventHandler('es_garages:spawnVehicle', function(carid)
	Citizen.CreateThread(function()
		local playerPed = GetPlayerPed(-1)
		FreezeEntityPosition(GetPlayerPed(-1), false)

		Citizen.Trace(carid .. " <- Spawn\n")
		RequestModel(GetHashKey(carid))
		while not HasModelLoaded(GetHashKey(carid)) do
			Citizen.Wait(0)
		end
		local playerCoords = GetEntityCoords(playerPed, false)

		inGarage = false
		currentMenu = "menu"
		selected = 0

		local veh = CreateVehicle(GetHashKey(carid), playerCoords.x, playerCoords.y, playerCoords.z - 1.0, 0.0, true, false)
		TaskWarpPedIntoVehicle(playerPed, veh, -1)
		SetVehicleDirtLevel(veh, 0)
		SetVehicleEngineOn(veh, true, true)

		return
	end)
end)

RegisterNetEvent('es_garages:newOwned')
AddEventHandler('es_garages:newOwned', function(veh)
	owned[veh] = true
end)

Citizen.CreateThread(function()
	while true do
		local p = GetEntityCoords(GetPlayerPed(-1), true)
		for i in ipairs(garages) do
			local garage = garages[i]
			DrawMarker(1, garage.x, garage.y, garage.z - 1, 0, 0, 0, 0, 0, 0, 3.4001, 3.4001, 0.8001, 0, 75, 255, 165, 0,0, 0,0)
		
			if (Vdist(garage.x, garage.y, garage.z, p.x, p.y, p.z) < 2.4) then

				if not inGarage then
					if(IsPedInAnyVehicle(GetPlayerPed(-1), false))then
						DisplayHelpText("Please leave your vehicle first.")
					else
						DisplayHelpText("Press ~INPUT_CONTEXT~ to access the garage")

						if IsControlJustPressed(1, 51) then
							inGarage = true

							FreezeEntityPosition(GetPlayerPed(-1), true)
						end
					end
				else
					if currentMenu == "menu" then
						DrawRect(0.15, 0.15, 0.23, 0.05, 0, 0, 0, 255)
						drawText(0.13, 0.153, 0.5, "Garage", {255, 255, 255, 255}, 0, true)
						
						local cur = 0
						for i in ipairs(menu) do
							if cur == selected then DrawRect(0.15, 0.20 + (0.05 * cur), 0.23, 0.05, 40, 40, 40, 200) else DrawRect(0.15, 0.20 + (0.05 * cur), 0.23, 0.05, 100, 100, 100, 200) end
							drawText(0.18 + (0.05 * cur), 0.153, 0.5, "" .. menu[i].name, {255, 255, 255, 255}, 0, true)
							cur = cur + 1
						end
					else
						DrawRect(0.15, 0.15, 0.23, 0.05, 0, 0, 0, 255)
						drawText(0.13, 0.153, 0.5, "" .. menu[currentMenu + 1].name, {255, 255, 255, 255}, 0, true)

						local cur = 0
						for i in ipairs(menu[currentMenu + 1].vehicles) do
							if cur == selected then DrawRect(0.15, 0.20 + (0.05 * cur), 0.23, 0.05, 40, 40, 40, 200) else DrawRect(0.15, 0.20 + (0.05 * cur), 0.23, 0.05, 100, 100, 100, 200) end
							drawText(0.18 + (0.05 * cur), 0.042, 0.5, "" .. menu[currentMenu + 1].vehicles[i].name, {255, 255, 255, 255}, 0, false)
							
							if(owned[menu[currentMenu + 1].vehicles[i].model])then
								drawText(0.18 + (0.05 * cur), 0.182, 0.5, "owned", {255, 255, 255, 255}, 0, false)
							else
								drawText(0.18 + (0.05 * cur), 0.182, 0.5, "$" .. menu[currentMenu + 1].vehicles[i].price, {255, 255, 255, 255}, 0, false)
							end
							cur = cur + 1
						end
					end

					if IsControlJustReleased(1, 173) then
						if currentMenu == "menu" then
							if selected < (#menu - 1) then
								selected = selected + 1
							end
						else
							if selected < (#menu[currentMenu + 1].vehicles - 1) then
								selected = selected + 1
							end
						end
					end

					DisableControlAction(1, 27, true)

					if IsDisabledControlJustPressed(1, 172) then
						if selected ~= 0 then
							selected = selected - 1
						end
					end

					if IsControlJustReleased(1, 176) then
						if currentMenu == "menu" then
							currentMenu = selected
							selected = 0
						else
							TriggerServerEvent('es_garages:selectVehicle', menu[currentMenu + 1].vehicles[selected + 1].model)
						end
					end

					if IsControlJustReleased(1, 177) then
						if currentMenu ~= "menu" then
							currentMenu = "menu"
							selected = 0
						else
							inGarage = false
							FreezeEntityPosition(GetPlayerPed(-1), false)
						end
					end
				end
			end
		end

		Citizen.Wait(0)
	end
end)