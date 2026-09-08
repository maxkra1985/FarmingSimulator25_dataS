-- Local values: FogSettings_mt
FogSettings = {}
local FogSettings_mt = Class(FogSettings)

-- Upvalues: FogSettings_mt
-- Local values: self
function FogSettings.new(customMt)
	-- upvalues: (copy) FogSettings_mt
	local v3_ = customMt or FogSettings_mt
	local v4_ = setmetatable({}, v3_)
	v4_.groundFogCoverageEdge0 = 0.15
	v4_.groundFogCoverageEdge1 = 1
	v4_.groundFogExtraHeight = 7
	v4_.groundFogGroundLevelDensity = 0.05
	v4_.groundFogMinValleyDepth = 1.5
	v4_.groundFogStartDayTimeMinutes = 240
	v4_.groundFogEndDayTimeMinutes = 600
	v4_.groundFogWeatherTypes = {}
	v4_.heightFogMaxHeight = 550
	v4_.heightFogGroundLevelDensity = 0.6
	v4_.template = nil
	return v4_
end

-- Local values: ret
function FogSettings:clone()
	local v6_ = self.new()
	v6_.groundFogCoverageEdge0 = self.groundFogCoverageEdge0
	v6_.groundFogCoverageEdge1 = self.groundFogCoverageEdge1
	v6_.groundFogExtraHeight = self.groundFogExtraHeight
	v6_.groundFogGroundLevelDensity = self.groundFogGroundLevelDensity
	v6_.groundFogMinValleyDepth = self.groundFogMinValleyDepth
	v6_.groundFogStartDayTimeMinutes = self.groundFogStartDayTimeMinutes
	v6_.groundFogEndDayTimeMinutes = self.groundFogEndDayTimeMinutes
	v6_.groundFogWeatherTypes = table.clone(self.groundFogWeatherTypes)
	v6_.heightFogMaxHeight = self.heightFogMaxHeight
	v6_.heightFogGroundLevelDensity = self.heightFogGroundLevelDensity
	return v6_
end

-- Local values: template, _, weatherTypeKey, weatherTypeName, weatherType
function FogSettings:loadTemplate(xmlFile, key)
	local v10_ = {
		["groundFogCoverageEdge0"] = {}
	}
	v10_.groundFogCoverageEdge0.min = xmlFile:getFloat(key .. ".groundFog.coverageEdge0#min", 0.15)
	v10_.groundFogCoverageEdge0.max = xmlFile:getFloat(key .. ".groundFog.coverageEdge0#max", 0.15)
	v10_.groundFogCoverageEdge1 = {}
	v10_.groundFogCoverageEdge1.min = xmlFile:getFloat(key .. ".groundFog.coverageEdge1#min", 1)
	v10_.groundFogCoverageEdge1.max = xmlFile:getFloat(key .. ".groundFog.coverageEdge1#max", 1)
	v10_.groundFogExtraHeight = {}
	v10_.groundFogExtraHeight.min = xmlFile:getFloat(key .. ".groundFog.extraHeight#min", 20)
	v10_.groundFogExtraHeight.max = xmlFile:getFloat(key .. ".groundFog.extraHeight#max", 20)
	v10_.groundFogGroundLevelDensity = {}
	v10_.groundFogGroundLevelDensity.min = xmlFile:getFloat(key .. ".groundFog.groundLevelDensity#min", 0.1)
	v10_.groundFogGroundLevelDensity.max = xmlFile:getFloat(key .. ".groundFog.groundLevelDensity#max", 0.1)
	v10_.groundFogMinValleyDepth = {}
	v10_.groundFogMinValleyDepth.min = xmlFile:getFloat(key .. ".groundFog.minValleyDepth#min", 1.5)
	v10_.groundFogMinValleyDepth.max = xmlFile:getFloat(key .. ".groundFog.minValleyDepth#max", 1.5)
	v10_.groundFogStartDayTimeMinutes = {}
	v10_.groundFogStartDayTimeMinutes.min = xmlFile:getInt(key .. ".groundFog.startDayTimeMinutes#min", 300)
	v10_.groundFogStartDayTimeMinutes.max = xmlFile:getInt(key .. ".groundFog.startDayTimeMinutes#max", 300)
	v10_.groundFogEndDayTimeMinutes = {}
	v10_.groundFogEndDayTimeMinutes.min = xmlFile:getInt(key .. ".groundFog.endDayTimeMinutes#min", 600)
	v10_.groundFogEndDayTimeMinutes.max = xmlFile:getInt(key .. ".groundFog.endDayTimeMinutes#max", 600)
	v10_.groundFogWeatherTypes = {}
	for _, v11_ in xmlFile:iterator(key .. ".groundFog.weatherTypes.weatherType") do
		local v12_ = xmlFile:getString(v11_ .. "#name")
		local v13_ = WeatherType.getByName(v12_)
		if v13_ ~= nil then
			v10_.groundFogWeatherTypes[v13_] = true
		end
	end
	v10_.heightFogMaxHeight = {}
	v10_.heightFogMaxHeight.min = xmlFile:getInt(key .. ".heightFog.maxHeight#min", 550)
	v10_.heightFogMaxHeight.max = xmlFile:getInt(key .. ".heightFog.maxHeight#max", 550)
	v10_.heightFogGroundLevelDensity = {}
	v10_.heightFogGroundLevelDensity.min = xmlFile:getFloat(key .. ".heightFog.groundLevelDensity#min", 0.6)
	v10_.heightFogGroundLevelDensity.max = xmlFile:getFloat(key .. ".heightFog.groundLevelDensity#max", 0.6)
	self.template = v10_
	return true
