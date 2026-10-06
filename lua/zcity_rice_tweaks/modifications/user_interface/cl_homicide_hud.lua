local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local function doUIChanges()
    local mode = zb.modes.hmcd

    local getFont = RiceUI.Font.Get

    local fade = 0
    local handicap = {
        "你是一位残疾人: 你的右腿断了",
        "你是一位残疾人: 你患有严重的肥胖症。",
        "你是一位残疾人: 你患有血友病。",
        "你是一位残疾人: 你身体残疾。"
    }

    function mode:HUDPaint()
        if not self.Type or not self.TypeObjectives[self.Type] then return end
        if lply:Team() == TEAM_SPECTATOR then return end

        if not StartTime then return end
        if StartTime + 12 < CurTime() then return end

        fade = Lerp(FrameTime() * 1, fade, math.Clamp(StartTime + 5 - CurTime(), -2, 2))

        draw.SimpleText("凶杀现场 | " .. (self.TypeNames[self.Type] or "Unknown"), getFont("RiceUI_M_96"), sw * 0.5,
            sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local Rolename = (lply.isTraitor and self.TypeObjectives[self.Type].traitor.name) or
            (lply.isGunner and self.TypeObjectives[self.Type].gunner.name) or self.TypeObjectives[self.Type].innocent.name

        local ColorRole = (lply.isTraitor and self.TypeObjectives[self.Type].traitor.color1) or
            (lply.isGunner and self.TypeObjectives[self.Type].gunner.color1) or
            self.TypeObjectives[self.Type].innocent.color1

        ColorRole.a = 255 * fade

        local color_role_innocent = self.TypeObjectives[self.Type].innocent.color1
        color_role_innocent.a = 255 * fade

        local color_white_faded = Color(255, 255, 255, 255 * fade)
        color_white_faded.a = 255 * fade

        draw.SimpleText("你是 " .. Rolename, getFont("RiceUI_M_64"), sw * 0.5, sh * 0.5, ColorRole,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local cur_y = sh * 0.5

        -- local ColorRole = ( lply.isTraitor and self.TypeObjectives[self.Type].traitor.color1 ) or ( lply.isGunner and self.TypeObjectives[self.Type].gunner.color1 ) or self.TypeObjectives[self.Type].innocent.color1
        -- ColorRole.a = 255 * fade
        if (lply.SubRole and lply.SubRole ~= "") then
            cur_y = cur_y + ScreenScale(20)

            draw.SimpleText(
                "" .. ((self.SubRoles[lply.SubRole] and self.SubRoles[lply.SubRole].Name or lply.SubRole) or lply.SubRole),
                getFont("RiceUI_M_64"), sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if (not lply.MainTraitor and lply.isTraitor) then
            cur_y = cur_y + ScreenScale(20)

            draw.SimpleText("你的同伙:", getFont("RiceUI_M_64"), sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER)
        end

        if (lply.isTraitor) then
            cur_y = cur_y + ScreenScale(20)

            if (lply.MainTraitor) then
                self.TraitorsLocal = self.TraitorsLocal or {}

                if (#self.TraitorsLocal > 1) then
                    draw.SimpleText("同伙列表:", getFont("RiceUI_32"), sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER)

                    for _, traitor_info in ipairs(self.TraitorsLocal) do
                        local traitor_color = Color(traitor_info[1].r, traitor_info[1].g, traitor_info[1].b, 255 * fade)
                        cur_y = cur_y + ScreenScale(16)

                        draw.SimpleTextOutlined(traitor_info[2], getFont("RiceUI_M_48"), sw * 0.5, cur_y, traitor_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, ColorAlpha(Color(100, 100, 100), 255 * fade))
                    end
                end
            else
                draw.SimpleText("接头暗号:", getFont("RiceUI_32"), sw * 0.5, cur_y, ColorRole,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                cur_y = cur_y + ScreenScale(15)

                draw.SimpleText("\"" .. self.TraitorWord .. "\"", getFont("RiceUI_32"), sw * 0.5, cur_y, color_white_faded,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                cur_y = cur_y + ScreenScale(15)

                draw.SimpleText("\"" .. self.TraitorWordSecond .. "\"", getFont("RiceUI_32"), sw * 0.5, cur_y,
                    color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        if (lply.Profession and lply.Profession ~= "") then
            cur_y = cur_y + ScreenScale(20)

            local profession_name = (self.Professions[lply.Profession] and self.Professions[lply.Profession].Name or lply.Profession) or lply.Profession

            draw.SimpleText("个人职业: " .. profession_name, getFont("RiceUI_32"), sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if (handicap[lply:GetLocalVar("karma_sickness", 0)]) then
            cur_y = cur_y + ScreenScale(20)

            draw.SimpleText(handicap[lply:GetLocalVar("karma_sickness", 0)], getFont("RiceUI_32"), sw * 0.5, cur_y,
                color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local Objective = (lply.isTraitor and self.TypeObjectives[self.Type].traitor.objective) or
            (lply.isGunner and self.TypeObjectives[self.Type].gunner.objective) or
            self.TypeObjectives[self.Type].innocent.objective

        if (lply.SubRole and lply.SubRole ~= "") then
            if (self.SubRoles[lply.SubRole] and self.SubRoles[lply.SubRole].Objective) then
                Objective = self.SubRoles[lply.SubRole].Objective
            end
        end

        if (not lply.MainTraitor and lply.isTraitor) then
            Objective = "没有为你准备多余的装备了，赤手空拳帮助其他杀手取得胜利吧。"
        end

        --; WARNING Traitor's objective is not lined up with SubRole's
        if (not self.RoleEndedChosingState) then
            Objective = "回合即将开始..."
        end

        local ColorObj = (lply.isTraitor and self.TypeObjectives[self.Type].traitor.color2) or
            (lply.isGunner and self.TypeObjectives[self.Type].gunner.color2) or
            self.TypeObjectives[self.Type].innocent.color2 or Color(255, 255, 255)

        ColorObj.a = 255 * fade

        draw.SimpleText(Objective, getFont("RiceUI_32"), sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER)

        if hg.PluvTown.Active then
            surface.SetMaterial(hg.PluvTown.PluvMadness)
            surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
            surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

            draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2),
                Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    zb.modesHooks.hmcd.HUDPaint = mode.HUDPaint
end

if ZCITY_INITALIZED then
    doUIChanges()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide_UI", function()
    doUIChanges()
end)
