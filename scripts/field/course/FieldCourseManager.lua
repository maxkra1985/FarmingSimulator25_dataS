-- Local values: FieldCourseManager_mt
FieldCourseManager = {}
source("dataS/scripts/field/course/FieldCourseUtil.lua")
source("dataS/scripts/field/course/FieldCourse.lua")
source("dataS/scripts/field/course/FieldCourseSegmentGenerator.lua")
source("dataS/scripts/field/course/FieldCourseBoundary.lua")
source("dataS/scripts/field/course/FieldCourseIterator.lua")
source("dataS/scripts/field/course/FieldCourseVisual.lua")
source("dataS/scripts/field/course/FieldCourseSettings.lua")
source("dataS/scripts/field/course/FieldCourseField.lua")
source("dataS/scripts/field/course/BoundaryDetectionTask.lua")
source("dataS/scripts/field/course/BoundaryDetectionTaskInsideOut.lua")
source("dataS/scripts/field/course/BoundaryLineGenerationTask.lua")
source("dataS/scripts/field/course/TrapezoidDecomposition.lua")
source("dataS/scripts/field/course/SteeringFieldCourse.lua")
source("dataS/scripts/field/course/enums/FieldCourseDetectionState.lua")
source("dataS/scripts/field/course/enums/FieldCourseGenerationState.lua")
source("dataS/scripts/field/course/ai/AIFieldCourse.lua")
local FieldCourseManager_mt = Class(FieldCourseManager, AbstractManager)

-- Upvalues: FieldCourseManager_mt
-- Local values: self
function FieldCourseManager.new(customMt)
	-- upvalues: (copy) FieldCourseManager_mt
	local v3_ = AbstractManager.new(customMt or FieldCourseManager_mt)
	v3_.updateables = {}
	v3_.sortedUpdateables = {}
	v3_.pendingFieldCourseGenerators = {}
	return v3_
end

function FieldCourseManager:initDataStructures() end

-- Local values: i
function FieldCourseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.terrainDetailMapSize = g_currentMission.terrainDetailMapSize
	self.terrainDetailResolution = g_currentMission.terrainSize / self.terrainDetailMapSize
	self.terrainDetailMapNumBits = 1
	for v5_ = 1, 16 do
		if 2 ^ v5_ == self.terrainDetailMapSize then
			self.terrainDetailMapNumBits = v5_
		end
	end
	if g_fieldCourseTool == nil then
		self.fieldCourseVisual = FieldCourseVisual.new()
	end
end

-- Local values: k, updateable
function FieldCourseManager:unloadMapData()
	if self.fieldCourseVisual ~= nil then
		self.fieldCourseVisual:delete()
		self.fieldCourseVisual = nil
	end
	for v7_, v8_ in pairs(self.updateables) do
		if v8_.delete ~= nil then
			v8_:delete()
		end
		table.removeElement(self.sortedUpdateables, v8_)
		self.updateables[v7_] = nil
	end
end

function FieldCourseManager:addFieldCourseToGenerate(fieldCourseSegmentGenerator)
	local v11_ = self.pendingFieldCourseGenerators
	table.insert(v11_, fieldCourseSegmentGenerator)
end

-- Local values: oldUpdateable
function FieldCourseManager:addUpdateable(updateable, key)
	local v15_ = self.updateables[key or updateable]
	if v15_ ~= nil then
		table.removeElement(self.sortedUpdateables, v15_)
	end
	self.updateables[key or updateable] = updateable
	table.addElement(self.sortedUpdateables, updateable)
end

function FieldCourseManager:removeUpdateable(updateableOrKey)
	if self.updateables[updateableOrKey] ~= nil then
		table.removeElement(self.sortedUpdateables, self.updateables[updateableOrKey])
	end
	self.updateables[updateableOrKey] = nil
end

-- Local values: i, fieldCourseSegmentGenerator
function FieldCourseManager:update(dt)
	for v20_ = #self.sortedUpdateables, 1, -1 do
		if self.sortedUpdateables[v20_] ~= nil then
			self.sortedUpdateables[v20_]:update(dt)
		end
	end
	if #self.pendingFieldCourseGenerators > 0 then
		local v21_ = self.pendingFieldCourseGenerators[1]
		if v21_ ~= nil then
			v21_:update(dt)
			if v21_:getHasFinished() then
				table.remove(self.pendingFieldCourseGenerators, 1)
			end
		end
	end
end

function FieldCourseManager:generateFieldCourseAtWorldPos(wx, wz, fieldCourseSettings, callback, callbackTarget)
	FieldCourse.generateByFieldPosition(wx, wz, fieldCourseSettings, function(p27_)
		-- upvalues: (copy) callback, (copy) callbackTarget
		if p27_ == nil then
			callback(callbackTarget)
		else
			callback(callbackTarget, p27_)
		end
	end)
end

function FieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
	if self.fieldCourseVisual ~= nil then
		self.fieldCourseVisual:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
	end
end

-- Local values: terrainDetailResolution
function FieldCourseManager:roundToTerrainDetailPixel(wx, wz)
	local v34_ = self.terrainDetailResolution
	return MathUtil.round((wx - v34_ * 0.25) / v34_) * v34_ + v34_ * 0.5, MathUtil.round((wz - v34_ * 0.25) / v34_) * v34_ + v34_ * 0.5
end

function FieldCourseManager:writeTerrainDetailPixel(streamId, x, z)
	streamWriteUIntN(streamId, (x - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
	streamWriteUIntN(streamId, (z - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
end

-- Local values: x, z
function FieldCourseManager:readTerrainDetailPixel(streamId)
	return (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5, (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5
end
g_fieldCourseManager = FieldCourseManager.new()
