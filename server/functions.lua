local Locale = Config.Lang
local ESXCore = exports[Config.ESXCoreName]:getSharedObject()
-- ==============================
-- Whitelist Check
-- ==============================
function checkWhitelist(identifier)
    if not identifier then
        return false
    end

    local status = MySQL.scalar.await(
        "SELECT status FROM ucp_whitelist_applications WHERE identifier = ? ORDER BY updatedAt DESC LIMIT 1",
        { identifier }
    )
    print(("[Whitelist] Identifier: %s | Status: %s | Approved: %s"):format(
           identifier,
           tostring(status),
           tostring(approved)
       ))

    return status ~= nil and tostring(status):upper() == "APPROVED"
end
-- ==============================
-- Username change check
-- ==============================
function updateUserName(identifier, newName)
    -- Query to fetch the current name from the database
    local selectQuery = [[
        SELECT name FROM community_users WHERE hex_id = @hexid;
    ]]

    local selectParams = { ["hexid"] = identifier }

    -- Fetch the current name using oxmysql
    exports.oxmysql:execute(selectQuery, selectParams, function(result)
        if result and #result > 0 then
            local currentName = result[1].name  -- Assuming result is a table with the first row containing the name
            print("Current Name: " .. currentName)

            -- Check if the current name is different from the new name
            if currentName ~= newName then
                local updateQuery = [[
                    UPDATE community_users
                    SET name = @newname
                    WHERE hex_id = @hexid;
                ]]

                local updateParams = {
                    ["hexid"] = identifier,
                    ["newname"] = newName
                }

                -- Execute the update query
                exports.oxmysql:execute(updateQuery, updateParams, function(result)
                    if not result or result.affectedRows == 0 then
                        print("Failed to update username or no rows affected.")
                    else
                        print("User name updated successfully.")
                    end
                end)
            else
                print("No change in user name.")
            end
        else
            print("Failed to retrieve current username.")
        end
    end)
end




-- ==============================
-- Player Kick Function
-- ==============================
function kickPlayer(src, reason, setKickReason, deferrals)

    local formattedReason = "\n" .. reason

    print("[KICK] "..formattedReason)

    if setKickReason then
        setKickReason(formattedReason)
    end

    if deferrals then
        deferrals.update(formattedReason)

        Citizen.Wait(1000)

        deferrals.done(formattedReason)
    else
        DropPlayer(src, formattedReason)
    end
end


function WhitelistControl(src, setKickReason, def)

    local self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }


    for i = 1, 5 do

        if Locale == "EE" then
            def.update('Whitelisti kontroll: ' .. i .. '/5.')
        else
            def.update('Whitelist check: ' .. i .. '/5.')
        end

        Citizen.Wait(1000)
    end


    local identifier = self.hexid


    if not identifier then

        if Config.Logs then
            exports.nc_logs:AddLog(
                "Steam Check",
                self.name,
                self.license,
                "Steam identifier missing!",
                nil
            )
        end


        if Locale == "EE" then
            kickPlayer(
                src,
                'Steami kasutaja pole ühenduses!',
                setKickReason,
                def
            )
        else
            kickPlayer(
                src,
                'Didnt found steam account data!',
                setKickReason,
                def
            )
        end

        CancelEvent()
        return false
    end



    if not checkWhitelist(identifier) then

        if Config.Logs then
            exports.nc_logs:AddLog(
                "Whitelist Check",
                self.name,
                self.license,
                "User failed whitelist check!",
                nil
            )
        end


        if Locale == "EE" then

            kickPlayer(
                src,
                'Sinul pole whitelist tehtud! Palun tee ära meie whitelisti taotlus. UCP:'..Config.UCPWebsite,
                setKickReason,
                def
            )

        else

            kickPlayer(
                src,
                'You dont have whitelisted access! Complete it in: '..Config.UCPWebsite,
                setKickReason,
                def
            )

        end


        CancelEvent()
        return false
    end



    return true
end



exports('WhitelistControl', function(src, setKickReason, def)
    return WhitelistControl(src, setKickReason, def)
end)