end

-- Local values: template, settings
function FogSettings:createFromTemplate()
	local v15_ = self.template
	if v15_ == nil then
		return nil
	end
	local v16_ = FogSettings.new()
	v16_.groundFogCoverageEdge0 = MathUtil.lerp(v15_.groundFogCoverageEdge0.min, v15_.groundFogCoverageEdge0.max, math.random())
	v16_.groundFogCoverageEdge1 = MathUtil.lerp(v15_.groundFogCoverageEdge1.min, v15_.groundFogCoverageEdge1.max, math.random())
	v16_.groundFogExtraHeight = MathUtil.lerp(v15_.groundFogExtraHeight.min, v15_.groundFogExtraHeight.max, math.random())
	v16_.groundFogGroundLevelDensity = MathUtil.lerp(v15_.groundFogGroundLevelDensity.min, v15_.groundFogGroundLevelDensity.max, math.random())
	v16_.groundFogMinValleyDepth = MathUtil.lerp(v15_.groundFogMinValleyDepth.min, v15_.groundFogMinValleyDepth.max, math.random())
	local v17_ = MathUtil.lerp(v15_.groundFogStartDayTimeMinutes.min, v15_.groundFogStartDayTimeMinutes.max, math.random())
	v16_.groundFogStartDayTimeMinutes = math.floor(v17_)
	local v18_ = MathUtil.lerp(v15_.groundFogEndDayTimeMinutes.min, v15_.groundFogEndDayTimeMinutes.max, math.random())
	v16_.groundFogEndDayTimeMinutes = math.floor(v18_)
	v16_.groundFogWeatherTypes = table.clone(v15_.groundFogWeatherTypes)
	v16_.heightFogMaxHeight = MathUtil.lerp(v15_.heightFogMaxHeight.min, v15_.heightFogMaxHeight.max, math.random())
	v16_.heightFogGroundLevelDensity = MathUtil.lerp(v15_.heightFogGroundLevelDensity.min, v15_.heightFogGroundLevelDensity.max, math.random())
	return v16_
end

-- Local values: weatherTypeNames, weatherTypes, _, weatherTypeName, weatherType
function FogSettings:loadFromXMLFile(xmlFile, key)
	self.groundFogCoverageEdge0 = xmlFile:getFloat(key .. ".groundFog#coverageEdge0", self.groundFogCoverageEdge0)
	self.groundFogCoverageEdge1 = xmlFile:getFloat(key .. ".groundFog#coverageEdge1", self.groundFogCoverageEdge1)
	self.groundFogExtraHeight = xmlFile:getFloat(key .. ".groundFog#extraHeight", self.groundFogExtraHeight)
	self.groundFogGroundLevelDensity = xmlFile:getFloat(key .. ".groundFog#groundLevelDensity", self.groundFogGroundLevelDensity)
	self.groundFogMinValleyDepth = xmlFile:getFloat(key .. ".groundFog#minValleyDepth", self.groundFogMinValleyDepth)
	self.groundFogStartDayTimeMinutes = xmlFile:getInt(key .. ".groundFog#startDayTimeMinutes", self.groundFogStartDayTimeMinutes)
	self.groundFogEndDayTimeMinutes = xmlFile:getInt(key .. ".groundFog#endDayTimeMinutes", self.groundFogEndDayTimeMinutes)
	local v22_ = xmlFile:getString(key .. ".groundFog#weatherTypes")
	if v22_ ~= nil then
		local v23_ = string.split(v22_, " ")
		for _, v24_ in ipairs(v23_) do
			local v25_ = WeatherType.getByName(v24_)
			if v25_ ~= nil then
				self.groundFogWeatherTypes[v25_] = true
			end
		end
	end
	self.heightFogMaxHeight = xmlFile:getFloat(key .. ".heightFog#maxHeight", self.heightFogMaxHeight)
	self.heightFogGroundLevelDensity = xmlFile:getFloat(key .. ".heightFog#groundLevelDensity", self.heightFogGroundLevelDensity)
	self:validate(xmlFile, key)
end

