-- Local values: FieldCourse_mt
FieldCourse = {}
local FieldCourse_mt = Class(FieldCourse)
FieldCourse.MIN_SEGMENT_LENGTH = 1

-- Upvalues: FieldCourse_mt
-- Local values: self
function FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
	-- upvalues: (copy) FieldCourse_mt
	local v5_ = FieldCourse_mt
	local v6_ = setmetatable({}, v5_)
	v6_.fieldCourseSettings = fieldCourseSettings
	v6_.courseField = courseField
	v6_.isVineyardCourse = isVineyardCourse
	v6_.isUICourse = false
	v6_.segments = {}
	v6_.totalLength = 0
	v6_.numHeadlands = 0
	return v6_
end

-- Local values: generator
function FieldCourse.generateByFieldPosition(x, z, fieldCourseSettings, callback)
	local v15_ = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(p11_, p12_, p13_)
		-- upvalues: (copy) fieldCourseSettings, (copy) callback
		if #p11_ > 0 then
			local v14_ = FieldCourse.new(fieldCourseSettings, p12_, p13_)
			v14_:addSegments(p11_)
			callback(v14_)
		else
			callback()
		end
	end)
	v15_:setStartPosition(x, z)
	v15_:generate()
end

-- Local values: generator
function FieldCourse.generateUICourseByFieldPosition(x, z, fieldCourseSettings, callback)
	local v24_ = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(p20_, p21_, p22_)
		-- upvalues: (copy) fieldCourseSettings, (copy) callback
		if #p20_ > 0 then
			local v23_ = FieldCourse.new(fieldCourseSettings, p21_, p22_)
			v23_:addSegments(p20_)
			v23_.isUICourse = true
			callback(v23_)
		else
			callback()
		end
	end)
	v24_:setStartPosition(x, z)
	v24_:setIsUICourse()
	v24_:generate()
end

-- Local values: generator
function FieldCourse:updateFieldCourseSettings(fieldCourseSettings, callback)
	local v30_ = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(p28_, _, p29_)
		-- upvalues: (copy) self, (copy) callback
		if #p28_ > 0 then
			self.segments = {}
			self:addSegments(p28_)
			self.isVineyardCourse = p29_
			callback(true)
		else
			callback(false)
		end
	end)
	self.courseField:reset()
	if self.isUICourse then
		v30_:setIsUICourse()
	end
	v30_:setFieldData(self.courseField)
	v30_:generate()
end

-- Local values: i, segment, segmentIndex, segment
function FieldCourse:addSegments(segments)
	for _, v33_ in ipairs(segments) do
		local v34_ = self.segments
		table.insert(v34_, v33_)
	end
	self.totalLength = 0
	self.numHeadlands = 0
	for v35_, v36_ in ipairs(self.segments) do
		v36_.index = v35_
		v36_.segmentId = v35_
		self.totalLength = self.totalLength + v36_.length
		local v37_ = v36_.headlandIndex or 0
		local v38_ = self.numHeadlands
		self.numHeadlands = math.max(v37_, v38_)
	end
end

function FieldCourse:writeStream(streamId, connection)
	self.fieldCourseSettings:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.courseField ~= nil) then
		self.courseField:writeStream(streamId, connection)
	end
end

-- Local values: fieldCourseSettings, attributes, courseField, generator
function FieldCourse.readStream(streamId, connection, callback)
	local v_u_45_ = FieldCourseSettings.new()
	v_u_45_:applyAttributes((FieldCourseSettings.readStream(streamId, connection)))
	local v_u_46_
	if streamReadBool(streamId) then
		v_u_46_ = FieldCourseField.new(v_u_45_)
		v_u_46_:readStream(streamId, connection)
	else
		v_u_46_ = nil
	end
	local v50_ = FieldCourseSegmentGenerator.new(v_u_45_, function(p47_, _, p48_)
		-- upvalues: (copy) v_u_45_, (ref) v_u_46_, (copy) callback
		if #p47_ > 0 then
			local v49_ = FieldCourse.new(v_u_45_, v_u_46_, p48_)
			v49_:addSegments(p47_)
			callback(v49_)
		else
			callback()
		end
	end)
	v50_:setFieldData(v_u_46_)
	v50_:generate()
end

function FieldCourse:saveToXML(xmlFile, key)
	if self.courseField ~= nil then
		self.courseField:saveToXML(xmlFile, key .. ".field")
	end
	if self.fieldCourseSettings ~= nil then
		self.fieldCourseSettings:saveToXML(xmlFile, key .. ".fieldCourseSettings")
	end
