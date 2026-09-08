-- Local values: Tween_mt
Tween = {}
local Tween_mt = Class(Tween)

-- Upvalues: Tween_mt
-- Local values: self
function Tween.new(setterFunction, startValue, endValue, duration, customMt)
	-- upvalues: (copy) Tween_mt
	local v7_ = customMt or Tween_mt
	local v8_ = setmetatable({}, v7_)
	v8_.setter = setterFunction
	v8_.startValue = startValue
	v8_.endValue = endValue
	v8_.duration = duration
	v8_.elapsedTime = 0
	v8_.isFinished = duration == 0
	v8_.functionTarget = nil
	v8_.curveFunc = Tween.CURVE.LINEAR
	return v8_
end

function Tween:getDuration()
	return self.duration
end

function Tween:getFinished()
	return self.isFinished
end

function Tween:reset()
	self.elapsedTime = 0
	self.isFinished = self.duration == 0
end

function Tween:setTarget(target)
	self.functionTarget = target
end

-- Local values: newValue, t
function Tween:update(dt)
	if not self.isFinished then
		self.elapsedTime = self.elapsedTime + dt
		local v16_
		if self.elapsedTime >= self.duration then
			self.isFinished = true
			v16_ = self:tweenValue(1)
		else
			v16_ = self:tweenValue(self.elapsedTime / self.duration)
		end
		self:applyValue(v16_)
	end
end

function Tween:tweenValue(t)
	return MathUtil.lerp(self.startValue, self.endValue, self.curveFunc(t))
end

function Tween:applyValue(newValue)
	if self.functionTarget == nil then
		self.setter(newValue)
	else
		self.setter(self.functionTarget, newValue)
	end
end

function Tween:setCurve(func)
	self.curveFunc = func or Tween.CURVE.LINEAR
end
Tween.CURVE = {}
function Tween.CURVE.LINEAR(p23_)
	return p23_
end
function Tween.CURVE.EASE_IN(p24_)
	return p24_ * p24_ * p24_
end
function Tween.CURVE.EASE_OUT(p25_)
	local v26_ = p25_ - 1
	return v26_ * v26_ * v26_ + 1
end
function Tween.CURVE.EASE_IN_OUT(p27_)
	if p27_ < 0.5 then
		return 0.5 * Tween.CURVE.EASE_IN(p27_ * 2)
	else
		return 0.5 * Tween.CURVE.EASE_OUT((p27_ - 0.5) * 2) + 0.5
	end
end
function Tween.CURVE.EASE_OUT_IN(p28_)
	if p28_ < 0.5 then
		return 0.5 * Tween.CURVE.EASE_OUT(p28_ * 2)
	else
		return 0.5 * Tween.CURVE.EASE_IN((p28_ - 0.5) * 2) + 0.5
	end
end
function Tween.CURVE.EASE_IN_BACK(p29_)
	return math.pow(p29_, 2) * (2.70158 * p29_ - 1.70158)
end
function Tween.CURVE.EASE_OUT_BACK(p30_)
	local v31_ = p30_ - 1
	return math.pow(v31_, 2) * (2.70158 * v31_ + 1.70158) + 1
end
function Tween.CURVE.EASE_IN_OUT_BACK(p32_)
	if p32_ < 0.5 then
		return 0.5 * Tween.CURVE.EASE_IN_BACK(p32_ * 2)
	else
		return 0.5 * Tween.CURVE.EASE_OUT_BACK((p32_ - 0.5) * 2) + 0.5
	end
end
function Tween.CURVE.EASE_OUT_IN_BACK(p33_)
	if p33_ < 0.5 then
		return 0.5 * Tween.CURVE.EASE_OUT_BACK(p33_ * 2)
	else
		return 0.5 * Tween.CURVE.EASE_IN_BACK((p33_ - 0.5) * 2) + 0.5
	end
end
