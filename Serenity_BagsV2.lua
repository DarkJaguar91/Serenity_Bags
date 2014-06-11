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

local SavedItemCategories = {}

local FamilyCodeToName = {
	armor = 1,
	weapon = 2,
	bag = 5,
	brocken = 13,
	gear = 15,
	consumable = 16,
	charged = 17,
	reagent = 18,	
	schematic = 19,
	housing = 20,
	housingExt = 21,
	fam22 = 22,
	questItm = 24,
	misc = 25,
	costume = 26,
	crafting = 27,
	tool = 28,
	path = 29,
	warplot = 30,
	unusual = 31,
	amp = 32,
	rune = 33,
}

local CatToBag = {
	[FamilyCodeToName.armor] = "BagContainerL", -- armor
	[FamilyCodeToName.brocken] = "BagContainerL", -- brocken item
	[FamilyCodeToName.charged] = "BagContainerL", -- charged item
	[FamilyCodeToName.costume] = "BagContainerL", -- costume
	[FamilyCodeToName.misc] = "BagContainerL", -- miscelaneous
	[FamilyCodeToName.tool] = "BagContainerL", -- tool
	[FamilyCodeToName.consumable] = "BagContainerL", -- consumable

	[FamilyCodeToName.fam22] = "BagContainerR", -- family-22
	[FamilyCodeToName.unusual] = "BagContainerR", -- unuslual component
	[FamilyCodeToName.warplot] = "BagContainerR", -- warplot
	[FamilyCodeToName.reagent] = "BagContainerR", -- reagent
	[FamilyCodeToName.rune] = "BagContainerR", -- rune
	[FamilyCodeToName.schematic] = "BagContainerR", --schematic
	[FamilyCodeToName.path] = "BagContainerR", -- path
	[FamilyCodeToName.housing] = "BagContainerR", -- housing
	[FamilyCodeToName.housingExt] = "BagContainerR", -- housing exterior
	[FamilyCodeToName.amp] = "BagContainerR", -- amp
	[FamilyCodeToName.crafting] = "BagContainerR", -- crafting
	[FamilyCodeToName.questItm] = "BagContainerR",-- quest item
	[FamilyCodeToName.bag] = "BagContainerR", -- bag
}

local function BagItemSorter(a, b)
	return string.lower(a:GetItemFamily()) < string.lower(b:GetItemFamily())
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
 
function Serenity_BagsV2:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		return {
			savedBagNames = SavedItemCategories,
		}
	end
	
	return nil
end

