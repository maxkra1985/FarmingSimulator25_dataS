-- Local values: DashboardValueType_mt
DashboardValueType = {}
local DashboardValueType_mt = Class(DashboardValueType)

-- Upvalues: DashboardValueType_mt
-- Local values: self
function DashboardValueType.new(specName, name, customMt)
	-- upvalues: (copy) DashboardValueType_mt
	local v5_ = customMt or DashboardValueType_mt
	local v6_ = setmetatable({}, v5_)
	v6_.specName = specName
	v6_.name = name
	v6_.fullName = specName .. "." .. name
	v6_.pollUpdate = true
	v6_.valueObject = nil
	v6_.loadFunction = nil
	v6_.stateFunction = nil
	v6_.valueFactor = 1
	v6_.valueCompare = nil
	v6_.idleValue = nil
	v6_.getSourceValue = v6_.getDefaultValue
	v6_.getMinValue = v6_.getDefaultValue
	v6_.getMaxValue = v6_.getDefaultValue
	v6_.getCenterValue = v6_.getDefaultValue
	v6_.getInterpolationSpeed = v6_.getDefaultValue
	return v6_
end

function DashboardValueType:setXMLKey(xmlKey)
	self.xmlKey = xmlKey
end

-- Local values: rootName
function DashboardValueType:loadFromXML(xmlFile, vehicle)
	if self.xmlKey == nil then
		vehicle:loadDashboardsFromXML(xmlFile, xmlFile:getRootName() .. "." .. self.specName .. ".dashboards", self)
	else
		vehicle:loadDashboardsFromXML(xmlFile, self.xmlKey, self)
	end
end

function DashboardValueType:setPollUpdate(pollUpdate)
	self.pollUpdate = pollUpdate
end

function DashboardValueType:setAdditionalFunctions(loadFunction, stateFunction)
	self.loadFunction = loadFunction
	self.stateFunction = stateFunction
end

function DashboardValueType:setValueFactor(valueFactor)
	self.valueFactor = valueFactor
end
function DashboardValueType.setValueCompare(p19_, ...)
	p19_.valueCompare = {}
	for v20_ = 1, select("#", ...) do
		p19_.valueCompare[select(v20_, ...)] = true
	end
end

function DashboardValueType:setIdleValue(idleValue)
	self.idleValue = idleValue
end

function DashboardValueType:setValue(object, func)
	self.valueObject = object
	self:setFunction("getSourceValue", object, func)
end

function DashboardValueType:setCenter(centerFunc)
	self:setFunction("getCenterValue", self.valueObject, centerFunc)
end

function DashboardValueType:setRange(min, max)
	self:setFunction("getMinValue", self.valueObject, min)
	self:setFunction("getMaxValue", self.valueObject, max)
end

function DashboardValueType:setInterpolationSpeed(interpolationSpeed)
	self:setFunction("getInterpolationSpeed", self.valueObject, interpolationSpeed)
end

-- Local values: value, isNumber, min, max, center
function DashboardValueType:getValue(dashboard)
	local v35_ = self:getSourceValue(dashboard)
	if self.valueCompare ~= nil then
		v35_ = self.valueCompare[v35_] == true
	end
	local v36_ = type(v35_) == "number"
	local v37_, v38_, v39_
	if v36_ then
		if self.valueFactor ~= nil then
			v35_ = v35_ * self.valueFactor
		end
		v37_ = self:getMinValue(dashboard)
		v38_ = self:getMaxValue(dashboard)
		v39_ = self:getCenterValue(dashboard)
	else
		v37_ = nil
		v38_ = nil
		v39_ = nil
	end
	return v35_, v37_, v38_, v39_, v36_
end

-- Local values: func
function DashboardValueType:setFunction(funcName, object, value)
	local v44_ = nil
	if type(value) == "number" or type(value) == "boolean" then
		v44_ = function(self)
			-- upvalues: (copy) value
			return value
		end
	elseif type(value) == "function" then
		v44_ = function(_, p45_)
			-- upvalues: (copy) value, (copy) object
			return value(object, p45_)
		end
	elseif type(value) == "string" then
		local v46_ = object[value]
		if type(v46_) == "number" then
			v44_ = function(self)
				-- upvalues: (copy) object, (copy) value
				return object[value]
			end
		else
			local v47_ = object[value]
			if type(v47_) == "boolean" then
				v44_ = function(self)
					-- upvalues: (copy) object, (copy) value
					return object[value]
				end
			else
				local v48_ = object[value]
				v44_ = type(v48_) == "function" and function(_, p49_)
					-- upvalues: (copy) object, (copy) value
					return object[value](object, p49_)
				end or v44_
			end
		end
	end
	if v44_ ~= nil then
		self[funcName] = v44_
	end
end

function DashboardValueType:getDefaultValue()
	return nil
end
