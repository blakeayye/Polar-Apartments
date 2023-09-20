local QBCore = exports['qb-core']:GetCoreObject()

local InApartment = false
local ClosestHouse = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentDoorBell = 0
local CurrentOffset = 0
local HouseObj = {}
local POIOffsets = {
    exit = vec4( -5.26,  -4.61,  -0.66,  179.79),
    clothes = vec3( -3.14, 4.224, -0.66),
    stash = vec3( -6.11, -0.06,  -1.16),
    logout = vec3(5000000000000000000000000.19,  -1.59,  -0.66),
}
local RangDoorbell = nil


local function ShowEntranceHeaderMenu()
    --[[local headerMenu = {}

    if IsOwned then
        headerMenu[#headerMenu+1] = {
            header = Lang:t('text.enter'),
            params = {
                event = 'apartments:client:EnterApartment',
                args = {}
            }
        }
     elseif not IsOwned then
        headerMenu[#headerMenu+1] = {
            header = Lang:t('text.move_here'),
            params = {
                event = 'apartments:client:UpdateApartment',
                args = {}
            }
        }
     end

    headerMenu[#headerMenu+1] = {
        header = Lang:t('text.ring_doorbell'),
        params = {
            event = 'apartments:client:DoorbellMenu',
            args = {}
        }
    }

    headerMenu[#headerMenu+1] = {
        header = Lang:t('text.close_menu'),
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(headerMenu)]]
end

local function ShowExitHeaderMenu()
    local headerMenu = {}

   --[[ headerMenu[#headerMenu+1] = {
        header = Lang:t('text.open_door'),
        params = {
            event = 'apartments:client:OpenDoor',
            args = {}
        }
    }]]
    
    headerMenu[#headerMenu+1] = {
        header = Lang:t('text.leave'),
        params = {
            event = 'apartments:client:LeaveApartment',
            args = {}
        }
    }

    headerMenu[#headerMenu+1] = {
        header = Lang:t('text.close_menu'),
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(headerMenu)
end


RegisterNetEvent('Polar-Apartments:Client:LeaveApartment', function()

    ShowExitHeaderMenu()
end)
local oxt = false

function CreateTarget(names, coords1, handler, labels, icons, his)
    if oxt then
        targets[names] = exports.ox_target:addBoxZone({ coords = coords1, size = vec3(1, 1, 1), rotation = 1, debug = his,
        options = {{  event = handler,  icon = icons, label = labels, id = names, canInteract = function(_, distance) return distance <= Config.OxTargetDistance end }, } })
    else
        exports['qb-target']:AddBoxZone(names,  coords1, 0.5, 0.5, { name =  names, heading = 28.69, debug = his, minZ = coords1.z-0.5, maxZ =  coords1.z+0.5,}, 
        { options = {{ event = handler, icon = icons, label = labels, id = names }}, distance = 1 }) 
    end 
end
CreateThread(function()
exports['qb-target']:AddBoxZone("apartment", vector3(-271.01, -959.305, 32.692 - 1.12), 2.5, 2.3, {
    name = "apartment",
    heading = -20,
        debugPoly = false,
        minZ = 32.692 - 1.12 - 1,
        maxZ = 32.692 - 1.12 + 1,
    }, {
        options = {
            {
                type = "client",
                event = "apartments:client:EnterApartment",
                icon = "fa-regular fa-building",
                label = "Enter Apartment",
            },
            {
                icon = "fa-solid fa-clipboard",
                label = "Raid Apartment",
                event = "qb-apartments:choose",
                canInteract = function()
                    local PlayerData = QBCore.Functions.GetPlayerData()
                    local job = PlayerData.job
                    local jobName = job.name
                    local gradeAllowed = tonumber(job.grade.level) >= 3
                    local onDuty = job.onduty

                    return jobName == "police" and gradeAllowed and onDuty
                end,
            },
           
        },
        distance = 1.5
    })
end)
function SetInApartmentTargets()
    if not POIOffsets then
        -- do nothing
        return
    end
    
    local entrancePos = vector3(Apartments.Locations["apartment3"].coords.enter.x - POIOffsets.exit.x, Apartments.Locations["apartment3"].coords.enter.y - POIOffsets.exit.y , Apartments.Locations["apartment3"].coords.enter.z - CurrentOffset + POIOffsets.exit.z + 2)--vector3(-275.09, -960.75, 2.23)
    local stashPos = vector3(Apartments.Locations["apartment3"].coords.enter.x - POIOffsets.stash.x, Apartments.Locations["apartment3"].coords.enter.y - POIOffsets.stash.y, Apartments.Locations["apartment3"].coords.enter.z - CurrentOffset + POIOffsets.stash.z+ 2)--vector3(-271.41, -959.79, 2.23)
    local outfitsPos = vector3(Apartments.Locations["apartment3"].coords.enter.x - POIOffsets.clothes.x, Apartments.Locations["apartment3"].coords.enter.y - POIOffsets.clothes.y, Apartments.Locations["apartment3"].coords.enter.z - CurrentOffset + POIOffsets.clothes.z+ 2)--vector3(-271.31, -955.26, 2.23)
    local logoutPos = vector3(Apartments.Locations["apartment3"].coords.enter.x - POIOffsets.logout.x, Apartments.Locations["apartment3"].coords.enter.y + POIOffsets.logout.y, Apartments.Locations["apartment3"].coords.enter.z - CurrentOffset + POIOffsets.logout.z + 2)--vector3(-267.56, -957.68, 2.23)
   
    CreateTarget('stashPos', stashPos, "apartments:client:OpenStash", "Open", "fas fa-bolt", false)
    CreateTarget('outfitsPos', outfitsPos, "apartments:client:ChangeOutfit", "Outfits", "fas fa-bolt", false)
    CreateTarget('logoutPos', logoutPos, "apartments:client:Logout", "Logout", "fas fa-bolt", false)
    CreateTarget('entrancePos', entrancePos, "Polar-Apartments:Client:LeaveApartment", "Leave", "fas fa-bolt", false)


end

function DeleteApartmentTargets()
   
    exports['qb-target']:RemoveZone('stashPos') 
    exports['qb-target']:RemoveZone('outfitsPos') 
    exports['qb-target']:RemoveZone('logoutPos') 
    exports['qb-target']:RemoveZone('entrancePos') 
    
end


function TeleportToInterior(x, y, z, h)
    CreateThread(function()
        SetEntityCoords(PlayerPedId(), x, y, z, 0, 0, 0, false)
        --SetEntityHeading(PlayerPedId(), 175)

        Wait(100)

        DoScreenFadeIn(1000)
    end)
end

-- utility functions

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    loadAnimDict("anim@heists@keycard@")
    TaskPlayAnim( PlayerPedId(), "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0 )
    Wait(400)
    ClearPedTasks(PlayerPedId())
end
local objects = {}
function EnterApartment(house, apartmentId, new)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
 
    openHouseAnim()
    Wait(250)
    exports['Polar-Sub']:toggleProps()
    QBCore.Functions.TriggerCallback('apartments:GetApartmentOffset', function(offset)
        if offset == nil or offset == 0 then
            QBCore.Functions.TriggerCallback('apartments:GetApartmentOffsetNewOffset', function(newoffset)
                if newoffset > 230 then
                    newoffset = 210
                end
                CurrentOffset = newoffset
                TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
                local coords = { x = Apartments.Locations[house].coords.enter.x, y = Apartments.Locations[house].coords.enter.y, z = Apartments.Locations[house].coords.enter.z - CurrentOffset}
                
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                RequestModel('modernhotel_shell')
                while not HasModelLoaded('modernhotel_shell') do
                    Wait(3)
                end
                local house = CreateObject('modernhotel_shell', coords.x, coords.y, coords.z, false, false, false)
                FreezeEntityPosition(house, true)
                objects[#objects+1] = house
                    TeleportToInterior(coords.x - -5.06, coords.y - -4.01, coords.z + 1.16, POIOffsets.exit.h)
                    
                if new then
                    SetTimeout(750, function()
                        TriggerEvent('Polar-Clothes:client:CreateFirstCharacter')
                        new = false
                    end)
                end
              
               

                Wait(100)
                SetInApartmentTargets()
                InApartment = true
                CurrentApartment = apartmentId
                ClosestHouse = house
                RangDoorbell = nil
                Wait(500)
                TriggerEvent('qb-weathersync:client:DisableSync')
                Wait(100)
                TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, false)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
                TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
                
            end, house)
        else
            if offset > 230 then
                offset = 210
            end
            CurrentOffset = offset
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
            TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
            local coords = { x = Apartments.Locations[ClosestHouse].coords.enter.x, y = Apartments.Locations[ClosestHouse].coords.enter.y, z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset}
            POIOffsets.exit = json.decode('{"x": -5.26, "y": -4.21, "z": -0.66, "h": 0.79}')
            POIOffsets.clothes = json.decode('{"x": -3.14, "y": 2.824, "z": -0.66}')
            POIOffsets.stash = json.decode('{"x": -6.11, "y": -0.06, "z": -1.16}')
            POIOffsets.logout = json.decode('{"x": 5000000000000000000000000.19, "y": -1.59, "z": -0.66}')
            DoScreenFadeOut(500)
            while not IsScreenFadedOut() do
                Wait(10)
            end
            RequestModel('modernhotel_shell')
            while not HasModelLoaded('modernhotel_shell') do
                Wait(3)
            end
            local house = CreateObject('modernhotel_shell', coords.x, coords.y, coords.z, false, false, false)
            FreezeEntityPosition(house, true)
            objects[#objects+1] = house
                TeleportToInterior(coords.x - -5.06, coords.y - -4.01, coords.z + 1.16, POIOffsets.exit.h)
            if new then
                SetTimeout(750, function()
                    TriggerEvent('Polar-Clothes:client:CreateFirstCharacter')
                    new = false
                end)
            end
           Wait(100)
            HouseObj = house
          --  POIOffsets = data[2]
            InApartment = true
            CurrentApartment = apartmentId
            Wait(500)
            TriggerEvent('qb-weathersync:client:DisableSync')
            Wait(100)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, true)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
            TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
        end

       
    end, apartmentId)
end

local function LeaveApartment(house)
    exports['Polar-Sub']:toggleProps()
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
    openHouseAnim()
    TriggerServerEvent("qb-apartments:returnBucket")
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
        
        for _, v in pairs(HouseObj) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
       
        TriggerEvent('qb-weathersync:client:EnableSync')
        SetEntityCoords(PlayerPedId(), Apartments.Locations[house].coords.enter.x, Apartments.Locations[house].coords.enter.y,Apartments.Locations[house].coords.enter.z)
        SetEntityHeading(PlayerPedId(), Apartments.Locations[house].coords.enter.w)
        Wait(1000)
        TriggerServerEvent("apartments:server:RemoveObject", CurrentApartment, house)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', CurrentApartment, false)
        CurrentApartment = nil
        InApartment = false
        CurrentOffset = 0
        DoScreenFadeIn(1000)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
        TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", nil)

        DeleteApartmentTargets()
        
        exports['Polar-Sub']:toggleProps()
end

function SetClosestApartment()
    local pos = GetEntityCoords(PlayerPedId())
    local current = nil
    local dist = 100
    for id, _ in pairs(Apartments.Locations) do
        local distcheck = #(pos - vector3(Apartments.Locations[id].coords.enter.x, Apartments.Locations[id].coords.enter.y, Apartments.Locations[id].coords.enter.z))
        if distcheck < dist then
            current = id
        end
    end
    if current ~= ClosestHouse and LocalPlayer.state.isLoggedIn and not InApartment then
        ClosestHouse = current
        QBCore.Functions.TriggerCallback('apartments:IsOwner', function(result)
            IsOwned = result
            
            DeleteApartmentTargets()
        end, ClosestHouse)
    end
end



-- Event Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if HouseObj ~= nil then
            for _, v in pairs(HouseObj) do
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
                CurrentApartment = nil
                TriggerEvent('qb-weathersync:client:EnableSync')
                DoScreenFadeIn(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                SetEntityCoords(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y,Apartments.Locations[ClosestHouse].coords.enter.z)
                SetEntityHeading(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.w)
                Wait(1000)
                InApartment = false
                DoScreenFadeIn(1000)
          
        end

        
        DeleteApartmentTargets()
    end
end)


-- Events

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CurrentApartment = nil
    InApartment = false
    CurrentOffset = 0

    
    DeleteApartmentTargets()
end)
local targetlocations = {
  --  vector3(-270.92, -957.91, 31.22),
    --vector3(-270.92, -957.91, 31.22),
    --vector3(-270.92, -957.91, 31.22),
    --vector3(291.42, -1078.36, 29.41),
    vector3(-265.22, -956.32, 31.22),
   -- vector3(287.66, -644.41, 42.02),
   -- vector3(-1288.54, -430.45, 35.15),
    
}


RegisterNetEvent('qb-apartments:choose')
AddEventHandler('qb-apartments:choose',function()
local PlayerData = QBCore.Functions.GetPlayerData()
local dialog = exports['qb-input']:ShowInput({
    header = "Enter the CID of the persons apartment",
    submitText = "Enter",
    inputs = {
        {
            text = "Citizen ID (#)",
            name = "citizenid",
            type = "text",
            isRequired = true 
        },
    },
})

    if dialog then
        QBCore.Functions.TriggerCallback('apartments:PoliceApartment', function(result)
            if result then
                if PlayerData.job.grade.level > 2 then
                    altaapartment = result.type

                    SetClosestApartment()

                    EnterApartment(altaapartment, result.name)
                else
                    QBCore.Functions.Notify("You are not high enough rank.", "error")
                end
            end
        end, dialog.citizenid)
    end
end)
RegisterNetEvent('apartments:client:setupSpawnUI', function(cData)
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result then
          

                TriggerEvent("apartments:client:SetHomeBlip", result.type)
                TriggerEvent('ivs_spawns:openMenu', lastLocation)

                
        
        else
            TriggerServerEvent("apartments:server:CreateApartment", 'apartment3', 'Alta Street Apartment')
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')

            Wait(5000)

            TriggerServerEvent('Polar-Apartments:Server:Start')
           
        end
    end, cData.citizenid)
end)


RegisterNetEvent('apartments:client:SpawnInApartment', function(apartmentId, apartment)
    local pos = GetEntityCoords(PlayerPedId())
    if RangDoorbell ~= nil then
        local doorbelldist = #(pos - vector3(Apartments.Locations[RangDoorbell].coords.enter.x, Apartments.Locations[RangDoorbell].coords.enter.y,Apartments.Locations[RangDoorbell].coords.enter.z))
        if doorbelldist > 5 then
            QBCore.Functions.Notify(Lang:t('error.to_far_from_door'))
            return
        end
    end
    ClosestHouse = "apartment3"
    EnterApartment(apartment, apartmentId, true)
    IsOwned = true
end)

RegisterNetEvent('qb-apartments:client:LastLocationHouse', function(apartmentType, apartmentId)
    ClosestHouse = apartmentType
    EnterApartment(apartmentType, apartmentId, false)
end)

RegisterNetEvent('apartments:client:SetHomeBlip', function(home)
    CreateThread(function()
        SetClosestApartment()
        for name, _ in pairs(Apartments.Locations) do
            RemoveBlip(Apartments.Locations[name].blip)

            Apartments.Locations[name].blip = AddBlipForCoord(Apartments.Locations[name].coords.enter.x, Apartments.Locations[name].coords.enter.y, Apartments.Locations[name].coords.enter.z)
            if (name == home) then
                SetBlipSprite(Apartments.Locations[name].blip, 475)
            else
                SetBlipSprite(Apartments.Locations[name].blip, 476)
            end
            SetBlipDisplay(Apartments.Locations[name].blip, 4)
            SetBlipScale(Apartments.Locations[name].blip, 0.6)
            SetBlipAsShortRange(Apartments.Locations[name].blip, true)
            SetBlipColour(Apartments.Locations[name].blip, 3)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Apartments.Locations[name].label)
            EndTextCommandSetBlipName(Apartments.Locations[name].blip)
        end
    end)
end)

