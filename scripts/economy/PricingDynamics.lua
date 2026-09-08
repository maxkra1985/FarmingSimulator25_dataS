-- Local values: PricingDynamics_mt
PricingDynamics = {}
local PricingDynamics_mt = Class(PricingDynamics)
PricingDynamics.VERSION = 1
PricingDynamics.AMP_DIST_CONSTANT = 1
PricingDynamics.AMP_DIST_LINEAR_DOWN = 2
PricingDynamics.AMP_DIST_LINEAR_UP = 3
PricingDynamics.TREND_PLATEAU = 1
PricingDynamics.TREND_CLIMBING = 2
PricingDynamics.TREND_FALLING = 3

-- Upvalues: PricingDynamics_mt
-- Local values: self, sinePeriod, t
function PricingDynamics.new(mean, amp, ampVar, ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction, customMt)
	-- upvalues: (copy) PricingDynamics_mt
	local v12_ = customMt or PricingDynamics_mt
	local v13_ = setmetatable({}, v12_)
	v13_.curves = {}
	v13_.plateauDuration = per * plateauFactor
	v13_.meanValue = mean
	v13_.isInPlateau = math.random() < initialPlateauFraction
	v13_.nextPlateauNumber = 0
	v13_.baseCurve = v13_:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)
	local v14_ = v13_.baseCurve.period
	if not v13_.isInPlateau then
		v13_.plateauTime = 0
		local v15_ = v13_.baseCurve.time
		if v13_.baseCurve.period * 0.5 <= v15_ and v15_ < v13_.baseCurve.period * 0.75 then
			v13_.nextPlateauNumber = 1
		end
		return v13_
	end
	v13_.plateauTime = math.random() * v13_.plateauDuration
	if Utils.getCoinToss() then
		v13_.baseCurve.time = v14_ * 0.25
		return v13_
	end
	v13_.baseCurve.time = v14_ * 0.75
	v13_.nextPlateauNumber = 1
	return v13_
end

-- Local values: curve
function PricingDynamics:addCurve(amp, ampVar, ampDist, per, perVar, perDist)
	local v23_ = self:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)
	local v24_ = self.curves
	table.insert(v24_, v23_)
end

-- Local values: newTime, newTime, _, curve, nextPlateauTime
function PricingDynamics:update(dt)
	if self.isInPlateau then
		local v27_ = self.plateauTime + dt
		if self.plateauDuration <= v27_ then
			self.isInPlateau = false
			self.plateauTime = 0
			self.nextPlateauNumber = 1 - self.nextPlateauNumber
		else
			self.plateauTime = v27_
		end
	else
		local v28_ = self.baseCurve.time + dt
		self:updateCurve(self.baseCurve, dt)
		for _, v29_ in pairs(self.curves) do
			self:updateCurve(v29_, dt)
		end
		local v30_ = self.baseCurve.period * 0.25
		if self.nextPlateauNumber == 1 then
			v30_ = self.baseCurve.period * 0.75
		end
		if not self.isInPlateau and (v30_ < v28_ and v28_ < v30_ + self.baseCurve.period * 0.25) then
			self.isInPlateau = true
			self.plateauTime = 0
			self.baseCurve.time = v30_
		end
		return
	end
end

-- Local values: value, _, curve
function PricingDynamics:evaluate()
	local v32_ = self.meanValue + self:evaluateCurve(self.baseCurve)
	for _, v33_ in pairs(self.curves) do
		v32_ = v32_ + self:evaluateCurve(v33_)
	end
	return v32_
end

function PricingDynamics:getBaseCurveTrend()
	if self.isInPlateau then
		return PricingDynamics.TREND_PLATEAU
	elseif self.baseCurve.time >= self.baseCurve.period * 0.25 and self.baseCurve.time <= self.baseCurve.period * 0.75 then
		return PricingDynamics.TREND_FALLING
	else
		return PricingDynamics.TREND_CLIMBING
	end
end

function PricingDynamics:evaluateForTrend(timeDelta)
	return self.meanValue + self:evaluateCurve(self.baseCurve, timeDelta)
end

-- Local values: k, curve
function PricingDynamics:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#priceVersion", PricingDynamics.VERSION)
	xmlFile:setValue(key .. "#isInPlateau", self.isInPlateau)
	xmlFile:setValue(key .. "#nextPlateauNumber", self.nextPlateauNumber)
	xmlFile:setValue(key .. "#plateauDuration", self.plateauDuration)
	xmlFile:setValue(key .. "#meanValue", self.meanValue)
	xmlFile:setValue(key .. "#plateauTime", self.plateauTime)
	self:saveCurveToXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")
	for v40_, v41_ in pairs(self.curves) do
		self:saveCurveToXMLFile(xmlFile, key, v41_, v40_)
	end
end

-- Local values: k, curve
function PricingDynamics:loadFromXMLFile(xmlFile, key)
	if xmlFile:getValue(key .. "#priceVersion", 0) == PricingDynamics.VERSION then
		self.isInPlateau = xmlFile:getValue(key .. "#isInPlateau", self.isInPlateau)
		self.nextPlateauNumber = xmlFile:getValue(key .. "#nextPlateauNumber", self.nextPlateauNumber)
		self.meanValue = xmlFile:getValue(key .. "#meanValue", self.meanValue)
		self.plateauTime = xmlFile:getValue(key .. "#plateauTime", self.plateauTime)
		self.plateauDuration = xmlFile:getValue(key .. "#plateauDuration", self.plateauDuration)
		self:loadCurveFromXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")
		for v45_, v46_ in pairs(self.curves) do
			self:loadCurveFromXMLFile(xmlFile, key, v46_, v45_)
		end
	end
