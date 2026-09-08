-- Local values: AbstractManager_mt
AbstractManager = {}
local AbstractManager_mt = Class(AbstractManager)

-- Upvalues: AbstractManager_mt
-- Local values: self
function AbstractManager.new(customMt)
	-- upvalues: (copy) AbstractManager_mt
	if customMt ~= nil and type(customMt) ~= "table" then
		printCallstack()
	end
	local v3_ = customMt or AbstractManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_:initDataStructures()
	v4_.loadedMapData = false
	return v4_
end

function AbstractManager:initDataStructures() end

function AbstractManager:load()
	return true
end

function AbstractManager:loadMapData()
	if g_isDevelopmentVersion and self.loadedMapData then
		Logging.error("Manager map-data already loaded or not deleted after last game load!")
		printCallstack()
	end
	self.loadedMapData = true
	return true
end

function AbstractManager:unloadMapData()
	self.loadedMapData = false
	self:initDataStructures()
end
