-----------------------------------------------------------------------------------------------
-- Client Lua Script for Serenity_Bags
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Serenity_Bags Module Definition
-----------------------------------------------------------------------------------------------
local Serenity_Bags = {} 
local Serenity_BagContainer = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Serenity_Bags:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Serenity_Bags:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Serenity_Bags OnLoad
-----------------------------------------------------------------------------------------------
function Serenity_Bags:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Serenity_Bags.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags OnDocLoaded
-----------------------------------------------------------------------------------------------
function Serenity_Bags:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		
	    self.mainBag = Apollo.LoadForm(self.xmlDoc, "MainBagForm", nil, self)
	    self.mainBag:Show(false, true)		
		
		self.bags = {}
		
		
		Apollo.RegisterSlashCommand("bag", "ShowBags", self)
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Functions
-----------------------------------------------------------------------------------------------
function Serenity_Bags:DestroyBags()
	for i, v in pairs(self.bags) do
		v:Show(false)
		v:Destroy()
		v = nil	
	end
	
	self.bags = {}
end

function Serenity_Bags:ShowBags()
	self:DestroyBags() -- kill all currently shown bags
	
	if self.mainBag:IsVisible() then
		self.mainBag:Show(false)
	else
		self.mainBag:Show(true)
	end
end
-----------------------------------------------------------------------------------------------
-- Serenity_BagContainer
-----------------------------------------------------------------------------------------------

function Serenity_BagContainer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Serenity_BagContainer:Init(parent)
	self.parent = parent

	self.frame = Apollo.LoadForm(parent.xmlDoc, "BagContainer", nil, self)
end


-----------------------------------------------------------------------------------------------
-- Serenity_Bags Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsInst = Serenity_Bags:new()
Serenity_BagsInst:Init()