-- Local values: weatherTypes, weatherType, _
function FogSettings:saveToXMLFile(xmlFile, key)
	xmlFile:setFloat(key .. ".groundFog#coverageEdge0", self.groundFogCoverageEdge0)
	xmlFile:setFloat(key .. ".groundFog#coverageEdge1", self.groundFogCoverageEdge1)
	xmlFile:setFloat(key .. ".groundFog#extraHeight", self.groundFogExtraHeight)
	xmlFile:setFloat(key .. ".groundFog#groundLevelDensity", self.groundFogGroundLevelDensity)
	xmlFile:setFloat(key .. ".groundFog#minValleyDepth", self.groundFogMinValleyDepth)
	xmlFile:setInt(key .. ".groundFog#startDayTimeMinutes", self.groundFogStartDayTimeMinutes)
	xmlFile:setInt(key .. ".groundFog#endDayTimeMinutes", self.groundFogEndDayTimeMinutes)
	local v29_ = nil
	for v30_, _ in pairs(self.groundFogWeatherTypes) do
		if v29_ == nil then
			v29_ = WeatherType.getName(v30_)
		else
			v29_ = v29_ .. " " .. WeatherType.getName(v30_)
		end
	end
	if v29_ ~= nil then
		xmlFile:setString(key .. ".groundFog#weatherTypes", v29_)
	end
	xmlFile:setFloat(key .. ".heightFog#maxHeight", self.heightFogMaxHeight)
	xmlFile:setFloat(key .. ".heightFog#groundLevelDensity", self.heightFogGroundLevelDensity)
end

function FogSettings:disableGroundFog()
	self.groundFogGroundLevelDensity = 0
end

function FogSettings:validate(xmlFile, key)
	if MathUtil.getIsOutOfBounds(self.groundFogCoverageEdge0, 0, 1) then
		Logging.xmlWarning(xmlFile, "GroundFog coverageEdge0 \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogCoverageEdge0, key)
		local v35_ = self.groundFogCoverageEdge0
		self.groundFogCoverageEdge0 = math.clamp(v35_, 0, 1)
	end
	if MathUtil.getIsOutOfBounds(self.groundFogCoverageEdge1, 0, 1) then
		Logging.xmlWarning(xmlFile, "GroundFog coverageEdge1 \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogCoverageEdge1, key)
		local v36_ = self.groundFogCoverageEdge1
		self.groundFogCoverageEdge1 = math.clamp(v36_, 0, 1)
	end
	if self.groundFogCoverageEdge0 > self.groundFogCoverageEdge1 then
		local v37_ = self.groundFogCoverageEdge1
		local v38_ = self.groundFogCoverageEdge0
		self.groundFogCoverageEdge0 = v37_
		self.groundFogCoverageEdge1 = v38_
	end
	if MathUtil.getIsOutOfBounds(self.groundFogExtraHeight, 0, 50) then
		Logging.xmlWarning(xmlFile, "GroundFog extraHeight \'%.3f\' is out of bounds [0, 50] for \'%s\'", self.groundFogExtraHeight, key)
		local v39_ = self.groundFogExtraHeight
		self.groundFogExtraHeight = math.clamp(v39_, 0, 50)
	end
	if MathUtil.getIsOutOfBounds(self.groundFogGroundLevelDensity, 0, 1) then
		Logging.xmlWarning(xmlFile, "GroundFog groundLevelDensity \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.groundFogGroundLevelDensity, key)
		local v40_ = self.groundFogGroundLevelDensity
		self.groundFogGroundLevelDensity = math.clamp(v40_, 0, 1)
	end
	if MathUtil.getIsOutOfBounds(self.groundFogMinValleyDepth, 0.5, 20) then
		Logging.xmlWarning(xmlFile, "GroundFog minValleyDepth \'%.3f\' is out of bounds [0.5, 20] for \'%s\'", self.groundFogMinValleyDepth, key)
		local v41_ = self.groundFogMinValleyDepth
		self.groundFogMinValleyDepth = math.clamp(v41_, 0.5, 20)
	end
	if MathUtil.getIsOutOfBounds(self.heightFogMaxHeight, 0, 1500) then
		Logging.xmlWarning(xmlFile, "HeightFog maxHeight \'%.3f\' is out of bounds [0, 1500] for \'%s\'", self.heightFogMaxHeight, key)
		local v42_ = self.heightFogMaxHeight
		self.heightFogMaxHeight = math.clamp(v42_, 0, 1500)
	end
	if MathUtil.getIsOutOfBounds(self.heightFogGroundLevelDensity, 0, 1) then
		Logging.xmlWarning(xmlFile, "HeightFog groundLevelDensity \'%.3f\' is out of bounds [0, 1] for \'%s\'", self.heightFogGroundLevelDensity, key)
		local v43_ = self.heightFogGroundLevelDensity
		self.heightFogGroundLevelDensity = math.clamp(v43_, 0, 1)
	end
end
