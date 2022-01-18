local ROLE = {}

ROLE.nameraw = "sanda"
ROLE.name = "Santa"
ROLE.nameplural = "Santas"
ROLE.nameext = "a Santa"
ROLE.nameshort = "san"

ROLE.desc = [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You can use your christmas cannon to give gifts to nice children and coal to naughty children.

Press {menukey} to receive your equipment!]]

ROLE.team = ROLE_TEAM_DETECTIVE
ROLE.loadout = {"weapon_san_christmas_cannon"}
ROLE.startingcredits = 1

CreateConVar("ttt_santa_random_presents", 0)
CreateConVar("ttt_santa_jesters_are_naughty", 0)
CreateConVar("ttt_santa_independents_are_naughty", 1)

ROLE.convars = {
    {
        cvar = "ttt_santa_random_presents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_santa_jesters_are_naughty",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_santa_independents_are_naughty",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["santa_help_pri"] = "Use {primaryfire} to give gifts to nice children",
        ["santa_help_sec"] = "Use {secondaryfire} to shoot coal at naughty children",
        ["santa_load_gift"] = "Open your buy menu with {menukey} to load a present!"
    }
}

RegisterRole(ROLE)

if CLIENT then
    hook.Add("TTTTutorialRoleText", "Santa_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_SANTA then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
            local traitorColor = GetRoleTeamColor[ROLE_TEAM_TRAITOR]
            local jesterColor = GetRoleTeamColor[ROLE_TEAM_JESTER]
            local independentColor = GetRoleTeamColor[ROLE_TEAM_INDEPENDENT]
            local html = ROLE_STRINGS[ROLE_SANTA] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have a christmas cannon.</span>"

            -- Gifts
            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of buying items for themselves, " .. ROLE_STRINGS[ROLE_SANTA] .. " can"
            if GetGlobalBool("ttt_santa_random_presents", false) then
                html = html .. "shoot random shop items"
            else
                html = html .. "buy an item from their shop and shoot it"
            end
            html = html .. " from their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span>. Each player can only open one gift.</span>"

            -- Coal
            html = html .. "<span style='display: block; margin-top: 10px;'>The <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span> can also shoot coal which will kill anyone it hits.</span>"

            -- Ammo
            html = html .. "<span style='display: block; margin-top: 10px;'>Ammo for the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span> is refunded whenever a player opens a gift OR a naughty ("
            html = html .. "<span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor</span>"
            if GetGlobalBool("ttt_santa_jesters_are_naughty", false) then
                html = html .. ", <span style='color: rgb(" .. jesterColor.r .. ", " .. jesterColor.g .. ", " .. jesterColor.b .. ")'>jester</span>"
            end
            if GetGlobalBool("ttt_santa_independents_are_naughty", false) then
                html = html .. ", <span style='color: rgb(" .. independentColor.r .. ", " .. independentColor.g .. ", " .. independentColor.b .. ")'>independent</span>"
            end
            html = html .. ") player is killed by coal."

            return html
        end
    end)
end

if SERVER then
    AddCSLuaFile()

    hook.Add("TTTSyncGlobals", "Santa_TTTSyncGlobals", function()
        SetGlobalBool("ttt_santa_random_presents", GetConVar("ttt_santa_random_presents"):GetBool())
        SetGlobalBool("ttt_santa_jesters_are_naughty", GetConVar("ttt_santa_jesters_are_naughty"):GetBool())
        SetGlobalBool("ttt_santa_independents_are_naughty", GetConVar("ttt_santa_independents_are_naughty"):GetBool())
    end)

    -- We don't want Santa to receive items unless random presents is turned on
    hook.Add("TTTCanOrderEquipment", "Santa_TTTCanOrderEquipment", function(ply, id, is_item)
        if ply:IsSanta() and not GetGlobalBool("ttt_santa_random_presents", false) then
            if ply:GetNWString("SantaLoadedItem") == "" then
                -- TODO: Check that santa is allowed to buy the item before loading it into the christmas cannon
                ply:SetNWString("SantaLoadedItem", tostring(id))
                ply:SetNWBool("SantaHasAmmo", false)
                ply:SetCredits(0)
                ply:AddBought(id)
            else
                ply:PrintMessage(HUD_PRINTTALK, "You have already loaded an item into the christmas cannon!")
            end
            return false
        end
    end)

    hook.Add("TTTPrepareRound", "Santa_TTTPrepareRound", function()
        for _, v in pairs(player.GetAll()) do
            v:SetNWString("SantaLoadedItem", "")
            v:SetNWBool("SantaHasAmmo", false)
        end
    end)

    hook.Add("TTTBeginRound", "Santa_TTTBeginRound", function()
        for _, v in pairs(player.GetAll()) do
            if v:IsActiveSanta() then
                v:SetNWBool("SantaHasAmmo", true)
            end
        end

        -- If random presents are disabled we hijack santa's credits to tie them to their ammo
        if not GetGlobalBool("ttt_santa_random_presents", false) then
            timer.Create("santacredits", 1, 0, function()
                for _, v in pairs(player.GetAll()) do
                    if v:IsActiveSanta() then
                        if v:GetCredits() ~= 0 and not v:GetNWBool("SantaHasAmmo", false) then
                            v:SetCredits(0)
                        elseif v:GetCredits() ~= 1 and v:GetNWBool("SantaHasAmmo", false) then
                            v:SetCredits(1)
                        end
                    end
                end
            end)
        end
    end)

    hook.Add("TTTEndRound", "Santa_TTTEndRound", function()
        if timer.Exists("santacredits") then timer.Remove("santacredits") end
    end)
end