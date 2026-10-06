if SERVER then
    RiceLib.Net.RegisterReceiver("ZCity_RiceTweaks_Troll", {
        PlaySound = function(data, ply)
            if not ply:IsSuperAdmin() then return end

            local target_players, sound = data.TargetPlayers, data.Sound
            local resolved_players = {}
            local players = player.GetAll()

            for _, index in ipairs(target_players) do
                local player_entity = players[index]

                if IsValid(player_entity) then
                    table.insert(resolved_players, player_entity)
                end
            end

            PrintTable(resolved_players)

            RiceLib.Net.Send{
                NameSpace = "ZCity_RiceTweaks_Troll",
                Command = "PlaySound",
                Data = sound,
                TargetPlayer = resolved_players
            }
        end
    })

    return
end

local sound_browser

local function open()
    if IsValid(sound_browser) then
        sound_browser:SetVisible(true)
        sound_browser:AlphaTo(255, RiceUI.Animation.GetTime("Instant"))

        return
    end

    sound_browser = RiceUI.SimpleCreate{type = "rl_frame2",
        Center = true,
        Root = true,

        w = 1200,
        h = 768,

        ThemeNT = {
            Theme = "Modern",
            Class = "Frame",
            Style = "Acrylic",
            Color = "black"
        },

        Title = "Sound Browser",

        DoClose = function(self)
            self:AlphaTo(0, RiceUI.Animation.GetTime("Instant"), 0, function()
                if not IsValid(self) then return end

                self:SetVisible(false)
            end)
        end,

        PlaySound = function(self, soundName)
            if not isbool(self.SoundChannel) and IsValid(self.SoundChannel) then
                self.SoundChannel:Stop()
            end

            self:GetElement("NowPlaying"):SetText(Format("正在播放: %s", soundName))

            self.SoundChannel = true
            sound.PlayFile(soundName, "noblock", function(channel)
                self.SoundChannel = channel

                channel:Play()

                local rate = self:GetElement("PlaybackRate")

                channel:SetPlaybackRate(100 / rate:GetValue())
            end)
        end,

        children = {
            {type = "rl_panel",
                Dock = LEFT,
                w = 292,

                ThemeNT = {
                    Class = "Layer"
                },

                children = {
                    {type = "rl_node",
                        ID = "FileTree",
                        Dock = FILL,
                    }
                }
            },

            {type = "rl_panel",
                Dock = FILL,
                Margin = {16, 0, 16, 16},

                ThemeNT = {
                    Class = "NoDraw"
                },

                children = {
                    {type = "rl_panel",
                        Dock = FILL,
                        Margin = {0, 0, 0, 16},

                        ThemeNT = {
                            Class = "Layer"
                        },

                        children = {
                            {type = "rl_scrollpanel",
                                ID = "FileList",

                                Dock = FILL,

                                ScrollSpeed = 3
                            }
                        }
                    },

                    {type = "rl_panel",
                        Dock = BOTTOM,
                        h = 128,

                        ThemeNT = {
                            Class = "Layer"
                        },

                        children = {
                            {type = "label",
                                ID = "NowPlaying",

                                Dock = TOP,
                                Margin = {16, 8, 0, 0},

                                Text = "正在播放:"
                            },

                            {type = "rl_slider",
                                ID = "PlaybackRate",

                                Dock = TOP,
                                Margin = {16, 8, 16, 0},

                                Max = 255,
                                Value = 100,

                                OnValueChanged = function(self)
                                    if not IsValid(sound_browser) then return end

                                    local val = self:GetValue()
                                    local soundChannel = sound_browser.SoundChannel

                                    if not IsValid(soundChannel) then return end
                                    soundChannel:SetPlaybackRate(100 / val)
                                end
                            }
                        }
                    },
                }
            }
        }
    }

    local tree = sound_browser:GetElement("FileTree")

    local node = tree:AddNode("sound")
    node:MakeFolder("sound", "GAME")

    function tree:OnNodeSelected(node)
        local path = node:GetFolder()

        local panels = {}
        for _, fileName in ipairs(select(1, file.Find(path .. "/*", "GAME")), true) do
            table.insert(panels, {type = "rl_button",
                Dock = TOP,
                h = 32,

                ThemeNT = {
                    Style = "ComboChoice"
                },

                Text = fileName,

                OnCursorEntered = function(self)
                    if not input.IsMouseDown(MOUSE_LEFT) then return end

                    self:DoClick()
                end,

                DoClick = function(self)
                    local soundName = Format("%s/%s", path, fileName)

                    sound_browser:PlaySound(soundName)

                    for _, btn in ipairs(self:GetParent():GetChildren()) do
                        btn.Selected = false
                    end

                    self.Selected = true
                end,

                DoRightClick = function(self)
                    local soundName = Format("%s/%s", path, fileName)

                    SetClipboardText(soundName)
                end
            })
        end

        local fileList = sound_browser:GetElement("FileList")
        fileList:Clear()
        fileList:SetScroll(0)
        RiceUI.Create(panels, fileList)

        RiceUI.ApplyTheme(fileList)
    end
