FieldCourseSettings = {}
FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS = 4
FieldCourseSettings.MAX_HEADLAND_AMOUNT = 2 ^ FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS - 1
FieldCourseSettings.SETTINGS = {}
local v1_ = FieldCourseSettings.SETTINGS
local v2_ = {
	["name"] = "implementWidth",
	["default"] = 10,
	["title"] = "Implement width",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = true,
	["min"] = 0.5,
	["max"] = 60
}
table.insert(v1_, v2_)
local v3_ = FieldCourseSettings.SETTINGS
local v4_ = {
	["name"] = "numHeadlands",
	["default"] = 2,
	["title"] = "Number of headlands",
	["xmlValueType"] = XMLValueType.INT,
	["customizable"] = true,
	["min"] = 1,
	["max"] = 10
}
table.insert(v3_, v4_)
local v5_ = FieldCourseSettings.SETTINGS
local v6_ = {
	["name"] = "headlandsFirst",
	["default"] = false,
	["title"] = "Headlands first",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = true
}
table.insert(v5_, v6_)
local v7_ = FieldCourseSettings.SETTINGS
local v8_ = {
	["name"] = "skipNumLines",
	["default"] = 0,
	["title"] = "Skip Num Lines",
	["xmlValueType"] = XMLValueType.INT,
	["customizable"] = true,
	["min"] = 0,
	["max"] = 10
}
table.insert(v7_, v8_)
local v9_ = FieldCourseSettings.SETTINGS
local v10_ = {
	["name"] = "workHeadlands",
	["default"] = true,
	["title"] = "Work headlands",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = true
}
table.insert(v9_, v10_)
local v11_ = FieldCourseSettings.SETTINGS
local v13_ = {
	["name"] = "workDirection",
	["default"] = -1,
	["title"] = "Work direction",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = true,
	["min"] = -1,
	["max"] = 3.141592653589793,
	["formatFunc"] = function(p12_)
		return p12_ > 0 and math.deg(p12_) or "Automatic"
	end
}
table.insert(v11_, v13_)
local v14_ = FieldCourseSettings.SETTINGS
local v15_ = {
	["name"] = "workInitialSegment",
	["default"] = false,
	["title"] = "Work initial segment",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v14_, v15_)
local v16_ = FieldCourseSettings.SETTINGS
local v17_ = {
	["name"] = "minTurnRadius",
	["default"] = 8,
	["title"] = "Minimum turn radius",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 1,
	["max"] = 20
}
table.insert(v16_, v17_)
local v18_ = FieldCourseSettings.SETTINGS
local v19_ = {
	["name"] = "initialTurnRadiusFactor",
	["default"] = 1,
	["title"] = "Initial turn radius factor",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 1,
	["max"] = 5
}
table.insert(v18_, v19_)
local v20_ = FieldCourseSettings.SETTINGS
local v21_ = {
	["name"] = "canTurnBackward",
	["default"] = true,
	["title"] = "Can turn backward",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v20_, v21_)
local v22_ = FieldCourseSettings.SETTINGS
local v23_ = {
	["name"] = "allowStraightReversing",
	["default"] = true,
	["title"] = "Allow straight reversing",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v22_, v23_)
local v24_ = FieldCourseSettings.SETTINGS
local v25_ = {
	["name"] = "isVineyardTool",
	["default"] = false,
	["title"] = "Is vineyard tool",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v24_, v25_)
local v26_ = FieldCourseSettings.SETTINGS
local v27_ = {
	["name"] = "isVineyardRowTool",
	["default"] = false,
	["title"] = "Is vineyard row tool",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v26_, v27_)
local v28_ = FieldCourseSettings.SETTINGS
local v29_ = {
	["name"] = "headlandTailAvoidance",
	["default"] = false,
	["title"] = "Headland tail avoidance",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v28_, v29_)
