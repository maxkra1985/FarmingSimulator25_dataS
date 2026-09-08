-- Local values: Windmill_mt
Windmill = {}
Windmill.RPM_TO_RADPMS = 0.00010471975511965977
local Windmill_mt = Class(Windmill)

function Windmill.onCreate(_, node)
	Windmill.new(node)
end

-- Upvalues: Windmill_mt
-- Local values: self, bladeIndexStr, bladeIndex, wobbleMaxDeg, windUpdater
function Windmill.new(node, customMt)
	-- upvalues: (copy) Windmill_mt
	local v4_ = Windmill_mt
	local v5_ = setmetatable({}, v4_)
	local v6_ = getUserAttribute(node, "bladeIndex")
	local v7_ = tonumber(v6_)
	if v7_ ~= nil and getNumOfChildren(node) - 1 >= v7_ then
		v5_.bladeNode = getChildAt(node, v7_)
		local v8_ = getUserAttribute
		v5_.minRequiredWindSpeed = tonumber(v8_(node, "minRequiredWindSpeed")) or 1
		local v9_ = getUserAttribute
		v5_.windSpeedRpmRatio = tonumber(v9_(node, "windSpeedRpmRatio")) or 0.3
		local v10_ = getUserAttribute
		v5_.maxRpm = tonumber(v10_(node, "maxRpm")) or 15
		local v11_ = getUserAttribute
		local v12_ = tonumber(v11_(node, "wobbleMaxDeg")) or 1
		v5_.wobbleMaxRad = math.rad(v12_)
		local v13_ = g_currentMission.environment.weather.windUpdater
		v13_:addWindChangedListener(v5_)
		v5_:setWindValues(v13_:getCurrentValues())
		g_currentMission:addUpdateable(v5_)
		return v5_
	end
	Logging.error("Invalid value \'%s\' for bladeIndex userAttribute for Windmill onCreate for %s", v6_, I3DUtil.getNodePath(node))
end

-- Local values: wobble, _, _, z
function Windmill:update(dt)
	if self.rotSpeed ~= 0 then
		local v16_ = self.wobbleAmount
		local v17_ = g_time / 500
		local v18_ = v16_ * math.sin(v17_)
		local _, _, v19_ = getRotation(self.bladeNode)
		setRotation(self.bladeNode, v18_, -v18_, (v19_ + self.rotSpeed * dt) % 6.283185307179586)
	end
end

-- Local values: rpm
function Windmill:setWindValues(currentDirX, currentDirZ, currentVelocityMps, currentCirrusSpeedFactor)
	if currentVelocityMps < self.minRequiredWindSpeed then
		self.rotSpeed = 0
	else
		local v22_ = currentVelocityMps * self.windSpeedRpmRatio
		local v23_ = -self.maxRpm
		local v24_ = self.maxRpm
		local v25_ = math.clamp(v22_, v23_, v24_)
		self.rotSpeed = Windmill.RPM_TO_RADPMS * v25_
		local v26_ = v25_ / self.maxRpm
		self.wobbleAmount = math.abs(v26_) * self.wobbleMaxRad
	end
end
