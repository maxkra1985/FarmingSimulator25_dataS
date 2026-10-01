FieldCourseSettings = {}
FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS = 4
FieldCourseSettings.MAX_HEADLAND_AMOUNT = 2 ^ FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS - 1
FieldCourseSettings.SETTINGS = {}
table.insert(FieldCourseSettings.SETTINGS, { name = "implementWidth", default = 10, title = "Implement width", xmlValueType = XMLValueType.FLOAT, customizable = true, min = 0.5, max = 60 })
table.insert(FieldCourseSettings.SETTINGS, { name = "numHeadlands", default = 2, title = "Number of headlands", xmlValueType = XMLValueType.INT, customizable = true, min = 1, max = 10 })
table.insert(FieldCourseSettings.SETTINGS, { name = "headlandsFirst", default = false, title = "Headlands first", xmlValueType = XMLValueType.BOOL, customizable = true })
table.insert(FieldCourseSettings.SETTINGS, { name = "skipNumLines", default = 0, title = "Skip Num Lines", xmlValueType = XMLValueType.INT, customizable = true, min = 0, max = 10 })
table.insert(FieldCourseSettings.SETTINGS, { name = "workHeadlands", default = true, title = "Work headlands", xmlValueType = XMLValueType.BOOL, customizable = true })
table.insert(FieldCourseSettings.SETTINGS, {
	name = "workDirection",
	default = -1,
	title = "Work direction",
	xmlValueType = XMLValueType.FLOAT,
	customizable = true,
	min = -1,
	max = 3.141592653589793,
	formatFunc = function(v)
		return 0 < v and math.deg(v) or "Automatic"
	end,
})
table.insert(FieldCourseSettings.SETTINGS, { name = "workInitialSegment", default = false, title = "Work initial segment", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "minTurnRadius", default = 8, title = "Minimum turn radius", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 1, max = 20 })
table.insert(FieldCourseSettings.SETTINGS, { name = "initialTurnRadiusFactor", default = 1, title = "Initial turn radius factor", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 1, max = 5 })
table.insert(FieldCourseSettings.SETTINGS, { name = "canTurnBackward", default = true, title = "Can turn backward", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "allowStraightReversing", default = true, title = "Allow straight reversing", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "isVineyardTool", default = false, title = "Is vineyard tool", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "isVineyardRowTool", default = false, title = "Is vineyard row tool", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "headlandTailAvoidance", default = false, title = "Headland tail avoidance", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "rowSpacing", default = 0, title = "Row Spacing", xmlValueType = XMLValueType.FLOAT, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "rowSnapAngle", default = 0, title = "Row Snap Angle", xmlValueType = XMLValueType.FLOAT, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "rowOffset", default = 0, title = "Row Offset", xmlValueType = XMLValueType.FLOAT, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "cornerCutOutSupported", default = false, title = "Corner cut out supported", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolFrontOffset", default = 0, title = "Front offset of the tool", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -25, max = 25 })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolBackOffset", default = 0, title = "Back offset of the tool", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -25, max = 25 })
table.insert(FieldCourseSettings.SETTINGS, { name = "hasStaticTools", default = false, title = "Has static tools", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolFullOverlap", default = false, title = "Tool full overlap", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolFullOverlapInside", default = false, title = "Tool full overlap inside", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentExtendedToBoundary", default = false, title = "Segments Extended to Boundary", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentHeadlandReverseLines", default = false, title = "Segments Headland Rev. Lines", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentMinOffset", default = 0, title = "Segment Min. Offset", xmlValueType = XMLValueType.FLOAT, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentMinLength", default = 0, title = "Segment Min. Length", xmlValueType = XMLValueType.FLOAT, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "sideOffset", default = 0, title = "Side offset", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -10, max = 10 })
table.insert(FieldCourseSettings.SETTINGS, { name = "variableSideOffset", default = false, title = "Variable side offset", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "sideOffsetHeadlandAlternate", default = false, title = "Alternate headland side offset", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "headlandForcedDirection", default = 0, title = "Forced headland direction", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -1, max = 1 })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentSplitAngle", default = 25, title = "Segment Split Angle", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 0, max = 90 })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentSplitDistance", default = 10, title = "Segment Split Distance", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 0, max = 1000 })
table.insert(FieldCourseSettings.SETTINGS, { name = "segmentValidityCheckOffset", default = 0, title = "Segment Validity Offset", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 0, max = 1000 })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolAlwaysActive", default = false, title = "Tool Always Active", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolStraighteningSegmentLength", default = 2, title = "Straightening Seg. Length", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 0.1, max = 100 })
table.insert(FieldCourseSettings.SETTINGS, { name = "toolStraighteningAlwaysActive", default = false, title = "Straightening Always Active", xmlValueType = XMLValueType.BOOL, customizable = false })
table.insert(FieldCourseSettings.SETTINGS, { name = "agentFrontOffset", default = 4, title = "Front offset of the agent", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -25, max = 25 })
table.insert(FieldCourseSettings.SETTINGS, { name = "agentBackOffset", default = 4, title = "Back offset of the agent", xmlValueType = XMLValueType.FLOAT, customizable = false, min = -25, max = 25 })
table.insert(FieldCourseSettings.SETTINGS, { name = "agentHeight", default = 4, title = "Height of the agent", xmlValueType = XMLValueType.FLOAT, customizable = false, min = 0, max = 25 })
function FieldCourseSettings.new()
	local self = {}
	FieldCourseSettings.init(self)
	local mt = {}
	mt.__index = FieldCourseSettings
	function mt.__newindex(t, key, value)
		if key ~= "__CLASSNAME" then
			Logging.warning("Setting '%s' not defined in FieldCourseSettings", key)
		end
	end
	setmetatable(self, mt)
	return self