local v30_ = FieldCourseSettings.SETTINGS
local v31_ = {
	["name"] = "rowSpacing",
	["default"] = 0,
	["title"] = "Row Spacing",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false
}
table.insert(v30_, v31_)
local v32_ = FieldCourseSettings.SETTINGS
local v33_ = {
	["name"] = "rowSnapAngle",
	["default"] = 0,
	["title"] = "Row Snap Angle",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false
}
table.insert(v32_, v33_)
local v34_ = FieldCourseSettings.SETTINGS
local v35_ = {
	["name"] = "rowOffset",
	["default"] = 0,
	["title"] = "Row Offset",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false
}
table.insert(v34_, v35_)
local v36_ = FieldCourseSettings.SETTINGS
local v37_ = {
	["name"] = "cornerCutOutSupported",
	["default"] = false,
	["title"] = "Corner cut out supported",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v36_, v37_)
local v38_ = FieldCourseSettings.SETTINGS
local v39_ = {
	["name"] = "toolFrontOffset",
	["default"] = 0,
	["title"] = "Front offset of the tool",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -25,
	["max"] = 25
}
table.insert(v38_, v39_)
local v40_ = FieldCourseSettings.SETTINGS
local v41_ = {
	["name"] = "toolBackOffset",
	["default"] = 0,
	["title"] = "Back offset of the tool",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -25,
	["max"] = 25
}
table.insert(v40_, v41_)
local v42_ = FieldCourseSettings.SETTINGS
local v43_ = {
	["name"] = "hasStaticTools",
	["default"] = false,
	["title"] = "Has static tools",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v42_, v43_)
local v44_ = FieldCourseSettings.SETTINGS
local v45_ = {
	["name"] = "toolFullOverlap",
	["default"] = false,
	["title"] = "Tool full overlap",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v44_, v45_)
local v46_ = FieldCourseSettings.SETTINGS
local v47_ = {
	["name"] = "toolFullOverlapInside",
	["default"] = false,
	["title"] = "Tool full overlap inside",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v46_, v47_)
local v48_ = FieldCourseSettings.SETTINGS
local v49_ = {
	["name"] = "segmentExtendedToBoundary",
	["default"] = false,
	["title"] = "Segments Extended to Boundary",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v48_, v49_)
local v50_ = FieldCourseSettings.SETTINGS
local v51_ = {
	["name"] = "segmentHeadlandReverseLines",
	["default"] = false,
	["title"] = "Segments Headland Rev. Lines",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v50_, v51_)
local v52_ = FieldCourseSettings.SETTINGS
local v53_ = {
	["name"] = "segmentMinOffset",
	["default"] = 0,
	["title"] = "Segment Min. Offset",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false
}
table.insert(v52_, v53_)
local v54_ = FieldCourseSettings.SETTINGS
local v55_ = {
	["name"] = "segmentMinLength",
	["default"] = 0,
	["title"] = "Segment Min. Length",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false
}
table.insert(v54_, v55_)
local v56_ = FieldCourseSettings.SETTINGS
local v57_ = {
	["name"] = "sideOffset",
	["default"] = 0,
	["title"] = "Side offset",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -10,
	["max"] = 10
}
table.insert(v56_, v57_)
local v58_ = FieldCourseSettings.SETTINGS
local v59_ = {
	["name"] = "variableSideOffset",
	["default"] = false,
	["title"] = "Variable side offset",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v58_, v59_)
local v60_ = FieldCourseSettings.SETTINGS
local v61_ = {
	["name"] = "sideOffsetHeadlandAlternate",
	["default"] = false,
	["title"] = "Alternate headland side offset",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v60_, v61_)
local v62_ = FieldCourseSettings.SETTINGS
local v63_ = {
	["name"] = "headlandForcedDirection",
	["default"] = 0,
	["title"] = "Forced headland direction",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -1,
	["max"] = 1
}
table.insert(v62_, v63_)
local v64_ = FieldCourseSettings.SETTINGS
local v65_ = {
	["name"] = "segmentSplitAngle",
	["default"] = 25,
	["title"] = "Segment Split Angle",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 0,
	["max"] = 90
}
table.insert(v64_, v65_)
local v66_ = FieldCourseSettings.SETTINGS
local v67_ = {
	["name"] = "segmentSplitDistance",
	["default"] = 10,
	["title"] = "Segment Split Distance",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 0,
	["max"] = 1000
}
table.insert(v66_, v67_)
local v68_ = FieldCourseSettings.SETTINGS
local v69_ = {
	["name"] = "segmentValidityCheckOffset",
	["default"] = 0,
	["title"] = "Segment Validity Offset",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 0,
	["max"] = 1000
}
table.insert(v68_, v69_)
local v70_ = FieldCourseSettings.SETTINGS
local v71_ = {
	["name"] = "toolAlwaysActive",
	["default"] = false,
	["title"] = "Tool Always Active",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v70_, v71_)