end

-- Local values: curveKey
function PricingDynamics:saveCurveToXMLFile(xmlFile, key, curve, name)
	local v51_ = string.format("%s.curve%s", key, (tostring(name)))
	xmlFile:setValue(v51_ .. "#nominalAmplitude", curve.nominalAmplitude)
	xmlFile:setValue(v51_ .. "#nominalAmplitudeVariation", curve.nominalAmplitudeVariation)
	xmlFile:setValue(v51_ .. "#amplitudeDistribution", curve.amplitudeDistribution)
	xmlFile:setValue(v51_ .. "#nominalPeriod", curve.nominalPeriod)
	xmlFile:setValue(v51_ .. "#nominalPeriodVariation", curve.nominalPeriodVariation)
	xmlFile:setValue(v51_ .. "#periodDistribution", curve.periodDistribution)
	xmlFile:setValue(v51_ .. "#amplitude", curve.amplitude)
	xmlFile:setValue(v51_ .. "#period", curve.period)
	xmlFile:setValue(v51_ .. "#time", curve.time)
end

function PricingDynamics:loadCurveFromXMLFile(xmlFile, key, curve, name)
	curve.nominalAmplitude = xmlFile:getValue(key .. ".curve" .. name .. "#nominalAmplitude", curve.nominalAmplitude)
	curve.nominalAmplitudeVariation = xmlFile:getValue(key .. ".curve" .. name .. "#nominalAmplitudeVariation", curve.nominalAmplitudeVariation)
	curve.amplitudeDistribution = xmlFile:getValue(key .. ".curve" .. name .. "#amplitudeDistribution", curve.amplitudeDistribution)
	curve.nominalPeriod = xmlFile:getValue(key .. ".curve" .. name .. "#nominalPeriod", curve.nominalPeriod)
	curve.nominalPeriodVariation = xmlFile:getValue(key .. ".curve" .. name .. "#nominalPeriodVariation", curve.nominalPeriodVariation)
	curve.periodDistribution = xmlFile:getValue(key .. ".curve" .. name .. "#periodDistribution", curve.periodDistribution)
	curve.amplitude = xmlFile:getValue(key .. ".curve" .. name .. "#amplitude", curve.amplitude)
	curve.period = xmlFile:getValue(key .. ".curve" .. name .. "#period", curve.period)
	curve.time = xmlFile:getValue(key .. ".curve" .. name .. "#time", curve.time)
end

function PricingDynamics:startFirstCycle(curve, amp, ampVar, ampDist, per, perVar, perDist)
	local v64_ = curve or {}
	v64_.nominalAmplitude = amp
	v64_.nominalAmplitudeVariation = ampVar
	v64_.amplitudeDistribution = ampDist
	v64_.nominalPeriod = per
	v64_.nominalPeriodVariation = perVar
	v64_.periodDistribution = perDist
	self:startNewCycle(v64_)
	v64_.time = math.random() * v64_.period
	return v64_
end

-- Local values: sinePeriod, sinePeriodVariation
function PricingDynamics:startNewCycle(curve)
	local v67_ = curve.nominalPeriod - 2 * self.plateauDuration
	local v68_ = v67_ * curve.nominalPeriodVariation / curve.nominalPeriod
	curve.amplitude = self:getRandomValue(curve.nominalAmplitude, curve.nominalAmplitudeVariation, curve.amplitudeDistribution)
	curve.period = self:getRandomValue(v67_, v68_, curve.periodDistribution)
	curve.time = 0
end

function PricingDynamics:updateCurve(curve, dt)
	curve.time = curve.time + dt
	if curve.time >= curve.period then
		self:startNewCycle(curve)
	end
end

function PricingDynamics:evaluateCurve(curve, atTimeDelta)
	local v74_ = curve.amplitude
	local v75_ = 6.283185307179586 * (curve.time + (atTimeDelta or 0)) / curve.period
	return v74_ * math.sin(v75_)
end

-- Local values: minValue, maxValue, r, r
function PricingDynamics:getRandomValue(center, deviation, distribution)
	local v79_ = center - deviation
	local v80_ = center + deviation
	if distribution == PricingDynamics.AMP_DIST_CONSTANT then
		return MathUtil.randomFloat(v79_, v80_)
	end
	if distribution == PricingDynamics.AMP_DIST_LINEAR_DOWN then
		local v81_ = math.random()
		return v80_ + math.sqrt(v81_) * (v79_ - v80_)
	end
	if distribution ~= PricingDynamics.AMP_DIST_LINEAR_UP then
		return -math.huge
	end
	local v82_ = math.random()
	return v79_ - math.sqrt(v82_) * (v80_ - v79_)
end

function PricingDynamics.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#priceVersion", "Price version (If version is outdated values are reset)", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#isInPlateau", "Is in plateau")
	schema:register(XMLValueType.INT, basePath .. "#nextPlateauNumber", "Next plateau number")
	schema:register(XMLValueType.FLOAT, basePath .. "#meanValue", "Mean value")
	schema:register(XMLValueType.FLOAT, basePath .. "#plateauTime", "Plateau time")
	schema:register(XMLValueType.INT, basePath .. "#plateauDuration", "Plateau duration")
	PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, "BaseCurve")
	PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, "1")
end

function PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, name)
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#nominalAmplitude", "Normal amplitude")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#nominalAmplitudeVariation", "Normal amplitude variation")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#amplitudeDistribution", "Amplitude fistribution")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#nominalPeriod", "Nominal period")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#nominalPeriodVariation", "Nominal period variation")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#periodDistribution", "Period distribution")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#amplitude", "Amplitude")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#period", "Period")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#time", "Time")
end