end
function FieldCourseSettings:init()
	for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
		self[setting.name] = setting.default
	end
end
function FieldCourseSettings:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.implementWidth)
	streamWriteUIntN(streamId, math.clamp(self.numHeadlands, 0, FieldCourseSettings.MAX_HEADLAND_AMOUNT), FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS)
	streamWriteBool(streamId, self.headlandsFirst)
	streamWriteBool(streamId, self.workHeadlands)
	streamWriteFloat32(streamId, self.workDirection)
	streamWriteUIntN(streamId, math.clamp(self.skipNumLines, 0, 5), 3)
	streamWriteFloat32(streamId, self.sideOffset)
end
function FieldCourseSettings.readStream(streamId, connection)
	local attributes = { ["implementWidth"] = streamReadFloat32(streamId), ["numHeadlands"] = streamReadUIntN(streamId, FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS), ["headlandsFirst"] = streamReadBool(streamId), ["workHeadlands"] = streamReadBool(streamId), ["workDirection"] = streamReadFloat32(streamId), ["skipNumLines"] = streamReadUIntN(streamId, 3), ["sideOffset"] = streamReadFloat32(streamId) }
	return attributes
end
function FieldCourseSettings:clone()
	local clone = FieldCourseSettings.new()
	for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
		clone[setting.name] = self[setting.name]
	end
	return clone
end
function FieldCourseSettings:isIdentical(otherSettings)
	if 0.01 < math.abs(self.implementWidth - otherSettings.implementWidth) then
		return false
	elseif self.numHeadlands ~= otherSettings.numHeadlands then
		return false
	elseif self.headlandsFirst ~= otherSettings.headlandsFirst then
		return false
	elseif self.workHeadlands ~= otherSettings.workHeadlands then
		return false
	elseif 0.01 < math.abs(self.workDirection - otherSettings.workDirection) then
		return false
	elseif self.skipNumLines ~= otherSettings.skipNumLines then
		return false
	elseif 0.01 < math.abs(self.sideOffset - otherSettings.sideOffset) then
		return false
	else
		return true
	end
end
function FieldCourseSettings:applyAttributes(attributes)
	for name, value in pairs(attributes) do
		self[name] = value
	end
end
function FieldCourseSettings:getProtectedBoundarySize()
	local boundarySize = (self.hasStaticTools and 0.45 or 0.25) * self.implementWidth
	if self.sideOffsetHeadlandAlternate then
		boundarySize = math.min(boundarySize, self.implementWidth * 0.5 - math.abs(self.sideOffset) - 0.25)
	end
	return boundarySize
end
function FieldCourseSettings:saveToXML(xmlFile, key)
	for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
		xmlFile:setValue(key .. "#" .. setting.name, self[setting.name])
	end