local v72_ = FieldCourseSettings.SETTINGS
local v73_ = {
	["name"] = "toolStraighteningSegmentLength",
	["default"] = 2,
	["title"] = "Straightening Seg. Length",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 0.1,
	["max"] = 100
}
table.insert(v72_, v73_)
local v74_ = FieldCourseSettings.SETTINGS
local v75_ = {
	["name"] = "toolStraighteningAlwaysActive",
	["default"] = false,
	["title"] = "Straightening Always Active",
	["xmlValueType"] = XMLValueType.BOOL,
	["customizable"] = false
}
table.insert(v74_, v75_)
local v76_ = FieldCourseSettings.SETTINGS
local v77_ = {
	["name"] = "agentFrontOffset",
	["default"] = 4,
	["title"] = "Front offset of the agent",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -25,
	["max"] = 25
}
table.insert(v76_, v77_)
local v78_ = FieldCourseSettings.SETTINGS
local v79_ = {
	["name"] = "agentBackOffset",
	["default"] = 4,
	["title"] = "Back offset of the agent",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = -25,
	["max"] = 25
}
table.insert(v78_, v79_)
local v80_ = FieldCourseSettings.SETTINGS
local v81_ = {
	["name"] = "agentHeight",
	["default"] = 4,
	["title"] = "Height of the agent",
	["xmlValueType"] = XMLValueType.FLOAT,
	["customizable"] = false,
	["min"] = 0,
	["max"] = 25
}
table.insert(v80_, v81_)
function FieldCourseSettings.new()
	local v82_ = {}
	FieldCourseSettings.init(v82_)
	local v84_ = {
		["__index"] = FieldCourseSettings,
		["__newindex"] = function(_, p83_, _)
			if p83_ ~= "__CLASSNAME" then
				Logging.warning("Setting \'%s\' not defined in FieldCourseSettings", p83_)
			end
		end
	}
	setmetatable(v82_, v84_)
	return v82_
end

-- Local values: _, setting
function FieldCourseSettings:init()
	for _, v86_ in ipairs(FieldCourseSettings.SETTINGS) do
		self[v86_.name] = v86_.default
	end
end

function FieldCourseSettings:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.implementWidth)
	local v89_ = streamWriteUIntN
	local v90_ = self.numHeadlands
	local v91_ = FieldCourseSettings.MAX_HEADLAND_AMOUNT
	v89_(streamId, math.clamp(v90_, 0, v91_), FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS)
	streamWriteBool(streamId, self.headlandsFirst)
	streamWriteBool(streamId, self.workHeadlands)
	streamWriteFloat32(streamId, self.workDirection)
	local v92_ = streamWriteUIntN
	local v93_ = self.skipNumLines
	v92_(streamId, math.clamp(v93_, 0, 5), 3)
	streamWriteFloat32(streamId, self.sideOffset)
end

-- Local values: attributes
function FieldCourseSettings.readStream(streamId, connection)
	return {
		["implementWidth"] = streamReadFloat32(streamId),
		["numHeadlands"] = streamReadUIntN(streamId, FieldCourseSettings.NUM_HEADLANDS_SYNC_BITS),
		["headlandsFirst"] = streamReadBool(streamId),
		["workHeadlands"] = streamReadBool(streamId),
		["workDirection"] = streamReadFloat32(streamId),
		["skipNumLines"] = streamReadUIntN(streamId, 3),
		["sideOffset"] = streamReadFloat32(streamId)
	}
end

-- Local values: clone, _, setting
function FieldCourseSettings:clone()
	local v96_ = FieldCourseSettings.new()
	for _, v97_ in ipairs(FieldCourseSettings.SETTINGS) do
		v96_[v97_.name] = self[v97_.name]
	end
	return v96_
end

