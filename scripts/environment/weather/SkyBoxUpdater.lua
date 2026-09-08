-- Local values: SkyBoxUpdater_mt
SkyBoxUpdater = {}
SkyBoxUpdater.RAIN_FADE_IN = 7200000
local SkyBoxUpdater_mt = Class(SkyBoxUpdater)

-- Upvalues: SkyBoxUpdater_mt
-- Local values: self
function SkyBoxUpdater.new(customMt)
	-- upvalues: (copy) SkyBoxUpdater_mt
	local v3_ = customMt or SkyBoxUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.x = 1
	v4_.y = 0
	v4_.z = 0
	v4_.w = 0
	v4_.rainScale = 0
	v4_.loadRequestId = nil
	return v4_
end

-- Local values: i3dFilename
function SkyBoxUpdater:load(xmlFile, key)
	local v8_ = xmlFile:getString(key .. "#filename")
	if v8_ == nil then
		Logging.devWarning("Missing filename for skybox updater in \'%s\'", key)
		return false
	end
	self.loadRequestId = g_i3DManager:loadI3DFileAsync(v8_, false, false, SkyBoxUpdater.skyNodeLoaded, self, nil)
	self.skyCurve = AnimCurve.new(linearInterpolator4)
	self.skyCurve:loadCurveFromXML(xmlFile:getHandle(), key .. ".curve", loadInterpolator4Curve)
	return true
end

function SkyBoxUpdater:skyNodeLoaded(i3dNode, failedReason, args)
	if i3dNode ~= nil and i3dNode ~= 0 then
		self.skyNode = i3dNode
		link(getRootNode(), self.skyNode)
		self.skyId = getChildAt(self.skyNode, 0)
	end
	self.loadRequestId = nil
end

function SkyBoxUpdater:delete()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	if self.skyNode ~= nil then
		delete(self.skyNode)
	end
end

-- Local values: alpha, dayMinutes, x, y, z, w
function SkyBoxUpdater:update(dt, dayTime, rainScale, timeUntilRain)
	local v17_ = rainScale > 0 and 1 or 0
	if v17_ < self.rainScale then
		v17_ = v17_ + math.pow(0.999, dt) * (self.rainScale - v17_)
	end
	if timeUntilRain < SkyBoxUpdater.RAIN_FADE_IN then
		local v18_ = (1 - timeUntilRain / SkyBoxUpdater.RAIN_FADE_IN) ^ 0.5
		v17_ = math.min(v18_, 1)
	end
	local v19_ = dayTime / 60000
	local v20_, v21_, v22_, v23_ = self.skyCurve:get(v19_)
	self.dayScale = 1 - v22_
	self:setPartScale(v20_ * (1 - v17_), v21_ * (1 - v17_), v22_ * (1 - v17_), v23_ * (1 - v17_))
	self:setRainScale(v17_, self.dayScale)
end

function SkyBoxUpdater:setPartScale(x, y, z, w)
	if self.skyId ~= nil then
		setShaderParameter(self.skyId, "partScale", x, y, z, w)
	end
	self.x = x
	self.y = y
	self.z = z
	self.w = w
end

-- Local values: dayRainScale, nightRainScale
function SkyBoxUpdater:setRainScale(scale, dayScale)
	if self.skyId ~= nil then
		local v32_ = scale * dayScale
		local v33_ = scale * (1 - dayScale)
		setShaderParameter(self.skyId, "rainScale", v32_, v33_, 0, 0)
	end
	self.rainScale = scale
end

function SkyBoxUpdater:addDebugValues(data)
	table.insert(data, {
		["name"] = "SKYBOX",
		["value"] = ""
	})
	local v36_ = {
		["name"] = "partScale",
		["value"] = string.format("%.2f %.2f %.2f %.2f", self.x, self.y, self.z, self.w)
	}
	table.insert(data, v36_)
	local v37_ = {
		["name"] = "rainScale",
		["value"] = string.format("%.2f", self.rainScale)
	}
	table.insert(data, v37_)
	local v38_ = {
		["name"] = "dayScale",
		["value"] = string.format("%.2f", self.dayScale)
	}
	table.insert(data, v38_)
end
