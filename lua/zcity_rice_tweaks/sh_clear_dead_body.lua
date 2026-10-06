local CONFIG_BODY_LIFETIME = RiceLib.Config.Define("zcity_rice_tweaks", "clear_body_lifetime", {
    DisplayName = "尸体完全死亡后清理时间",
    Category = "性能",

    Default = 60,
    Shared = true
})

local CONFIG_GIB_LIFETIME = RiceLib.Config.Define("zcity_rice_tweaks", "clear_gib_lifetime", {
    DisplayName = "肉丸清理时间",
    Category = "性能",

    Default = 60,
    Shared = true
})

if CLIENT then return end

local delay = 0
local entity_clear_timers = {}

hook.Add("Think", "ZCity_RiceTweaks_Clear_Dead_Body", function()
    if delay > CurTime() then return end
    delay = CurTime() + 1

    for entity_or_clear_function, clear_time in pairs(entity_clear_timers) do
        if clear_time > CurTime() then continue end

        if isfunction(entity_or_clear_function) then
            if entity_or_clear_function() then
                entity_clear_timers[entity_or_clear_function] = nil
            end

            continue
        end

        SafeRemoveEntity(entity_or_clear_function)

        entity_clear_timers[entity_or_clear_function] = nil
    end

    local lifetime = CONFIG_BODY_LIFETIME:GetValue()

    for _, entity in ipairs(ents.FindByClass("prop_ragdoll")) do
        local organism = entity.new_organism or entity.organism

        if not organism then continue end
        if organism.alive then continue end
        if entity_clear_timers[entity] then continue end

        entity_clear_timers[entity] = CurTime() + lifetime
    end
end)

hook.Add("OnEntityCreated", "ZCity_RiceTweaks_ClearMeatballs", function(entity)
    if entity:GetClass() ~= "prop_physics" then return end

    local life_time = CONFIG_GIB_LIFETIME:GetValue()

    local clear_function = function()
        if not IsValid(entity) then return true end
        if entity:GetModel() ~= "models/props_junk/watermelon01_chunk02a.mdl" then return true end

        entity:Remove()

        return true
    end

    entity_clear_timers[clear_function] = CurTime() + life_time
end)