function FieldCourseSettings:isIdentical(otherSettings)
	local v100_ = self.implementWidth - otherSettings.implementWidth
	if math.abs(v100_) > 0.01 then
		return false
	end
	if self.numHeadlands ~= otherSettings.numHeadlands then
		return false
	end
	if self.headlandsFirst ~= otherSettings.headlandsFirst then
		return false
	end
	if self.workHeadlands ~= otherSettings.workHeadlands then
		return false
	end
	local v101_ = self.workDirection - otherSettings.workDirection
	if math.abs(v101_) > 0.01 then
		return false
	end
	if self.skipNumLines ~= otherSettings.skipNumLines then
		return false
	end
	local v102_ = self.sideOffset - otherSettings.sideOffset
	return math.abs(v102_) <= 0.01
end

-- Local values: name, value
function FieldCourseSettings:applyAttributes(attributes)
	for v105_, v106_ in pairs(attributes) do
		self[v105_] = v106_
	end
end

-- Local values: boundarySize
function FieldCourseSettings:getProtectedBoundarySize()
	local v108_ = (self.hasStaticTools and 0.45 or 0.25) * self.implementWidth
	if self.sideOffsetHeadlandAlternate then
		local v109_ = self.implementWidth * 0.5
		local v110_ = self.sideOffset
		local v111_ = v109_ - math.abs(v110_) - 0.25
		v108_ = math.min(v108_, v111_)
	end
	return v108_
end

-- Local values: _, setting
function FieldCourseSettings:saveToXML(xmlFile, key)
	for _, v115_ in ipairs(FieldCourseSettings.SETTINGS) do
		xmlFile:setValue(key .. "#" .. v115_.name, self[v115_.name])
	end
end

-- Local values: fieldCourseSettings, _, setting
function FieldCourseSettings.loadFromXML(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	local v118_ = FieldCourseSettings.new()
	for _, v119_ in ipairs(FieldCourseSettings.SETTINGS) do
		v118_[v119_.name] = xmlFile:getValue(key .. "#" .. v119_.name, v118_[v119_.name])
	end
	return v118_
end

-- Local values: numSettings, isLeft, y, i, setting, v
function FieldCourseSettings:draw()
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(0.5, 0.98, 0.015, "FieldCourse Settings")
	local v121_ = #FieldCourseSettings.SETTINGS
	local v122_ = true
	local v123_ = 1
	for v124_ = 1, v121_ do
		local v125_ = FieldCourseSettings.SETTINGS[v124_]
		if v122_ and v121_ * 0.5 < v124_ then
			v122_ = false
			v123_ = 1
		end
		local v126_ = self[v125_.name]
		local v127_
		if v125_.formatFunc == nil then
			if v125_.xmlValueType == XMLValueType.FLOAT then
				v127_ = string.format("%.3f", v126_)
			elseif v125_.xmlValueType == XMLValueType.INT then
				v127_ = string.format("%d", v126_)
			else
				v127_ = tostring(v126_)
			end
		else
			v127_ = v125_.formatFunc(v126_)
		end
		if v122_ then
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.35, 0.98 - v123_ * 0.016, 0.015, string.format("%s: %s", v125_.title, v127_))
		else
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.65, 0.98 - v123_ * 0.016, 0.015, string.format("%s: %s", v125_.title, v127_))
		end
		v123_ = v123_ + 1
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
end

