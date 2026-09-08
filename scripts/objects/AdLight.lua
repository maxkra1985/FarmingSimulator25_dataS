-- Local values: AdLight_mt
AdLight = {}
local AdLight_mt = Class(AdLight)

-- Local values: light
function AdLight:onCreate(self)
	local v3_ = AdLight.new()
	if v3_:loadFromNode(self) then
		g_currentMission:addUpdateable(v3_)
	else
		v3_:delete()
	end
end

-- Upvalues: AdLight_mt
-- Local values: self
function AdLight.new(self)
	-- upvalues: (copy) AdLight_mt
	local v4_ = AdLight_mt
	return setmetatable({}, v4_)
end

-- Local values: startColorString, startColor, midColorString, midColor, endColorString, endColor
function AdLight:loadFromNode(self)
	self.node = node
	if not getHasClassId(node, ClassIds.LIGHT_SOURCE) then
		Logging.warning("Node is not a light source for \'%s\'", I3DUtil.getNodePath(self))
		return false
	end
	self.curve = AnimCurve.new(linearInterpolator3, 2)
	local v7_ = getUserAttribute(node, "startColor")
	local v8_ = string.getVector(v7_, 3)
	if v8_ == nil then
		Logging.warning("Invalid or missing \'startColor\' attribute value for \'%s\'", I3DUtil.getNodePath(self))
		return false
	end
	self.curve:addKeyframe({
		v8_[1],
		v8_[2],
		v8_[3],
		["time"] = 0
	})
	local v9_ = getUserAttribute(node, "midColor")
	local v10_ = string.getVector(v9_, 3)
	if v10_ == nil then
		Logging.warning("Invalid or missing \'midColor\' attribute value for \'%s\'", I3DUtil.getNodePath(self))
		return false
	end
	self.curve:addKeyframe({
		v10_[1],
		v10_[2],
		v10_[3],
		["time"] = 0.5
	})
	local v11_ = getUserAttribute(node, "endColor")
	local v12_ = string.getVector(v11_, 3)
	if v12_ == nil then
		Logging.warning("Invalid or missing \'endColor\' attribute value for \'%s\'", I3DUtil.getNodePath(self))
		return false
	end
	self.curve:addKeyframe({
		v12_[1],
		v12_[2],
		v12_[3],
		["time"] = 1
	})
	local v13_ = getUserAttribute
	self.duration = (tonumber(v13_(node, "durationSeconds")) or 1) * 1000
	self.time = 0
	return true
end

function AdLight:delete() end

-- Local values: value, r, g, b
function AdLight:update(dt)
	local v15_ = g_currentMission.time % self.duration / self.duration
	local v16_, v17_, v18_ = self.curve:get(v15_)
	setLightColor(self.self, v16_, v17_, v18_)
end
