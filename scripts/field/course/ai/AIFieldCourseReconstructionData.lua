-- Local values: AIFieldCourseReconstructionData_mt
AIFieldCourseReconstructionData = {}
local AIFieldCourseReconstructionData_mt = Class(AIFieldCourseReconstructionData)
function AIFieldCourseReconstructionData.new()
	-- upvalues: (copy) AIFieldCourseReconstructionData_mt
	local v2_ = AIFieldCourseReconstructionData_mt
	local v3_ = setmetatable({}, v2_)
	v3_.lastVehicleX = 0
	v3_.lastVehicleZ = 0
	v3_.fieldCourseField = nil
	v3_.fieldCourseSettings = nil
	v3_.activeSegmentId = nil
	v3_.fieldCourseSegments = {}
	return v3_
end

-- Local values: activeSegment, usedSegments, excludedSegments, segmentsToSkip, getIsUsed, _, segment, segmentData, allSegmentsWorked, _, otherSegment
function AIFieldCourseReconstructionData:setDataByAIFieldCourse(aiFieldCourse)
	local v6_ = aiFieldCourse.lastVehicleX
	local v7_ = aiFieldCourse.lastVehicleZ
	self.lastVehicleX = v6_
	self.lastVehicleZ = v7_
	self.fieldCourseField = aiFieldCourse.fieldCourse.courseField
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	local v8_ = aiFieldCourse:getActiveSegment()
	if v8_ ~= nil then
		self.activeSegmentId = v8_.segmentId
	end
	local v_u_9_ = aiFieldCourse.usedSegments
	local v_u_10_ = aiFieldCourse.segmentOrderTask.excludedSegments
	local v_u_11_ = aiFieldCourse.segmentOrderTask.segmentsToSkip
	local function v14_(p12_)
		-- upvalues: (copy) self, (copy) v_u_10_, (copy) v_u_11_, (copy) v_u_9_
		if p12_.segmentId == self.activeSegmentId then
			return false
		end
		for v13_, _ in pairs(v_u_10_) do
			if v13_.segmentId == p12_.segmentId then
				return true
			end
		end
		return v_u_11_[p12_.segmentId] ~= nil and true or v_u_9_[p12_.segmentId] ~= nil
	end
	for _, v15_ in pairs(aiFieldCourse.fieldCourse.segments) do
		local v16_ = {
			["segmentId"] = v15_.segmentId,
			["lineGroupIndex"] = v15_.lineGroupIndex,
			["isHeadlandSegment"] = v15_.isHeadlandSegment,
			["headlandIndex"] = v15_.headlandIndex,
			["isIslandSegment"] = v15_.isIslandSegment,
			["islandIndex"] = v15_.islandIndex
		}
		local v17_ = true
		for _, v18_ in pairs(aiFieldCourse.fieldCourse.segments) do
			if v18_.segmentId == v15_.segmentId and not v14_(v18_) then
				v17_ = false
				break
			end
		end
		v16_.used = v17_
		local v19_ = self.fieldCourseSegments
		table.insert(v19_, v16_)
	end
end

-- Local values: xmlIndex, _, segmentData, segmentKey
function AIFieldCourseReconstructionData:saveToXML(xmlFile, key)
	xmlFile:setValue(key .. "#lastPosition", self.lastVehicleX, self.lastVehicleZ)
	if self.fieldCourseField ~= nil then
		self.fieldCourseField:saveToXML(xmlFile, key .. ".field")
	end
	if self.fieldCourseSettings ~= nil then
		self.fieldCourseSettings:saveToXML(xmlFile, key .. ".fieldCourseSettings")
	end
	if self.activeSegmentId ~= nil then
		xmlFile:setValue(key .. "#activeSegmentId", self.activeSegmentId)
	end
	local v23_ = 0
	for _, v24_ in pairs(self.fieldCourseSegments) do
		local v25_ = string.format("%s.segments.segment(%d)", key, v23_)
		xmlFile:setValue(v25_ .. "#segmentId", v24_.segmentId)
		xmlFile:setValue(v25_ .. "#used", v24_.used)
		if v24_.lineGroupIndex ~= nil then
			xmlFile:setValue(v25_ .. "#lineGroupIndex", v24_.lineGroupIndex)
		end
		if v24_.isHeadlandSegment then
			xmlFile:setValue(v25_ .. "#isHeadlandSegment", v24_.isHeadlandSegment)
			xmlFile:setValue(v25_ .. "#headlandIndex", v24_.headlandIndex)
		end
		if v24_.isIslandSegment then
			xmlFile:setValue(v25_ .. "#isIslandSegment", v24_.isIslandSegment)
			xmlFile:setValue(v25_ .. "#islandIndex", v24_.islandIndex)
		end
		v23_ = v23_ + 1
	end
end