-- Local values: tableStr, _, setting, v, _, setting, v, _, setting, v
function FieldCourseSettings:print(func, target)
	local v131_ = func or Logging.info
	local v132_ = "{"
	for _, v133_ in ipairs(FieldCourseSettings.SETTINGS) do
		local v134_ = self[v133_.name]
		if type(v134_) == "number" then
			v134_ = string.format("%.3f", v134_)
		end
		v132_ = v132_ .. string.format("%s=%s,", v133_.name, v134_)
	end
	local v135_ = v132_ .. "}"
	if target == nil then
		v131_("FieldCourse Settings:")
		for _, v136_ in ipairs(FieldCourseSettings.SETTINGS) do
			local v137_ = self[v136_.name]
			local v138_
			if v136_.formatFunc == nil then
				if v136_.xmlValueType == XMLValueType.FLOAT then
					v138_ = string.format("%.3f", v137_)
				elseif v136_.xmlValueType == XMLValueType.INT then
					v138_ = string.format("%d", v137_)
				else
					v138_ = tostring(v137_)
				end
			else
				v138_ = v136_.formatFunc(v137_)
			end
			v131_("  %s: %s", v136_.title, v138_)
		end
		v131_("  Setting: %s", v135_)
	else
		v131_(target, "FieldCourse Settings:")
		for _, v139_ in ipairs(FieldCourseSettings.SETTINGS) do
			local v140_ = self[v139_.name]
			local v141_
			if v139_.formatFunc == nil then
				if v139_.xmlValueType == XMLValueType.FLOAT then
					v141_ = string.format("%.3f", v140_)
				elseif v139_.xmlValueType == XMLValueType.INT then
					v141_ = string.format("%d", v140_)
				else
					v141_ = tostring(v140_)
				end
			else
				v141_ = v139_.formatFunc(v140_)
			end
			v131_(target, "  %s: %s", v139_.title, v141_)
		end
		v131_(target, "  Setting: %s", v135_)
	end
end

-- Local values: _, implementData
function FieldCourseSettings:reset(rootVehicle)
	local _, v144_ = FieldCourseSettings.generate(rootVehicle, self)
	return v144_
end

-- Local values: customData, _, setting, implementData, _, setting
function FieldCourseSettings:resetDynamicSettings(rootVehicle)
	local v147_ = {}
	for _, v148_ in ipairs(FieldCourseSettings.SETTINGS) do
		if v148_.customizable then
			v147_[v148_.name] = self[v148_.name]
		end
	end
	local v149_ = self:reset(rootVehicle)
	if #v149_ > 0 then
		for _, v150_ in ipairs(FieldCourseSettings.SETTINGS) do
			if v150_.customizable then
				self[v150_.name] = v147_[v150_.name]
			end
		end
	end
	return v149_
end

