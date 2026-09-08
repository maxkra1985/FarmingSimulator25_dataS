-- Local values: MultiValueTween_mt
MultiValueTween = {}
local MultiValueTween_mt = Class(MultiValueTween, Tween)

-- Upvalues: MultiValueTween_mt
-- Local values: self
function MultiValueTween.new(setterFunction, startValues, endValues, duration, customMt)
	-- upvalues: (copy) MultiValueTween_mt
	local v7_ = Tween.new(setterFunction, startValues, endValues, duration, customMt or MultiValueTween_mt)
	v7_.values = { unpack(startValues) }
	return v7_
end

-- Local values: hadTarget
function MultiValueTween:setTarget(target)
	local v10_ = self.functionTarget ~= nil
	MultiValueTween:superClass().setTarget(self, target)
	if target == nil or v10_ then
		if target == nil and v10_ then
			table.remove(self.values, 1)
		else
			self.values[1] = target
		end
	else
		local v11_ = self.values
		table.insert(v11_, 1, target)
		return
	end
end

-- Local values: targetOffset, i, startValue, endValue
function MultiValueTween:tweenValue(t)
	local v14_ = self.functionTarget == nil and 0 or 1
	for v15_ = 1, #self.startValue do
		local v16_ = self.startValue[v15_]
		local v17_ = self.endValue[v15_]
		self.values[v15_ + v14_] = MathUtil.lerp(v16_, v17_, self.curveFunc(t))
	end
	return self.values
end

function MultiValueTween:applyValue()
	local v19_ = self.setter
	local v20_ = self.values
	v19_(unpack(v20_))
end
