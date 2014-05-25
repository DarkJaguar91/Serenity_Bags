-----------------------------------------------------------------------------------------------
-- Client Lua Script for Serenity_Bags
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Serenity_Bags Module Definition
-----------------------------------------------------------------------------------------------
local Serenity_Bags = {} 
<<<<<<< HEAD
local Serenity_BagContainer = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
=======
local Serenity_BagContainer = {
	itemsPerRow = 5,
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ItemQualityToColor = {
	"ff333333",
	"ffffffff",
	"ff00ff00",
	"ff0000ff",
	"ffff00ff",
	"ffffff00",
	"ffff8888",
}

>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Serenity_Bags:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
<<<<<<< HEAD
=======
	self.vendorOpen = false
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a

    return o
end

function Serenity_Bags:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
<<<<<<< HEAD
		-- "UnitOrPackageName",
=======
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Serenity_Bags OnLoad
-----------------------------------------------------------------------------------------------
<<<<<<< HEAD
function Serenity_Bags:OnLoad()
    -- load our form file
=======
function Serenity_Bags:OnLoad()	
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a
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
		
<<<<<<< HEAD
		
		Apollo.RegisterSlashCommand("bag", "ShowBags", self)
=======
		Apollo.RegisterSlashCommand("bag", "ShowBags", self)
		Apollo.RegisterEventHandler("InvokeVendorWindow", "VendorWindowOpen", self)
		Apollo.RegisterEventHandler("CloseVendorWindow", "VendorWindowClosed", self)
		Apollo.RegisterEventHandler("PersonaUpdateCharacterStats",	"ResetBags", self)
		Apollo.RegisterEventHandler("InterfaceMenu_ToggleInventory", "ToggleBags", self)
		Apollo.RegisterEventHandler("GuildBank_ShowPersonalInventory",	"ShowBags", self)
		Apollo.RegisterEventHandler("ToggleInventory",	"ToggleBags", self)
		Apollo.RegisterEventHandler("ShowInventory",	"ShowBags", self)
		Apollo.RegisterEventHandler("PlayerCurrencyChanged",	"ResetMainBag", self)
		Apollo.RegisterEventHandler("LootedItem",	"ResetBags", self)
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Functions
-----------------------------------------------------------------------------------------------
<<<<<<< HEAD
function Serenity_Bags:DestroyBags()
	for i, v in pairs(self.bags) do
		v:Show(false)
=======
function Serenity_Bags:VendorWindowOpen()
	self.vendorOpen = true
end

function Serenity_Bags:VendorWindowClosed()
	self.vendorOpen = false
end

function Serenity_Bags:DestroyBags()
	for i, v in pairs(self.bags) do
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a
		v:Destroy()
		v = nil	
	end
	
	self.bags = {}
end

<<<<<<< HEAD
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
=======
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
	self:DestroyBags()
	
	if self.mainBag:IsVisible() then
		self.mainBag:Close()
	else
		self:ShowBags()
	end
end

function Serenity_Bags:ShowBags()
	self:DestroyBags() -- kill all currently shown bags
	
	self.mainBag:Show(true)
	
	-- reset mainBagData
	self:ResetMainBag()	
	
	-- create bags
	self:ResetBags()
end

function Serenity_Bags:ResetBags()
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
		return string.lower(a:GetCategory()) < string.lower(b:GetCategory())
	end)
	
	local x = -5
	local y = -55
	
	local mH = 0
	
	for i, v in pairs(self.bags) do
		local w, h = v:GetSize()
		if (h > mH) then mH = h end
		
		v:SetPosition({1, 1, 1, 1}, {x-w, y-h, x, y})
		
		x = x-w
		
		if (x < -500) then
			x = -5
			y = y - mH
			mH = 0
		end
	end
end
---------------------------------------------------------------------------------------------------
-- Tooltip Functions
---------------------------------------------------------------------------------------------------

function Serenity_BagContainer:ItemHover( wndHandler, wndControl, eToolTipType, x, y )
	if (wndHandler ~= wndControl) then return end

	local itm = wndHandler:GetData()
	if not itm then
		itm = wndControl:GetData()
	end
	
	wndControl:SetTooltipDoc(nil)
	Tooltip.GetItemTooltipForm(self, wndControl, itm.itemInBag, {bPrimary = true, bSelling = false})
end

function Serenity_BagContainer:OnItemMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if (wndControl ~= wndHandler) then return end
	
	if (self.par.vendorOpen) then
		if (eMouseButton == GameLib.CodeEnumInputMouse.Right) then
			local item = wndControl:GetData()
		
			SellItemToVendor(item.nBagSlot, 1)
		end
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
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a

function Serenity_BagContainer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

<<<<<<< HEAD
function Serenity_BagContainer:Init(parent)
	self.parent = parent

	self.frame = Apollo.LoadForm(parent.xmlDoc, "BagContainer", nil, self)
end

=======
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
		
		itm:FindChild("Sprite"):SetSprite(v.itemInBag:GetIcon()) 
		
		itm:SetBGColor(ItemQualityToColor[v.itemInBag:GetItemQuality()])
		
		if v.itemInBag:GetStackCount() > 1 then
			itm:FindChild("Number"):SetText(tostring(v.itemInBag:GetStackCount()))
			itm:FindChild("Number"):Show(true)
		else
			itm:FindChild("Number"):Show(false)		
		end
		
		itm:SetData(v)
		_G["itm"] = itm
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
>>>>>>> 8668392f2f7643b98979cfbacc9e15577edcaf3a

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsInst = Serenity_Bags:new()
Serenity_BagsInst:Init()