-- Local values: aiSteeringNode, implementData, attachedAIImplements, _, vehicle, implementWidth, toolFrontOffset, toolBackOffset, hasStaticTools, toolFullOverlap, toolFullOverlapInside, implementMinX, implementMaxX, sideOffset, variableSideOffset, _, agentLength, agentLengthOffset, _, agentHeight, _, maxInitialTurnRadiusFactor, aiImplementsIdenticalTypes, segmentValidityCheckOffset, rowSpacing, rowSnapAngle, rowOffset, i, implement, firstObject, aiMarkerLeft, aiMarkerRight, aiMarkerBack, _, aiMarkerWidth, aiMarkerValidityOffset, data, baseZOffset, _, attacherVehicle, jointDesc, offset, _, _, frontOffsetLeft, _, _, frontOffsetRight, _, _, backOffset, _, _, wheels, _, initialTurnRadiusFactor, implementSideOffset, implementVariableSideOffset, hasNoFullCoverageArea, _, doRowAlignment, _rowSpacing, _rowSnapAngle, _rowOffset, i, implement, attacherVehicle, otherImplementIndex, otherImplement, offset, canTurnBackward, minTurnRadius, aiMinTurningRadius, maxToolRadius, _, implement, allowStraightReversing, totalLength, numHeadlands, _, vehicle
function FieldCourseSettings.generate(rootVehicle, fieldCourseSettings)
	local v153_ = rootVehicle:getAISteeringNode()
	local v154_ = {}
	local v155_ = rootVehicle:getAttachedAIImplements()
	if #v155_ == 0 then
		if fieldCourseSettings == nil then
			fieldCourseSettings = FieldCourseSettings.new()
		else
			FieldCourseSettings.init(fieldCourseSettings)
		end
		for _, v156_ in ipairs(rootVehicle.childVehicles) do
			SpecializationUtil.raiseEvent(v156_, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
			SpecializationUtil.raiseEvent(v156_, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
		end
		return fieldCourseSettings, v154_
	end
	local _, v157_, v158_, _, v159_, _ = rootVehicle:getAIAgentSize()
	local v160_ = true
	local v161_ = math.huge
	local v162_ = false
	local v163_ = 0
	local v164_ = math.huge
	local v165_ = -math.huge
	local v166_ = -math.huge
	local v167_ = 0
	local v168_ = false
	local v169_ = 0
	local v170_ = 0
	local v171_ = 0
	local v172_ = v157_ or 0
	local v173_ = v158_ or 0
	local v174_ = false
	local v175_ = false
	local v176_ = v159_ or 0
	for v177_, v178_ in ipairs(v155_) do
		v178_.object:updateAIMarkerWidth()
		if v177_ > 1 then
			local v179_ = v155_[1].object
			v160_ = v160_ and v178_.object:compareFieldCropsQuery(v179_)
			if v160_ then
				v160_ = v179_:compareFieldCropsQuery(v178_.object)
			end
		end
		local v180_, v181_, v182_, _, v183_, v184_ = v178_.object:getAIMarkers()
		local v185_ = {
			["isLowered"] = false,
			["wasLowered"] = nil,
			["width"] = v183_,
			["frontOffset"] = 0,
			["backOffset"] = 0
		}
		if v184_ ~= nil then
			v167_ = math.max(v167_, v184_)
		end
		local v186_ = nil
		if v178_.object.getAttacherVehicle ~= nil then
			local v187_ = v178_.object:getAttacherVehicle()
			if v187_ ~= nil then
				local v188_ = v187_:getAttacherJointDescFromObject(v178_.object)
				local v189_, v190_
				v189_, v190_, v186_ = localToLocal(v188_.jointTransformOrig, v153_, 0, 0, 0)
			end
		end
		local v191_ = v186_ or 0
		local v192_ = v178_.object:getAIMarkerAttacherJointOffset(v180_)
		if v192_ ~= nil then
			v185_.frontOffset = v191_ + v192_.frontOffset * math.sign(v191_)
			v185_.backOffset = v191_ + v192_.backOffset * math.sign(v191_)
		end
		if rootVehicle == v178_.object then
			local _, _, v193_ = localToLocal(v180_, v153_, 0, 0, 0)
			local _, _, v194_ = localToLocal(v181_, v153_, 0, 0, 0)
			local _, _, v195_ = localToLocal(v182_, v153_, 0, 0, 0)
			v185_.frontOffset = (v193_ + v194_) * 0.5
			v185_.backOffset = v195_
		end
		v154_[v177_] = v185_
		local v196_ = v185_.frontOffset
		v166_ = math.max(v166_, v196_)
		local v197_ = v185_.backOffset
		v161_ = math.min(v161_, v197_)
		local _, _, v198_, _, v199_ = v178_.object:getAITurnRadiusLimitation()
		v162_ = v162_ or (v198_ == nil and true or #v198_ == 0)
		if v199_ ~= nil then
			v163_ = math.max(v163_, v199_)
		end
		local v200_, v201_ = v178_.object:getAIImplementSideOffset()
		local v202_ = -v185_.width * 0.5 + v200_
		v164_ = math.min(v202_, v164_)
		local v203_ = v185_.width * 0.5 + v200_
		v165_ = math.max(v203_, v165_)
		v175_ = v201_ and true or v175_
		local v204_, _ = v178_.object:getAIHasNoFullCoverageArea()
		if v204_ then
			v168_ = true
			v174_ = true
		end
		local v205_, v206_, v207_, v208_ = v178_.object:getAIRowAlignment()
		if v205_ then
			v171_ = v208_
			v170_ = v207_
			v169_ = v206_
		end
	end
	for v209_, v210_ in ipairs(v155_) do
		if v210_.object.getAttacherVehicle ~= nil then
			local v211_ = v210_.object:getAttacherVehicle()
			for v212_, v213_ in ipairs(v155_) do
				if v213_ ~= v210_ and v213_.object == v211_ then
					v154_[v209_].parentAIImplement = v154_[v212_]
				end
			end
		end
	end
	local v214_, v215_
	if v164_ == math.huge then
		v214_ = 0
		v215_ = 5
	else
		v215_ = v165_ - v164_
		v214_ = v164_ + v215_ * 0.5
	end
	local v216_ = v166_ - v161_ - 0.25
	local v217_ = math.min(0.5, v216_) * 0.5
	local v218_ = math.max(v217_, 0)
	local v219_ = v166_ - v218_
	local v220_ = v161_ + v218_
	if v220_ - v219_ == 0 then
		v220_ = v220_ - 0.25
	end
	local v221_ = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(rootVehicle)
	local v222_ = rootVehicle.maxTurningRadius * 1.1
	if g_server ~= nil then
		local v223_ = rootVehicle:getAIMinTurningRadius()
		if v223_ ~= nil then
			v222_ = math.max(v222_, v223_)
		end
		local v224_ = 0
		for _, v225_ in pairs(v155_) do
			local v226_ = AIVehicleUtil.getMaxToolRadius
			v224_ = math.max(v224_, v226_(v225_))
		end
		local v227_ = math.max(v222_, v224_)
		v222_ = math.max(v227_, 2.5)
	end
	local v228_ = v163_ == 0 and 1 or v163_
	local v229_ = AIVehicleUtil.getAIToolReverserDirectionNode(rootVehicle) ~= nil
	local v230_ = math.max(v172_, 0.1)
	local v231_ = v230_ + v173_
	local v232_ = math.max(v231_, v219_)
	if v220_ < 0 then
		v232_ = v232_ - v220_
	end
	local v233_ = v232_ / v215_
	local v234_ = math.ceil(v233_)
	if not v174_ then
		if v219_ > 0 then
			v174_ = v220_ < 0
		else
			v174_ = false
		end
	end
	if fieldCourseSettings == nil then
		fieldCourseSettings = FieldCourseSettings.new()
	else
		FieldCourseSettings.init(fieldCourseSettings)
	end
	fieldCourseSettings.implementWidth = v215_
	fieldCourseSettings.numHeadlands = v234_
	fieldCourseSettings.minTurnRadius = v222_
	fieldCourseSettings.initialTurnRadiusFactor = v228_
	fieldCourseSettings.canTurnBackward = v221_
	fieldCourseSettings.allowStraightReversing = v229_
	fieldCourseSettings.toolFrontOffset = v219_
	fieldCourseSettings.toolBackOffset = v220_
	fieldCourseSettings.hasStaticTools = v162_
	fieldCourseSettings.toolFullOverlap = v174_
	fieldCourseSettings.toolFullOverlapInside = v168_
	fieldCourseSettings.sideOffset = v214_
	fieldCourseSettings.variableSideOffset = v175_
	fieldCourseSettings.segmentValidityCheckOffset = v167_
	fieldCourseSettings.rowSpacing = v169_
	fieldCourseSettings.rowSnapAngle = v170_
	fieldCourseSettings.rowOffset = v171_
	fieldCourseSettings.agentFrontOffset = v230_ * 0.5 + v173_
	fieldCourseSettings.agentBackOffset = v230_ * 0.5 - v173_
	fieldCourseSettings.agentHeight = v176_
	fieldCourseSettings.segmentSplitAngle = 25
	if not fieldCourseSettings.hasStaticTools and fieldCourseSettings.toolFrontOffset < 0 then
		fieldCourseSettings.segmentSplitAngle = 45
	end
	if not v160_ then
		fieldCourseSettings.toolFullOverlap = true
		fieldCourseSettings.toolFullOverlapInside = true
		fieldCourseSettings.headlandsFirst = false
	end
	local v235_ = fieldCourseSettings.toolBackOffset
	fieldCourseSettings.toolStraighteningSegmentLength = math.abs(v235_) * 2
	for _, v236_ in ipairs(rootVehicle.childVehicles) do
		SpecializationUtil.raiseEvent(v236_, "onAIFieldCourseSettingsInitialized", fieldCourseSettings)
		SpecializationUtil.raiseEvent(v236_, "onPostAIFieldCourseSettingsInitialized", fieldCourseSettings)
	end
	return fieldCourseSettings, v154_
end

-- Local values: _, setting
function FieldCourseSettings.registerXMLPaths(schema, path)
	for _, v239_ in pairs(FieldCourseSettings.SETTINGS) do
		schema:register(v239_.xmlValueType, path .. "#" .. v239_.name, v239_.title)
	end
end
