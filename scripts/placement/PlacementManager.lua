-- Local values: PlacementManager_mt
PlacementManager = {}
PlacementManager.TEST_STEP_SIZE = 1
PlacementManager.ASYNC_NUM_OVERLAPS_PER_TICK = 4
local PlacementManager_mt = Class(PlacementManager)

-- Upvalues: PlacementManager_mt
-- Local values: self
function PlacementManager.new(customMt)
	-- upvalues: (copy) PlacementManager_mt
	local v3_ = customMt or PlacementManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.getPlaceQueue = {}
	return v4_
end

function PlacementManager:delete()
	g_currentMission:removeUpdateable(self)
end

-- Local values: task
function PlacementManager:getPlaceAsync(places, reqSpace, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
	local v15_ = FindPlaceTask.new(places, reqSpace, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
	local v16_ = self.getPlaceQueue
	table.insert(v16_, v15_)
	g_currentMission:addUpdateable(self)
end

-- Local values: findPlaceTask, _, isFinished
function PlacementManager:update()
	if #self.getPlaceQueue > 0 then
		local v18_ = self.getPlaceQueue[1]
		for _ = 1, PlacementManager.ASYNC_NUM_OVERLAPS_PER_TICK do
			self.spaceIsFree = false
			if v18_:runStep() then
				table.remove(self.getPlaceQueue, 1)
				return
			end
		end
	else
		g_currentMission:removeUpdateable(self)
	end
end

function PlacementManager:consoleCommandTogglePlacementDebug()
	PlacementManager.debugEnabled = not PlacementManager.debugEnabled
	if not PlacementManager.debugEnabled then
		g_debugManager:removeGroup("PlacementManager")
	end
	local v19_ = PlacementManager.debugEnabled
	return "PlacementManager debug = " .. tostring(v19_)
end
