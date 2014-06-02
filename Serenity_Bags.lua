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
local SavedItemCategories = {}
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
 
function Serenity_Bags:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		return {
			savedBagNames = SavedItemCategories,
		}
	end
	
	return nil
end

function Serenity_Bags:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character  then
		if not tSavedData then
			return
		end
		
		SavedItemCategories = tSavedData.savedBagNames
	end	
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
	
		self.deleteWindow = Apollo.LoadForm(self.xmlDoc, "InventoryDeleteNotice", nil, self)
		self.deleteWindow:Show(false, true)
		
		self.salvageWindow = Apollo.LoadForm(self.xmlDoc, "InventorySalvageNotice", nil, self)
		self.salvageWindow:Show(false, true)
		
		self.BagNamingWindow = Apollo.LoadForm(self.xmlDoc, "BagNamer", nil, self)
		self.BagNamingWindow:Show(false, true)
		
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
		Apollo.RegisterEventHandler("UpdateInventory", "ResetBagItems", self)
		
		Apollo.RegisterEventHandler("VendorItemsUpdated", "OnVendorWindowInvoke", self)
		
		Apollo.RegisterEventHandler("DragDropSysBegin", "OnSystemBeginDragDrop", self)
		
		Apollo.RegisterEventHandler("ItemRemoved", 					"OnItemRemoved", self)
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Functions
-----------------------------------------------------------------------------------------------

function Serenity_Bags:OnSystemBeginDragDrop(wndSource, strType, iData)
	if strType ~= "DDBagItem" then return end
	
	if (Apollo.IsControlKeyDown()) then
		--lf:InvokeSalvageConfirmWindow(iData)
	end
end

function Serenity_Bags:DestroyBags()
	for i, v in pairs(self.bags) do
		v:Destroy()
		v = nil	
	end
	
	self.bags = {}
end

function Serenity_Bags:OnItemRemoved(itemSold, nCount, eReason)
	SavedItemCategories[itemSold:GetItemId()] = nil
end

function Serenity_Bags:CollectBagItems()
	if (GameLib.GetPlayerUnit()) then
		local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
		local categories = {}
		
		for i, v in pairs(items) do
			local category = nil
			if (SavedItemCategories[v.itemInBag:GetItemId()]) then
				category = SavedItemCategories[v.itemInBag:GetItemId()]
			else
				category = v.itemInBag:GetItemFamilyName()
			end
			
			if categories[category] == nil then
				categories[category] = {}
			end
			
			table.insert(categories[category], v)
		end
			
		return categories
	end
	return nil
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
	if (GameLib.GetPlayerUnit() == nil) then return end
	self:DestroyBags()
		
	if self.mainBag:IsVisible() then
		local categories = self:CollectBagItems()
		
		if (categories == nil) then return end
		
		for i, v in pairs(categories) do
			local bag = Serenity_BagContainer:new()
			
			bag:Init(self, {i, v})
			
			table.insert(self.bags, bag)
		end
		
		_G["qst"] = Item.GetVirtualItems()
		local questItems = Item.GetVirtualItems()
		if (#questItems > 0) then
			local bag = Serenity_BagContainer:new()
			
			bag:Init(self, {"Quest", questItems})
			
			table.insert(self.bags, bag)
		end
		
				
		self:ArrangeBagContainers()
	end
end

function Serenity_Bags:ResetMainBag()
	self.mainBag:FindChild("Currency"):SetAmount(GameLib.GetPlayerCurrency())
	
	
	
	local emptyBagFrame = self.mainBag:FindChild("EmptyBag")
	if (emptyBagFrame:GetTotalEmptyBagSlots() > 0) then
		local totalBagSlots = emptyBagFrame:GetTotalBagSlots()
		local y = (totalBagSlots-1) * 35
		
		emptyBagFrame:SetAnchorPoints(0,0,1,1)
		emptyBagFrame:SetAnchorOffsets(0, -y,0,0)
		emptyBagFrame:Show(true)
	else
		emptyBagFrame:Show(false)
	end
	self.mainBag:FindChild("NumberSlotsEmpty"):SetText(tostring(emptyBagFrame:GetTotalEmptyBagSlots()))
	
	
	for i = 1, 4 do
		local bagItm = self.mainBag:FindChild("Bag" .. i)
		bagItm:FindChild("Number"):SetText(tostring(bagItm:GetItem():GetBagSlots()))
	end
end

function Serenity_Bags:GetMaxWidth()
	local mW = 0;

	for i, v in pairs(self.bags) do
		local w, h = v:GetSize()
		if (w > mW) then
			mW = w
		end
	end
	
	return mW
end

function Serenity_Bags:ArrangeBagContainers()
	table.sort(self.bags, function(a,b)
		if (a:GetCategory() == "Quest") then
			return true
		elseif (b:GetCategory() == "Quest") then
			return false
		else
			return string.lower(a:GetCategory()) > string.lower(b:GetCategory())	
		end
	end)
	
	local catagories = {}
	for i, v in pairs(self.bags) do
		table.insert(catagories, i)
	end
		
	local l, t, r, b = self.mainBag:GetAnchorOffsets()
	
	local x = r
	local y = t
	
	local w = self:GetMaxWidth() 
	
	local cnt = 1;
	for i, v in pairs(self.bags) do
		local h = v:GetHeight()
		if cnt % 2 == 0 then
			local tH = self.bags[catagories[cnt-1]]:GetHeight()
			
			if (tH > h) then h = tH end
		else
			if (catagories[cnt+1]) then
				local tH = self.bags[catagories[cnt+1]]:GetHeight()
			
				if (tH > h) then h = tH end
			end
		end
	
		v:SetPosition({1, 1, 1, 1}, {x-w, y-h, x, y})
		
		x = x - w
		
		if (cnt % 2 == 0) then
			x = r
			y = y - h
		end
		cnt = cnt + 1
	end
end

function Serenity_Bags:InvokeDeleteConfirmWindow(iData) 
	local itemData = Item.GetItemFromInventoryLoc(iData)
	if itemData and not itemData:CanDelete() then
		return
	end
	self.deleteWindow:SetData(iData)
	self.deleteWindow:Show(true)
	self.deleteWindow:ToFront()
	self.deleteWindow:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

function Serenity_Bags:InvokeSalvageConfirmWindow(iData) 
	local itemData = Item.GetItemFromInventoryLoc(iData)
	if itemData and not itemData:CanSalvage() then
		return
	end

	self.salvageWindow:SetData(iData)
	self.salvageWindow:Show(true)
	self.salvageWindow:ToFront()
	self.salvageWindow:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, iData)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

