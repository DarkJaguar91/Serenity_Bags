-----------------------------------------------------------------------------------------------
-- Client Lua Script for Serenity_Bags
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Serenity_Bags Module Definition
-----------------------------------------------------------------------------------------------
local Serenity_Bags = {} 
local Serenity_BagContainer = {
	itemsPerRow = 5,
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Serenity_Bags:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.vendorOpen = false

    return o
end

function Serenity_Bags:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Serenity_Bags OnLoad
-----------------------------------------------------------------------------------------------
function Serenity_Bags:OnLoad()	
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

		Apollo.RegisterEventHandler("ToggleInventory",	"ToggleBags", self)
		Apollo.RegisterEventHandler("InterfaceMenu_ToggleInventory", "ToggleBags", self)
		Apollo.RegisterEventHandler("GuildBank_ShowPersonalInventory",	"ShowBags", self)
		Apollo.RegisterEventHandler("ShowInventory",	"ShowBags", self)
		
		Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", "ResetAllBags", self)
		Apollo.RegisterEventHandler("PlayerCurrencyChanged",	"ResetAllBags", self)

		Apollo.RegisterEventHandler("LootedItem",	"ResetBagItems", self)
		Apollo.RegisterEventHandler("ChallengeUpdated", "ResetBagItems", self)
		Apollo.RegisterEventHandler("PlayerPathMissionUpdate", "ResetBagItems", self)
		Apollo.RegisterEventHandler("QuestObjectiveUpdated", "ResetBagItems", self)
		Apollo.RegisterEventHandler("PlayerPathRefresh", "ResetBagItems", self)
		Apollo.RegisterEventHandler("QuestStateChanged", "ResetBagItems", self)
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Functions
-----------------------------------------------------------------------------------------------

function Serenity_Bags:DestroyBags()
	for i, v in pairs(self.bags) do
		v:Destroy()
		v = nil	
	end
	
	self.bags = {}
end

function Serenity_Bags:CollectBagItems()
	local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
	local categories = {}
	
	for i, v in pairs(items) do
		local category = v.itemInBag:GetItemFamilyName()
		
		if categories[category] == nil then
			categories[category] = {}
		end
		
		table.insert(categories[category], v)
	end
		
	return categories
end

function Serenity_Bags:ToggleBags()
	if self.mainBag:IsVisible() then
		self:DestroyBags()
		self.mainBag:Close()
	else
		self:ShowBags()
	end
end

function Serenity_Bags:ShowBags()
	self:DestroyBags() -- kill all currently shown bags
	
	self.mainBag:Show(true)
	
	self:ResetAllBags()
end

function Serenity_Bags:ResetAllBags()
	self:ResetMainBag()
	self:ResetBagItems()
end

function Serenity_Bags:ResetBagItems()
	self:DestroyBags()
		
	if self.mainBag:IsVisible() then
		local categories = self:CollectBagItems()
		
		for i, v in pairs(categories) do
			local bag = Serenity_BagContainer:new()
			
			bag:Init(self, {i, v})
			
			table.insert(self.bags, bag)
		end
		
		self:ArrangeBagContainers()
	end
end

function Serenity_Bags:ResetMainBag()
	self.mainBag:FindChild("Currency"):SetAmount(GameLib.GetPlayerCurrency())
	
	for i = 1, 4 do
		local bagItm = self.mainBag:FindChild("Bag" .. i)
		bagItm:FindChild("Number"):SetText(tostring(bagItm:GetItem():GetBagSlots()))
	end
end

function Serenity_Bags:ArrangeBagContainers()
	table.sort(self.bags, function(a,b)
		return string.lower(a:GetCategory()) > string.lower(b:GetCategory())
	end)
	
	local l, t, r, b = self.mainBag:GetAnchorOffsets()
	
	local x = r
	local y = t
	
	local mH = 0
	
	for i, v in pairs(self.bags) do
		local w, h = v:GetSize()
		if (h > mH) then mH = h end
		
		v:SetPosition({1, 1, 1, 1}, {x-w, y-h, x, y})
		
		x = x-w
		
		if (x < (l)) then
			x = r
			y = y - mH
			mH = 0
		end
	end
end
---------------------------------------------------------------------------------------------------
-- Tooltip Functions
---------------------------------------------------------------------------------------------------

function Serenity_BagContainer:ItemHover( wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

function Serenity_Bags:BagItemHover( wndHandler, wndControl, eToolTipType, x, y )
	if (wndHandler ~= wndControl) then return end
	
	local item = wndControl:GetItem()
	
	wndControl:SetTooltipDoc(nil)
	Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false})
end

---------------------------------------------------------------------------------------------------
-- BagContainer function
---------------------------------------------------------------------------------------------------

function Serenity_BagContainer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Serenity_BagContainer:Init(parent, params)
	self.par = parent

	self.frame = Apollo.LoadForm(self.par.xmlDoc, "BagContainer", nil, self)
	
	if params[1] == "" then
		self.frame:FindChild("Label"):SetText("Default")
	else
		self.frame:FindChild("Label"):SetText(params[1])
	end
	
	if (params[2]) then
		self:SetItems(params[2])
	end
end

function Serenity_BagContainer:GetCategory()
	return self.frame:FindChild("Label"):GetText()
end

function Serenity_BagContainer:GetSize()
	return self.frame:GetWidth(), self.frame:GetHeight() 
end

function Serenity_BagContainer:SetPosition(anchors, offsets)
	self.frame:SetAnchorPoints(unpack(anchors))
	self.frame:SetAnchorOffsets(unpack(offsets))
end

function Serenity_BagContainer:SetItems(items)
	table.sort(items, function(a, b) 
		return string.lower(a.itemInBag:GetName()) < string.lower(b.itemInBag:GetName())
	end)

	self.items = items
	
	for i, v in pairs(items) do
		local itm = Apollo.LoadForm(self.par.xmlDoc, "BagItem", self.frame:FindChild("ItemFrame"), self)
		
		local y = v.nBagSlot * 51
		
		itm:FindChild("BItm"):SetAnchorOffsets(0, -y, 0, 0)
		_G["itm"] = v;
	end
	
	self:SizeToFit()
	
	self.frame:FindChild("ItemFrame"):ArrangeChildrenTiles()
end

function Serenity_BagContainer:SizeToFit()
	if (self.items) then
		local number = #self.items
		
		local xItems = self.itemsPerRow
		local yItems = 1
		if (xItems > number) then
			xItems = number
		else
			yItems = math.floor(number / xItems)
		end
		
		local w = 10 + 50 * xItems + xItems * 2
		local h = 30 + 50 * yItems + yItems * 2
		
		
		local left, top, right, bottom = self.frame:GetAnchorOffsets()
		left = right - w
		top = bottom - h
		
		self.frame:SetAnchorOffsets(left, top, right, bottom)
	end
end

function Serenity_BagContainer:Destroy()
	self.frame:Destroy()
	self.frame = nil
end

---------------------------------------------------------------------------------------------------
-- MainBagForm Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags:TestDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	self:ArrangeBagContainers()
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsInst = Serenity_Bags:new()
Serenity_BagsInst:Init()
