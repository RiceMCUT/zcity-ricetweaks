ZCityRiceTweaks = ZCityRiceTweaks or {}
ZCityRiceTweaks.ZCITY_INITALIZED = ZCityRiceTweaks.ZCITY_INITALIZED or false

RiceLib.Config.DefineNameSpace("zcity_rice_tweaks", {
    DisplayName = "ZCity Rice Tweaks",
    Author = "Rice"
})

RiceLib.IncludeDir("zcity_rice_tweaks")

hook.Add("InitPostEntity", "ZCityRiceTweaksInit", function()
    ZCityRiceTweaks.ZCITY_INITALIZED = true

    hook.Run("ZCityRiceTweaksInit")
end)
