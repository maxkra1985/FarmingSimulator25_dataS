-- Local values: DebugDisplacementDialog_mt
DebugDisplacementDialog = {}
local DebugDisplacementDialog_mt = Class(DebugDisplacementDialog, DialogElement)
function DebugDisplacementDialog.register()
	local v2_ = DebugDisplacementDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/debug/DebugDisplacementDialog.xml", "DebugDisplacementDialog", v2_)
	DebugDisplacementDialog.INSTANCE = v2_
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

-- Upvalues: DebugDisplacementDialog_mt
-- Local values: self
function DebugDisplacementDialog.new(target, custom_mt)
	-- upvalues: (copy) DebugDisplacementDialog_mt
	local v5_ = ColorPickerDialog.new(target, custom_mt or DebugDisplacementDialog_mt)
	v5_.needInput = false
	return v5_
end

function DebugDisplacementDialog.createFromExistingGui(gui, guiName)
	DebugDisplacementDialog.register()
	DebugDisplacementDialog.show()
end

-- Local values: terrainNode, numOverlayLayers, i, name, shortName, i, postFix, maxValue, i, value
function DebugDisplacementDialog:onOpen()
	DebugDisplacementDialog:superClass().onOpen(self)
	local v7_ = g_terrainNode
	local v8_ = getTerrainNumOfOverlayLayers(v7_)
	self.overlayNames = {}
	self.overlayLayerNameMapping = {}
	for v9_ = 0, v8_ - 1 do
		local v10_ = getTerrainOverlayLayerName(v7_, v9_)
		local v11_ = v10_
		for v12_ = 1, 4 do
			local v13_ = string.format("0%d", v12_)
			if string.endsWith(v10_, v13_) then
				v11_ = string.gsub(v10_, v13_, "")
			end
		end
		if self.overlayLayerNameMapping[v11_] == nil then
			self.overlayLayerNameMapping[v11_] = {}
			local v14_ = self.overlayNames
			table.insert(v14_, v11_)
		end
		local v15_ = self.overlayLayerNameMapping[v11_]
		table.insert(v15_, {
			["name"] = v10_,
			["index"] = v9_
		})
	end
	self.overlayLayers:setTexts(self.overlayNames)
	self.values = {}
	self.texts = {}
	for v16_ = 0, 100 do
		local v17_ = v16_ / 100
		local v18_ = self.texts
		local v19_ = string.format
		table.insert(v18_, v19_("%.2f", v17_))
		local v20_ = self.values
		table.insert(v20_, v17_)
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

-- Local values: shortName, overlayLayers, overlayLayerIndex, value, index, k, v
function DebugDisplacementDialog:selectCurrentValue(element, attributeName)
	local v25_ = self.overlayNames[self.overlayLayers:getState()]
	local v26_ = self.overlayLayerNameMapping[v25_][1].index
	local v27_ = getTerrainOverlayLayerXmlAttribute(g_terrainNode, v26_, attributeName)
	local v28_ = 1
	if v27_ ~= nil then
		for v29_, v30_ in ipairs(self.values) do
			if v27_ < v30_ + 0.001 then
				v28_ = v29_
				break
			end
		end
	end
	self.currentValues[attributeName] = v27_
	element:setState(v28_)
end

-- Local values: x, _, z, farmland, field, polygon, shortName, overlayLayers, terrainNode, _, overlayInfo, hasAttribute, text, attributeName, value
function DebugDisplacementDialog:applyValues()
	if g_localPlayer ~= nil then
		local v32_, _, v33_ = g_localPlayer:getPosition()
		local v34_ = g_farmlandManager:getFarmlandAtWorldPosition(v32_, v33_)
		if v34_ ~= nil then
			local v35_ = v34_:getField()
			if v35_ ~= nil then
				local v36_ = v35_:getDensityMapPolygon()
				FSDensityMapUtil.resetDisplacement(v36_, nil, nil)
			end
		end
	end
	local v37_ = self.overlayNames[self.overlayLayers:getState()]
	local v38_ = self.overlayLayerNameMapping[v37_]
	local v39_ = g_terrainNode
	for _, v40_ in ipairs(v38_) do
		local v41_ = ""
		local v42_ = false
		for v43_, v44_ in pairs(self.currentValues) do
			if setTerrainOverlayLayerXmlAttribute(v39_, v40_.index, v43_, v44_) then
				v41_ = v41_ .. string.format(" %s=\"%.2f\"", v43_, v44_)
				v42_ = true
			end
		end
		if v42_ then
			local v45_ = string.format("<OverlayLayer name=\"%s\"%s />", v40_.name, v41_)
			log(v45_)
		end
	end
	finalizeTerrainFillLayers(v39_)
end

-- Local values: value
function DebugDisplacementDialog:onClickFirmness(state)
	local v48_ = self.values[state]
	self.currentValues.firmness = v48_
	self:updateViscosityWet()
end

-- Local values: value
function DebugDisplacementDialog:onClickFirmnessWet(state)
	local v51_ = self.values[state]
	self.currentValues.firmnessWet = v51_
	self:updateViscosityWet()
end

-- Local values: value
function DebugDisplacementDialog:onClickViscosity(state)
	local v54_ = self.values[state]
	self.currentValues.viscosity = v54_
	self:updateViscosityWet()
end

-- Local values: firmnessDry, firmnessWet, viscosityDry, viscocityRatio, viscosityWet
function DebugDisplacementDialog:updateViscosityWet()
	local v56_ = self.currentValues.firmness
	local v57_ = self.currentValues.firmnessWet
	local v58_ = self.currentValues.viscosity
	local v59_
	if v56_ == 0 then
		v59_ = 1
	else
		local v60_ = v57_ / v56_
		v59_ = math.min(v60_, 1)
	end
	local v61_ = v58_ + (0.5 - v59_ * 0.5) * (1 - v58_)
	self.viscosityWet:setText(string.format("%.2f", v61_))
end

function DebugDisplacementDialog:onClickOk()
	self:applyValues()
end