function Serenity_Bags:GetSavedBagNames()
	local names = {}
	
	for i, v in pairs(SavedItemCategories) do
		if not self:tableContains(names, v) then
			table.insert(names, v)
		end
	end
	
	Print(#names)
	
	return names
end

function Serenity_Bags:tableContains(table, data)
	for i, v in pairs(table) do
		if (v == data) then
			return true
		end
	end
	return false
end

function Serenity_Bags:InvokeBagNamingWindow(item) 
	if item == nil then
		return
	end
	
	self.BagNamingWindow:SetData(item)
	self.BagNamingWindow:Show(true)
	self.BagNamingWindow:ToFront()
	if (SavedItemCategories[item]) then
		self.BagNamingWindow:FindChild("RemoveBtn"):Show(true)
	else
		self.BagNamingWindow:FindChild("RemoveBtn"):Show(false)
	end
	
	local bagNames = self:GetSavedBagNames()
	Print(#bagNames)
	if (#bagNames > 0) then
		local wnd = self.BagNamingWindow:FindChild("NamesAvailable")
		wnd:Show(true)
		local list = wnd:FindChild("ListOfNames")
		
		list:DestroyChildren()
		
		for i, v in pairs(bagNames) do
			local bagNameWnd = Apollo.LoadForm(self.xmlDoc, "BagName", list, self)
			bagNameWnd:FindChild("NameBtn"):SetText(v)
		end
		list:ArrangeChildrenVert()
	else
		self.BagNamingWindow:FindChild("NamesAvailable"):Show(false)	
	end
	
	self.BagNamingWindow:FindChild("EditBox"):SetText("")
	Sound.Play(Sound.PlayUI55ErrorVirtual)
	self.BagNamingWindow:FindChild("EditBox"):SetFocus()
end


function Serenity_Bags:OnVendorWindowInvoke()
	local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
	for i,v in pairs(items) do
		--Print(v.itemInBag:GetItemCategoryName())
		--_G["itm"] = v
		if (v.itemInBag:GetItemCategoryName() == "Junk") then
			SellItemToVendor(v.nBagSlot, v.itemInBag:GetStackCount())
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
		if (params[1] == "Quest") then
			self:SetQuestItems(params[2])
		else 
			self:SetItems(params[2])
		end
	end
end

function Serenity_BagContainer:GetCategory()
	return self.frame:FindChild("Label"):GetText()
end

function Serenity_BagContainer:GetSize()
	return self.frame:GetWidth(), self.frame:GetHeight() 
end


function Serenity_BagContainer:GetWidth()
	return self.frame:GetWidth()
end

function Serenity_BagContainer:GetHeight()
	return self.frame:GetHeight()
end

function Serenity_BagContainer:SetPosition(anchors, offsets)
	self.frame:SetAnchorPoints(unpack(anchors))
	self.frame:SetAnchorOffsets(unpack(offsets))
end

function Serenity_BagContainer:SetQuestItems(items)
	table.sort(items, function(a, b) 
		return string.lower(a.strName) < string.lower(b.strName)
	end)
	
	self.items = items
	
	for i,v in pairs(items) do
		local itm = Apollo.LoadForm(self.par.xmlDoc, "QuestItem", self.frame:FindChild("ItemFrame"), self)
		
		itm:FindChild("Sprite"):SetSprite(v.strIcon)
		itm:FindChild("Count"):SetText(v.nCount)
		itm:SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P><P Font=\"CRB_InterfaceSmall\" TextColor=\"aaaaaaaa\">%s</P>", v.strName, v.strFlavor))

		if (v.nCount > 1) then
			itm:FindChild("Count"):Show(true)
		else
			itm:FindChild("Count"):Show(false)
		end
	end
	
	self:SizeToFit()
	self.frame:FindChild("ItemFrame"):ArrangeChildrenTiles()
end

function Serenity_BagContainer:SetItems(items)
	table.sort(items, function(a, b) 
		return string.lower(a.itemInBag:GetName()) < string.lower(b.itemInBag:GetName())
	end)

	self.items = items
	
	local onceFlag = true
	
	for i, v in pairs(items) do
		local itm = Apollo.LoadForm(self.par.xmlDoc, "BagItem", self.frame:FindChild("ItemFrame"), self)
		
		local y = v.nBagSlot  * 51
		
		itm:FindChild("BItm"):SetAnchorOffsets(0, -y, 0, 0)
		itm:FindChild("BItm"):SetData(v)
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
			yItems = math.ceil(number / xItems)
		end
		self.xH = xItems
		self.yH = yItems
		
		local w = 10 + 50 * xItems + xItems * 2
		local h = 30 + 50 * yItems + yItems * 2
		
		
		local left, top, right, bottom = self.frame:GetAnchorOffsets()
		left = right - w
		top = bottom - h
		
		self.frame:SetAnchorOffsets(left, top, right, bottom)
	end
end

function Serenity_BagContainer:Destroy()
	local bg = self.frame:FindChild("ItemFrame"):GetChildren()[1]
	if (bg:GetName() == "BagItem") then
		bg:FindChild("BItm"):MarkAllItemsAsSeen()
	end
	
	--self.frame:FindChild("ItemFrame"):GetChildren()[1]:FindChild("BItm"):MarkAllItemsAsSeen()
	self.frame:Destroy()
	self.frame = nil
end

---------------------------------------------------------------------------------------------------
-- MainBagForm Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags:MoveFrames( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	self:ArrangeBagContainers()
end

function Serenity_Bags:ToggleTradeSkillBag( wndHandler, wndControl, eMouseButton )
	local tAnchors = {}
	tAnchors.nLeft, tAnchors.nTop, tAnchors.nRight, tAnchors.nBottom = self.mainBag:GetAnchorOffsets()
	Event_FireGenericEvent("ToggleTradeskillInventoryFromBag", tAnchors)
end

---------------------------------------------------------------------------------------------------
-- BagItem Functions
---------------------------------------------------------------------------------------------------

function Serenity_BagContainer:OnDragCancel( wndHandler, wndControl, strType, iData, eReason, bDragDropHasBeenReset )
	if strType ~= "DDBagItem" or eReason == Apollo.DragDropCancelReason.EscapeKey or eReason == Apollo.DragDropCancelReason.ClickedOnNothing then
		return false
	end

	if eReason == Apollo.DragDropCancelReason.ClickedOnWorld or eReason == Apollo.DragDropCancelReason.DroppedOnNothing then
		self.par:InvokeDeleteConfirmWindow(iData)
	end
	return false
end

function Serenity_BagContainer:OnBagClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if eMouseButton == GameLib.CodeEnumInputMouse.Middle then
		if (wndHandler:GetName() == "BItm") then
			local itm = wndHandler:GetData()
			
			if (Apollo.IsControlKeyDown()) then
				self.par:InvokeSalvageConfirmWindow(itm.itemInBag:GetInventoryId())
			end
			if Apollo.IsAltKeyDown() then
				self.par:InvokeBagNamingWindow(itm.itemInBag:GetItemId())
							
				self.par:ResetBagItems()
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- InventoryDeleteNotice Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags:OnDeleteCancel( wndHandler, wndControl )
	self.deleteWindow:SetData(nil)
	self.deleteWindow:Close()
	self:ResetBagItems()
end

------------------------------------------------------------------------
---------------------------
-- InventorySalvageNotice Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags:OnSalvageCancel( wndHandler, wndControl )
	self.salvageWindow:SetData(nil)
	self.salvageWindow:Close()
	self:ResetBagItems()
end


---------------------------------------------------------------------------------------------------
-- BagNamer Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags:OnBagNamerCancel( wndHandler, wndControl, eMouseButton )
	self.BagNamingWindow:SetData(nil)
	self.BagNamingWindow:Show(false)
end

function Serenity_Bags:NameBag( wndHandler, wndControl, eMouseButton )
	local text = self.BagNamingWindow:FindChild("EditBox"):GetText()
	if (text ~= "") then
		SavedItemCategories[self.BagNamingWindow:GetData()] = text
	end

	self:ResetBagItems()
	self:OnBagNamerCancel()
end

function Serenity_Bags:OnRemoveName( wndHandler, wndControl, eMouseButton )
	SavedItemCategories[self.BagNamingWindow:GetData()] = nil

	self:ResetBagItems()
	self:OnBagNamerCancel()

end

function Serenity_Bags:SetBagNameText( wndHandler, wndControl, eMouseButton )
	self.BagNamingWindow:FindChild("EditBox"):SetText(wndHandler:GetText())
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsInst = Serenity_Bags:new()
Serenity_BagsInst:Init()
