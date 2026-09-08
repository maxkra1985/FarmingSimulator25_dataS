-- Local values: ValueInterpolator_mt
ValueInterpolator = {}
local ValueInterpolator_mt = Class(ValueInterpolator)

-- Upvalues: ValueInterpolator_mt
-- Local values: self, i, isValid, i
function ValueInterpolator.new(customKey, get, set, target, duration, speed, customMt)
	-- upvalues: (copy) ValueInterpolator_mt
	local v9_ = customMt or ValueInterpolator_mt
	local v10_ = setmetatable({}, v9_)
	v10_.customKey = customKey
	v10_.get = get
	v10_.set = set
	v10_.target = target
	v10_.duration = duration
	v10_.cur = { get() }
	if v10_.duration == nil then
		local v11_ = (speed or 1) / 1000
		v10_.speed = {}
		for v12_ = 1, #v10_.target do
			v10_.speed[v12_] = v11_
		end
	else
		v10_:updateSpeed()
	end
	local v13_ = false
	for v14_ = 1, #v10_.speed do
		local v15_ = v10_.speed[v14_]
		if math.abs(v15_) > 1e-9 then
			v13_ = true
			break
		end
	end
	if not v13_ then
		return nil
	end
	g_currentMission:addUpdateable(v10_, customKey)
	return v10_
end
function ValueInterpolator.setUpdateFunc(p16_, p17_, p18_, ...)
	p16_.updateFunc = p17_
	p16_.updateTarget = p18_
	p16_.updateArgs = { ... }
end
function ValueInterpolator.setFinishedFunc(p19_, p20_, p21_, ...)
	p19_.finishedFunc = p20_
	p19_.finishedTarget = p21_
	p19_.finishedArgs = { ... }
end

function ValueInterpolator:setDeleteListenerObject(object)
	if object ~= nil and object:isa(Object) then
		object:addDeleteListener(self, "onDeleteParent")
		self.deleteListenerObject = object
	end
end

function ValueInterpolator:delete() end

function ValueInterpolator:getTarget()
	return self.target
end

-- Local values: i
function ValueInterpolator:updateSpeed()
	local v26_ = self.duration
	if type(v26_) == "number" then
		self.speed = {}
		for v27_ = 1, #self.target do
			local v28_ = self.speed
			local v29_ = self.target[v27_] - self.cur[v27_]
			v28_[v27_] = math.abs(v29_) / self.duration
		end
	else
		self.speed = self.duration
	end
end

-- Local values: finished, i, direction, limitFunc
function ValueInterpolator:update(dt)
	local v32_ = true
	for v33_ = 1, #self.cur do
		local v34_ = self.target[v33_] - self.cur[v33_]
		local v35_ = math.sign(v34_)
		local v36_ = math.min
		if v35_ < 0 then
			v36_ = math.max
		end
		self.cur[v33_] = v36_(self.cur[v33_] + self.speed[v33_] * dt * v35_, self.target[v33_])
		if v32_ then
			v32_ = self.cur[v33_] == self.target[v33_]
		end
	end
	local v37_ = self.set
	local v38_ = self.cur
	v37_(unpack(v38_))
	if self.updateFunc ~= nil then
		local v39_ = self.updateFunc
		local v40_ = self.updateTarget
		local v41_ = self.updateArgs
		v39_(v40_, unpack(v41_))
	end
	if self.duration ~= nil then
		local v42_ = self.duration - dt
		self.duration = math.max(v42_, 1)
	end
	if v32_ then
		g_currentMission:removeUpdateable(self.customKey)
		if self.deleteListenerObject ~= nil then
			self.deleteListenerObject:removeDeleteListener("onDeleteParent")
		end
		if self.finishedFunc ~= nil then
			local v43_ = self.finishedFunc
			local v44_ = self.finishedTarget
			local v45_ = self.finishedArgs
			v43_(v44_, unpack(v45_))
		end
	end
end

function ValueInterpolator.removeInterpolator(key)
	if g_currentMission:getHasUpdateable(key) then
		g_currentMission:removeUpdateable(key)
	end
end

function ValueInterpolator.hasInterpolator(key)
	return g_currentMission:getHasUpdateable(key)
end

function ValueInterpolator:onDeleteParent()
	g_currentMission:removeUpdateable(self.customKey)
end
