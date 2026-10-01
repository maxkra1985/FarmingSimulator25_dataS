DebugDisplacementDialog = {}
local DebugDisplacementDialog_mt = Class(DebugDisplacementDialog, DialogElement)
function DebugDisplacementDialog.register()
	local debugDisplacementDialog = DebugDisplacementDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/debug/DebugDisplacementDialog.xml", "DebugDisplacementDialog", debugDisplacementDialog)
	DebugDisplacementDialog.INSTANCE = debugDisplacementDialog
end
function DebugDisplacementDialog.show()
	if DebugDisplacementDialog.INSTANCE ~= nil then
		if Platform.isPC then
			g_gui:showDialog("DebugDisplacementDialog")
			return
		end
		Logging.warning("DebugDisplacementDialog is a PC only feature")
	end
end
function DebugDisplacementDialog.new(target, custom_mt)
	local self = ColorPickerDialog.new(target, custom_mt or DebugDisplacementDialog_mt)
	self.needInput = false
	return self
end
function DebugDisplacementDialog.createFromExistingGui(gui, guiName)
	DebugDisplacementDialog.register()
	DebugDisplacementDialog.show()
end
function DebugDisplacementDialog:onOpen()
	DebugDisplacementDialog:superClass().onOpen(self)
	local terrainNode = g_terrainNode
	local numOverlayLayers = getTerrainNumOfOverlayLayers(terrainNode)
	self.overlayNames = {}
	self.overlayLayerNameMapping = {}
	for i = 0, numOverlayLayers - 1 do
		local name = getTerrainOverlayLayerName(terrainNode, i)
		local shortName = name
		for i = 1, 4 do
			local postFix = string.format("0%d", i)
			if string.endsWith(name, postFix) then
				shortName = string.gsub(name, postFix, "")
			end
		end
		if self.overlayLayerNameMapping[shortName] == nil then
			self.overlayLayerNameMapping[shortName] = {}
			table.insert(self.overlayNames, shortName)
		end
		table.insert(self.overlayLayerNameMapping[shortName], { name = name, index = i })
	end
	self.overlayLayers:setTexts(self.overlayNames)
	self.values = {}
	self.texts = {}
	local maxValue = 100
	for i = 0, 100 do
		local value = i / 100
		table.insert(self.texts, string.format("%.2f", value))
		table.insert(self.values, value)
	end
	self.firmness:setTexts(self.texts)
	self.firmnessWet:setTexts(self.texts)
	self.viscosity:setTexts(self.texts)
	self.currentValues = {}
	self:onClickOverlayLayer()
end
function DebugDisplacementDialog:onClickOverlayLayer()
	self:selectCurrentValue(self.firmness, "firmness")
	self:selectCurrentValue(self.firmnessWet, "firmnessWet")
	self:selectCurrentValue(self.viscosity, "viscosity")
	self:updateViscosityWet()
end
function DebugDisplacementDialog:selectCurrentValue(element, attributeName)
	local shortName = self.overlayNames[self.overlayLayers:getState()]
	local overlayLayers = self.overlayLayerNameMapping[shortName]
	local overlayLayerIndex = overlayLayers[1].index
	local value = getTerrainOverlayLayerXmlAttribute(g_terrainNode, overlayLayerIndex, attributeName)
	local index = 1
	if value ~= nil then
		for k, v in ipairs(self.values) do
			if value < v + 0.001 then
				index = k
				break
			end
		end
	end
	self.currentValues[attributeName] = value
	element:setState(index)
end
function DebugDisplacementDialog:applyValues()
	if g_localPlayer ~= nil then
		local x, _, z = g_localPlayer:getPosition()
		local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
		if farmland ~= nil then
			local field = farmland:getField()
			if field ~= nil then
				local polygon = field:getDensityMapPolygon()
				FSDensityMapUtil.resetDisplacement(polygon, nil, nil)
			end
		end
	end
	local shortName = self.overlayNames[self.overlayLayers:getState()]
	local overlayLayers = self.overlayLayerNameMapping[shortName]
	local terrainNode = g_terrainNode
	for _, overlayInfo in ipairs(overlayLayers) do
		local hasAttribute = false
		local text = ""
		for attributeName, value in pairs(self.currentValues) do
			if setTerrainOverlayLayerXmlAttribute(terrainNode, overlayInfo.index, attributeName, value) then
				text = text .. string.format(' %s="%.2f"', attributeName, value)
				hasAttribute = true
			end
		end
		if hasAttribute then
			text = string.format('<OverlayLayer name="%s"%s />', overlayInfo.name, text)
			log(text)
		end
	end
	finalizeTerrainFillLayers(terrainNode)
end
function DebugDisplacementDialog:onClickFirmness(state)
	local value = self.values[state]
	self.currentValues.firmness = value
	self:updateViscosityWet()
end
function DebugDisplacementDialog:onClickFirmnessWet(state)
	local value = self.values[state]
	self.currentValues.firmnessWet = value
	self:updateViscosityWet()
end
function DebugDisplacementDialog:onClickViscosity(state)
	local value = self.values[state]
	self.currentValues.viscosity = value
	self:updateViscosityWet()
end
function DebugDisplacementDialog:updateViscosityWet()
	local firmnessDry = self.currentValues.firmness
	local firmnessWet = self.currentValues.firmnessWet
	local viscosityDry = self.currentValues.viscosity
	local viscocityRatio = firmnessDry == 0 and 1 or math.min(firmnessWet / firmnessDry, 1)
	viscocityRatio = 0.5 - viscocityRatio * 0.5
	local viscosityWet = viscosityDry + viscocityRatio * (1 - viscosityDry)
	self.viscosityWet:setText(string.format("%.2f", viscosityWet))
end
function DebugDisplacementDialog:onClickOk()
	self:applyValues()
end
