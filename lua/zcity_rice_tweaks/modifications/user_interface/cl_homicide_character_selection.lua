local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local function doSelectPlayerRoleUIModification()
    local mode = zb.modes.hmcd

    function hg.SelectPlayerRole(role, mode_type)
        role = role or "Traitor"
        mode_type = mode_type or "soe"

        local frame = RiceUI.SimpleCreate{type = "rl_frame2",
            Center = true,
            Root = true,

            w = 968,
            h = 512,

            Title = "#zcity.ricetweaks.homicide.select_role",

            UseNewTheme = true,
            ThemeNT = {
                Theme = "Z-City",
                Class = "Frame",
                Color = "black"
            },

            children = {
                {type = "rl_horizontal_scrollpanel",
                    ID = "RoleList",

                    Dock = FILL,
                    Margin = {16, 16, 16, 16},

                    ScrollSpeed = 10,

                    DisableSmoothScroll = true
                }
            }
        }

        if mode.RoleChooseRoundTypes[mode_type] then
            local all_roles = mode.RoleChooseRoundTypes[mode_type][role]
            local role_cards = {}

            local convar = GetConVar(mode.ConVarName_SubRole_Traitor)

            if mode_type == "soe" then
                convar = GetConVar(mode.ConVarName_SubRole_Traitor_SOE)
            end

            for role_id, _ in pairs(all_roles) do
                local role_info = mode.SubRoles[role_id]
                local role_name = role_info.Name
                local role_description = role_info.Description

                table.insert(role_cards, {type = "rl_panel",
                    Dock = LEFT,
                    Margin = {0, 0, 16, 0},
                    w = 448,

                    ThemeNT = {
                        StyleSheet = {
                            Blur = false,
                        }
                    },

                    children = {
                        {type = "rl_panel",
                            Dock = TOP,
                            Margin = {16, 16, 0, 0},
                            h = 64,

                            ThemeNT = {
                                Class = "NoDraw"
                            },

                            children = {
                                {type = "rl_panel",
                                    Dock = LEFT,
                                    w = 6,

                                    ThemeNT = {
                                        Class = "NoDraw",
                                        Style = "Custom",
                                        StyleSheet = {
                                            Draw = function(self, w, h)
                                                surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))

                                                if convar:GetString() == role_id then
                                                    surface.SetDrawColor(self:RiceUI_GetColor("Panel", "AccentEnabled"))
                                                end

                                                surface.DrawRect(0, 0, w, h)
                                            end
                                        }
                                    }
                                },

                                {type = "label",
                                    Dock = FILL,
                                    Margin = {12, 0, 0, 0},

                                    Text = role_name,
                                    Font = "RiceUI_B_64"
                                }
                            }
                        },

                        {type = "label",
                            x = 16,
                            y = 96,

                            w = 416,

                            Text = role_description,
                            Font = "RiceUI_24",

                            NoResize = true,
                            Wrap = true
                        },

                        {type = "rl_button",
                            x = 0,
                            y = 0,

                            ThemeNT = {
                                Class = "NoDraw"
                            },

                            Text = "",

                            PerformLayout = function(self)
                                self:SetSize(self:GetParent():GetSize())
                            end,

                            DoClick = function()
                                if mode_type == "soe" then
                                    RunConsoleCommand(mode.ConVarName_SubRole_Traitor_SOE, role_id)
                                else
                                    RunConsoleCommand(mode.ConVarName_SubRole_Traitor, role_id)
                                end

                                surface.PlaySound("ricelib_userinterface/arc9_eft_shared/weap_rifle_pickup.ogg")
                            end
                        }
                    }
                })
            end

            RiceUI.Create(role_cards, frame:GetElement("RoleList"))
            RiceUI.ApplyTheme(frame)
        end
    end
end

if ZCITY_INITALIZED then
    doSelectPlayerRoleUIModification()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide_SelectPlayerRoleUI", function()
    doSelectPlayerRoleUIModification()
end)
