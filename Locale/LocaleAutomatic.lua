
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)




local strLower  = string.lower

local tostring = tostring



local L = setmetatable({}, {
  __index = function(self, key)
    rawset(self, key, key)
    if Addon:IsDebugEnabled() then
      geterrorhandler()(ADDON_NAME..": Missing automatic translation for '"..tostring(key).."'")
    end
    return key
  end
})
Addon.L = L


L["Options"] = OPTIONS

L["Enable"]  = ENABLE
L["Disable"] = DISABLE
L["Enabled"] = VIDEO_OPTIONS_ENABLED
-- L["Disabled"] = ADDON_DISABLED
L["Modifiers:"] = MODIFIERS_COLON

L["never"] = strLower(CALENDAR_REPEAT_NEVER)
L["any"]   = strLower(SPELL_TARGET_TYPE1_DESC)
L["all"]   = strLower(SPELL_TARGET_TYPE12_DESC)

L["SHIFT key"] = SHIFT_KEY
L["CTRL key"]  = CTRL_KEY
L["ALT key"]   = ALT_KEY

L["Features"] = FEATURES_LABEL


L["ERROR"] = ERROR_CAPS


L["Debug"]                        = BINDING_HEADER_DEBUG
L["Display Lua Errors"]           = SHOW_LUA_ERRORS
L["Reload UI"]                    = RELOADUI
L["Hide messages like this one."] = COMBAT_LOG_MENU_SPELL_HIDE
L["Lua Warning"]                  = LUA_WARNING
L["Clear Cache"]                  = BROWSER_CLEAR_CACHE
-- L["Delete"]                       = DELETE