function Serenity_BagsV2:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character  then
		if not tSavedData then
			return
		end
		
		SavedItemCategories = tSavedData.savedBagNames
	end	
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
	
	-- Splitting items	
	Apollo.RegisterEventHandler("SplitItemStack", "OnSplitItemStack", self)

	-- update events
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", "ResetBagContainers", self) -- route to same event
	Apollo.RegisterEventHandler("QuestObjectiveUpdated", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("PlayerPathRefresh", "ResetBagContainers", self) -- route to same event
	Apollo.RegisterEventHandler("QuestStateChanged", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("ChallengeUpdated", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("LootedItem",	"ResetBagContainers", self)
	Apollo.RegisterEventHandler("UpdateInventory", "ResetBagContainers", self)
	Apollo.RegisterEventHandler("ItemRemoved", "OnItemRemoved", self)

	Apollo.RegisterEventHandler("PlayerCurrencyChanged", "ResetAll", self)
	--Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", "ResetAll", self)
	
	Apollo.LoadSprites("SerenitySprite.xml", "SerenitySprite")
	
	self.wndDeleteConfirm = Apollo.LoadForm(self.xmlDoc, "InventoryDeleteNotice", nil, self)
	self.wndSalvageConfirm 	= Apollo.LoadForm(self.xmlDoc, "InventorySalvageNotice", nil, self)
	self.CurrenciesPopUp = Apollo.LoadForm(self.xmlDoc, "Currencies", nil, self);
	self.bagNamer = Apollo.LoadForm(self.xmlDoc, "BagNamer", nil, self);
	self.splitter = Apollo.LoadForm(self.xmlDoc, "SplitStackContainer", nil, self);
	self.wndSalvageConfirm:Show(false, true)
	self.wndDeleteConfirm:Show(false, true)
	self.CurrenciesPopUp:Show(false, true)
	self.bagNamer:Show(false, true)
	self.splitter:Show(false, true)

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

function Serenity_BagsV2:OnItemRemoved(itemSold, nCount, eReason)
	if eReason == Item.CodeEnumItemUpdateReason.Vendor then
		SavedItemCategories[itemSold:GetItemId()] = nil
	end
	self:ResetBagContainers()
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
	self.frame:FindChild("TextActionPrompt_Spec"):Show(false)

	self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashTogglePressed")
	self.frame:FindChild("SpecIcon"):SetSprite("CRB_Inventory:InvBtn_ModifyTogglePressed")

	Sound.Play(Sound.PlayUI45LiftVirtual)
end

function Serenity_BagsV2:OnSystemEndDragDrop(strType, iData)
	if not self.frame or not self.frame:IsValid() or not self.frame:FindChild("TrashIcon") or strType == "DDGuildBankItem" or strType == "DDWarPartyBankItem" or strType == "DDGuildBankItemSplitStack" then
		return -- TODO Investigate if there are other types
	end

	self.frame:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashToggleNormal")
	self.frame:FindChild("SpecIcon"):SetSprite("CRB_Inventory:InvBtn_ModifyToggleNormal")
	self.frame:FindChild("TextActionPrompt_Trash"):Show(false)
	self.frame:FindChild("TextActionPrompt_Salvage"):Show(false)
	self.frame:FindChild("TextActionPrompt_Spec"):Show(false)
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

function Serenity_BagsV2:OnSplitItemStack(item)
	if not item then return end
	local wndSplit = self.splitter
	local nStackCount = item:GetStackCount()
	if nStackCount < 2 then
		wndSplit:Show(false)
		return
	end

	local mouse = Apollo.GetMouse()
	wndSplit:SetAnchorOffsets(mouse.x - wndSplit:GetWidth(), mouse.y - wndSplit:GetHeight(), mouse.x, mouse.y)
	
	wndSplit:SetData(item)
	wndSplit:FindChild("SplitValue"):SetValue(1)
	wndSplit:FindChild("SplitValue"):SetMinMax(1, nStackCount - 1)
	wndSplit:Show(true)
	wndSplit:ToFront()
	wndSplit:FindChild("SplitValue"):SetFocus()
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
		emptyBagFrame:SetAnchorOffsets(0,-y,0,0)
		emptyBagFrame:Show(true)
	else
		emptyBagFrame:Show(false)
	end
	self.frame:FindChild("NumberSlotsEmpty"):SetText(tostring(emptyBagFrame:GetTotalEmptyBagSlots()))
	
	for i = 1, 4 do
		local wnd = self.frame:FindChild("Bag" .. i)
		if self.frame:FindChild("EmptyBag"):GetBagItem(i) and wnd:GetItem() then
			wnd:FindChild("Number"):SetText(wnd:GetItem():GetBagSlots())
			Tooltip.GetItemTooltipForm(self, wnd, self.frame:FindChild("EmptyBag"):GetBagItem(i), {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		else
			wnd:FindChild("Number"):SetText("")
		end
	end
end

function Serenity_BagsV2:CollectBagItems()
if (GameLib.GetPlayerUnit()) then
		local items = GameLib.GetPlayerUnit():GetInventoryItems()
	
		local categories = {}
		
		for i, v in pairs(items) do
			local category = v.itemInBag:GetItemFamilyName()
			local catCode = v.itemInBag:GetItemFamily()
			
			-- checks for easier use
			if (catCode == FamilyCodeToName.gear or catCode == FamilyCodeToName.weapon) then
				catCode = FamilyCodeToName.armor
				category = "Armor"
			end
			
			if SavedItemCategories[v.itemInBag:GetItemId()] then
				category = SavedItemCategories[v.itemInBag:GetItemId()]
				catCode = category
			end
			
			if categories[catCode] == nil then
				categories[catCode] = {{}, category} -- TODO 
			end
			
			table.insert(categories[catCode][1], v)
		end
			
		return categories
	end
	return nil
end

function Serenity_BagsV2:ResetBagContainers()
	if not self.frame:IsVisible() then return end
	local itemCat = self:CollectBagItems()
	
	if (itemCat == nil) then return end
	
	local bagContL = self.frame:FindChild("BagContainerL")
	local bagContR = self.frame:FindChild("BagContainerR")
	bagContL:DestroyChildren()
	bagContR:DestroyChildren()
	for i, v in pairs(itemCat) do
		local bag = nil
		if (CatToBag[i]) then
			bag = Apollo.LoadForm(self.xmlDoc, "BagContainer", self.frame:FindChild(CatToBag[i]), self)
		else 
			bag = Apollo.LoadForm(self.xmlDoc, "BagContainer", self.frame:FindChild("BagContainerL"), self)
		end

		bag:FindChild("Name"):SetText(v[2])
		bag:SetData(v[2])
	
		self:AddItemListToBag(bag, i, #v[1])
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

function Serenity_BagsV2:CheckItemInBag(item, cat)
	if SavedItemCategories[item:GetItemId()] == cat then
		return true
	else
		return false
	end
end

function Serenity_BagsV2:GetBagSortingAlgorithm(catCode)
	function contains(data)
		for i, v in pairs(FamilyCodeToName) do
			if (v == data) then
				return true
			end		
		end
		return false
	end

	if (contains(catCode)) then
		if catCode == FamilyCodeToName.armor then
			return function(a, b) -- armor
					if SavedItemCategories[a:GetItemId()] and SavedItemCategories[b:GetItemId()] then
						return 0
					elseif SavedItemCategories[a:GetItemId()] then
						return 1
					elseif SavedItemCategories[b:GetItemId()] then
						return -1
					elseif (a:GetItemFamily() == FamilyCodeToName.armor and b:GetItemFamily() == FamilyCodeToName.armor) then
						return a:GetName() < b:GetName()
					elseif (a:GetItemFamily() == FamilyCodeToName.armor) then
						return -1
					elseif (b:GetItemFamily() == FamilyCodeToName.armor) then
						return 1
					elseif (a:GetItemFamily() == FamilyCodeToName.gear and b:GetItemFamily() == FamilyCodeToName.gear) then
						return a:GetName() < b:GetName()
					elseif (a:GetItemFamily() == FamilyCodeToName.gear) then
						return -1
					elseif (b:GetItemFamily() == FamilyCodeToName.gear) then
						return 1
					elseif (a:GetItemFamily() == FamilyCodeToName.weapon and b:GetItemFamily() == FamilyCodeToName.weapon) then
						return a:GetName() < b:GetName()
					elseif (a:GetItemFamily() == FamilyCodeToName.weapon) then
						return -1
					elseif (b:GetItemFamily() == FamilyCodeToName.weapon) then
						return 1
					else
						return 1	
					end
				end
		else
			return function (a,b) -- others
					if SavedItemCategories[a:GetItemId()] and SavedItemCategories[b:GetItemId()] then
						return 0
					elseif SavedItemCategories[a:GetItemId()] then
						return 1
					elseif SavedItemCategories[b:GetItemId()] then
						return -1
					elseif (a:GetItemFamily() == catCode and b:GetItemFamily() == catCode) then
						return a:GetName() < b:GetName()
					elseif (a:GetItemFamily() == catCode) then
						return -1
					else
						return 1
					end
			end
		end
	end
	return function (a,b)
		if self:CheckItemInBag(a, catCode) and self:CheckItemInBag(b, catCode) then
			return a:GetName() < b:GetName()
		elseif self:CheckItemInBag(a, catCode) then
			return -1
		elseif self:CheckItemInBag(b, catCode) then
			return 1
		end
		return 1
	end
end

function Serenity_BagsV2:AddItemListToBag(bag, catCode, numItems)
	local numToNotShow = 8 - numItems % 8
	
	local list = Apollo.LoadForm(self.xmlDoc, "BagList", bag:FindChild("Items"), self)
	list:SetAnchorPoints(0,0,1,1)
	list:SetAnchorOffsets(0,0,0,0)

	list:FindChild("BItm"):SetSort(true)
	
	list:FindChild("BItm"):SetItemSortComparer(self:GetBagSortingAlgorithm(catCode))
	
	list:FindChild("BItm"):SetBoxesPerRow(8)
	
	local blocker = list:FindChild("Blocker")
	if numToNotShow == 8 then
		blocker:Show(false)
	else
		blocker:Show(true)
		blocker:SetAnchorPoints(1,1,1,1)
		blocker:SetAnchorOffsets(-(numToNotShow * 44), -43, 0, 0)
		blocker:SetTooltip(bag:GetData())
	end
	
	do
		bag:SetAnchorPoints(0, 1, 1, 1)
		local y = math.ceil(numItems / 8)
		bag:SetAnchorOffsets(0, -(y * (44) + 27), 0, 0)
	end
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

function Serenity_BagsV2:OnSplitStackCloseClick( wndHandler, wndControl, eMouseButton )
	self.splitter:Show(false)
end

function Serenity_BagsV2:OnSplitStackConfirm( wndHandler, wndControl, eMouseButton )
	local wndSplit = self.splitter
	local tItem = wndSplit:GetData()
	wndSplit:Show(false)
	self.frame:FindChild("EmptyBag"):StartSplitStack(tItem, wndSplit:FindChild("SplitValue"):GetValue())
end

function Serenity_BagsV2:OnDragDropHoverSpec( wndHandler, wndControl, bMe )
	if bMe then
		self.frame:FindChild("SpecIcon"):SetSprite("CRB_Inventory:InvBtn_ModifyToggleFlyby")
		self.frame:FindChild("TextActionPrompt_Spec"):Show(true)
	else
		self.frame:FindChild("SpecIcon"):SetSprite("CRB_Inventory:InvBtn_ModifyTogglePressed")
		self.frame:FindChild("TextActionPrompt_Spec"):Show(false)
	end
end

function Serenity_BagsV2:OnSpecDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
	self:InvokeBagNamingWindow(Item.GetItemFromInventoryLoc(iData):GetItemId())
							
	self:ResetBagContainers()
end

function Serenity_BagsV2:OnSpecifyBag( wndHandler, wndControl, eMouseButton )
	local text = self.bagNamer:FindChild("EditBox"):GetText()
	if (text ~= "") then
		SavedItemCategories[self.bagNamer:GetData()] = text
	end

	self:ResetBagContainers()
	self.bagNamer:Show(false)
end

function Serenity_BagsV2:OnRemoveName( wndHandler, wndControl, eMouseButton )
	SavedItemCategories[self.bagNamer:GetData()] = nil

	self:ResetBagContainers()
	self.bagNamer:Show(false)
end

function Serenity_BagsV2:InvokeBagNamingWindow(item) 
	if item == nil then
		return
	end
	
	self.bagNamer:SetData(item)
	self.bagNamer:Show(true)
	self.bagNamer:ToFront()
	if (SavedItemCategories[item]) then
		self.bagNamer:FindChild("RemoveBtn"):Show(true)
	else
		self.bagNamer:FindChild("RemoveBtn"):Show(false)
	end
	
	local bagNames = self:GetSavedBagNames()
	if (#bagNames > 0) then
		local wnd = self.bagNamer:FindChild("NamesAvailable")
		wnd:Show(true)
		local list = wnd:FindChild("ListOfNames")
		
		list:DestroyChildren()
		
		for i, v in pairs(bagNames) do
			local bagNameWnd = Apollo.LoadForm(self.xmlDoc, "BagName", list, self)
			bagNameWnd:FindChild("NameBtn"):SetText(v)
		end
		list:ArrangeChildrenVert()
	else
		self.bagNamer:FindChild("NamesAvailable"):Show(false)	
	end
	
	self.bagNamer:FindChild("EditBox"):SetText("")
	Sound.Play(Sound.PlayUI55ErrorVirtual)
	self.bagNamer:FindChild("EditBox"):SetFocus()
end

function Serenity_BagsV2:tableContains(table, data)
	for i, v in pairs(table) do
		if (v == data) then
			return true
		end
	end
	return false
end

function Serenity_BagsV2:GetSavedBagNames()
	local names = {}
	
	for i, v in pairs(SavedItemCategories) do
		if not self:tableContains(names, v) then
			table.insert(names, v)
		end
	end

	return names
end

function Serenity_BagsV2:SetBagNameText( wndHandler, wndControl, eMouseButton )
	self.bagNamer:FindChild("EditBox"):SetText(wndHandler:GetText())
end

function Serenity_BagsV2:OnExitNotification( wndHandler, wndControl, eMouseButton )
	wndHandler:GetParent():Close()
end

function Serenity_BagsV2:OnDeleteConfirm( wndHandler, wndControl )
	self.wndDeleteConfirm:Show(false)
end

function Serenity_BagsV2:OnSalvageConfirm( wndHandler, wndControl )
	self.wndSalvageConfirm:Show(false)
end

function Serenity_BagsV2:OnDragCancel( wndHandler, wndControl, strType, iData, eReason, bDragDropHasBeenReset )
	if strType ~= "DDBagItem" then return end
	self:InvokeDeleteConfirmWindow(iData)
end

-----------------------------------------------------------------------------------------------
-- Serenity_BagsV2 Instance
-----------------------------------------------------------------------------------------------
local Serenity_BagsV2Inst = Serenity_BagsV2:new()
Serenity_BagsV2Inst:Init()