-- Local values: LifetimeStats_mt
LifetimeStats = {}
LifetimeStats.MS_TO_HOUR = 2.7777777777777776e-7
LifetimeStats.SAVE_PERIOD = 60000
local LifetimeStats_mt = Class(LifetimeStats)

-- Upvalues: LifetimeStats_mt
-- Local values: self
function LifetimeStats.new(customMt)
	-- upvalues: (copy) LifetimeStats_mt
	local v3_ = LifetimeStats_mt or customMt
	local v4_ = setmetatable({}, v3_)
	v4_.xmlFilename = Utils.getFilename("lifetimeStats.xml", getUserProfileAppPath())
	v4_.saveTimer = LifetimeStats.SAVE_PERIOD
	v4_.totalRuntimeUpToStart = 0
	v4_.gameRateMessagesShown = 0
	v4_.runtimeSinceLoad = 0
	return v4_
end

function LifetimeStats:delete() end

-- Local values: xmlFile
function LifetimeStats:load()
	if GS_PLATFORM_PHONE then
		if fileExists(self.xmlFilename) then
			local v6_ = loadXMLFile("lifetimeStats", self.xmlFilename)
			self.totalRuntimeUpToStart = Utils.getNoNil(getXMLFloat(v6_, "lifetimeStats.totalRuntime"), self.totalRuntimeUpToStart)
			self.gameRateMessagesShown = Utils.getNoNil(getXMLInt(v6_, "lifetimeStats.gameRateMessagesShown"), self.gameRateMessagesShown)
			self.runtimeSinceLoad = g_time
			delete(v6_)
		end
	end
end

-- Local values: xmlFile
function LifetimeStats:save()
	if GS_PLATFORM_ID == PlatformId.IOS or GS_PLATFORM_ID == PlatformId.ANDROID then
		local v8_ = createXMLFile("lifetimeStats", self.xmlFilename, "lifetimeStats")
		if v8_ == 0 then
			Logging.error("Failed to create lifetimeStats xml file")
		else
			setXMLFloat(v8_, "lifetimeStats.totalRuntime", self:getTotalRuntime())
			setXMLInt(v8_, "lifetimeStats.gameRateMessagesShown", self.gameRateMessagesShown)
			saveXMLFile(v8_)
			delete(v8_)
			self.saveTimer = LifetimeStats.SAVE_PERIOD
		end
	else
		return
	end
end

function LifetimeStats:reload()
	self.totalRuntimeUpToStart = 0
	self.gameRateMessagesShown = 0
	self:load()
end

function LifetimeStats:update(dt)
	self.saveTimer = self.saveTimer - dt
	if self.saveTimer < 0 then
		self.saveTimer = LifetimeStats.SAVE_PERIOD
		self:save()
	end
end

function LifetimeStats:getTotalRuntime()
	return g_time * LifetimeStats.MS_TO_HOUR + self.totalRuntimeUpToStart - self.runtimeSinceLoad
end
