local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local CONFIG_TRAITOR_COUNT = RiceLib.Config.Define("zcity_rice_tweaks", "homicide_traitor_count", {
    DisplayName = "杀手数量",
    Category = "杀手模式",

    Default = 1,
    Shared = true
})

local CONFIG_TRAITOR_FLASHLIGHT = RiceLib.Config.Define("zcity_rice_tweaks", "homicide_traitor_flashlight", {
    DisplayName = "杀手默认获得手电筒",
    Category = "杀手模式",

    Type = "Bool",
    Default = true,
    Shared = true
})

local CONFIG_ALL_PLAYER_FLASHLIGHT = RiceLib.Config.Define("zcity_rice_tweaks", "homicide_all_player_flashlight", {
    DisplayName = "所有玩家默认获得手电筒",
    Category = "杀手模式",

    Type = "Bool",
    Default = false,
    Shared = true
})

hook.Add("RiceLib_ConfigManager_ValueChanged", "ZCityRiceTweaks_Homicide", function(name_space, key, value)
    if CLIENT then return end
    if name_space ~= "zcity_rice_tweaks" then return end
    if key ~= "homicide_traitor_count" then return end

    local convar = GetConVar("homicide_traitoramount")

    convar:SetInt(value)
end)

local function modifyLoadouts()
    if CLIENT then return end

    if not zb.modes then return end

    local mode = zb.modes.hmcd

    local profession_spawn_functions = {
        doctor = function(player, mode)
            player:Give("weapon_medkit_sh")
        end,

        huntsman = function(player, mode)
            -- player:Give("weapon_hg_bow")

            -- player:SetAmmo(1, "Arrow")
        end,

        engineer = function(player, mode)
            hg.AddArmor(player, {"mask2"})
        end,

        cook = function(player, mode)
            if mode == "soe" then
                player:Give("weapon_pan")
            end
        end,

        builder = function(player, mode)
            if mode == "soe" then
                player:Give("weapon_hammer")
                player:SetAmmo(3, "Nails")
            end
        end,
    }

    local gaymaps = {
        ["zs_shelter"] = true,
        ["gm_sirenmine_v2"] = true,
    }

    local traitorLoot = {
        standard = function(player)
            local main_weapon = player:Give("weapon_hk_usp")

            hg.AddAttachmentForce(player, main_weapon, "supressor4")
            hg.AddAttachmentForce(player, main_weapon, "laser2")

            player:SetAmmo(15, "9x19 mm Parabellum")

            player:Give("weapon_pocketknife")
            player:Give("weapon_hg_rgd_tpik")
            player:Give("weapon_adrenaline")
            player:Give("weapon_hg_smokenade_tpik")
            player:Give("weapon_traitor_ied")
            player:Give("weapon_traitor_poison1")
            player:Give("weapon_traitor_suit")
            player:Give("weapon_hg_jam")

            player.organism.stamina.max = 220
            player.organism.stamina.range = 220

            local inv = player:GetNetVar("Inventory")
            inv["Weapons"]["hg_flashlight"] = true

            player:SetNetVar("Inventory", inv)
        end,

        soe = function(player)
            local main_weapon = player:Give("weapon_p22")

            hg.AddAttachmentForce(player, main_weapon, "supressor4")

            player:SetAmmo(15, ".22 Long Rifle")

            player:Give("weapon_sogknife")
            player:Give("weapon_hg_rgd_tpik")
            player:Give("weapon_adrenaline")
            player:Give("weapon_hg_smokenade_tpik")
            player:Give("weapon_traitor_ied")
            player:Give("weapon_traitor_poison1")
            player:Give("weapon_traitor_suit")
            player:Give("weapon_hg_jam")

            player.organism.stamina.max = 220
            player.organism.stamina.range = 220

            local inv = player:GetNetVar("Inventory")
            inv["Weapons"]["hg_flashlight"] = true

            player:SetNetVar("Inventory", inv)
        end,

        gunfreezone = function(player)
            player:Give("weapon_buck200knife")
            player:Give("weapon_hg_type59_tpik")
            player:Give("weapon_adrenaline")
            player:Give("weapon_hg_shuriken")
            player:Give("weapon_hg_smokenade_tpik")
            player:Give("weapon_traitor_ied")
            player:Give("weapon_traitor_poison1")
            player:Give("weapon_traitor_poison2")
            player:Give("weapon_traitor_poison3")
            player:Give("weapon_traitor_poison_consumable")
            player:Give("weapon_traitor_suit")
            player:Give("weapon_hg_bow")

            player:SetAmmo(10, "Arrow")

            player.organism.stamina.max = 220

            local inv = player:GetNetVar("Inventory")
            inv["Weapons"]["hg_flashlight"] = true

            player:SetNetVar("Inventory", inv)
        end
    }

    function mode.SpawnPlayers(spawn_with_subroles)
        local gunner_found = false

        local function professionSpawnFunction(player)
            local profession = player.Profession
            local spawn_function = profession_spawn_functions[profession]

            if spawn_function then
                spawn_function(player)
            end
        end

        for _, ply in RandomPairs(player.GetAll()) do
            if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end
            if math.random(100) > (ply.Karma or 100) then continue end

            ply.isGunner = true
            gunner_found = true

            break
        end

        if not gunner_found then
            for _, ply in RandomPairs(player.GetAll()) do
                if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end

                ply.isGunner = true

                break
            end
        end

        local player_count = 0

        for _, ply in player.Iterator() do
            if ply:Team() ~= TEAM_SPECTATOR then
                player_count = player_count + 1
            end
        end

        if spawn_with_subroles and mode.RoleChooseRoundTypes[mode.Type] then
            local professions_possible_pre = mode.RoleChooseRoundTypes[mode.Type].Professions

            if professions_possible_pre then
                local professions_possible = {}
                local professions_count_to_satisfy = math.ceil(player_count / 2)

                for profession, profession_info in pairs(professions_possible_pre) do
                    professions_possible[#professions_possible + 1] = {profession_info.Chance, profession}
                end

                for _, ply in RandomPairs(player.GetAll()) do
                    if ply:Team() ~= TEAM_SPECTATOR then
                        if math.random(100) <= (ply.Karma or 100) and (math.random(1, 3) == 1 or not ply.isTraitor and not ply.isGunner) then
                            local profession_key, profession = hg.WeightedRandomSelect(professions_possible)

                            professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
                            professions_count_to_satisfy = professions_count_to_satisfy - 1

                            ply.Profession = profession

                            professionSpawnFunction(ply)

                            if professions_count_to_satisfy == 0 then
                                break
                            end
                        end
                    end
                end

                if professions_count_to_satisfy > 0 then
                    for _, ply in RandomPairs(player.GetAll()) do
                        if ply:Team() ~= TEAM_SPECTATOR and not ply.Profession then
                            local profession_key, profession = hg.WeightedRandomSelect(professions_possible)

                            professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
                            professions_count_to_satisfy = professions_count_to_satisfy - 1

                            ply.Profession = profession

                            professionSpawnFunction(ply)

                            if professions_count_to_satisfy == 0 then
                                break
                            end
                        end
                    end
                end
            end
        end

        for index, current_ply in player.Iterator() do
            if current_ply:Team() ~= TEAM_SPECTATOR then
                current_ply.SubRole = nil

                ApplyAppearance(current_ply, nil, nil, nil, true)

                current_ply:Spawn()
                current_ply:GetRandomSpawn()

                if not current_ply:Alive() then
                    continue
                end

                current_ply:SetSuppressPickupNotices(true)
                current_ply.noSound = true

                if mode.Type == "supermario" then
                    mode.Types.supermario.CustomJump(current_ply)
                end

                local sub_role = nil

                if spawn_with_subroles and mode.RoleChooseRoundTypes[mode.Type] then
                    if current_ply.isTraitor then
                        local sub_role_id = mode.Type == "soe" and (current_ply:GetInfo(mode.ConVarName_SubRole_Traitor_SOE) or "traitor_default_soe") or (current_ply:GetInfo(mode.ConVarName_SubRole_Traitor) or "traitor_default")

                        sub_role = sub_role_id
                    end

                    if current_ply.isGunner then
                        mode.Types[mode.Type].GunManLoot(current_ply)
                    end

                    if sub_role then
                        if current_ply.isTraitor then
                            local role_info = mode.SubRoles[sub_role]

                            if not role_info or not mode.RoleChooseRoundTypes[mode.Type].Traitor[sub_role] then
                                sub_role = mode.RoleChooseRoundTypes[mode.Type].TraitorDefaultRole or "traitor_default"
                                role_info = mode.SubRoles[sub_role]
                            end

                            if current_ply.MainTraitor then
                                current_ply.SubRole = sub_role

                                local spawn_func = role_info.SpawnFunction
                                spawn_func(current_ply, mode.Type)
                            end
                        end
                    end
                else
                    if current_ply.isTraitor then
                        --mode.Types[mode.Type].TraitorLoot(current_ply)

                        traitorLoot[mode.Type](current_ply)
                    end

                    if current_ply.isGunner then
                        mode.Types[mode.Type].GunManLoot(current_ply)
                    end
                end

                if mode.Type == "soe" then
                    if current_ply.isTraitor then
                        local walkie_talkie = current_ply:Give("weapon_walkie_talkie")

                        if walkie_talkie.Frequencies then
                            mode.TraitorFrequency = mode.TraitorFrequency or math.random(1, #walkie_talkie.Frequencies)

                            walkie_talkie.Frequency = mode.TraitorFrequency

                            current_ply:ChatPrint("Walkie-Talkie Frequency = " .. walkie_talkie.Frequencies[mode.TraitorFrequency])
                        end
                    end
                end

                local give_flashlight_dark_map = gaymaps[game.GetMap()]
                local give_flashlight_traitor = current_ply.isTraitor and CONFIG_TRAITOR_FLASHLIGHT:GetValue()
                local give_flashlight_all = CONFIG_ALL_PLAYER_FLASHLIGHT:GetValue()

                if give_flashlight_all or give_flashlight_traitor or give_flashlight_dark_map then
                    local inv = current_ply:GetNetVar("Inventory") or {}

                    inv["Weapons"] = inv["Weapons"] or {}
                    inv["Weapons"]["hg_flashlight"] = true

                    current_ply:SetNetVar("Inventory", inv)
                end

                local hands = current_ply:Give("weapon_hands_sh")
                current_ply:SetActiveWeapon(hands)
                current_ply:SetNetVar("flashlight", false)

                local this_player = current_ply

                timer.Simple(0.1, function()
                    if IsValid(this_player) then
                        this_player.noSound = false
                        this_player:SetSuppressPickupNotices(false)
                    end
                end)

                timer.Simple(0.2 * index, function()
                    if not IsValid(this_player) then return end

                    local traitor_amt = 0
                    local traitor_assistants = {}

                    if this_player.isTraitor then
                        for _, other_ply in player.Iterator() do
                            if other_ply.isTraitor then
                                traitor_amt = traitor_amt + 1

                                if this_player.MainTraitor and other_ply.CurAppearance then
                                    local Appearance = other_ply.CurAppearance
                                    local color = Appearance.AColor or color_white
                                    local name = Appearance.AName or "error"
                                    local steamID = other_ply:SteamID() or ""

                                    if not IsColor(color) then
                                        color = Color(color.r, color.g, color.b)
                                    end

                                    table.insert(traitor_assistants, {color, name, steamID})
                                end
                            end
                        end
                    end

                    net.Start("HMCD_RoundStart")

                    net.WriteBool(this_player.isTraitor)
                    net.WriteBool(this_player.isGunner)
                    net.WriteString(mode.Type)
                    net.WriteBool(true)
                    net.WriteString(this_player.SubRole or "")
                    net.WriteBool(this_player.MainTraitor)

                    if this_player.isTraitor then
                        net.WriteString(mode.TraitorWord)
                        net.WriteString(mode.TraitorWordSecond)
                        net.WriteUInt(traitor_amt, mode.TraitorExpectedAmtBits)
                    else
                        net.WriteString("")
                        net.WriteString("")
                        net.WriteUInt(0, mode.TraitorExpectedAmtBits)
                    end

                    if this_player.MainTraitor then
                        for _, traitor_info in ipairs(traitor_assistants) do
                            net.WriteColor(traitor_info[1], false)
                            net.WriteString(traitor_info[2])
                        end

                        timer.Simple(0.5, function()
                            if IsValid(this_player) and this_player.isTraitor and this_player.MainTraitor then
                                net.Start("HMCD_UpdateTraitorAssistants")

                                net.WriteUInt(#traitor_assistants, 8)

                                for _, info in ipairs(traitor_assistants) do
                                    net.WriteColor(info[1])
                                    net.WriteString(info[2])
                                    net.WriteString(info[3])
                                end

                                net.Send(this_player)
                            end
                        end)
                    end

                    net.WriteString(this_player.Profession or "")

                    net.Send(this_player)

                    local role = mode.Roles[mode.Type][(this_player.isTraitor and "traitor") or (this_player.isGunner and "gunner") or "innocent"]

                    if role then
                        zb.GiveRole(this_player, role.name, role.color)
                    end
                end)
            end
        end
    end

    local function modifySubRoleSpawnFunction(role_name, spawn_function)
        local sub_role = mode.SubRoles[role_name]

        if not sub_role then return end

        sub_role.SpawnFunction = spawn_function
    end

    modifySubRoleSpawnFunction("traitor_default", function(player)
        local main_weapon = player:Give("weapon_hk_usp")

        hg.AddAttachmentForce(player, main_weapon, "supressor4")
        hg.AddAttachmentForce(player, main_weapon, "laser2")

        player:SetAmmo(15, "9x19 mm Parabellum")

        player:Give("weapon_pocketknife")
        player:Give("weapon_hg_rgd_tpik")
        player:Give("weapon_adrenaline")
        player:Give("weapon_hg_smokenade_tpik")
        player:Give("weapon_traitor_ied")
        player:Give("weapon_traitor_poison1")
        player:Give("weapon_traitor_suit")
        player:Give("weapon_hg_jam")

        player.organism.stamina.max = 220
    end)

    modifySubRoleSpawnFunction("traitor_default_soe", function(player)
        local main_weapon = player:Give("weapon_p22")

        hg.AddAttachmentForce(player, main_weapon, "supressor4")

        player:SetAmmo(15, ".22 Long Rifle")

        player:Give("weapon_sogknife")
        player:Give("weapon_hg_rgd_tpik")
        player:Give("weapon_adrenaline")
        player:Give("weapon_hg_smokenade_tpik")
        player:Give("weapon_traitor_ied")
        player:Give("weapon_traitor_poison1")
        player:Give("weapon_traitor_suit")
        player:Give("weapon_hg_jam")

        player.organism.stamina.max = 220
    end)

    modifySubRoleSpawnFunction("traitor_assasin", function(player)
        player:Give("weapon_breachcharge")
        player:Give("weapon_hg_flashbang_tpik")
        player:Give("weapon_traitor_ied")
        player:Give("weapon_hg_pipebomb_tpik")
        player:Give("weapon_hg_smokenade_tpik")
        player:Give("weapon_hg_slam")
        player:Give("weapon_hg_type59_tpik")

        player.organism.recoilmul = 0.8
        player.organism.stamina.max = 300
    end)

    modifySubRoleSpawnFunction("traitor_chemist", function(player)
        player:Give("weapon_sogknife")
        player:Give("weapon_adrenaline")
        player:Give("weapon_traitor_poison1")
        player:Give("weapon_traitor_poison2")
        player:Give("weapon_traitor_poison3")
        player:Give("weapon_traitor_poison4")
        player:Give("weapon_traitor_poison_consumable")
        player:Give("weapon_hg_shuriken")

        player.organism.stamina.max = 220
    end)

    -- MARK: Gun Man Weapons

    local gun_man_weapons_soe = {
        "weapon_remington870",
        "weapon_kar98",
        "weapon_revolver357",
        "weapon_m1911",
        "weapon_mosin"
    }

    mode.Types.soe.GunManLoot = function(player)
        local gun = player:Give(gun_man_weapons_soe[math.random(#gun_man_weapons_soe)])

        player.organism.recoilmul = 1.0

        if gun:GetClass() == "weapon_kar98" then
            hg.AddAttachmentForce(player, gun, "optic12")
        end

        local inv = player:GetNetVar("Inventory")
        inv["Weapons"]["hg_sling"] = true

        player:SetNetVar("Inventory", inv)
        player:SetNetVar("CurPluv", "pluvboss")
    end
end

if ZCITY_INITALIZED then
    modifyLoadouts()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide", function()
    modifyLoadouts()
end)
