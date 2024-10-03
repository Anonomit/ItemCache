
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)







function Addon:InitDB()
  local configVersion = self.SemVer(self:GetGlobalOption"version" or tostring(self.version))
  
  
  if not self:GetGlobalOption"version" then -- first run
  
  else -- upgrade data schema
    
  end
  
  -- init roll db
  do
    self:SetGlobalOptionQuiet(self.IndexedQueue(self:GetGlobalOptionQuiet"rolls"), "rolls")
  end
  
  if self:GetGlobalOption"version" ~= tostring(self.version) then
    self:SetGlobalOption(tostring(self.version), "version")
  end
end


function Addon:InitProfile()
  local configVersion = self.SemVer(self:GetOption"version" or tostring(self.version))
  
  
  if not self:GetOption"version" then -- first run
  
  else -- upgrade data schema
    
  end
  
  if self:GetOption"version" ~= tostring(self.version) then
    self:SetOption(tostring(self.version), "version")
  end
end


function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({}                         , self:MakeDefaultOptions(), true)
  
  self:RunInitializeCallbacks()
end

function Addon:OnEnable()
  self.version = self.SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB()
  self:InitProfile()
  self:GetDB().RegisterCallback(self, "OnProfileChanged", "InitProfile")
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , "InitProfile")
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , "InitProfile")
  
  self:InitChatCommands("ic", ADDON_NAME:lower())
  
  self:RunEnableCallbacks()
end

function Addon:OnDisable()
end




