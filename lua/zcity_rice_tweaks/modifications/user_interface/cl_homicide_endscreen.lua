local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local function doEndScreenModification()
    local mode = zb.modes.hmcd

    local getFont = RiceUI.Font.Get

    local function createEndMenu(traitors)
        local getLanguagePhrase = RiceLib.Languages.GetPhrase
        local getFont = RiceUI.Font.Get

        surface.PlaySound("ambient/alarms/warningbell1.wav")

        local frame = RiceUI.SimpleCreate{type = "rl_frame2",
            w = 512,
            h = 960,

            Alpha = 0,

            Title = "#zcity.ricetweaks.homicide.end_menu.title",

            ThemeNT = {
                Theme = "Z-City",
                Class = "Frame",
                Color = "black"
            },

            ShouldRemove = CurTime() + 5,

            Think = function(self)
                if self.ShouldRemove > CurTime() then return end
                self.ShouldRemove = math.huge

                self:RiceUI_MoveTo{
                    X = ScrW(),

                    Time = 2,

                    Callback = function()
                        if IsValid(self) then
                            self:Remove()
                        end
                    end
                }

                self:RiceUI_AlphaTo{
                    Alpha = 0,

                    Time = 1
                }
            end,

            children = {
                {type = "rl_scrollpanel",
                    ID = "PlayerList",

                    Dock = FILL,
                    Margin = {16, 16, 16, 16},

                    ScrollSpeed = 10,

                    DisableSmoothScroll = true,

                    children = {
                        {type = "rl_panel",
                            ID = "Traitors",

                            Dock = TOP,
                            Margin = {0, 0, 0, 8},
                            Padding = {16, 48, 16, 0},

                            ThemeNT = {
                                Class = "NoDraw",
                                Style = "Custom",
                                StyleSheet = {
                                    Draw = function(self, w, h)
                                        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Layer"))
                                        surface.DrawRect(0, 0, w, h)

                                        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))
                                        surface.DrawRect(0, 0, RICEUI_SIZE_4, h)

                                        draw.SimpleText(getLanguagePhrase("zcity.ricetweaks.homicide.end_menu.traitor"), getFont("RiceUI_M_32"), RICEUI_SIZE_16, RICEUI_SIZE_8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                                    end
                                }
                            }
                        },

                        {type = "rl_panel",
                            ID = "Gunners",

                            Dock = TOP,
                            Margin = {0, 0, 0, 8},
                            Padding = {16, 48, 16, 0},

                            ThemeNT = {
                                Class = "NoDraw",
                                Style = "Custom",
                                StyleSheet = {
                                    Draw = function(self, w, h)
                                        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Layer"))
                                        surface.DrawRect(0, 0, w, h)

                                        surface.SetDrawColor(HexToColor("#00AAFF"))
                                        surface.DrawRect(0, 0, RICEUI_SIZE_4, h)

                                        draw.SimpleText(getLanguagePhrase("zcity.ricetweaks.homicide.end_menu.gunner"), getFont("RiceUI_M_32"), RICEUI_SIZE_16, RICEUI_SIZE_8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                                    end
                                }
                            }
                        },

                        {type = "rl_panel",
                            ID = "Innocents",

                            Dock = TOP,
                            Margin = {0, 0, 0, 8},
                            Padding = {16, 48, 16, 0},

                            ThemeNT = {
                                Class = "NoDraw",
                                Style = "Custom",
                                StyleSheet = {
                                    Draw = function(self, w, h)
                                        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Layer"))
                                        surface.DrawRect(0, 0, w, h)

                                        surface.SetDrawColor(HexToColor("#AAAAAA"))
                                        surface.DrawRect(0, 0, RICEUI_SIZE_4, h)

                                        draw.SimpleText(getLanguagePhrase("zcity.ricetweaks.homicide.end_menu.innocent"), getFont("RiceUI_M_32"), RICEUI_SIZE_16, RICEUI_SIZE_8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                                    end
                                }
                            }
                        },
                    }
                }
            }
        }

        frame:SetX(ScrW())
        frame:SetY(ScrH() / 2 - frame:GetTall() / 2)

        frame:RiceUI_MoveTo{
            X = ScrW() - frame:GetWide() - RICEUI_SIZE_32,

            Time = 2
        }

        frame:RiceUI_AlphaTo{
            Alpha = 255,

            Time = 1
        }

        local function playerCard(info)
            local player = info.Player
            local is_bot = player:IsBot()

            return {type = "rl_panel",
                Dock = TOP,
                Margin = {0, 0, 0, 8},
                h = 64,

                ThemeNT = {
                    Class = "NoDraw",
                    Style = "Custom",
                    StyleSheet = {
                        Draw = function(self, w, h)
                            local layer_color = self:RiceUI_GetColor("Panel", "Layer")

                            if not info.Alive then
                                layer_color = HexToColor("#FF000050")

                                RiceUI.Render.ShadowText(getLanguagePhrase("zcity.ricetweaks.homicide.end_menu.dead"), getFont("RiceUI_B_48"), w - RICEUI_SIZE_16, h / 2, Color(255, 255, 255, 30), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 100)
                            end

                            if info.InCapacitated then
                                layer_color = HexToColor("#FFAA0050")

                                RiceUI.Render.ShadowText(getLanguagePhrase("zcity.ricetweaks.homicide.end_menu.incapacitated"), getFont("RiceUI_B_48"), w - RICEUI_SIZE_16, h / 2, Color(255, 255, 255, 30), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 100)
                            end

                            surface.SetDrawColor(layer_color)
                            surface.DrawRect(0, 0, w, h)

                            surface.SetDrawColor(self:RiceUI_GetColor("Panel", "LayerShadow"))
                            surface.DrawRect(0, h - RICEUI_SIZE_4, w, RICEUI_SIZE_4)
                        end
                    }
                },

                children = {
                    {type = "rl_panel",
                        Dock = LEFT,
                        Margin = {8, 8, 0, 8},
                        w = 4,

                        ShouldCreate = function()
                            return player:IsAdmin() or is_bot
                        end,

                        ThemeNT = {
                            Style = "AdminIndicator",
                            StyleSheet = {
                                IsAdmin = player:IsAdmin(),
                                IsSuperAdmin = player:IsSuperAdmin(),
                                IsBot = is_bot
                            }
                        }
                    },

                    {type = "player_profile",
                        Dock = LEFT,
                        Margin = {8, 8, 0, 8},

                        PerformLayout = function(self)
                            self:SetWide(self:GetTall())
                        end,

                        Player = player
                    },

                    {type = "label",
                        Dock = LEFT,
                        Margin = {16, 0, 0, 0},

                        Text = info.CharacterName .. " - " .. info.PlayerName,
                        Font = "Source_32"
                    }
                }
            }
        end

        local players = {}

        for _, ply in player.Iterator() do
            if ply:Team() == TEAM_SPECTATOR then continue end

            players[#players + 1] = {
                PlayerName = ply:Nick(),
                CharacterName = ply:GetPlayerName(),
                IsTraitor = ply.isTraitor,
                IsGunner = ply.isGunner,
                InCapacitated = ply.organism and ply.organism.otrub,
                Alive = ply:Alive(),
                Color = ply:GetPlayerColor():ToColor(),
                Frags = ply:Frags(),
                SteamID64 = ply:IsBot() and "BOT" or ply:SteamID64(),

                Player = ply
            }
        end

        local traitor_cards = {}
        local gunner_cards = {}
        local innocents_cards = {}

        for _, info in ipairs(players) do
            if info.IsTraitor then
                table.insert(traitor_cards, playerCard(info))

                continue
            end

            if info.IsGunner then
                table.insert(gunner_cards, playerCard(info))

                continue
            end

            table.insert(innocents_cards, playerCard(info))
        end

        local traitors_panel = frame:GetElement("Traitors")
        RiceUI.Create(traitor_cards, traitors_panel)

        traitors_panel:FitContents_Vertical(RICEUI_SIZE_16)

        local gunners_panel = frame:GetElement("Gunners")
        RiceUI.Create(gunner_cards, gunners_panel)

        gunners_panel:FitContents_Vertical(RICEUI_SIZE_16)


        local innocents_panel = frame:GetElement("Innocents")
        RiceUI.Create(innocents_cards, innocents_panel)

        innocents_panel:FitContents_Vertical(RICEUI_SIZE_16)

        RiceUI.ApplyTheme(frame)
    end

    net.Receive("hmcd_roundend", function()
        local traitors, gunners = {}, {}

        for _ = 1, net.ReadUInt(mode.TraitorExpectedAmtBits) do
            net.ReadEntity().isTraitor = true
        end

        for _ = 1, net.ReadUInt(mode.TraitorExpectedAmtBits) do
            net.ReadEntity().isGunner = true
        end

        timer.Simple(2.5, function()
            local local_player = LocalPlayer()

            local_player.isPolice = false
            local_player.isTraitor = false
            local_player.isGunner = false
            local_player.MainTraitor = false
            local_player.SubRole = nil
            local_player.Profession = nil
        end)

        createEndMenu(traitors)
    end)

    concommand.Add("zcity_rice_tweaks_ui_endscreen", function()
        if not LocalPlayer():IsSuperAdmin() then return end

        createEndMenu()
    end)
end

if ZCITY_INITALIZED then
    doEndScreenModification()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide_EndScreen", function()
    doEndScreenModification()
end)
