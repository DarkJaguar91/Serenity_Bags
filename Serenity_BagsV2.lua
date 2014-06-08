-----------------------------------------------------------------------------------------------
-- Client Lua Script for Serenity_BagsV2
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2 Module Definition
-----------------------------------------------------------------------------------------------
local Serenity_BagsV2 = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local cCurrenciesSize = {["width"] = 220, ["height"] = 133}

local CatToBag = {
	["Armor"] = "BagContainerL",
	["Gear"] = "BagContainerL",
	["Broken Item"] = "BagContainerL",
	["Charged Item"] = "BagContainerL",
	["Costume"] = "BagContainerL",
	["Miscellaneous"] = "BagContainerL",
	["Tool"] = "BagContainerL",
	["Weapon"] = "BagContainerL",
	["Consumable"] = "BagContainerL",

	
	["Unusual Component"] = "BagContainerR",
	["Warplot"] = "BagContainerR",
	["Reagent"] = "BagContainerR",
	["Runes"] = "BagContainerR",
	["Schematic"] = "BagContainerR",
	["Path"] = "BagContainerR",
	["Housing"] = "BagContainerR",
	["AMP"] = "BagContainerR",
	["Crafting"] = "BagContainerR",
	["Quest"] = "BagContainerR",
	["Quest Item"] = "BagContainerR",
	["Bag"] = "BagContainerR",
}

local function BagItemSorter(a, b)
	return string.lower(a:GetItemFamilyName()) < string.lower(b:GetItemFamilyName())
