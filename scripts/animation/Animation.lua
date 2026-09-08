-- Local values: Animation_mt
Animation = {}
Animation.DEFAULT_UPDATE_DISTANCE = 150
local Animation_mt = Class(Animation)

-- Upvalues: Animation_mt
-- Local values: self
function Animation.new(customMt)
	-- upvalues: (copy) Animation_mt
	local v3_ = customMt or Animation_mt
	local v4_ = setmetatable({}, v3_)
	v4_.duplicates = {}
	v4_.allowUpdate = true
	v4_.lastUpdateTime = 0
	return v4_
end

-- Local values: i
function Animation:delete()
	for v6_ = #self.duplicates, 1, -1 do
		self.duplicates[v6_] = nil
	end
end

function Animation:update(dt) end

function Animation:isRunning()
	return false
end

function Animation:setUpdateDistance(maxUpdateDistance)
	if self.owner == nil then
		return
	elseif self.owner.currentUpdateDistance ~= nil then
		if maxUpdateDistance == math.huge then
			maxUpdateDistance = nil
		end
		self.maxUpdateDistance = maxUpdateDistance
	end
end

function Animation:getAllowUpdate()
	return self.maxUpdateDistance == nil and true or self.owner.currentUpdateDistance < self.maxUpdateDistance
end

function Animation:start()
	return false
end

function Animation:stop()
	return false
end

function Animation:reset() end

function Animation:setFillType(fillTypeIndex) end

function Animation:isDuplicate(otherAnimation)
	return false
end

function Animation:addDuplicate(otherAnimation)
	local v12_ = self.duplicates
	table.insert(v12_, otherAnimation)
end

-- Local values: i
function Animation:updateDuplicates()
	for v14_ = 1, #self.duplicates do
		self:updateDuplicate(self.duplicates[v14_])
	end
end

function Animation:updateDuplicate(otherAnimation) end

-- Local values: finalPos, speedChangePerMS, i, int, fraction, targetRad, targetPos
function Animation.calculateTurnOffFadeTime(currentSpeedFactor, currentSpeed, direction, position, targetPosition, originalFadeOut, wrapPosition, subDivisions)
	local v23_ = wrapPosition / subDivisions
	local v24_ = 1 / originalFadeOut
	local v25_ = position
	for _ = 1, originalFadeOut do
		local v26_ = currentSpeedFactor - v24_
		currentSpeedFactor = math.max(v26_, 0)
		position = position + currentSpeed * currentSpeedFactor
	end
	local v27_ = v25_ - position
	if math.abs(v27_) < 0.00001 then
		return 1
	end
	local v28_ = (position - targetPosition) / v23_
	local v29_, v30_ = math.modf(v28_)
	local v31_ = v29_ * v23_ + targetPosition
	if (direction <= 0 or math.abs(v30_) <= 0.2) and (direction >= 0 or math.abs(v30_) >= 0.2) then
		local v32_ = v31_ - v25_
		if math.abs(v32_) >= v23_ * 0.5 then
			::l11::
			return (v25_ - (v29_ * v23_ + targetPosition)) / (v25_ - position) * originalFadeOut
		end
	end
	v29_ = v29_ + direction
	goto l11
end
