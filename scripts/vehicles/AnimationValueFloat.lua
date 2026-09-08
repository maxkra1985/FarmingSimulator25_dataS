-- Local values: AnimationValueFloat_mt
AnimationValueFloat = {}
local AnimationValueFloat_mt = Class(AnimationValueFloat)
AnimationValueFloat.TANGENT_TYPE_LINEAR = 0
AnimationValueFloat.TANGENT_TYPE_SPLINE = 1
AnimationValueFloat.TANGENT_TYPE_STEP = 2
AnimationValueFloat.TANGENT_TYPE_SPLINE01 = 1
AnimationValueFloat.TANGENT_TYPE_SPLINE02 = 3
AnimationValueFloat.TANGENT_TYPE_SPLINE03 = 4
AnimationValueFloat.TANGENT_TYPE_SPLINE04 = 5

-- Upvalues: AnimationValueFloat_mt
-- Local values: self
function AnimationValueFloat.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt)
	-- upvalues: (copy) AnimationValueFloat_mt
	local v13_ = customMt or AnimationValueFloat_mt
	local v14_ = setmetatable({}, v13_)
	v14_.vehicle = vehicle
	v14_.animation = animation
	v14_.part = part
	v14_.startName = startName
	v14_.endName = endName
	v14_.name = name
	v14_.initialUpdate = initialUpdate
	v14_.get = get
	v14_.set = set
	v14_.extraLoad = extraLoad
	v14_.warningInfo = v14_.name
	v14_.compareParams = {}
	v14_.oldCurValues = {}
	v14_.oldSpeed = {}
	v14_.curValue = nil
	v14_.speed = nil
	return v14_
end

-- Local values: i, i, success, tangentTypeStr, i
function AnimationValueFloat:load(xmlFile, key)
	if self.startName ~= "" then
		self.startValue = xmlFile:getValue(key .. "#" .. self.startName, nil, true)
		local v18_ = self.startValue
		if type(v18_) == "number" then
			self.startValue = { self.startValue }
		else
			local v19_ = self.startValue
			if type(v19_) == "boolean" then
				self.startValue = { self.startValue and 1 or 0 }
			else
				local v20_ = self.startValue
				if type(v20_) == "string" then
					local v21_ = {}
					local v22_ = self.startValue
					__set_list(v21_, 1, {tonumber(v22_) or 0})
					self.startValue = v21_
				else
					local v23_ = self.startValue
					if type(v23_) == "table" then
						for v24_ = 1, #self.startValue do
							local v25_ = self.startValue[v24_]
							if type(v25_) == "string" then
								local v26_ = self.startValue
								local v27_ = self.startValue[v24_]
								v26_[v24_] = tonumber(v27_) or 0
							end
						end
					end
				end
			end
		end
	end
	if self.endName ~= "" then
		self.endValue = xmlFile:getValue(key .. "#" .. self.endName, nil, true)
		local v28_ = self.endValue
		if type(v28_) == "number" then
			self.endValue = { self.endValue }
		else
			local v29_ = self.endValue
			if type(v29_) == "boolean" then
				self.endValue = { self.endValue and 1 or 0 }
			else
				local v30_ = self.endValue
				if type(v30_) == "string" then
					local v31_ = {}
					local v32_ = self.endValue
					__set_list(v31_, 1, {tonumber(v32_) or 0})
					self.endValue = v31_
				else
					local v33_ = self.endValue
					if type(v33_) == "table" then
						for v34_ = 1, #self.endValue do
							local v35_ = self.endValue[v34_]
							if type(v35_) == "string" then
								local v36_ = self.endValue
								local v37_ = self.endValue[v34_]
								v36_[v34_] = tonumber(v37_) or 0
							end
						end
					end
				end
			end
		end
	end
	if self.endValue ~= nil or self.endName == "" then
		self.warningInfo = key
		self.xmlFile = xmlFile
		if self:extraLoad(xmlFile, key) then
			local v38_ = xmlFile:getValue(key .. "#tangentType", "linear")
			local v39_ = "TANGENT_TYPE_" .. string.upper(v38_)
			if AnimationValueFloat[v39_] == nil then
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_LINEAR
			else
				self.tangentType = AnimationValueFloat[v39_]
			end
			if self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE01 then
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
				self.splineFunction = AnimationValueFloat.splineFunction01
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE02 then
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
				self.splineFunction = AnimationValueFloat.splineFunction02
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE03 then
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
				self.splineFunction = AnimationValueFloat.splineFunction03
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE04 then
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
				self.splineFunction = AnimationValueFloat.splineFunction04
			end
			self.curStartValue = {}
			self.curRealValue = {}
			for v40_ = 1, #(self.startValue or self.endValue) do
				self.curStartValue[v40_] = 0
				self.curRealValue[v40_] = 0
			end
			return true
		end
	end
	return false
end
function AnimationValueFloat.addCompareParameters(p41_, ...)
	for v42_ = 1, select("#", ...) do
		local v43_ = select(v42_, ...)
		local v44_ = p41_.compareParams
		table.insert(v44_, v43_)
	end
end

function AnimationValueFloat:setWarningInformation(info)
	self.warningInfo = info
end