-- Local values: _, segmentKey, segmentData
function AIFieldCourseReconstructionData:loadFromXML(xmlFile, key)
	local v29_, v30_ = xmlFile:getValue(key .. "#lastPosition", "0 0")
	self.lastVehicleX = v29_
	self.lastVehicleZ = v30_
	self.fieldCourseSettings = FieldCourseSettings.loadFromXML(xmlFile, key .. ".fieldCourseSettings")
	if self.fieldCourseSettings == nil then
		Logging.warning("Failed to load FieldCourseSettings from xml")
		return false
	end
	self.fieldCourseField = FieldCourseField.new(self.fieldCourseSettings)
	if not self.fieldCourseField:loadFromXML(xmlFile, key .. ".field") then
		Logging.warning("Failed to load FieldCourseField from xml")
		return false
	end
	self.activeSegmentId = xmlFile:getValue(key .. "#activeSegmentId")
	self.fieldCourseSegments = {}
	for _, v31_ in xmlFile:iterator(key .. ".segments.segment") do
		local v32_ = {
			["segmentId"] = xmlFile:getValue(v31_ .. "#segmentId")
		}
		if v32_.segmentId ~= nil then
			v32_.used = xmlFile:getValue(v31_ .. "#used", false)
			v32_.lineGroupIndex = xmlFile:getValue(v31_ .. "#lineGroupIndex")
			v32_.isHeadlandSegment = xmlFile:getValue(v31_ .. "#isHeadlandSegment", false)
			v32_.headlandIndex = xmlFile:getValue(v31_ .. "#headlandIndex")
			v32_.isIslandSegment = xmlFile:getValue(v31_ .. "#isIslandSegment", false)
			v32_.islandIndex = xmlFile:getValue(v31_ .. "#islandIndex")
			local v33_ = self.fieldCourseSegments
			table.insert(v33_, v32_)
		end
	end
	self:generateFieldCourse()
	return true
end

-- Local values: generator
function AIFieldCourseReconstructionData:generateFieldCourse()
	if self.fieldCourse == nil and not self.fieldCourseInProgress then
		local v37_ = FieldCourseSegmentGenerator.new(self.fieldCourseSettings, function(p35_, _, p36_)
			-- upvalues: (copy) self
			if #p35_ > 0 then
				self.fieldCourse = FieldCourse.new(self.fieldCourseSettings, self.fieldCourseField, p36_)
				self.fieldCourse:addSegments(p35_)
				self.fieldCourseInProgress = false
			else
				Logging.devWarning("Unable to generate field course based on savegame data")
			end
			if self.callback ~= nil then
				self:doCallback()
			end
		end)
		self.fieldCourseField.headlandBoundaries = {}
		v37_:setFieldData(self.fieldCourseField)
		self.fieldCourseInProgress = true
		v37_:generate()
	end
end

-- Local values: distance
function AIFieldCourseReconstructionData:apply(callbackTarget, callback, vx, vz)
	if self.lastVehicleX == nil or self.lastVehicleZ == nil then
		Logging.devInfo("AIFieldCourseReconstructionData: No last vehicle position available. Completely regenerate field course.")
		return false
	end
	if MathUtil.vector2Length(vx - self.lastVehicleX, vz - self.lastVehicleZ) > 25 then
		Logging.devInfo("AIFieldCourseReconstructionData: Vehicle has moved too far. Completely regenerate field course.")
		return false
	end
	if not FieldCourseUtil.getIsPointInsideBoundary(vx, vz, self.fieldCourseField.boundaryPositions) then
		Logging.devInfo("AIFieldCourseReconstructionData: Vehicle is not inside the field anymore. Completely regenerate field course.")
		return false
	end
	self.callbackTarget = callbackTarget
	self.callback = callback
	self:generateFieldCourse()
	if self.fieldCourse ~= nil then
		self:doCallback()
	end
	return true
end

-- Local values: aiFieldCourse, numSkippedSegments, segmentsToSkip, isValid, _, segment, _, segmentData
function AIFieldCourseReconstructionData:doCallback()
	if self.callback ~= nil then
		local v44_ = AIFieldCourse.new(self.fieldCourse)
		local v45_ = {}
		local v46_ = 0
		local v47_ = true
		for _, v48_ in pairs(self.fieldCourse.segments) do
			for _, v49_ in pairs(self.fieldCourseSegments) do
				if v48_.segmentId == v49_.segmentId then
					if v49_.lineGroupIndex ~= v48_.lineGroupIndex then
						v47_ = false
					end
					if v49_.isHeadlandSegment ~= v48_.isHeadlandSegment then
						v47_ = false
					end
					if v49_.headlandIndex ~= v48_.headlandIndex then
						v47_ = false
					end
					if v49_.isIslandSegment ~= v48_.isIslandSegment then
						v47_ = false
					end
					if v49_.islandIndex ~= v48_.islandIndex then
						v47_ = false
					end
					if v49_.used then
						v45_[v48_.segmentId] = true
						v46_ = v46_ + 1
					end
					break
				end
			end
		end
		if v47_ then
			Logging.devInfo("AIFieldCourseReconstructionData: Reconstructed field course from savegame. Skipping %d already worked segments.", v46_)
		else
			Logging.devInfo("AIFieldCourseReconstructionData: Loaded field course from savegame does not match the generated one. Dismiss worked data.")
			v45_ = nil
		end
		if v45_ ~= nil then
			v44_:setSegmentsToSkip(v45_)
		end
		if self.activeSegmentId ~= nil then
			v44_:setLastActiveSegmentId(self.activeSegmentId)
		end
		self.callback(self.callbackTarget, v44_)
		self.callbackTarget = nil
		self.callback = nil
	end
end

function AIFieldCourseReconstructionData.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#lastPosition", "Last vehicle position in world space")
	FieldCourseSettings.registerXMLPaths(schema, basePath .. ".fieldCourseSettings")
	FieldCourseField.registerXMLPaths(schema, basePath .. ".field")
	schema:register(XMLValueType.INT, basePath .. "#activeSegmentId", "Identifier of the currently active segment")
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#segmentId", "Identifier of the segment")
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#used", "Segment has been worked already")
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#lineGroupIndex", "Line group index")
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#isHeadlandSegment", "Is headland segment")
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#headlandIndex", "Headland index")
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#isIslandSegment", "Is island segment")
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#islandIndex", "Island index")
end
