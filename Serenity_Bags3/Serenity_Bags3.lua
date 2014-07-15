-----------------------------------------------------------------------------------------------
-- Client Lua Script for Serenity_Bags3
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 Module Definition
-----------------------------------------------------------------------------------------------
local Serenity_Bags3 = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local EnumSortedType = {
	tabbed = 1,
}

local EnumAnchorPoint = {
	none = 1,
	top = 2,
	left = 3,
	right = 4,
	bot = 5,
}

function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
        else return a[i], t[a[i]]
 		end
 	end
 	return iter
 end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Serenity_Bags3:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Serenity_Bags3:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function Serenity_Bags3:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local tL, tT, tR, tB = self.mainBag:GetAnchorOffsets()
		return {
			MainBagSqaureSize = self.mainBagSquareSize,
			l = tL,
			t = tT,
			r = tR,
			b = tB,
		}
	end
	
	return nil
end

function Serenity_Bags3:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character  then
		if not tSavedData then
			return
		end
		
		if (tSavedData.MainBagSqaureSize) then
			self.mainBagSquareSize = tSavedData.MainBagSqaureSize
		end
		if (tSavedData.l) then
			self.l = tSavedData.l
			self.t = tSavedData.t
			self.r = tSavedData.r
			self.b = tSavedData.b
		end
		
	end	
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 OnLoad
-----------------------------------------------------------------------------------------------
function Serenity_Bags3:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Serenity_Bags3.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 OnDocLoaded
-----------------------------------------------------------------------------------------------
function Serenity_Bags3:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		-- load sprite
		Apollo.LoadSprites("Serenity3Sprite.xml", "Serenity3Sprite")
	
		-- UI integration
		--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	
		-- inventory events
		Apollo.RegisterEventHandler("ToggleInventory", "OnToggleInventory", self)
		
		-- slash commands
		Apollo.RegisterSlashCommand("sb", "OnSlashCommand", self)
		
		-- Load bag sizes
		if (self.mainBagSquareSize == nil) then
			self.mainBagSquareSize = 30
		end
		if (self.sortedBagSquareSize == nil) then
			self.sortedBagSquareSize = 30
		end
		if (self.sortedType == nil) then
			self.sortedType = EnumSortedType.tabbed
		end
		if (self.attachedLocations == nil) then
			self.anchorPoint = EnumAnchorPoint.top
		end
		
		
	    self.mainBag = Apollo.LoadForm(self.xmlDoc, "MainBag", nil, self)
	    self.mainBag:Show(false, true)
		-- reposition bag
		if (self.l) then
			Print("Moving")
			self.mainBag:SetAnchorOffsets(self.l, self.t, self.r, self.b)
			self.l = nil self.t = nil self.r = nil self.b = nil
		end
		
	
		self.options = Apollo.LoadForm(self.xmlDoc, "OptionsFrame", nil, self)
	    self.options:Show(false, true)
		self:SetOptionsFunctions()
	
		local bagOptions = self.options:FindChild("BagOptions")
		bagOptions:AttachTab(self.options:FindChild("SplitOptions"), true)
	end
end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 Functions
-----------------------------------------------------------------------------------------------

function Serenity_Bags3:OnSlashCommand()
	self.options:Show(true)
	self.options:FindChild("BagOptions"):SetFocus()
end

function Serenity_Bags3:OnToggleInventory()
	if (self.mainBag:IsVisible()) then
		self.mainBag:Show(false)
	else
		self.mainBag:Show(true)
		self:ResetMainBag()
		self:ResetSortedBags()
	end
end

function Serenity_Bags3:ResetAllWindows()
	self:ResetMainBag()
end

function Serenity_Bags3:ResetMainBag()
	self:ResetBagItems()
	self:ResetCurrency()
	self:ResizeMainBagWindow()
end

function Serenity_Bags3:ResetSortedBags()
	self:DestroySortedBags()
	if (self.sortedType == EnumSortedType.tabbed)then
		self:CreateTabbedBagSystem()
	end
end

function Serenity_Bags3:DestroySortedBags()
	if (self.sortedBags) then
		if (type(self.sortedBags) == "table") then
			for i, v in pairs(self.sortedBags) do
				v:Destroy()
				v = nil
			end
		else
			self.sortedBags:Destroy()
		end
		self.sortedBags = nil
	end
end