function NameCheck(src, setKickReason, def)
    print("NameCheck")
    local self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }
    def.defer()
    if Locale == "EE" then
        def.update("📝 Nime kontroll...")
        Wait(1000)
        local PlayerName = self.name
        if not PlayerName or PlayerName == "" then
            if Config.Logs then
                exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Tühi nimi pole lubatud!", nil)
            end
            kickUser(src, '❌ Tühi nimi pole lubatud.', setKickReason, def)
            CancelEvent()
            return
        end
        if string.match(PlayerName, "[*%%'=`\"]") then
            if Config.Logs then
                exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Vigadega tähed!", nil)
            end
            kickUser(src, '❌ Vigadega tähed: ' .. string.match(PlayerName, "[*%%'=`\"]"), setKickReason, def)
            CancelEvent()
            return
        end
        if string.match(PlayerName, "drop") or string.match(PlayerName, "table") or string.match(PlayerName, "database") then
            if Config.Logs then
                exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Keelatud nimi!", nil)
            end
            kickUser(src, '❌ Keelatud nimi!', setKickReason, def)
            CancelEvent()
            return
        end
    end
    if Config.Lang == "EN" then
        def.update("📝 Name check...")
        Wait(1000)
        local PlayerName = self.name
        if not PlayerName or PlayerName == "" then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "Empty name was given!", nil)
            end
            kickUser(src, '❌ Empty name not allowed. Change your name or rename.', setKickReason, def)
            CancelEvent()
            return
        end
        if string.match(PlayerName, "[*%%'=`\"]") then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "His name had bad characters!", nil)
            end
            kickUser(src, '❌ Bad characters in name: ' .. string.match(PlayerName, "[*%%'=`\"]"), setKickReason, def)
            CancelEvent()
            return
        end
        if string.match(PlayerName, "drop") or string.match(PlayerName, "table") or string.match(PlayerName, "database") then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "Name not allowed!", nil)
            end
            kickUser(src, '❌ Name not allowed!', setKickReason, def)
            CancelEvent()
            return
        end
    end
end


exports('NameCheck', function(src, name, setKickReason, def)

    local self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }
    def.defer()

    if Config.Lang == "EE" then

            def.update("📝 Nime kontroll...")
            Wait(1000)

            local PlayerName = self.name
            if not PlayerName or PlayerName == "" then
                if Config.Logs then
                    exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Tühi nimi pole lubatud!", nil)
                end
                kickUser(src, '❌ Tühi nimi pole lubatud.', setKickReason, def)
                CancelEvent()
                return
            end

            if string.match(PlayerName, "[*%%'=`\"]") then
                if Config.Logs then
                    exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Vigadega tähed!", nil)
                end
                kickUser(src, '❌ Vigadega tähed: ' .. string.match(PlayerName, "[*%%'=`\"]"), setKickReason, def)
                CancelEvent()
                return
            end

            if string.match(PlayerName, "drop") or string.match(PlayerName, "table") or string.match(PlayerName, "database") then
                if Config.Logs then
                    exports.nc_logs:AddLog("Nime kontroll", self.name, self.license, "Keelatud nimi!", nil)
                end
                kickUser(src, '❌ Keelatud nimi!', setKickReason, def)
                CancelEvent()
                return
            end

    end

    if Config.Lang == "EN" then


        def.update("📝 Name check...")
        Wait(1000)

        local PlayerName = self.name
        if not PlayerName or PlayerName == "" then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "Empty name was given!", nil)
            end
            kickUser(src, '❌ Empty name not allowed. Change your name or rename.', setKickReason, def)
            CancelEvent()
            return
        end

        if string.match(PlayerName, "[*%%'=`\"]") then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "His name had bad characters!", nil)
            end
            kickUser(src, '❌ Bad characters in name: ' .. string.match(PlayerName, "[*%%'=`\"]"), setKickReason, def)
            CancelEvent()
            return
        end

        if string.match(PlayerName, "drop") or string.match(PlayerName, "table") or string.match(PlayerName, "database") then
            if Config.Logs then
                exports.nc_logs:AddLog("Name Check", self.name, self.license, "Name not allowed!", nil)
            end
            kickUser(src, '❌ Name not allowed!', setKickReason, def)
            CancelEvent()
            return
        end


    end

end)


function DiscordCheck(src, name, setKickReason, def)
    local self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }
    def.defer()
    if Locale == "ET" then
        def.update("💻 Discordi kontroll...")
        Wait(1000)



        local Discord = NC.GetIdentifier(src, "discord")
        if not Discord or Discord:sub(1, 8) ~= "discord:" then
            if Config.Logs then
                exports.nc_logs:AddLog("Discordi kontroll", self.name, self.license, "Ei leitud DISCORDI litsentsi!", nil)
            end
            kickUser(src, '❌ Sinul peab olema discordi kasutaja!', setKickReason, def)
            CancelEvent()
            return
        end
    end

    if Locale == "EN" then

        def.update("💻 Discord Check...")
        Wait(1000)



        local Discord = NC.GetIdentifier(src, "discord")
        if not Discord or Discord:sub(1, 8) ~= "discord:" then
            if Config.Logs then
                exports.nc_logs:AddLog("Discord Check", self.name, self.license, "Didnt found any discord license!", nil)
            end
            kickUser(src, '❌ This server allows discord users only!', setKickReason, def)
            CancelEvent()
            return
        end
    end