-- Local values: j, part2, animationValue2, secondIndex, secondAnimValue, allowed, paramIndex, param
function AnimationValueFloat:init(index, numParts)
	for v50_ = index + 1, numParts do
		local v51_ = self.animation.parts[v50_]
		if self.part.direction == v51_.direction then
			local v52_ = nil
			for v53_ = 1, #v51_.animationValues do
				local v54_ = v51_.animationValues[v53_]
				if v54_.endName == self.endName then
					local v55_ = true
					for v56_ = 1, #self.compareParams do
						local v57_ = self.compareParams[v56_]
						if v54_[v57_] ~= self[v57_] then
							v55_ = false
						end
					end
					if v55_ then
						v52_ = v54_
					end
				end
			end
			if v52_ ~= nil then
				if self.part.startTime + self.part.duration > v51_.startTime + 0.001 then
					Logging.xmlWarning(self.xmlFile, "Overlapping %s parts for \'%s\' in animation \'%s\'", self.name, self.warningInfo, self.animation.name)
				end
				self.nextPart = v52_.part
				v52_.prevPart = self.part
				if v52_.startValue == nil then
					local v58_ = {}
					local v59_ = self.endValue
					__set_list(v58_, 1, {unpack(v59_)})
					v52_.startValue = v58_
					return
				end
				break
			end
		end
	end
end

function AnimationValueFloat:postInit()
	if self.endValue ~= nil and self.startValue == nil then
		self.startValue = { self:get() }
	end
end

function AnimationValueFloat:reset()
	self.oldCurValues = self.curValue or self.oldCurValues
	self.oldSpeed = self.speed or self.oldSpeed
	self.curValue = nil
	self.speed = nil
end
function AnimationValueFloat.initValues(p62_, p63_, p64_, p65_, ...)
	p62_.curValue = p62_.curValue or p62_.oldCurValues
	local v66_ = select("#", ...)
	for v67_ = 1, v66_ do
		p62_.curValue[v67_] = select(v67_, ...)
	end
	local v68_ = 1 / math.max(p64_, 0.001)
	p62_.speed = p62_.speed or p62_.oldSpeed
	for v69_ = 1, #p62_.curValue do
		p62_.speed[v69_] = (p63_[v69_] - p62_.curValue[v69_]) * v68_
		p62_.curStartValue[v69_] = p62_.curValue[v69_]
		p62_.curRealValue[v69_] = p62_.curValue[v69_]
	end
	if p65_ == true then
		if p62_.animation.currentSpeed < 0 then
			for v70_ = 1, v66_ do
				p62_.curStartValue[v70_] = p62_.endValue[v70_]
			end
		else
			for v71_ = 1, v66_ do
				p62_.curStartValue[v71_] = p62_.startValue[v71_]
			end
		end
	end
	p62_.curTargetValue = p63_
	return p62_.initialUpdate
end

-- Local values: targetValue, forceUpdate, i, alpha, range, i, alpha
function AnimationValueFloat:update(durationToEnd, dtToUse, realDt, fixedTimeUpdate)
	if self.startValue ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(self.nextPart, self.prevPart, self.animation, true)) then
		local v76_ = self.endValue
		if self.animation.currentSpeed < 0 then
			v76_ = self.startValue
		end
		local v77_
		if self.curValue == nil then
			v77_ = self:initValues(v76_, durationToEnd, fixedTimeUpdate, self:get())
		else
			v77_ = false
		end
		if AnimatedVehicle.setMovedLimitedValuesN(#self.curValue, self.curValue, v76_, self.speed, realDt) or v77_ then
			if self.tangentType == AnimationValueFloat.TANGENT_TYPE_LINEAR then
				local v78_ = self.curValue
				self:set(unpack(v78_))
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE then
				for v79_ = 1, #self.curValue do
					local v80_ = 0
					if fixedTimeUpdate == true then
						if self.part.duration ~= 0 then
							local v81_ = (durationToEnd - realDt) / self.part.duration
							v80_ = 1 - math.clamp(v81_, 0, 1)
						end
					else
						local v82_ = self.curTargetValue[v79_] - self.curStartValue[v79_]
						if v82_ ~= 0 then
							v80_ = (self.curValue[v79_] - self.curStartValue[v79_]) / v82_
						end
					end
					if v80_ >= 0 and v80_ <= 1 then
						self.curRealValue[v79_] = self.splineFunction(v80_) * (self.curTargetValue[v79_] - self.curStartValue[v79_]) + self.curStartValue[v79_]
					else
						self.curRealValue[v79_] = self.curValue[v79_]
					end
				end
				local v83_ = self.curRealValue
				self:set(unpack(v83_))
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_STEP then
				for v84_ = 1, #self.curValue do
					local v85_ = self.curValue[v84_] - self.curStartValue[v84_]
					local v86_ = self.curTargetValue[v84_] - self.curStartValue[v84_]
					if v85_ / math.max(v86_, 0.00001) >= 1 then
						self.curRealValue[v84_] = self.curValue[v84_]
					else
						self.curRealValue[v84_] = self.curStartValue[v84_]
					end
				end
				local v87_ = self.curRealValue
				self:set(unpack(v87_))
			end
			return true
		end
	end
	return false
end

function AnimationValueFloat.splineFunction01(alpha)
	local v89_ = 3.141592653589793 * alpha
	return (1 - math.cos(v89_)) * 0.5
end

function AnimationValueFloat.splineFunction02(alpha)
	local v91_ = 3.141592653589793 * (alpha + 0.0625) * 0.888888889
	return (1 - math.cos(v91_) / 0.9848077531) * 0.5
end

function AnimationValueFloat.splineFunction03(alpha)
	local v93_ = 3.141592653589793 * (alpha + 0.125) * 0.8
	return (1 - math.cos(v93_) / 0.9510565163) * 0.5
end

function AnimationValueFloat.splineFunction04(alpha)
	local v95_ = 3.141592653589793 * (alpha + 0.25) * 0.66666667
	return (1 - math.cos(v95_) / 0.8660254038) * 0.5
end
