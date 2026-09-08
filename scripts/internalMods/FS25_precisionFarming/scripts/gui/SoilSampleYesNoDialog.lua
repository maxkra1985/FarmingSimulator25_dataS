-- Local values: SoilSampleYesNoDialog_mt
SoilSampleYesNoDialog = {}
SoilSampleYesNoDialog.MOD_NAME = g_currentModName
SoilSampleYesNoDialog.MOD_DIR = g_currentModDirectory
local SoilSampleYesNoDialog_mt = Class(SoilSampleYesNoDialog, YesNoDialog)
function SoilSampleYesNoDialog.register()
	local v2_ = SoilSampleYesNoDialog.new()
	g_gui:loadGui(SoilSampleYesNoDialog.MOD_DIR .. "gui/SoilSampleYesNoDialog.xml", "SoilSampleYesNoDialog", v2_)
	SoilSampleYesNoDialog.INSTANCE = v2_
end

-- Upvalues: SoilSampleYesNoDialog_mt
-- Local values: self
function SoilSampleYesNoDialog.new(target, custom_mt)
	-- upvalues: (copy) SoilSampleYesNoDialog_mt
	local v5_ = SoilSampleYesNoDialog:superClass().new(target, custom_mt or SoilSampleYesNoDialog_mt)
	v5_.farmlandId = 0
	v5_.fieldSize = 0
	v5_.numSamples = 0
	v5_.sampleCosts = 0
	v5_.serviceCosts = 0
	return v5_
end

-- Local values: totalPrice
function SoilSampleYesNoDialog:setData(farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
	self.farmlandId = farmlandId
	self.fieldSize = fieldSize
	self.numSamples = numSamples
	self.sampleCosts = sampleCost
	self.serviceCosts = serviceCost
	self.numSamplesText:setValue(numSamples)
	self.sampleCostsText:setValue(sampleCost)
	self.serviceCostsText:setValue(serviceCost)
	local v12_ = sampleCost + serviceCost
	self.dialogTitleElement:setText(string.format(g_i18n:getText("ui_economicAnalysisHeaderField", SoilSampleYesNoDialog.MOD_NAME), farmlandId, fieldSize))
	self.dialogTextElement:setText(string.format(g_i18n:getText("ui_soilSampleDialogQuestion", SoilSampleYesNoDialog.MOD_NAME), g_i18n:formatMoney(v12_, 0, true, true)))
end

-- Local values: dialog
function SoilSampleYesNoDialog.show(callback, target, farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
	if SoilSampleYesNoDialog.INSTANCE ~= nil then
		local v20_ = SoilSampleYesNoDialog.INSTANCE
		v20_:setData(farmlandId, fieldSize, numSamples, sampleCost, serviceCost)
		v20_:setDialogType(DialogElement.TYPE_QUESTION)
		v20_:setCallback(callback, target, farmlandId)
		g_gui:showDialog("SoilSampleYesNoDialog")
	end
end

-- Local values: callback, target, farmlandId, fieldSize, numSamples, sampleCost, serviceCost
function SoilSampleYesNoDialog.createFromExistingGui(gui, guiName)
	SoilSampleYesNoDialog.register()
	local v22_ = gui.callbackFunc
	local v23_ = gui.target
	local v24_ = gui.farmlandId
	local v25_ = gui.fieldSize
	local v26_ = gui.numSamples
	local v27_ = gui.sampleCost
	local v28_ = gui.serviceCost
	SoilSampleYesNoDialog.show(v22_, v23_, v24_, v25_, v26_, v27_, v28_)
end