end

function IdentifierCheck(src, name, setKickReason, def)
    local self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }
    def.defer()

    if Locale == "ET" then
        def.update("💻 License Check...")
        Wait(1000)

        if Config.IdentifierType == "steam" then
            if not self.hexid or self.hexid:sub(1, 6) ~= "steam:" then
                if Config.Logs then
                    exports.nc_logs:AddLog("License Check", self.name, self.license, "Ei leitud STEAMI litsentsi!", nil)
                end
                kickUser(src, '❌ Sinul peab olema steami kasutaja. NB! Server lubab ainult steami kasutajaid.', setKickReason, deferrals)
                CancelEvent()
                return
            end
        elseif Config.IdentifierType == "license" then
            if not self.license or self.license:sub(1, 8) ~= "license:" then
                if Config.Logs then
                    exports.nc_logs:AddLog("License Check", self.name, self.license, "Ei leitud ROCKSTARI litsentsi!", nil)
                end
                kickUser(src, '❌  Sinul peab olema Rockstari kasutaja. NB! Server lubab ainult Rockstari kasutajaid.', setKickReason, deferrals)
                CancelEvent()
                return
            end
        end
    end

    if Locale == "EN" then

        def.update("💻 License Check...")
        Wait(1000)

        if Config.IdentifierType == "steam" then
            if not self.hexid or self.hexid:sub(1, 6) ~= "steam:" then
                if Config.Logs then
                    exports.nc_logs:AddLog("License Check", self.name, self.license, "Didnt found the correct license!", nil)
                end
                kickUser(src, '❌  This server accepts only [Steam] users.', setKickReason, def)
                CancelEvent()
                return
            end
        elseif Config.IdentifierType == "license" then
            if not self.license or self.license:sub(1, 8) ~= "license:" then
                if Config.Logs then
                    exports.nc_logs:AddLog("License Check", self.name, self.license, "Didnt found Rockstar license!", nil)
                end
                kickUser(src, '❌  This server accepts only [Rockstar] users.', setKickReason, def)
                CancelEvent()
                return
            end
        end
    end

end


function BanCheck(src, name, setKickReason, def)
    self = {
        source = src,
        name = GetPlayerName(src),
        hexid = ESXCore.GetIdentifier(src, "steam"),
        license = ESXCore.GetIdentifier(src, "license"),
    }
    def.defer()

    if Config.Lang == "ET" then
        def.update("🔒 Keelustuse kontroll...")
        Wait(1000)

        local success, isBanned, reason = pcall(ESXCore.IsPlayerBanned, src)
        if not success then
            kickUser(src, 'Error fetching ban data.', setKickReason, def)
            if Config.Logs then
                exports.nc_logs:AddLog("Keelustuse kontroll", self.name, self.license, "Viga andmete saamisel", nil)
            end
            CancelEvent()
            return
        end

        if isBanned then
            if Config.Logs then
                exports.nc_logs:AddLog("Keelustuse kontroll", self.name, self.license, "See isik on meie serverist keelustatud!", nil)
            end
            kickUser(src, reason, setKickReason, def)

            CancelEvent()
            return
        end
    end


    if Locale == "EN" then
        def.update("🔒 Ban type check...")
        Wait(1000)

        local success, isBanned, reason = pcall(ESXCore.IsPlayerBanned, src)
        if not success then
            kickUser(src, 'Error fetching ban data.', setKickReason, def)
            if Config.Logs then
                exports.nc_logs:AddLog("Ban check", self.name, self.license, "Error fetching ban data.", nil)
            end
            CancelEvent()
            return
        end

        if isBanned then
            if Config.Logs then
                exports.nc_logs:AddLog("Ban Check", self.name, self.license, "This user is banned from our server!", nil)
            end
            kickUser(src, reason, setKickReason, def)

            CancelEvent()
            return
        end
    end


end


function UserCheck(def, pSrc)
    def.defer()
    local pSrc = source
    self = {
        source = pSrc,
        name = GetPlayerName(pSrc),
        hexid = ESXCore.GetIdentifier(pSrc, "steam"),
        license = ESXCore.GetIdentifier(pSrc, "license"),
    }


    if Locale == "EE" then
        for i = 1, 2 do
            def.update('Kasutaja kontroll: ' .. i .. '/2.')
            Citizen.Wait(1000)
        end

        Checks.User.CreateNewUser(self.source)

        updateUserName(self.hexid, self.name)
    end

    if Locale == "EN" then

        for i = 1, 2 do
            def.update('User account check: ' .. i .. '/2.')
            Citizen.Wait(1000)
        end

        Checks.User.CreateNewUser(self.source)

        updateUserName(self.hexid, self.name)
    end

end