end

-- Local values: fieldCourseSettings, courseField, generator
function FieldCourse.loadFromXML(xmlFile, key, callback)
	local v_u_57_ = FieldCourseSettings.loadFromXML(xmlFile, key .. ".fieldCourseSettings")
	if v_u_57_ == nil then
		callback(nil)
		return false
	end
	local v_u_58_ = FieldCourseField.new(v_u_57_)
	if not v_u_58_:loadFromXML(xmlFile, key .. ".field") then
		callback(nil)
		return false
	end
	local v62_ = FieldCourseSegmentGenerator.new(v_u_57_, function(p59_, _, p60_)
		-- upvalues: (copy) v_u_57_, (copy) v_u_58_, (copy) callback
		if #p59_ > 0 then
			local v61_ = FieldCourse.new(v_u_57_, v_u_58_, p60_)
			v61_:addSegments(p59_)
			callback(v61_)
		else
			callback()
		end
	end)
	v62_:setFieldData(v_u_58_)
	v62_:generate()
	return true
end

-- Local values: _, segment, r, g, b, numPositions, i, x1, z1, x2, z2, y1, y2
function FieldCourse:draw()
	if self.courseField ~= nil then
		self.courseField:draw()
	end
	for _, v64_ in pairs(self.segments) do
		local v65_ = 0
		local v66_ = 1
		local v67_ = 1
		if v64_.isIslandSegment then
			v67_ = 0.5
			v65_ = 0
			v66_ = 0.5
		elseif v64_.isHeadlandSegment then
			v67_ = 0.2
			v65_ = 0
			v66_ = 0.2
		end
		local v68_ = #v64_.positions
		for v69_ = 1, v68_ - 1 do
			local v70_ = v64_.positions[v69_][1]
			local v71_ = v64_.positions[v69_][2]
			local v72_ = v64_.positions[v69_ + 1][1]
			local v73_ = v64_.positions[v69_ + 1][2]
			local v74_ = getTerrainHeightAtWorldPos(g_terrainNode, v70_, 0, v71_) + (v64_.yOffset or 0.5)
			local v75_ = getTerrainHeightAtWorldPos(g_terrainNode, v72_, 0, v73_) + (v64_.yOffset or 0.5)
			drawDebugLine(v70_, v74_, v71_, v65_, v66_, v67_, v72_, v75_, v73_, v65_, v66_, v67_, true)
			drawDebugPoint(v70_, v74_, v71_, v65_, v66_, v67_, 1, true)
			if v69_ + 1 == v68_ then
				drawDebugPoint(v72_, v75_, v73_, v65_, v66_, v67_, 1, true)
			end
		end
	end
end

function FieldCourse.registerXMLPaths(schema, path)
	FieldCourseSettings.registerXMLPaths(schema, path .. ".fieldCourseSettings")
	FieldCourseField.registerXMLPaths(schema, path .. ".field")
end

-- Local values: rootNode, _, step, i, isOnField, _, offsetIsOnField, _, hasAccess
function FieldCourse.findClosestField(x, z, dirX, dirZ, farmId, vehicle, intoFieldOffset, fieldCourseSettings)
	if x == nil or (z == nil or (dirX == nil or dirZ == nil)) then
		local v86_ = vehicle:getAISteeringNode()
		local v87_
		x, v87_, z = getWorldTranslation(v86_)
		local v88_
		dirX, v88_, dirZ = localDirectionToWorld(v86_, 0, 0, vehicle:getReverserDirection())
	end
	if fieldCourseSettings ~= nil then
		x = x - dirZ * fieldCourseSettings.sideOffset
		z = z + dirX * fieldCourseSettings.sideOffset
	end
	local v89_ = intoFieldOffset or 2
	for _ = 1, 6 do
		local v90_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, 0, z)
		if v90_ then
			local v91_ = x + dirX * v89_
			local v92_ = z + dirZ * v89_
			local v93_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(v91_, 0, v92_)
			if v93_ then
				if g_currentMission.accessHandler:canFarmAccessLand(farmId, v91_, v92_) or g_missionManager:getIsMissionWorkAllowed(farmId, v91_, v92_, nil, vehicle) then
					return v91_, v92_, false
				else
					return nil, nil, true
				end
			end
			break
		end
		x = x + dirX * 5
		z = z + dirZ * 5
	end
	return nil, nil, false
end
