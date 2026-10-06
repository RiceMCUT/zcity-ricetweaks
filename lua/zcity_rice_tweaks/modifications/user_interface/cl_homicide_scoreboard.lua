local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local function getCurrentRound()
    return zb.modes[zb.CROUND]
end

local function doScoreboardModification()
    local GM = GM or GAMEMODE

    local Scoreboard

    function GM:ScoreboardShow()
        local current_round = getCurrentRound()

        local sub_mode = ""

        if current_round.TypeNames then
            sub_mode = " | " .. (current_round.TypeNames[current_round.Type] or "Unknown")
        end

        if IsValid(Scoreboard) then
            Scoreboard.Closing = false
            Scoreboard.ThemeNT.StyleSheet.Blur = true

            return
        end

        local target_x, target_y = 0, 0

        Scoreboard = RiceUI.SimpleCreate{type = "rl_panel",
            w = 1200,
            h = 960,

            UseNewTheme = true,
            ThemeNT = {
                Theme = "Z-City",
                Color = "black",
                StyleSheet = {
                    DrawShadows = true
                }
            },

            Fraction = 0,

            OnMousePressed = function(self, code)
                if code == MOUSE_RIGHT then
                    RiceUI.EnableClick(self)

                    return
                end

                self:MouseCapture(true)
            end,

            Think = function(self)
                local closing = self.Closing
                local fraction = math.Approach(self.Fraction, (closing and 0) or 1, RealFrameTime() * 8)

                if closing and fraction <= 0.05 then
                    self:Remove()
                end

                self.Fraction = fraction

                local ease_function = math.ease.OutQuint

                if closing then
                    ease_function = math.ease.InQuint
                end

                self:SetPos(target_x, Lerp(math.max(0, fraction), target_y + RICEUI_SIZE_32, target_y))
                self:SetAlpha(Lerp(math.max(0, fraction), 0, 255))
            end,

            children = {
                {type = "rl_panel",
                    Dock = TOP,
                    h = 72,

                    ThemeNT = {
                        Style = "Card"
                    },

                    children = {
                        {type = "label",
                            Dock = LEFT,
                            Margin = {16, 0, 0, 0},

                            ShouldCreate = function()
                                return sub_mode ~= nil and current_round.PrintName ~= nil
                            end,

                            Text = Format("Z-City [ %s%s ]", current_round.PrintName, sub_mode),
                            Font = "RiceUI_B_48"
                        },

                        {type = "label",
                            Dock = RIGHT,
                            Margin = {0, 0, 16, 0},

                            Text = Format("玩家: %d / %d", player.GetCount(), game.MaxPlayers()),
                            Font = "RiceUI_32"
                        },
                    }
                },

                {type = "rl_scrollpanel",
                    ID = "PlayerList",
                    Dock = FILL,

                    Margin = {8, 8, 8, 8},

                    ScrollSpeed = 10,

                    DisableSmoothScroll = true
                },

                {type = "rl_panel",
                    Dock = BOTTOM,
                    h = 64,

                    children = {
                        {type = "rl_button",
                            Dock = RIGHT,
                            Margin = {0, 12, 12, 12},
                            w = 128,

                            Text = (LocalPlayer():Team() == TEAM_SPECTATOR and "加入玩家") or "加入旁观者",

                            DoClick = function(self)
                                local to_specator = LocalPlayer():Team() ~= TEAM_SPECTATOR

                                net.Start("ZB_SpecMode")
                                net.WriteBool(to_specator)
                                net.SendToServer()

                                if to_specator then
                                    self.Text = "加入玩家"
                                    self.Enabled = true
                                else
                                    self.Text = "加入旁观者"
                                    self.Enabled = false
                                end
                            end
                        }
                    }
                }
            }
        }

        Scoreboard:MouseCapture(true)

        target_x, target_y = ScrW() / 2 - Scoreboard:GetWide() / 2, ScrH() / 2 - Scoreboard:GetTall() / 2

        local player_list = Scoreboard:GetElement("PlayerList")
        local player_cards = {}

        for _, ply in player.Iterator() do
            --- @cast ply Player

            local player_muted = ply:GetVoiceVolumeScale() == 0
            local is_bot = ply:IsBot()

            table.insert(player_cards, {type = "rl_panel",
                Dock = TOP,
                Margin = {8, 8, 8, 0},
                h = 64,

                ThemeNT = {
                    Style = "Layer"
                },

                children = {
                    {type = "rl_panel",
                        Dock = LEFT,
                        Margin = {8, 8, 0, 8},
                        w = 4,

                        ShouldCreate = function()
                            return ply:IsAdmin() or is_bot
                        end,

                        ThemeNT = {
                            Style = "AdminIndicator",
                            StyleSheet = {
                                IsAdmin = ply:IsAdmin(),
                                IsSuperAdmin = ply:IsSuperAdmin(),
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

                        Player = ply
                    },

                    {type = "label",
                        Dock = LEFT,
                        Margin = {16, 0, 0, 0},

                        Text = ply:Nick(),
                        Font = "Source_32"
                    },

                    {type = "rl_button",
                        Dock = RIGHT,
                        Margin = {0, 8, 8, 8},
                        w = 96,

                        Text = (player_muted and "#zcity.ricetweaks.unmute_player") or "#zcity.ricetweaks.mute_player",
                        Enabled = not player_muted,

                        ShouldCreate = function()
                            return ply ~= LocalPlayer() and not is_bot
                        end,

                        DoClick = function(self)
                            if ply:GetVoiceVolumeScale() == 0 then
                                ply:SetVoiceVolumeScale(1)

                                self.Enabled = true

                                return
                            end

                            ply:SetVoiceVolumeScale(0)

                            self.Enabled = false
                        end,
                    },

                    {type = "label",
                        Dock = RIGHT,
                        Margin = {0, 0, 16, 0},

                        Text = Format("%dms", ply:Ping()),
                        Font = "RiceUI_M_32",

                        ShouldCreate = function()
                            return not is_bot
                        end,
                    }
                }
            })
        end

        RiceUI.Create(player_cards, player_list)
        RiceUI.ApplyTheme(player_list)
    end

    function GM:ScoreboardHide()
        if not IsValid(Scoreboard) then return end

        Scoreboard.Closing = true
        Scoreboard.ThemeNT.StyleSheet.Blur = false
    end
end

if ZCITY_INITALIZED then
    doScoreboardModification()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide_Scoreboard", function()
    doScoreboardModification()
end)