end
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Serenity_BagsV2:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Serenity_BagsV2:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2 OnLoad
-----------------------------------------------------------------------------------------------
function Serenity_BagsV2:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Serenity_BagsV2.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.itemsPerRow = 5
end
---------------------------------------------------------------------------------
-- Serenity_BagsV2 OnDocLoaded
-----------------------------------------------------------------------------------------------
function Serenity_BagsV2:OnDocLoaded()
	if self.xmlDoc == nil then
	    return
	end
	
	-- wildstar addon management tools
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	
	-- Display event
	Apollo.RegisterEventHandler("InterfaceMenu_ToggleInventory", "OnToggleVisibility", self)
	Apollo.RegisterEventHandler("GuildBank_ShowPersonalInventory", "OnToggleVisibilityAlways", self)
	Apollo.RegisterEventHandler("ToggleInventory", "OnToggleVisibility", self)
	--Apollo.RegisterEventHandler("ShowInventory", "OnToggleVisibility", self) -- might not be needed
	Apollo.RegisterEventHandler("VendorItemsUpdated", "OnVendorWindowInvoke", self)
	
	-- drag drop events
	Apollo.RegisterEventHandler("DragDropSysBegin", "OnSystemBeginDragDrop", self)
	Apollo.RegisterEventHandler("DragDropSysEnd", "OnSystemEndDragDrop", self)
	
	-- update events
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", "ResetBagContainers", self) -- route to same event
	Apollo.RegisterEventHandler("QuestObjectiveUpdated", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("PlayerPathRefresh", "ResetBagContainers", self) -- route to same event
	Apollo.RegisterEventHandler("QuestStateChanged", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("ChallengeUpdated", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("LootedItem",	"ResetBagContainers", self)
	--Apollo.RegisterEventHandler("UpdateInventory", "ResetBagContainers", self)

	Apollo.RegisterEventHandler("PlayerCurrencyChanged", "ResetAll", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", "ResetAll", self)
	
	self.wndDeleteConfirm = Apollo.LoadForm(self.xmlDoc, "InventoryDeleteNotice", nil, self)
	self.wndSalvageConfirm 	= Apollo.LoadForm(self.xmlDoc, "InventorySalvageNotice", nil, self)
	self.CurrenciesPopUp = Apollo.LoadForm(self.xmlDoc, "Currencies", nil, self);
	self.wndSalvageConfirm:Show(false, true)
	self.wndDeleteConfirm:Show(false, true)
	self.CurrenciesPopUp:Show(false, true)

	self.frame = Apollo.LoadForm(self.xmlDoc, "MainBagForm", nil, self)
	self.frame:Show(false, true)
	
	-- set sort of bag
	self.frame:FindChild("EmptyBag"):SetSort(true)
	self.frame:FindChild("EmptyBag"):SetItemSortComparer(BagItemSorter)
end

-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2 Event callss
-----------------------------------------------------------------------------------------------
function Serenity_BagsV2:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_Inventory"), {"InterfaceMenu_ToggleInventory", "Inventory", "Icon_Windows32_UI_CRB_InterfaceMenu_Inventory"})
end

function Serenity_BagsV2:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.frame, strName = Apollo.GetString("Serenity_BagsV2")})
end

function Serenity_BagsV2:OnToggleVisibility()
	if self.frame:IsShown() then
		self:CloseBag()
	else
		self:OpenBag()
	end	
end

function Serenity_BagsV2:InvokeDeleteConfirmWindow(iData) 
	local itemData = Item.GetItemFromInventoryLoc(iData)
	if itemData and not itemData:CanDelete() then
		return
	end
	self.wndDeleteConfirm:SetData(iData)
	self.wndDeleteConfirm:Show(true)
	self.wndDeleteConfirm:ToFront()
	self.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

function Serenity_BagsV2:InvokeSalvageConfirmWindow(iData) 
	local itemData = Item.GetItemFromInventoryLoc(iData)
	if itemData and not itemData:CanSalvage() then
		return
	end

	self.wndSalvageConfirm :SetData(iData)
	self.wndSalvageConfirm :Show(true)
	self.wndSalvageConfirm :ToFront()
	self.wndSalvageConfirm :FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, iData)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

function Serenity_BagsV2:OnSystemBeginDragDrop(wndSource, strType, iData)
	if strType ~= "DDBagItem" then return end
	self.frame:FindChild("TextActionPrompt_Trash"):Show(false)
	self.frame:FindChild("TextActionPrompt_Salvage"):Show(false)

	self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashTogglePressed")

	Sound.Play(Sound.PlayUI45LiftVirtual)
end

function Serenity_BagsV2:OnSystemEndDragDrop(strType, iData)
	if not self.frame or not self.frame:IsValid() or not self.frame:FindChild("TrashIcon") or strType == "DDGuildBankItem" or strType == "DDWarPartyBankItem" or strType == "DDGuildBankItemSplitStack" then
		return -- TODO Investigate if there are other types
	end

	self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashToggleNormal")
	self.frame:FindChild("TextActionPrompt_Trash"):Show(false)
	self.frame:FindChild("TextActionPrompt_Salvage"):Show(false)
	--self:UpdateSquareSize()
	Sound.Play(Sound.PlayUI46PlaceVirtual)
end

function Serenity_BagsV2:OnVendorWindowInvoke()
	self:OpenBag()
	local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
	for i,v in pairs(items) do
		if (v.itemInBag:GetItemCategoryName() == "Junk") then
			SellItemToVendor(v.nBagSlot, v.itemInBag:GetStackCount())
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2Form User defined functions
-----------------------------------------------------------------------------------------------
function Serenity_BagsV2:OpenBag()
	self.frame:Show(true)
	self.frame:ToFront()
	Sound.Play(Sound.PlayUIBagOpen)
	
	-- refresh data
	self:ResetMainBar()
	self:ResetBagContainers()
end

function Serenity_BagsV2:CloseBag()
	self.frame:Show(false)
	
	-- memory handling
	self.frame:FindChild("BagContainerR"):DestroyChildren()
		
	self.frame:FindChild("EmptyBag"):MarkAllItemsAsSeen()
	
	Sound.Play(Sound.PlayUIBagClose)
end

function Serenity_BagsV2:ResetAll()
	self:ResetMainBar()
	self:ResetBagContainers()
end

function Serenity_BagsV2:ResetMainBar()
	self.frame:FindChild("Currency"):SetAmount(GameLib.GetPlayerCurrency():GetAmount())
	
	-- empty bag frame
	local emptyBagFrame = self.frame:FindChild("EmptyBag")
	if (emptyBagFrame:GetTotalEmptyBagSlots() > 0) then
		local totalBagSlots = emptyBagFrame:GetTotalBagSlots()
		local y = (totalBagSlots-1) * 29
		
		emptyBagFrame:SetAnchorPoints(0,0,1,1)
		emptyBagFrame:SetAnchorOffsets(0, -y,0,0)
		emptyBagFrame:Show(true)
	else
		emptyBagFrame:Show(false)
	end
	self.frame:FindChild("NumberSlotsEmpty"):SetText(tostring(emptyBagFrame:GetTotalEmptyBagSlots()))
	
	for i = 1, 4 do
		local wnd = self.frame:FindChild("Bag" .. i)
		wnd:FindChild("Number"):SetText(wnd:GetItem():GetBagSlots())
		Tooltip.GetItemTooltipForm(self, wnd, self.frame:FindChild("EmptyBag"):GetBagItem(i), {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

function Serenity_BagsV2:CollectBagItems()
if (GameLib.GetPlayerUnit()) then
		local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
		local categories = {}
		
		for i, v in pairs(items) do
			local category = nil
			category = v.itemInBag:GetItemFamilyName()
		
			-- checks for easier use
			if (category == "Gear" or category == "Weapon") then
				category = "Armor"
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

function Serenity_BagsV2:ResetBagContainers()
	local itemCat = self:CollectBagItems()
	
	local bagContL = self.frame:FindChild("BagContainerL")
	local bagContR = self.frame:FindChild("BagContainerR")
	bagContL:DestroyChildren()
	bagContR:DestroyChildren()
	bagContL:Show(false)
	bagContR:Show(false)
	for i, v in pairs(itemCat) do
		local bag = Apollo.LoadForm(self.xmlDoc, "BagContainer", self.frame:FindChild(CatToBag[i]), self)
		bag:FindChild("Name"):SetText(i)
		
		self:AddItemsToBag(bag, v)
		bag:SetData(i)
	end
	
	self:ArrangeBagContainers()
end

function Serenity_BagsV2:ArrangeBagContainers()
	local bagContR = self.frame:FindChild("BagContainerR")
	local bagContL = self.frame:FindChild("BagContainerL")

	local RItems = bagContR:GetChildren()
	local LItems = bagContL:GetChildren()
	table.sort(RItems, function(a, b)
		return a:GetData() > b:GetData()
	end)
	table.sort(LItems, function(a, b)
		return a:GetData() > b:GetData()
	end)
	
	bagContR:Show(false)
	bagContL:Show(false)
	local y = 0
	
	-- right	
	y = 0
	for i,v in pairs(RItems) do
		v:SetAnchorOffsets(0, -(y + v:GetHeight()), 0, -(y))	
	
		y = y + v:GetHeight()
	end
	
	-- left
	y = 0
	for i,v in pairs(LItems) do
		v:SetAnchorOffsets(0, -(y + v:GetHeight()), 0, -(y))	
	
		y = y + v:GetHeight()
	end
	
	bagContR:Show(true)
	bagContL:Show(true)
end

function Serenity_BagsV2:AddItemsToBag(bag, items)
	table.sort(items, function(a, b) 
		return string.lower(a.itemInBag:GetName()) < string.lower(b.itemInBag:GetName())
	end)
	
	local h = 0
	for i, v in pairs(items) do
		local itm = Apollo.LoadForm(self.xmlDoc, "BagItem", bag:FindChild("Items"), self)
		
		if (h == 0 ) then h = itm:GetWidth() + 1 end
		
		local y = v.nBagSlot * h
		
		itm:FindChild("BItm"):SetAnchorOffsets(0, -y, 0, 0)
	end
	
	--sizing
	do
		bag:SetAnchorPoints(0, 1, 1, 1)
		local y = math.ceil(#items / 7)
		bag:SetAnchorOffsets(0, -(y * (h) + 22), 0, 0)
	end
	
	bag:FindChild("Items"):ArrangeChildrenTiles()
end

---------------------------------------------------------------------------------------------------
-- MainBagForm Functions (input events events)
---------------------------------------------------------------------------------------------------

function Serenity_BagsV2:OnCurrencyHover( wndHandler, wndControl, x, y )
	-- reset anchors
	self.CurrenciesPopUp:SetAnchorPoints(1, 1, 1, 1)
	local l, t, r, b = self.frame:GetAnchorOffsets()
	local l2, t2, r2, b2 = self.frame:FindChild("Currency"):GetAnchorOffsets()
	
	r = r + r2	
	l = r - cCurrenciesSize["width"]
	b = b + t2
	t = b - cCurrenciesSize["height"]
	self.CurrenciesPopUp:SetAnchorOffsets(l, t, r, b)	
	
	--show
	if (wndHandler) then
		self.CurrenciesPopUp:Show(true)
	
		-- Update the currencies
		self.CurrenciesPopUp:FindChild("RenownCash"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
		self.CurrenciesPopUp:FindChild("RenownCash"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount(), true)
		self.CurrenciesPopUp:FindChild("GemsCash"):SetMoneySystem(Money.CodeEnumCurrencyType.ElderGems)
		self.CurrenciesPopUp:FindChild("GemsCash"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.ElderGems):GetAmount(), true)
		self.CurrenciesPopUp:FindChild("PrestigeCash"):SetMoneySystem(Money.CodeEnumCurrencyType.Prestige)
		self.CurrenciesPopUp:FindChild("PrestigeCash"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Prestige):GetAmount(), true)
		self.CurrenciesPopUp:FindChild("CraftCash"):SetMoneySystem(Money.CodeEnumCurrencyType.CraftingVouchers)
		self.CurrenciesPopUp:FindChild("CraftCash"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.CraftingVouchers):GetAmount(), true)
		
		self.CurrenciesPopUp:ToFront()
	end
end

function Serenity_BagsV2:OnCurrencyLeave( wndHandler, wndControl, x, y )
	self.CurrenciesPopUp:Show(false)
end

function Serenity_BagsV2:OnTradeSkillBagToggle( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("ToggleTradeskillInventoryFromBag")
end

function Serenity_BagsV2:OnSalvageAllClick( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("RequestSalvageAll")
end

function Serenity_BagsV2:OnTrashDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	if strType == "DDBagItem" then
		self:InvokeDeleteConfirmWindow(iData)
	end
	return false
end

function Serenity_BagsV2:OnDragDropHoverTrash( wndHandler, wndControl, bMe )
	if bMe then
		self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashToggleFlyby")
		self.frame:FindChild("TextActionPrompt_Trash"):Show(true)
	else
		self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashTogglePressed")
		self.frame:FindChild("TextActionPrompt_Trash"):Show(false)
	end
end

function Serenity_BagsV2:OnDragDropRequest( wndHandler, wndControl, x, y, wndSource, strType, iData, eResult )
	if strType == "DDBagItem" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

function Serenity_BagsV2:OnCloseNotafication( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():GetParent():Close()
end

function Serenity_BagsV2:OnMainBagMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self:OnCurrencyHover(nil, nil, 0, 0)
end

function Serenity_BagsV2:OnGenTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		-- Tooltip.GetItemTooltipForm(self, wndControl, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = item})
	end
end

function Serenity_BagsV2:OnSalvageDropRequest( wndHandler, wndControl, x, y, wndSource, strType, iData, eResult )
	if strType == "DDBagItem" and Item.GetItemFromInventoryLoc(iData):CanSalvage() then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

function Serenity_BagsV2:OnSalvageDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	self:InvokeSalvageConfirmWindow(iData)
end

function Serenity_BagsV2:OnSalvageDragDropNotify( wndHandler, wndControl, bMe )
	if bMe then
		self.frame:FindChild("TextActionPrompt_Salvage"):Show(true)
	else
		self.frame:FindChild("TextActionPrompt_Salvage"):Show(false)
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2 Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsV2Inst = Serenity_BagsV2:new()
Serenity_BagsV2Inst:Init()
