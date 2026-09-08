-- Local values: GreatDemandSpecs_mt
GreatDemandSpecs = {}
local GreatDemandSpecs_mt = Class(GreatDemandSpecs)

-- Upvalues: GreatDemandSpecs_mt
-- Local values: self
function GreatDemandSpecs.new(customMt)
	-- upvalues: (copy) GreatDemandSpecs_mt
	local v3_ = customMt or GreatDemandSpecs_mt
	local v4_ = setmetatable({}, v3_)
	v4_.sellStation = nil
	v4_.fillTypeIndex = 0
	v4_.demandMultiplier = 1
	v4_.demandStart = {
		["day"] = 0,
		["hour"] = 0
	}
	v4_.demandDuration = 0
	v4_.isRunning = false
	v4_.isValid = false
	return v4_
end

function GreatDemandSpecs:getIsDateEarlier(day1, hour1, day2, hour2)
	local v9_
	if day1 < day2 then
		v9_ = true
	elseif day1 == day2 then
		v9_ = hour1 < hour2
	else
		v9_ = false
	end
	return v9_
end

-- Local values: blockedTipTrigger, _, greatDemand, validUnloadingStations, _, station, tipTrigger, start, endDayOffset, endHour, endDay, conflictingFillTypes, _, greatDemand, otherStart, otherEndDayOffset, otherEndHour, otherEndDay, validFillTypes, fillType, enabled, amountUberTotal, _, fillTypeIndex, fillType, inverseRatioTotal, inverseRatioTable, _, fillTypeIndex, fillType, amountRatio, inverseRatio, inverseRatioEntry, randomNumber, _, inverseRatioEntry
function GreatDemandSpecs:setUpRandomDemand(weighted, greatDemands, mission)
	self.isRunning = false
	self.isValid = false
	self.fillTypeIndex = 0
	self.demandMultiplier = math.random(11, 14) / 10
	self.demandStart.day = mission.environment.currentMonotonicDay + math.random(2, 5)
	self.demandStart.hour = math.random(7, 18)
	self.demandDuration = math.random(1, 4) * 6
	local v14_ = {}
	for _, v15_ in pairs(greatDemands) do
		if v15_ ~= self and v15_.isValid then
			v14_[v15_.sellStation] = true
		end
	end
	local v16_ = {}
	for _, v17_ in pairs(mission.storageSystem:getUnloadingStations()) do
		if v17_.supportsGreatDemand and (v17_.getSupportsGreatDemand ~= nil and (not v17_.isGreatDemandActive and v14_[v17_] == nil)) then
			table.insert(v16_, v17_)
		end
	end
	if #v16_ > 0 then
		local v18_ = v16_[math.random(1, #v16_)]
		self.sellStation = v18_
		local v19_ = self.demandStart
		local v20_ = (v19_.hour + self.demandDuration) / 24
		local v21_, v22_ = math.modf(v20_)
		local v23_ = v22_ * 24
		local v24_ = v19_.day + v21_
		local v25_ = {}
		if greatDemands ~= nil then
			for _, v26_ in pairs(greatDemands) do
				local v27_ = v26_.demandStart
				if v26_ ~= self and (v26_.isValid and self.sellStation == v26_.sellStation) then
					local v28_ = (v27_.hour + v26_.demandDuration) / 24
					local v29_, v30_ = math.modf(v28_)
					local v31_ = v30_ * 24
					local v32_ = v27_.day + v29_
					if not (self:getIsDateEarlier(v24_, v23_, v27_.day, v27_.hour) or self:getIsDateEarlier(v32_, v31_, v19_.day, v19_.hour)) then
						v25_[v26_.fillTypeIndex] = true
					end
				end
			end
		end
		local v33_ = {}
		for v34_, v35_ in pairs(v18_.acceptedFillTypes) do
			if v35_ and (v25_[v34_] == nil and v18_.fillTypeSupportsGreatDemand[v34_]) then
				table.insert(v33_, v34_)
			end
		end
		if #v33_ > 0 then
			if weighted then
				local v36_ = 0
				for _, v37_ in pairs(v33_) do
					v36_ = v36_ + g_fillTypeManager:getFillTypeByIndex(v37_).totalAmount
				end
				if v36_ > 0 then
					local v38_ = 0
					local v39_ = {}
					for _, v40_ in pairs(v33_) do
						local v41_ = g_fillTypeManager:getFillTypeByIndex(v40_).totalAmount / v36_
						local v42_ = 1 / math.max(v41_, 1e-6)
						v38_ = v38_ + v42_
						table.insert(v39_, {
							["fillTypeIndex"] = v40_,
							["inverseRatio"] = v42_
						})
					end
					local v43_ = math.random()
					for _, v44_ in pairs(v39_) do
						v43_ = v43_ - v44_.inverseRatio / v38_
						if v43_ <= 0.0001 then
							self.fillTypeIndex = v44_.fillTypeIndex
							break
						end
					end
				end
			else
				self.fillTypeIndex = v33_[math.random(1, #v33_)]
			end
			if self.fillTypeIndex ~= 0 then
				self.isValid = true
			end
		end
	end
end