RegisterNetEvent('apartments:client:RingMenu', function(data)
    RangDoorbell = ClosestHouse
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    TriggerServerEvent("apartments:server:RingDoor", data.apartmentId, ClosestHouse)
end)

RegisterNetEvent('apartments:client:RingDoor', function(player, _)
    CurrentDoorBell = player
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    QBCore.Functions.Notify(Lang:t('info.at_the_door'))
end)

RegisterNetEvent('apartments:client:DoorbellMenu', function()
    MenuOwners()
end)

RegisterNetEvent('apartments:client:EnterApartment', function()
    SetClosestApartment()
   
   
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result ~= nil then
            EnterApartment(ClosestHouse, result.name)
        end
    end)
end)

RegisterNetEvent('apartments:client:UpdateApartment', function()
    local apartmentType = ClosestHouse
    local apartmentLabel = Apartments.Locations[ClosestHouse].label
    TriggerServerEvent("apartments:server:UpdateApartment", apartmentType, apartmentLabel)
    IsOwned = true

    
    DeleteApartmentTargets()
end)

RegisterNetEvent('apartments:client:OpenDoor', function()
    if CurrentDoorBell == 0 then
        QBCore.Functions.Notify(Lang:t('error.nobody_at_door'))
        return
    end
    TriggerServerEvent("apartments:server:OpenDoor", CurrentDoorBell, CurrentApartment, ClosestHouse)
    CurrentDoorBell = 0
end)

RegisterNetEvent('apartments:client:LeaveApartment', function()
    LeaveApartment("apartment3")
end)

RegisterNetEvent('apartments:client:OpenStash', function()
    if CurrentApartment ~= nil then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", CurrentApartment)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
        TriggerEvent("inventory:client:SetCurrentStash", CurrentApartment)
    end
end)

RegisterNetEvent('apartments:client:ChangeOutfit', function()
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
    TriggerEvent('Polar-Clothing:client:openOutfitMenu')
end)

RegisterNetEvent('apartments:client:Logout', function()
    TriggerServerEvent('qb-houses:server:LogoutLocation')
end)


