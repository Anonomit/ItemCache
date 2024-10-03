
local ADDON_NAME, Data = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)

L["Use Persistent Storage"] = true
L["If enabled, cache will be stored on logout. This may slightly increase loading time.|n|nIf disabled, cache will be rebuilt during each session. This will result in dramatically more cache misses."] = true

