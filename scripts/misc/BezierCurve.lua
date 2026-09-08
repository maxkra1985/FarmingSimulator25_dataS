-- Local values: BezierCurve_mt
BezierCurve = {}
local BezierCurve_mt = Class(BezierCurve)

-- Upvalues: BezierCurve_mt
-- Local values: self
function BezierCurve.new(positionX1, positionY1, positionX2, positionY2)
	-- upvalues: (copy) BezierCurve_mt
	local v6_ = BezierCurve_mt
	local v7_ = setmetatable({}, v6_)
	v7_.positionX1 = math.clamp(positionX1, 0, 1)
	v7_.positionY1 = positionY1
	v7_.positionX2 = math.clamp(positionX2, 0, 1)
	v7_.positionY2 = positionY2
	v7_.cx = 0
	v7_.bx = 0
	v7_.ax = 0
	v7_.cy = 0
	v7_.by = 0
	v7_.ay = 0
	v7_:recalculateCoefficients()
	return v7_
end

function BezierCurve:recalculateCoefficients()
	self.cx = 3 * self.positionX1
	self.bx = 3 * (self.positionX2 - self.positionX1) - self.cx
	self.ax = 1 - self.cx - self.bx
	self.cy = 3 * self.positionY1
	self.by = 3 * (self.positionY2 - self.positionY1) - self.cy
	self.ay = 1 - self.cy - self.by
end

function BezierCurve:setPositionX1(newValue)
	self.positionX1 = math.clamp(newValue, 0, 1)
	self:recalculateCoefficients()
end

function BezierCurve:setPositionY1(newValue)
	self.positionY1 = math.clamp(newValue, 0, 1)
	self:recalculateCoefficients()
end

function BezierCurve:setPositionX2(newValue)
	self.positionX2 = math.clamp(newValue, 0, 1)
	self:recalculateCoefficients()
end

function BezierCurve:setPositionY2(newValue)
	self.positionY2 = math.clamp(newValue, 0, 1)
	self:recalculateCoefficients()
end

function BezierCurve:sampleX(t)
	return ((self.ax * t + self.bx) * t + self.cx) * t
end

function BezierCurve:sampleY(t)
	return ((self.ay * t + self.by) * t + self.cy) * t
end

function BezierCurve:sampleDerivativeX(t)
	return (3 * self.ax * t + 2 * self.bx) * t + self.cx
end

-- Local values: sampleTime, i, sampleX, sampleDerivative, startX, endX, sampleX
function BezierCurve:solveX(x, epsilon)
	local v26_ = x
	local v27_ = epsilon or 1e-6
	for _ = 1, 8 do
		local v28_ = self:sampleX(x) - v26_
		if math.abs(v28_) < v27_ then
			return x
		end
		local v29_ = self:sampleDerivativeX(x)
		if math.abs(v29_) < v27_ then
			break
		end
		x = x - v28_ / v29_
	end
	local v30_ = 0
	local v31_ = 1
	if v26_ < v30_ then
		return v30_
	end
	if v31_ < v26_ then
		return v31_
	end
	local v32_ = v26_
	while v30_ < v31_ do
		local v33_ = self:sampleX(v26_)
		local v34_ = v33_ - v32_
		if math.abs(v34_) < v27_ then
			return v26_
		end
		if v33_ < v32_ then
			v30_ = v26_
			v26_ = v31_
		end
		local v35_ = (v26_ - v30_) * 0.5 + v30_
		v31_ = v26_
		v26_ = v35_
	end
	return v26_
end

function BezierCurve:solve(x, epsilon)
	return self:sampleY(self:solveX(x, epsilon))
end
