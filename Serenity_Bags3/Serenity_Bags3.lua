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
-- e.g. local kiExampleVariableMax = 999
 
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

-----------------------------------------------------------------------------------------------
-- Serenity_Bags3 Instance
-----------------------------------------------------------------------------------------------
local Serenity_Bags3Inst = Serenity_Bags3:new()
Serenity_Bags3Inst:Init()
