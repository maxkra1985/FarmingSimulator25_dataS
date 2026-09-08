-- Local values: DepthOfFieldManager_mt
DepthOfFieldManager = {}
DepthOfFieldManager.DEFAULT_VALUES = {
	0.8,
	0.5,
	0.2,
	1000,
	1400,
	false
}
local DepthOfFieldManager_mt = Class(DepthOfFieldManager, AbstractManager)

-- Upvalues: DepthOfFieldManager_mt
-- Local values: self
function DepthOfFieldManager.new(customMt)
	-- upvalues: (copy) DepthOfFieldManager_mt
	local v3_ = AbstractManager.new(customMt or DepthOfFieldManager_mt)
	v3_.defaultState = table.clone(DepthOfFieldManager.DEFAULT_VALUES)
	v3_:reset()
	v3_.areaStack = {
		{
			-1,
			-1,
			-1,
			-1,
			false
		}
	}
	return v3_
end

function DepthOfFieldManager:delete()
	self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
	setDoFBlurArea(-1, -1, -1, -1)
end

function DepthOfFieldManager:reset()
	self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
end

function DepthOfFieldManager:setManipulatedParams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	local v13_ = nearCoCRadius or self.defaultState[1]
	local v14_ = nearBlurEnd or self.defaultState[2]
	local v15_ = farCoCRadius or self.defaultState[3]
	local v16_ = farBlurStart or self.defaultState[4]
	local v17_ = farBlurEnd or self.defaultState[5]
	local v18_ = Utils.getNoNil(applyToSky, self.defaultState[6])
	setDoFparams(v13_, v14_, v15_, v16_, v17_, v18_)
end

function DepthOfFieldManager:applyInfo(info)
	self:setManipulatedParams(info.nearCoCRadius, info.nearBlurEnd, info.farCoCRadius, info.farBlurStart, info.farBlurEnd, info.applyToSky)
end

function DepthOfFieldManager:createInfo(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	return {
		["nearCoCRadius"] = nearCoCRadius,
		["nearBlurEnd"] = nearBlurEnd,
		["farCoCRadius"] = farCoCRadius,
		["farBlurStart"] = farBlurStart,
		["farBlurEnd"] = farBlurEnd,
		["applyToSky"] = applyToSky
	}
end

function DepthOfFieldManager:pushArea(x, y, width, height)
	local v32_ = self.areaStack
	local v33_ = {
		x,
		y,
		x + width,
		y + height,
		true
	}
	table.insert(v32_, 1, v33_)
	self:updateArea()
end

function DepthOfFieldManager:popArea()
	if #self.areaStack > 1 then
		table.remove(self.areaStack, 1)
	elseif g_isDevelopmentVersion then
		Logging.devWarning("Try to pop last blur area")
		printCallstack()
	end
	self:updateArea()
end

-- Local values: x1, x2, y1, y2, isBlurred, _, item, x, y, xs, ys
function DepthOfFieldManager:updateArea()
	if #self.areaStack > 0 then
		local v36_ = 1
		local v37_ = 1
		local v38_ = 0
		local v39_ = 0
		local v40_ = false
		for _, v41_ in ipairs(self.areaStack) do
			if v41_[5] then
				local v42_, v43_, v44_, v45_ = unpack(v41_)
				v36_ = math.min(v36_, v42_)
				v37_ = math.min(v37_, v43_)
				v38_ = math.max(v38_, v44_)
				v39_ = math.max(v39_, v45_)
				v40_ = true
			end
		end
		if not v40_ then
			v36_ = -1
			v37_ = -1
			v38_ = -1
			v39_ = -1
		end
		setDoFBlurArea(v36_, v37_, v38_, v39_)
	end
end

function DepthOfFieldManager:consoleCommandFarParams(farCoC, farStart, farEnd)
	local v50_ = tonumber(farCoC)
	local v51_ = tonumber(farStart)
	local v52_ = tonumber(farEnd)
	self.defaultState[3] = v50_ or self.defaultState[3]
	self.defaultState[4] = v51_ or self.defaultState[4]
	self.defaultState[5] = v52_ or self.defaultState[5]
	self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
	Logging.info("Set far depth of field parameters: farCoC=%.2f, farStart=%d, farEnd=%d", self.defaultState[3], self.defaultState[4], self.defaultState[5])
end

function DepthOfFieldManager:consoleCommandNearParams(enabled, nearCoC, nearEnd)
	local v57_ = Utils.stringToBoolean(enabled)
	local v58_ = tonumber(nearCoC)
	local v59_ = tonumber(nearEnd)
	setDofQuality(v57_ and 2 or 1)
	self.defaultState[1] = v58_ or self.defaultState[1]
	self.defaultState[2] = v59_ or self.defaultState[2]
	self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
	Logging.info("Set near depth of field parameters: enabled=%s, nearCoC=%.2f, nearEnd=%.2f", tostring(v57_), self.defaultState[1], self.defaultState[2])
end
g_depthOfFieldManager = DepthOfFieldManager.new()
addConsoleCommand("gsDepthOfFieldSetFarParams", "Set far depth of field parameters", "consoleCommandFarParams", g_depthOfFieldManager, "farCoC; farStart; farEnd")
addConsoleCommand("gsDepthOfFieldSetNearParams", "Set far depth of field parameters", "consoleCommandNearParams", g_depthOfFieldManager, "enabled; nearCoC; nearEnd")
