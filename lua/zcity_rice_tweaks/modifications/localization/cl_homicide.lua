local getPhrase = RiceLib.Languages.GetPhrase
local originals = ZCityRiceTweaks.Localization.HomicideFields or setmetatable({}, {__mode = "k"})
ZCityRiceTweaks.Localization.HomicideFields = originals

local function tryLocalize(tbl, key, phrase_id)
    if type(tbl[key]) ~= "string" then return end
    originals[tbl] = originals[tbl] or {}
    originals[tbl][key] = originals[tbl][key] or tbl[key]
    RiceLib.Languages.AddPhrases("english", {[phrase_id] = originals[tbl][key]})
    local localized = getPhrase(phrase_id)

    tbl[key] = localized ~= phrase_id and localized or originals[tbl][key]
end

local function localizeFields(tbl, prefix, fields)
    for id, entry in pairs(tbl) do
        for phrase_suffix, target_key in pairs(fields) do
            tryLocalize(entry, target_key, prefix .. id .. "." .. phrase_suffix)
        end
    end
end

local function doLocalizations()
    local mode = zb.modes.hmcd

    tryLocalize(mode, "PrintName", "zcity.ricetweaks.homicide.name")

    localizeFields(mode.SubRoles, "zcity.ricetweaks.homicide.subrole.", {
        name = "Name",
        description = "Description",
        objective = "Objective",
    })

    for sub_mode, roles in pairs(mode.Roles) do
        localizeFields(roles, "zcity.ricetweaks.homicide.role." .. sub_mode .. ".", {
            name = "name",
            objective = "objective",
        })
    end

    for type_name in pairs(mode.TypeNames) do
        tryLocalize(mode.TypeNames, type_name, "zcity.ricetweaks.homicide.type_names." .. type_name)
    end

    for type_name, roles in pairs(mode.TypeObjectives) do
        localizeFields(roles, "zcity.ricetweaks.homicide.type_objectives." .. type_name .. ".", {
            name = "name",
            objective = "objective",
        })
    end

    localizeFields(mode.Professions, "zcity.ricetweaks.homicide.profession.", {
        name = "Name",
    })
end

if ZCityRiceTweaks.ZCITY_INITALIZED then
    doLocalizations()
end

hook.Add("ZCityRiceTweaksInit", "ZCityRiceTweaks_Init_Homicide_Localization", function()
    doLocalizations()
end)

hook.Add("RiceLib_Language_ClientLanguageChanged", "ZCityRiceTweaks_Homicide_Tweaks_LanguageChanged", function()
    if not ZCityRiceTweaks.ZCITY_INITALIZED then return end

    doLocalizations()
end)
