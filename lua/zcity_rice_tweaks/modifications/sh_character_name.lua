local ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED

local function isInvalidName(name)
    if not isstring(name) then return true end
    if #string.Trim(name) < 2 then return true end

    local length = utf8.len(name)

    if not length or length > 25 then return true end

    return false
end

local function modifyCharacterNames()
    local appearance = hg and hg.Appearance

    if not appearance or not appearance.ValidateFunctions then return end

    appearance.IsInvalidName = isInvalidName

    -- 原版 AName 闭包捕获本地 IsInvalidName，必须同时替换。
    appearance.ValidateFunctions.AName = function(name)
        return not isInvalidName(name)
    end
end

if ZCITY_INITALIZED then
    modifyCharacterNames()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_CharacterName", modifyCharacterNames)