end
function FieldCourseSettings.loadFromXML(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return nil
	else
		local fieldCourseSettings = FieldCourseSettings.new()
		for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
			fieldCourseSettings[setting.name] = xmlFile:getValue(key .. "#" .. setting.name, fieldCourseSettings[setting.name])
		end
		return fieldCourseSettings
	end
end
function FieldCourseSettings:draw()
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(0.5, 0.98, 0.015, "FieldCourse Settings")
	local numSettings = #FieldCourseSettings.SETTINGS
	local isLeft = true
	local y = 1
	for i = 1, numSettings do
		local setting = FieldCourseSettings.SETTINGS[i]
		if isLeft and numSettings * 0.5 < i then
			isLeft = false
			y = 1
		end
		local v = self[setting.name]
		if setting.formatFunc ~= nil then
			v = setting.formatFunc(v)
		elseif setting.xmlValueType == XMLValueType.FLOAT then
			v = string.format("%.3f", v)
		elseif setting.xmlValueType == XMLValueType.INT then
			v = string.format("%d", v)
		else
			v = tostring(v)
		end
		if isLeft then
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.35, 0.98 - y * 0.016, 0.015, string.format("%s: %s", setting.title, v))
		else
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.65, 0.98 - y * 0.016, 0.015, string.format("%s: %s", setting.title, v))
		end
		y = y + 1
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
end
function FieldCourseSettings:print(func, target)
	func = func or Logging.info
	local tableStr = "{"
	for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
		local v = self[setting.name]
		if type(v) == "number" then
			v = string.format("%.3f", v)
		end
		tableStr = tableStr .. string.format("%s=%s,", setting.name, v)
	end
	tableStr = tableStr .. "}"
	if target ~= nil then
		func(target, "FieldCourse Settings:")
		for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
			local v = self[setting.name]
			if setting.formatFunc ~= nil then
				v = setting.formatFunc(v)
			elseif setting.xmlValueType == XMLValueType.FLOAT then
				v = string.format("%.3f", v)
			elseif setting.xmlValueType == XMLValueType.INT then
				v = string.format("%d", v)
			else
				v = tostring(v)
			end
			func(target, "  %s: %s", setting.title, v)
		end
		func(target, "  Setting: %s", tableStr)
	else
		func("FieldCourse Settings:")
		for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
			local v = self[setting.name]
			if setting.formatFunc ~= nil then
				v = setting.formatFunc(v)
			elseif setting.xmlValueType == XMLValueType.FLOAT then
				v = string.format("%.3f", v)
			elseif setting.xmlValueType == XMLValueType.INT then
				v = string.format("%d", v)
			else
				v = tostring(v)
			end
			func("  %s: %s", setting.title, v)
		end
		func("  Setting: %s", tableStr)
	end
end
function FieldCourseSettings:reset(rootVehicle)
	local _, implementData = FieldCourseSettings.generate(rootVehicle, self)
	return implementData
end
function FieldCourseSettings:resetDynamicSettings(rootVehicle)
	local customData = {}
	for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
		if setting.customizable then
			customData[setting.name] = self[setting.name]
		end
	end
	local implementData = self:reset(rootVehicle)
	if 0 < #implementData then
		for _, setting in ipairs(FieldCourseSettings.SETTINGS) do
			if setting.customizable then
				self[setting.name] = customData[setting.name]
			end
		end
	end
	return implementData
