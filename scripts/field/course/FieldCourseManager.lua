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
function FieldCourseManager.new(customMt)
	local self = AbstractManager.new(customMt or FieldCourseManager_mt)
	self.updateables = {}
	self.sortedUpdateables = {}
	self.pendingFieldCourseGenerators = {}
	return self
end
function FieldCourseManager:initDataStructures() end
function FieldCourseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.terrainDetailMapSize = g_currentMission.terrainDetailMapSize
	self.terrainDetailResolution = g_currentMission.terrainSize / self.terrainDetailMapSize
	self.terrainDetailMapNumBits = 1
	for i = 1, 16 do
		if 2 ^ i == self.terrainDetailMapSize then
			self.terrainDetailMapNumBits = i
		end
	end
	if g_fieldCourseTool == nil then
		self.fieldCourseVisual = FieldCourseVisual.new()
	end
end
function FieldCourseManager:unloadMapData()
	if self.fieldCourseVisual ~= nil then
		self.fieldCourseVisual:delete()
		self.fieldCourseVisual = nil
	end
	for k, updateable in pairs(self.updateables) do
		if updateable.delete ~= nil then
			updateable:delete()
		end
		table.removeElement(self.sortedUpdateables, updateable)
		self.updateables[k] = nil
	end
end
function FieldCourseManager:addFieldCourseToGenerate(fieldCourseSegmentGenerator)
	table.insert(self.pendingFieldCourseGenerators, fieldCourseSegmentGenerator)
end
function FieldCourseManager:addUpdateable(updateable, key)
	local oldUpdateable = self.updateables[key or updateable]
	if oldUpdateable ~= nil then
		table.removeElement(self.sortedUpdateables, oldUpdateable)
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
function FieldCourseManager:update(dt)
	for i = #self.sortedUpdateables, 1, -1 do
		if self.sortedUpdateables[i] == nil then
			continue
		end
		self.sortedUpdateables[i]:update(dt)
	end
	if 0 < #self.pendingFieldCourseGenerators then
		local fieldCourseSegmentGenerator = self.pendingFieldCourseGenerators[1]
		if fieldCourseSegmentGenerator ~= nil then
			fieldCourseSegmentGenerator:update(dt)
			if fieldCourseSegmentGenerator:getHasFinished() then
				table.remove(self.pendingFieldCourseGenerators, 1)
			end
		end
	end
end
function FieldCourseManager:generateFieldCourseAtWorldPos(wx, wz, fieldCourseSettings, callback, callbackTarget)
	FieldCourse.generateByFieldPosition(wx, wz, fieldCourseSettings, function(fieldCourse)
		if fieldCourse ~= nil then
			callback(callbackTarget, fieldCourse)
		else
			callback(callbackTarget)
		end
	end)
end
function FieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
	if self.fieldCourseVisual ~= nil then
		self.fieldCourseVisual:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
	end
end
function FieldCourseManager:roundToTerrainDetailPixel(wx, wz)
	local terrainDetailResolution = self.terrainDetailResolution
	wx = MathUtil.round((wx - terrainDetailResolution * 0.25) / terrainDetailResolution) * terrainDetailResolution + terrainDetailResolution * 0.5
	wz = MathUtil.round((wz - terrainDetailResolution * 0.25) / terrainDetailResolution) * terrainDetailResolution + terrainDetailResolution * 0.5
	return wx, wz
end
function FieldCourseManager:writeTerrainDetailPixel(streamId, x, z)
	streamWriteUIntN(streamId, (x - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
	streamWriteUIntN(streamId, (z - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
end
function FieldCourseManager:readTerrainDetailPixel(streamId)
	local x = (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5
	local z = (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5
	return x, z
end
g_fieldCourseManager = FieldCourseManager.new()
