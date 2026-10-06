local registerClass = RiceUI.ThemeNT.RegisterClass
local getFont = RiceUI.Font.Get

--- @type RiceLib.Libraries.RNDX
local RNDX = include("ricelib_libraries/rndx.lua")

local getLanguagePhrase = RiceLib.Languages.GetPhrase

local cross = Material("rl_icons/xmark.png")

local function getPhrase(input)
    if string.StartsWith(input, "#") then
        return getLanguagePhrase(string.TrimLeft(input, "#"))
    end

    return input
end

local colors = {
    black = {
        Panel = {
            Accent = HexToColor("#C10000"),
            AccentEnabled = HexToColor("#40CC20"),

            Layer = HexToColor("#00000050"),
            LayerShadow = HexToColor("#00000030"),

            CardShadow = HexToColor("#00000050"),

            Background = HexToColor("#000000CC"),
            BackgroundStroke = HexToColor("#FFFFFF05"),
        },

        AdminIndicator = {
            Admin = HexToColor("#88DDFF"),
            SuperAdmin = HexToColor("#FFEE33"),
            Bot = HexToColor("#AAAAAA")
        },

        Text = {
            Primary = color_white
        }
    },
}

RiceUI.ThemeNT.DefineTheme("Z-City", {
    Base = "Modern",
    BaseNT = true,
    Colors = colors
})

registerClass("Z-City", "Panel", {
    Default = function(self, w, h, style)
        local blur = self.Blur or true

        if blur then
            surface.SetDrawColor(255, 255, 255)

            local rect = RNDX.Rect(0, 0, w, h)
                :ManualColor()
                :KBlur(2, 3)
                :AcrylicBurn(Color(120, 120, 120), 0)
                :AcrylicTint(Color(255, 255, 255), 0.2)
                :AcrylicNoise(0.08, 4)
                :AcrylicFresnel(Color(255, 255, 255), 0.3, 0.4)
                :Draw()
        end

        if style.DrawShadows then
            surface.SetDrawColor(0, 0, 0, 100)

            local rect = RNDX.Rect(0, 0, w, h)
                :ManualColor()
                :Shadow(16, 2, RICEUI_SIZE_2, RICEUI_SIZE_4)
                :Draw()
        end

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Background"))
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "BackgroundStroke"))
        surface.DrawOutlinedRect(0, 0, w, h, RICEUI_SIZE_2)
    end,

    Layer = function(self, w, h, style)
        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Layer"))
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "LayerShadow"))
        surface.DrawRect(0, h - RICEUI_SIZE_4, w, RICEUI_SIZE_4)
    end,

    Card = function(self, w, h, style)
        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "CardShadow"))
        surface.DrawRect(0, h - RICEUI_SIZE_4, w, RICEUI_SIZE_4)
    end,

    AdminIndicator = function(self, w, h, style)
        local admin_type = "Admin"

        if style.IsSuperAdmin then
            admin_type = "SuperAdmin"
        end

        if style.IsBot then
            admin_type = "Bot"
        end

        surface.SetDrawColor(self:RiceUI_GetColor("AdminIndicator", admin_type))
        surface.DrawRect(0, 0, w, h)
    end
})

registerClass("Z-City", "Frame", {
    Default = function(self, w, h, style)
        local blur = style.Blur or 3

        if blur > 0 then
            RiceLib.VGUI.blurPanel(self, blur)

            RNDX.DrawBlur(0, 0, w, h)
        end

        if style.DrawShadows then
            RNDX.DrawShadows(0, RICEUI_SIZE_4, RICEUI_SIZE_4, w, h, Color(0, 0, 0, 50), 16, 32)
        end

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Background"))
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "BackgroundStroke"))
        surface.DrawOutlinedRect(0, 0, w, h, RICEUI_SIZE_2)

        local header_tall = RiceUI.Scale.Size(48)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))
        surface.DrawRect(0, 0, w, header_tall)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "CardShadow"))
        surface.DrawRect(0, header_tall - RICEUI_SIZE_4, w, RICEUI_SIZE_4)
    end
})

registerClass("Z-City", "Button", {
    Default = function(self, w, h, style)
        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))

        if self.Enabled then
            surface.SetDrawColor(self:RiceUI_GetColor("Panel", "AccentEnabled"))
        end

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(self:RiceUI_GetColor("Panel", "CardShadow"))
        surface.DrawRect(0, h - RICEUI_SIZE_4, w, RICEUI_SIZE_4)

        draw.SimpleText(getPhrase(self.Text), getFont(self:GetFont()), w / 2, h / 2, self:RiceUI_GetColor("Text", "Primary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end,

    Close = function(self, w, h, style)
        surface.SetDrawColor(self:RiceUI_GetColor("Text", "Primary"))
        surface.SetMaterial(cross)
        surface.DrawTexturedRectRotated(w / 2, h / 2, h / 2, h / 2, 0)
    end,

    Transparent = function(self, w, h, style)
        draw.SimpleText(getPhrase(self.Text), getFont(self:GetFont()), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end,
})

registerClass("Z-City", "RL_NumberWang", {
    Default = function(self, w, h, style)
        local textColor = self:RiceUI_GetColor("Text", "Primary")
        local hasFocus = self:HasFocus()

        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, w, h)

        if hasFocus then
            surface.SetDrawColor(self:RiceUI_GetColor("Panel", "Accent"))
            surface.DrawRect(0, h - RICEUI_SIZE_2, w, RICEUI_SIZE_2)
        end

        if hasFocus then
            local len = RICEUI_SIZE_8

            for i = 1, self:GetCaretPos() do
                local w = RiceLib.VGUI.TextWide(self:GetFont(), utf8.sub(self:GetText(), i, i))

                len = len + w
            end
            draw.SimpleText(self:GetText(), self:GetFont(), RICEUI_SIZE_8, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(ColorAlpha(textColor, 255 * math.abs(math.sin(RealTime() * 4))))
            surface.DrawRect(len, RICEUI_SIZE_4, RICEUI_SIZE_2, h - RICEUI_SIZE_8)
        else
            draw.SimpleText(self:GetValue(), self:GetFont(), RICEUI_SIZE_8, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end,
})
