-- Local values: SiloDialog_mt
SiloDialog = {}
local SiloDialog_mt = Class(SiloDialog, YesNoDialog)
function SiloDialog.register()
	local v2_ = SiloDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SiloDialog.xml", "SiloDialog", v2_)
	SiloDialog.INSTANCE = v2_
end

-- Local values: dialog
function SiloDialog.show(callback, target, title, fillLevels, hasInfiniteCapacity)
	if SiloDialog.INSTANCE ~= nil then
		local v8_ = SiloDialog.INSTANCE
		v8_:setCallback(callback, target)
		v8_:setTitle(title)
		v8_:setText(nil)
		v8_:setFillLevels(fillLevels, hasInfiniteCapacity)
		g_gui:showDialog("SiloDialog")
	end
end

-- Upvalues: SiloDialog_mt
-- Local values: self
function SiloDialog.new(target, custom_mt)
	-- upvalues: (copy) SiloDialog_mt
	local v11_ = YesNoDialog.new(target, custom_mt or SiloDialog_mt)
	v11_.selectedFillType = nil
	v11_.areButtonsDisabled = false
	v11_.lastSelectedFillType = nil
	return v11_
end

-- Local values: callback, target, title, fillLevels, hasInfiniteCapacity
function SiloDialog.createFromExistingGui(gui, guiName)
	SiloDialog.register()
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	local v15_ = gui.siloTitle
	local v16_ = gui.fillLevels
	local v17_ = gui.hasInfiniteCapacity
	SiloDialog.show(v13_, v14_, v15_, v16_, v17_)
end

function SiloDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	end
	self.lastSelectedFillType = self.selectedFillType
	self:sendCallback(self.selectedFillType)
	return false
end

function SiloDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(FillType.UNKNOWN)
	return false
end

-- Local values: siloAmount, width, fillType
function SiloDialog:onClickFillTypes(state)
	self:setButtonDisabled(false)
	self.selectedFillType = self.fillTypeMapping[state]
	if self.fillLevels ~= nil and self.fillLevels[self.selectedFillType] <= 0 then
		self:setButtonDisabled(true)
	end
	local v22_ = self.siloText:getTextWidth()
	local v23_ = self.siloText.absSize[1]
	local v24_ = math.min(v22_, v23_)
	self.siloIcon:setPosition(self.siloText.position[1] - v24_ * 0.5 - self.siloIcon.margin[3], nil)
	local v25_ = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
	self.siloIcon:setImageFilename(v25_.hudOverlayFilename)
end

function SiloDialog:setTitle(title)
	SiloDialog:superClass().setTitle(self, title)
	self.siloTitle = title
end

-- Local values: fillTypesTable, selectedId, numFillLevels, fillTypeIndex, _, fillType, level, name
function SiloDialog:setFillLevels(fillLevels, hasInfiniteCapacity)
	self.fillLevels = fillLevels
	self.fillTypeMapping = {}
	local v31_ = {}
	local v32_ = 1
	local v33_ = 1
	for v34_, _ in pairs(fillLevels) do
		local v35_ = g_fillTypeManager:getFillTypeByIndex(v34_)
		local v36_ = Utils.getNoNil(fillLevels[v34_], 0)
		local v37_
		if hasInfiniteCapacity then
			v37_ = string.format("%s", v35_.title)
		else
			v37_ = string.format("%s %s", v35_.title, g_i18n:formatFluid(v36_))
		end
		table.insert(v31_, v37_)
		local v38_ = self.fillTypeMapping
		table.insert(v38_, v34_)
		if v34_ == self.lastSelectedFillType then
			v33_ = v32_
		end
		v32_ = v32_ + 1
	end
	self.fillTypesElement:setTexts(v31_)
	self.fillTypesElement:setState(v33_, true)
end

function SiloDialog:setButtonDisabled(disabled)
	self.messageBackground:setVisible(disabled)
	self.areButtonsDisabled = disabled
	self.yesButton:setDisabled(disabled)
end