end

concommand.Add("rice_addontools_sound_browser", open)

local function openSoundMenu()
    local frame
    local selected_players = {}
    local sound_path

    frame = RiceUI.SimpleCreate{type = "rl_frame2",
        Center = true,
        Root = true,

        w = 960,
        h = 640,

        Title = "向玩家播放声音 (左边选择玩家)",

        ThemeNT = {
            Theme = "Modern",
            Class = "Frame",
            Style = "Acrylic",
            StyleSheet = {
                DrawShadows = true
            },
            Color = "black"
        },

        children = {
            {type = "rl_panel",
                Dock = LEFT,
                Margin = {0, 0, 16, 0},
                w = 292,

                ThemeNT = {
                    Style = "Layer"
                },

                children = {
                    {type = "rl_scrollpanel",
                        ID = "PlayerList",

                        Dock = FILL,
                        Margin = {8, 8, 8, 8},
                    }
                }
            },

            {type = "rl_panel",
                Dock = FILL,
                Margin = {0, 0, 16, 0},

                ThemeNT = {
                    Class = "NoDraw"
                },

                children = {
                    {type = "entry",
                        ID = "SoundName",

                        Dock = TOP,
                        Margin = {0, 0, 0, 8},

                        Placeholder = "输入声音路径",

                        OnValueChange = function(self, val)
                            sound_path = val
                        end
                    },

                    {type = "rl_button",
                        Dock = TOP,
                        h = 40,

                        Text = "播放",

                        DoClick = function()
                            if not sound_path or sound_path == "" then
                                return
                            end

                            local target_players = {}
                            for ply, selected in pairs(selected_players) do
                                if selected then
                                    table.insert(target_players, ply:EntIndex())
                                end
                            end

                            if #target_players > 0 then
                                RiceLib.Net.Send{
                                    NameSpace = "ZCity_RiceTweaks_Troll",
                                    Command = "PlaySound",

                                    Data = {
                                        TargetPlayers = target_players,
                                        Sound = sound_path
                                    }
                                }
                            end
                        end
                    }
                }
            },
        }
    }

    local players_element = {}

    for _, ply in player.Iterator() do
        table.insert(players_element, {type = "rl_button",
            Dock = TOP,
            h = 40,

            ThemeNT = {
                Style = "ComboChoice"
            },

            Text = ply:Nick(),

            DoClick = function(self)
                selected_players[ply] = not selected_players[ply]

                self.Selected = selected_players[ply]
            end
        })
    end

    RiceUI.Create(players_element, frame:GetElement("PlayerList"))
    RiceUI.ApplyTheme(frame)
end

RiceLib.Net.RegisterReceiver("ZCity_RiceTweaks_Troll", {
    PlaySound = function(sound_path)
        surface.PlaySound(sound_path)
    end
})

concommand.Add("zcity_rice_tweaks_troll_opensoundmenu", openSoundMenu, nil, "Opens the sound menu for ZCity Rice Tweaks.")