function Serenity_Bags3:ResizeMainBagWindow()
	if GameLib.GetPlayerUnit() == nil then return end
	local bagWindow = self.mainBag:FindChild("BagWindow")
	local numberItems = bagWindow:GetTotalBagSlots()
	local numRowItems = math.floor(bagWindow:GetWidth() / (self.mainBagSquareSize + 1))
	local numRows = math.ceil(numberItems / numRowItems)
	bagWindow:SetSquareSize(self.mainBagSquareSize, self.mainBagSquareSize)
	
	local l,t,r,b = self.mainBag:GetAnchorOffsets()
	self.mainBag:SetAnchorOffsets(l, b - (45 + (numRows * (self.mainBagSquareSize + 1))), r, b)	
end

function Serenity_Bags3:ResetCurrency()
	if GameLib.GetPlayerCurrency() then
		self.mainBag:FindChild("Currency"):SetAmount(GameLib.GetPlayerCurrency():GetAmount())
	end
end

function Serenity_Bags3:ResetBagItems()
	for i = 1, 4 do
		local wnd = self.mainBag:FindChild("Bag" .. i)
		if self.mainBag:FindChild("BagWindow"):GetBagItem(i) and wnd:GetItem() then
			wnd:FindChild("Number"):SetText(wnd:GetItem():GetBagSlots())
			Tooltip.GetItemTooltipForm(self, wnd, self.mainBag:FindChild("BagWindow"):GetBagItem(i), {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		else
			wnd:FindChild("Number"):SetText("")
		end

	end
end

function Serenity_Bags3:MoveAndSizeObject(form, maxHeight)
	if (self.anchorPoint == EnumAnchorPoint.none) then
		-- TODO work this into the system
	elseif (self.anchorPoint == EnumAnchorPoint.top) then
		form:SetAnchorPoints(0, 0, 1, 0)
		form:SetAnchorOffsets(0, -maxHeight, 0, 0)
	elseif (self.anchorPoint == EnumAnchorPoint.left) then
		form:SetAnchorPoints(0, 1, 0, 1)
		form:SetAnchorOffsets(-self.mainBag:GetWidth(), -maxHeight, 0, 0)
	elseif (self.anchorPoint == EnumAnchorPoint.right) then
		form:SetAnchorPoints(1, 0, 1, 0)
		form:SetAnchorOffsets(0, -maxHeight, self.mainBag:GetWidth(), 0)
	elseif (self.anchorPoint == EnumAnchorPoint.bot) then
		form:SetAnchorPoints(0, 0, 1, 0)
		form:SetAnchorOffsets(0, 0, 0, maxHeight)
	end
end

function Serenity_Bags3:CreateTabbedBagSystem()
	if (self.anchorPoint == EnumAnchorPoint.none) then
		self.sortedBags = Apollo.LoadForm(self.xmlDoc, "TabbedBagForm", nil, self)
	else
		self.sortedBags = Apollo.LoadForm(self.xmlDoc, "TabbedBagForm", self.mainBag, self)
	end
	
	local bagValues = self:CollectBagDetails()
	
	-- determine max
	local max = 0
	for i, v in pairs(bagValues) do
		local height = self:CalculateBagHeight(v[1], self.mainBag:GetWidth(), 10, self.sortedBagSquareSize) + 20
		if max < height then max = height end
	end
	
	self:MoveAndSizeObject(self.sortedBags, max)
	
	-- add all the tabs
	local firstTab = nil
	for i, v in pairsByKeys(bagValues) do
		local tabbedBag = Apollo.LoadForm(self.xmlDoc, "TabbedBag", self.sortedBags, self)
		
		tabbedBag:SetText(i)
		
		local bagItem = tabbedBag:FindChild("BagWindow")
		
		bagItem:SetSquareSize(self.sortedBagSquareSize, self.sortedBagSquareSize)
		bagItem:SetSort(true)
		bagItem:SetItemSortComparer(
			function(a,b) 
				if a:GetItemFamily() == v[2] and b:GetItemFamily() == v[2] then
					return 0
				elseif a:GetItemFamily() == v[2] then
					return -1
				else
					return 1
				end
			end
		)
		
		local height, rowItems, rows = self:CalculateBagHeight(v[1], self.mainBag:GetWidth(), 10, self.sortedBagSquareSize)
		local padding = bagItem:GetWidth() - rowItems * (self.sortedBagSquareSize + 1) + 1
		padding = padding / 2
		bagItem:FindChild("Blocker"):SetAnchorOffsets(-(rowItems-v[1]) * (self.sortedBagSquareSize+1) - padding, -rows * (self.sortedBagSquareSize + 1) + 1, 0, 0)	
		
		if (firstTab) then
			firstTab:AttachTab(tabbedBag)
		else
			firstTab = tabbedBag
		end
	end
end

function Serenity_Bags3:CollectBagDetails()
	local items = GameLib:GetPlayerUnit():GetInventoryItems()
	
	local list = {}
	
	for i, v in pairs(items) do
		local name = v.itemInBag:GetItemFamilyName()
		local code = v.itemInBag:GetItemFamily()
		
		if (list[name]) then
			list[name][1] = list[name][1] + 1
		else
			list[name] = {1, code}
		end
	end
	
	table.sort(list)
	
	return list
end

function Serenity_Bags3:CalculateBagHeight(items, width, padding, slotSize)
	local numRowItems = math.floor((width - padding) / (slotSize + 1))
	local numRows = math.ceil(items / numRowItems)
	
	return numRows * (slotSize + 1) + padding, numRowItems, numRows
end
-----------------------------------------------------------------------------------------------
-- Serenity_Bags3Form Functions
-----------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------
-- MainBag Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags3:OnGenerateItemTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

---------------------------------------------------------------------------------------------------
-- OptionsFrame Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags3:SetOptionsFunctions()
	-- Bag Tab
	local bagOptions = self.options:FindChild("BagOptions")
	bagOptions:FindChild("MainBagSquareSizeEdit"):SetText(self.mainBagSquareSize)
	bagOptions:FindChild("MainBagSquareSizeEdit"):SetData(
		function()
			if (tonumber(bagOptions:FindChild("MainBagSquareSizeEdit"):GetText()) < 10) then
				bagOptions:FindChild("MainBagSquareSizeEdit"):SetText("10")
			end
			self.mainBagSquareSize = tonumber(bagOptions:FindChild("MainBagSquareSizeEdit"):GetText())
			self:ResetAllWindows()
		end
	)
	bagOptions:FindChild("MainBagWidthEdit"):SetText(self.mainBag:GetWidth())
	bagOptions:FindChild("MainBagWidthEdit"):SetData(
		function()
			if (self.mainBag) then				
				if (tonumber(bagOptions:FindChild("MainBagWidthEdit"):GetText()) < 275) then
					bagOptions:FindChild("MainBagWidthEdit"):SetText("275")
				end
				local l,t,r,b = self.mainBag:GetAnchorOffsets()
				l = r - tonumber(bagOptions:FindChild("MainBagWidthEdit"):GetText())
				self.mainBag:SetAnchorOffsets(l,t,r,b)
				self:ResizeMainBagWindow()
				self:ResetSortedBags()
			end
		end
	)
	
end

function Serenity_Bags3:OnIncreaseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler ~= wndControl then return end
	
	local value = tonumber(wndHandler:GetParent():GetText())
	value = value + 1
	wndHandler:GetParent():SetText(value)
	
	if (wndHandler:GetParent():GetData()) then
		wndHandler:GetParent():GetData()()
	end
end

function Serenity_Bags3:OnDecreaseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler ~= wndControl then return end
	
	local value = tonumber(wndHandler:GetParent():GetText())
	value = value - 1
	wndHandler:GetParent():SetText(value)
	
	if (wndHandler:GetParent():GetData()) then
		wndHandler:GetParent():GetData()()
	end
end

function Serenity_Bags3:OnCloseOptions( wndHandler, wndControl, eMouseButton )
	self.options:Show(false)
end

function Serenity_Bags3:OnMouseWheelMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY, fScrollAmount, bConsumeMouseWheel )
	if wndHandler ~= wndControl then return	end
	
	
	local value = tonumber(wndHandler:GetText())
	value = math.floor(value + fScrollAmount)
	wndHandler:SetText(value)
	
	if (wndHandler:GetData()) then
		wndHandler:GetData()()
	end
	return true
end

---------------------------------------------------------------------------------------------------
-- TabbedBag Functions
---------------------------------------------------------------------------------------------------

function Serenity_Bags3:SortedBagWindowSizeChanged( wndHandler, wndControl )

end

-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 Instance
-----------------------------------------------------------------------------------------------
local Serenity_Bags3Inst = Serenity_Bags3:new()
Serenity_Bags3Inst:Init()
