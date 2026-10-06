if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "'Liminalin' Serotonin"
SWEP.Instructions = [[]]
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/morphine_syrette/morphine.mdl"

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/icons/ico_fent.png")
    SWEP.IconOverride = "vgui/icons/ico_fent.png"
    SWEP.BounceWeaponIcon = false
end

SWEP.AdminOnly = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1.5, 0)
SWEP.offsetAng = Angle(-30, 20, 180)
SWEP.Color = Color(0, 90, 255)
SWEP.modeNames = {
    [1] = "Liminalin"
}

function SWEP:InitializeAdd()
    self:SetHold(self.HoldType)

    self.modeValues = {
        [1] = 1
    }
end

SWEP.modeValuesdef = {
    [1] = 1
}

SWEP.DeploySnd = ""
SWEP.HolsterSnd = ""

SWEP.showstats = false

local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or
CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

function SWEP:Think()
    self:SetBodyGroups("11")
    if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
        self:SetHolding(math.max(self:GetHolding() - 4, 0))
    end
end

function SWEP:Animation()
	local hold = self:GetHolding()
    self:BoneSet("r_upperarm", vector_origin, Angle(0, -hold + (100 * (hold / 100)), 0))
    self:BoneSet("r_forearm", vector_origin, Angle(-hold / 6, -hold * 2, -15))
end

function SWEP:NPCHeal(npc, mul, snd)
    if not npc then npc = self:GetOwner() end

    if npc:IsNPC() then
        self:SetHold("melee")
        if not mul then mul = 0.3 end
        npc:SetHealth(math.Clamp(npc:Health() + (npc:GetMaxHealth() * 1 * mul), 0,
            npc:GetMaxHealth() * math.Clamp(2 * mul, 2, 100)))
        npc:EmitSound(snd or "snd_jack_hmcd_needleprick.wav", 80, math.random(95, 105))
        npc:SetPlaybackRate(6)
        npc:SetKeyValue("m_flPlaybackSpeed", 6)

        if SERVER then
            self:Remove()
        end
    end
end

function SWEP:OwnerChanged()
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsNPC() then
        self:SpawnGarbage(nil, nil, nil, self.Color, "2211")
        self:NPCHeal(owner, 20, "snd_jack_hmcd_needleprick.wav")
    end
end

if SERVER then
    function SWEP:Heal(ent, mode)
        if ent:IsNPC() then
            self:SpawnGarbage(nil, nil, nil, self.Color, "2211")

            return
        end

        local organism = ent.organism
        if not organism then return end

        local owner = self:GetOwner()
        if ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
            self:SetHolding(math.min(self:GetHolding() + 4, 100))

            if self:GetHolding() < 100 then return end
        end

        local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
        entOwner:EmitSound("snd_jack_hmcd_needleprick.wav", 80, math.random(115, 120))

        organism.temperature = 33
        organism.consciousness = 0
        organism.Liminalin = 1

        owner:SelectWeapon("weapon_hands_sh")
        self:SpawnGarbage(nil, nil, nil, self.Color, "2211")
        self:Remove()
    end
end

local delay = 0
hook.Add("Think", "Liminalin_Send", function()
    if CLIENT then return end

    if delay > CurTime() then
        return
    end

    delay = CurTime() + 0.1

    for _, ply in player.Iterator() do
        local organism = ply.organism
        if not organism then continue end
        if not organism.Liminalin then continue end

        organism.Liminalin = math.Approach(organism.Liminalin or 0, 0, 0.001)

        if organism.Liminalin <= 0 then
            organism.temperature = 33
            organism.consciousness = 0
            organism.Liminalin = nil

            RiceLib.Net.Send{
                NameSpace = "ZCity_RiceTweaks_Liminalin",
                Command = "Set",
                Data = 0,
                TargetPlayer = ply
            }

            return
        end

        RiceLib.Net.Send{
            NameSpace = "ZCity_RiceTweaks_Liminalin",
            Command = "Set",
            Data = organism.Liminalin,
            TargetPlayer = ply,
            Unreliable = true
        }
    end
end)

hook.Add("PlayerCanHearPlayersVoice", "Maximum Range", function(listener, talker)
    local organism = listener.organism
    if not organism then return end
    if not organism.Liminalin then return end

    if organism.Liminalin > 0 then
        return false
    end
end)

if CLIENT then
    RiceLib.Net.RegisterReceiver("ZCity_RiceTweaks_Liminalin", {
        Set = function(value)
            local organism = LocalPlayer().organism
            if not organism then return end

            organism.Liminalin = value
        end
    })

    hook.Add("PreDrawViewModels", "Liminalin_MirrorWorld", function()
        local organism = LocalPlayer().organism
        if not organism then return end

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        render.UpdateScreenEffectTexture()
        render.DrawTextureToScreenRect(render.GetScreenEffectTexture(), ScrW(), 0, -ScrW(), ScrH())
    end)

    hook.Add("HG.InputMouseApply", "Liminalin_MirrorWorld", function(input_table)
        local organism = LocalPlayer().organism
        if not organism then return end

        local x, y, ang = input_table.x, input_table.y, input_table.angle

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        input_table.angle = ang + Angle(0, x / 22.5, 0)
    end)

    hook.Add("CreateMove", "Liminalin_MirrorWorld", function(cmd)
        local organism = LocalPlayer().organism
        if not organism then return end

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        cmd:SetSideMove(-cmd:GetSideMove())
    end)

    local modify = {
        ["$pp_colour_addr"] = -0.2,
        ["$pp_colour_addg"] = -0.2,
        ["$pp_colour_addb"] = 0.1,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 2,
        ["$pp_colour_colour"] = 0.6,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0.2
    }

    hook.Add("RenderScreenspaceEffects", "Liminalin_Effects", function()
        local organism = LocalPlayer().organism
        if not organism then return end

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        DrawColorModify(modify)

        DrawBloom(0.5, 3, 8, 4, 1, 1, 1, 1, 1)

        DrawSharpen(1.2, 1.2)
    end)

    hook.Add("PrePlayerDraw", "Liminalin_HidePlayers", function()
        local organism = LocalPlayer().organism
        if not organism then return end

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        return true
    end)

    local function drawFog()
        local organism = LocalPlayer().organism
        if not organism then return end

        if not organism.Liminalin then return end
        if organism.Liminalin <= 0 then return end

        render.FogStart(10)
        render.FogEnd(10)
        render.FogColor(0, 0, 0)
        render.FogMaxDensity(0.99)
        render.FogMode(MATERIAL_FOG_LINEAR)

        return true
    end

    hook.Add("SetupSkyboxFog", "Liminalin_Fog", function()
        return drawFog()
    end)

    hook.Add("SetupWorldFog", "Liminalin_Fog", function()
        return drawFog()
    end)
end
