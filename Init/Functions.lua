
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)




local strGsub   = string.gsub
local strGmatch = string.gmatch
local strMatch  = string.match

local tinsert   = table.insert
local tblConcat = table.concat
local tblRemove = table.remove











--  ███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ ███████╗
--  ██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ ██╔════╝
--  ███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗███████╗
--  ╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║╚════██║
--  ███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝███████║
--  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝

do
  local function strRemove(text, ...)
    for _, pattern in ipairs{...} do
      text = strGsub(text, pattern, "")
    end
    return text
  end
  
  function Addon:StripText(text)
    return strRemove(text, "|c%x%x%x%x%x%x%x%x", "|r", "^ +", " +$")
  end
  
  function Addon:ChainGsub(text, ...)
    for i, patterns in ipairs{...} do
      local newText = patterns[#patterns]
      for i = 1, #patterns - 1 do
        local oldText = patterns[i]
        text = strGsub(text, oldText, newText)
      end
    end
    return text
  end
  
  local chainGsubPattern = {
    {"%%%d%$", "%%"},               -- koKR ITEM_RESIST_SINGLE: "%3$s 저항력 %1$c%2$d" -> "%s 저항력 %c%d"
    {"|3%-%d+%((.+)%)", "%1"},      -- ruRU ITEM_RESIST_SINGLE: "%c%d к сопротивлению |3-7(%s)" -> %c%d к сопротивлению %s
    {"[().+-]", "%%%0"},            -- cover special characters with escape codes
    {"%%c", "([+-])"},              -- "%c" -> "([+-])"
    {"%%d", "(%%d+)"},              -- "%d" -> "(%d+)"
    {"%%s", "(.*)"},                -- "%s" -> "(.*)"
    {"|4[^:]-:[^:]-:[^:]-;", ".-"}, -- removes |4singular:plural;
    {"|4[^:]-:[^:]-;", ".-"},       -- removes ruRU |4singular:plural1:plural2;
  }
  local reversedPatternsCache = {}
  function Addon:ReversePattern(text)
    reversedPatternsCache[text] = reversedPatternsCache[text] or "^" .. self:ChainGsub(text, unpack(chainGsubPattern)) .. "$"
    return reversedPatternsCache[text]
  end
  
  
  function Addon:CoverSpecialCharacters(text)
    return self:ChainGsub(text, {"%p", "%%%0"})
  end
  function Addon:UncoverSpecialCharacters(text)
    return (strGsub(text, "%%(.)", "%1"))
  end
  
  
  
  function Addon:MakeAtlas(atlas, height, width, hex)
    height = tostring(height or "0")
    local tex = "|A:" .. atlas .. ":" .. height .. ":" .. tostring(width or height)
    if hex then
      tex = tex .. format(":::%d:%d:%d", self:ConvertHexToRGB(hex))
    end
    return tex .. "|a"
  end
  function Addon:MakeIcon(texture, height, width, hex)
    local tex = "|T" .. texture .. ":" .. tostring(height or "0") .. ":"
    if width then
      tex = tex .. width
    end
    if hex then
      tex = tex .. format(":::1:1:0:1:0:1:%d:%d:%d", self:ConvertHexToRGB(hex))
    end
    return tex .. "|t"
  end
  function Addon:UnmakeIcon(texture)
    return strMatch(texture, "|T([^:]+):")
  end
  
  function Addon:InsertIcon(text, stat, customTexture)
    if self:GetOption("doIcon", stat) then
      if self:GetOption("iconSpace", stat) then
        text = " " .. text
      end
      text = self:MakeIcon(customTexture or self:GetOption("icon", stat), self:GetOption("iconSizeManual", stat) and self:GetOption("iconSize", stat) or nil) .. text
    end
    return text
  end
  function Addon:InsertAtlas(text, stat, customTexture)
    if self:GetOption("doIcon", stat) then
      if self:GetOption("iconSpace", stat) then
        text = " " .. text
      end
      text = self:MakeAtlas(customTexture or self:GetOption("icon", stat), self:GetOption("iconSizeManual", stat) and self:GetOption("iconSize", stat) or nil) .. text
    end
    return text
  end
end




--  ███████╗████████╗ █████╗ ████████╗███████╗
--  ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
--  ███████╗   ██║   ███████║   ██║   ███████╗
--  ╚════██║   ██║   ██╔══██║   ██║   ╚════██║
--  ███████║   ██║   ██║  ██║   ██║   ███████║
--  ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝

do
  function Addon:RegenerateStatOrder()
    wipe(self.statList[self.expansionLevel])
    wipe(self.statOrder)
    for stat in strGmatch(self:GetOption("order", self.expansionLevel), "[^,]+") do
      tinsert(self.statList[self.expansionLevel], stat)
      self.statOrder[stat] = #self.statList[self.expansionLevel]
    end
  end
  
  function Addon:ChangeOrder(from, to)
    tinsert(self.statList[self.expansionLevel], to, tblRemove(self.statList[self.expansionLevel], from))
    self:SetOption(tblConcat(self.statList[self.expansionLevel], ","), "order", self.expansionLevel)
    self:RegenerateStatOrder()
  end
  function Addon:ResetOrder()
    self:ResetOption("order", self.expansionLevel)
    self:RegenerateStatOrder()
  end
  function Addon:ResetReword(stat)
    self:ResetOption("reword", stat)
    self:SetDefaultRewordByLocale(stat)
  end
  function Addon:ResetMod(stat)
    self:ResetOption("mod", stat)
    self:SetDefaultModByLocale(stat)
  end
  function Addon:ResetPrecision(stat)
    self:ResetOption("precision", stat)
    self:SetDefaultPrecisionByLocale(stat)
  end
end




--  ██╗      ██████╗  ██████╗ █████╗ ██╗     ███████╗    ███████╗██╗  ██╗████████╗██████╗  █████╗ ███████╗
--  ██║     ██╔═══██╗██╔════╝██╔══██╗██║     ██╔════╝    ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
--  ██║     ██║   ██║██║     ███████║██║     █████╗      █████╗   ╚███╔╝    ██║   ██████╔╝███████║███████╗
--  ██║     ██║   ██║██║     ██╔══██║██║     ██╔══╝      ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║╚════██║
--  ███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗    ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║███████║
--  ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

do
  local defaultRewordLocaleOverrides    = {}
  local defaultModLocaleOverrides       = {}
  local defaultPrecisionLocaleOverrides = {}
  local localeExtraStatCaptures         = {}
  local localeExtraReplacements         = {}
  
  function Addon:AddDefaultRewordByLocale(stat, val)
    defaultRewordLocaleOverrides[stat] = val
  end
  function Addon:AddDefaultModByLocale(stat, val)
    defaultModLocaleOverrides[stat] = val
  end
  function Addon:AddDefaultPrecisionByLocale(stat, val)
    defaultPrecisionLocaleOverrides[stat] = val
  end
  
  function Addon:GetExtraStatCapture(stat)
    return localeExtraStatCaptures[stat]
  end
  function Addon:AddExtraStatCapture(stat, ...)
    localeExtraStatCaptures[stat] = localeExtraStatCaptures[stat] or {}
    for i, rule in ipairs{...} do
      tinsert(localeExtraStatCaptures[stat], rule)
    end
  end
  
  local replacementKeys = {}
  function Addon:GetExtraReplacements()
    return localeExtraReplacements
  end
  function Addon:AddExtraReplacement(label, ...)
    if not replacementKeys[label] then
      tinsert(localeExtraReplacements, {label = label})
      replacementKeys[label] = #localeExtraReplacements
    end
    for i, rule in ipairs{...} do
      tinsert(localeExtraReplacements[replacementKeys[label]], rule)
    end
  end
  
  
  -- these functions are run when relevant settings are reset/initialized
  local localeDefaultOverrideMethods = {
    SetDefaultRewordByLocale    = {"reword"   , defaultRewordLocaleOverrides},
    SetDefaultModByLocale       = {"mod"      , defaultModLocaleOverrides},
    SetDefaultPrecisionByLocale = {"precision", defaultPrecisionLocaleOverrides},
  }
  for method, data in pairs(localeDefaultOverrideMethods) do
    local field, overrides = unpack(data, 1, 2)
    Addon[method] = function(self, stat)
      if stat then
        if overrides[stat] then
          Addon.SetOption(self, overrides[stat], field, stat)
        end
      else
        for stat, val in pairs(overrides) do
          Addon.SetOption(self, val, field, stat)
        end
      end
    end
  end
  
  function Addon:OverrideAllLocaleDefaults()
    for method in pairs(localeDefaultOverrideMethods) do
      Addon[method](self)
    end
  end
end