end
function FieldCourseSettings.generate(rootVehicle, fieldCourseSettings)
	local aiSteeringNode = rootVehicle:getAISteeringNode()
	local implementData = {}
	local attachedAIImplements = rootVehicle:getAttachedAIImplements()
	if #attachedAIImplements == 0 then
		if fieldCourseSettings == nil then
			fieldCourseSettings = FieldCourseSettings.new()
		else
			FieldCourseSettings.init(fieldCourseSettings)
		end
		for _, vehicle in ipairs(rootVehicle.childVehicles) do
			SpecializationUtil.raiseEvent(vehicle, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
			SpecializationUtil.raiseEvent(vehicle, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
		end
		return fieldCourseSettings, implementData
	else
		local implementWidth = 0
		local toolFrontOffset = -math.huge
		local toolBackOffset = math.huge
		local hasStaticTools = false
		local toolFullOverlap = false
		local toolFullOverlapInside = false
		local implementMinX = math.huge
		local implementMaxX = -math.huge
		local sideOffset = 0
		local variableSideOffset = false
		local _, agentLength, agentLengthOffset, _, agentHeight, _ = rootVehicle:getAIAgentSize()
		agentLength = agentLength or 0
		agentLengthOffset = agentLengthOffset or 0
		agentHeight = agentHeight or 0
		local maxInitialTurnRadiusFactor = 0
		local aiImplementsIdenticalTypes = true
		local segmentValidityCheckOffset = 0
		local rowSpacing = 0
		local rowSnapAngle = 0
		local rowOffset = 0
		for i, implement in ipairs(attachedAIImplements) do
			implement.object:updateAIMarkerWidth()
			if 1 < i then
				local firstObject = attachedAIImplements[1].object
				aiImplementsIdenticalTypes = aiImplementsIdenticalTypes and implement.object:compareFieldCropsQuery(firstObject) and firstObject:compareFieldCropsQuery(implement.object)
			end
			local aiMarkerLeft, aiMarkerRight, aiMarkerBack, _, aiMarkerWidth, aiMarkerValidityOffset = implement.object:getAIMarkers()
			local data = {}
			data.isLowered = false
			data.wasLowered = nil
			data.width = aiMarkerWidth
			data.frontOffset = 0
			data.backOffset = 0
			if aiMarkerValidityOffset ~= nil then
				segmentValidityCheckOffset = math.max(segmentValidityCheckOffset, aiMarkerValidityOffset)
			end
			local baseZOffset = nil
			local _ = nil
			if implement.object.getAttacherVehicle ~= nil then
				local attacherVehicle = implement.object:getAttacherVehicle()
				if attacherVehicle ~= nil then
					local jointDesc = attacherVehicle:getAttacherJointDescFromObject(implement.object)
					_, _, baseZOffset = localToLocal(jointDesc.jointTransformOrig, aiSteeringNode, 0, 0, 0)
				end
			end
			baseZOffset = baseZOffset or 0
			local offset = implement.object:getAIMarkerAttacherJointOffset(aiMarkerLeft)
			if offset ~= nil then
				data.frontOffset = baseZOffset + offset.frontOffset * math.sign(baseZOffset)
				data.backOffset = baseZOffset + offset.backOffset * math.sign(baseZOffset)
			end
			if rootVehicle == implement.object then
				local _, _, frontOffsetLeft = localToLocal(aiMarkerLeft, aiSteeringNode, 0, 0, 0)
				local _, _, frontOffsetRight = localToLocal(aiMarkerRight, aiSteeringNode, 0, 0, 0)
				local _, _, backOffset = localToLocal(aiMarkerBack, aiSteeringNode, 0, 0, 0)
				data.frontOffset = (frontOffsetLeft + frontOffsetRight) * 0.5
				data.backOffset = backOffset
			end
			implementData[i] = data
			toolFrontOffset = math.max(toolFrontOffset, data.frontOffset)
			toolBackOffset = math.min(toolBackOffset, data.backOffset)
			local _, _, wheels, _, initialTurnRadiusFactor = implement.object:getAITurnRadiusLimitation()
			hasStaticTools = hasStaticTools or wheels == nil or #wheels == 0
			if initialTurnRadiusFactor ~= nil then
				maxInitialTurnRadiusFactor = math.max(maxInitialTurnRadiusFactor, initialTurnRadiusFactor)
			end
			local implementSideOffset, implementVariableSideOffset = implement.object:getAIImplementSideOffset()
			implementMinX = math.min(-data.width * 0.5 + implementSideOffset, implementMinX)
			implementMaxX = math.max(data.width * 0.5 + implementSideOffset, implementMaxX)
			if implementVariableSideOffset then
				variableSideOffset = true
			end
			local hasNoFullCoverageArea, _ = implement.object:getAIHasNoFullCoverageArea()
			if hasNoFullCoverageArea then
				toolFullOverlapInside = true
				toolFullOverlap = true
			end
			local doRowAlignment, _rowSpacing, _rowSnapAngle, _rowOffset = implement.object:getAIRowAlignment()
			if doRowAlignment then
				rowSpacing = _rowSpacing
				rowSnapAngle = _rowSnapAngle
				rowOffset = _rowOffset
			end
		end
		for i, implement in ipairs(attachedAIImplements) do
			if implement.object.getAttacherVehicle == nil then
				continue
			end
			local attacherVehicle = implement.object:getAttacherVehicle()
			for otherImplementIndex, otherImplement in ipairs(attachedAIImplements) do
				if otherImplement == implement then
					continue
				end
				if otherImplement.object == attacherVehicle then
					implementData[i].parentAIImplement = implementData[otherImplementIndex]
				end
			end
		end
		if implementMinX ~= math.huge then
			implementWidth = implementMaxX - implementMinX
			sideOffset = implementMinX + implementWidth * 0.5
		else
			implementWidth = 5
			sideOffset = 0
		end
		local offset = math.max(math.min(0.5, toolFrontOffset - toolBackOffset - 0.25) * 0.5, 0)
		toolFrontOffset = toolFrontOffset - offset
		toolBackOffset = toolBackOffset + offset
		if toolBackOffset - toolFrontOffset == 0 then
			toolBackOffset = toolBackOffset - 0.25
		end
		local canTurnBackward = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(rootVehicle)
		local minTurnRadius = rootVehicle.maxTurningRadius * 1.1
		if g_server ~= nil then
			local aiMinTurningRadius = rootVehicle:getAIMinTurningRadius()
			if aiMinTurningRadius ~= nil then
				minTurnRadius = math.max(minTurnRadius, aiMinTurningRadius)
			end
			local maxToolRadius = 0
			for _, implement in pairs(attachedAIImplements) do
				maxToolRadius = math.max(maxToolRadius, AIVehicleUtil.getMaxToolRadius(implement))
			end
			minTurnRadius = math.max(minTurnRadius, maxToolRadius)
			minTurnRadius = math.max(minTurnRadius, 2.5)
		end
		if maxInitialTurnRadiusFactor == 0 then
			maxInitialTurnRadiusFactor = 1
		end
		local allowStraightReversing = AIVehicleUtil.getAIToolReverserDirectionNode(rootVehicle) ~= nil
		agentLength = math.max(agentLength, 0.1)
		local totalLength = math.max(agentLength + agentLengthOffset, toolFrontOffset)
		if toolBackOffset < 0 then
			totalLength = totalLength - toolBackOffset
		end
		local numHeadlands = math.ceil(totalLength / implementWidth)
		toolFullOverlap = toolFullOverlap or 0 >= toolFrontOffset or toolBackOffset < 0
		if fieldCourseSettings == nil then
			fieldCourseSettings = FieldCourseSettings.new()
		else
			FieldCourseSettings.init(fieldCourseSettings)
		end
		fieldCourseSettings.implementWidth = implementWidth
		fieldCourseSettings.numHeadlands = numHeadlands
		fieldCourseSettings.minTurnRadius = minTurnRadius
		fieldCourseSettings.initialTurnRadiusFactor = maxInitialTurnRadiusFactor
		fieldCourseSettings.canTurnBackward = canTurnBackward
		fieldCourseSettings.allowStraightReversing = allowStraightReversing
		fieldCourseSettings.toolFrontOffset = toolFrontOffset
		fieldCourseSettings.toolBackOffset = toolBackOffset
		fieldCourseSettings.hasStaticTools = hasStaticTools
		fieldCourseSettings.toolFullOverlap = toolFullOverlap
		fieldCourseSettings.toolFullOverlapInside = toolFullOverlapInside
		fieldCourseSettings.sideOffset = sideOffset
		fieldCourseSettings.variableSideOffset = variableSideOffset
		fieldCourseSettings.segmentValidityCheckOffset = segmentValidityCheckOffset
		fieldCourseSettings.rowSpacing = rowSpacing
		fieldCourseSettings.rowSnapAngle = rowSnapAngle
		fieldCourseSettings.rowOffset = rowOffset
		fieldCourseSettings.agentFrontOffset = agentLength * 0.5 + agentLengthOffset
		fieldCourseSettings.agentBackOffset = agentLength * 0.5 - agentLengthOffset
		fieldCourseSettings.agentHeight = agentHeight
		fieldCourseSettings.segmentSplitAngle = 25
		if not fieldCourseSettings.hasStaticTools and fieldCourseSettings.toolFrontOffset < 0 then
			fieldCourseSettings.segmentSplitAngle = 45
		end
		if not aiImplementsIdenticalTypes then
			fieldCourseSettings.toolFullOverlap = true
			fieldCourseSettings.toolFullOverlapInside = true
			fieldCourseSettings.headlandsFirst = false
		end
		fieldCourseSettings.toolStraighteningSegmentLength = math.abs(fieldCourseSettings.toolBackOffset) * 2
		for _, vehicle in ipairs(rootVehicle.childVehicles) do
			SpecializationUtil.raiseEvent(vehicle, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
			SpecializationUtil.raiseEvent(vehicle, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
		end
		return fieldCourseSettings, implementData
	end
end
function FieldCourseSettings.registerXMLPaths(schema, path)
	for _, setting in pairs(FieldCourseSettings.SETTINGS) do
		schema:register(setting.xmlValueType, path .. "#" .. setting.name, setting.title)
	end
end
