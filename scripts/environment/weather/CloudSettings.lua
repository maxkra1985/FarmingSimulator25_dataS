-- Local values: CloudSettings_mt
CloudSettings = {}
local CloudSettings_mt = Class(CloudSettings)

-- Upvalues: CloudSettings_mt
-- Local values: self
function CloudSettings.new(customMt)
	-- upvalues: (copy) CloudSettings_mt
	local v3_ = customMt or CloudSettings_mt
	local v4_ = setmetatable({}, v3_)
	v4_.type = 1
	v4_.baseShapeTiling = 2500
	v4_.erosionTiling = 2500
	v4_.precipitation = 0
	v4_.combinedNoiseEdge0 = 0.49
	v4_.combinedNoiseEdge1 = 1
	v4_.noise0Weight = 0.314507
	v4_.noise0Edge0 = 0.09
	v4_.noise0Edge1 = 0.99
	v4_.noise1Weight = 0.525494
	v4_.noise1Edge0 = 0
	v4_.noise1Edge1 = 0.88
	v4_.noise2Weight = 0.16
	v4_.noise2Edge0 = 0
	v4_.noise2Edge1 = 0.9
	v4_.erosionWeight = 0.3
	v4_.cirrusCoverage = 0.05
	v4_.envMapCloudProbeIndex = 1
	v4_.curlNoiseTiling = 2500
	v4_.curlNoiseHeightFractionModifier = 3
	v4_.curlNoiseModifier = 600
	v4_.groundAlbedo = { 1, 1, 1 }
	v4_.densityScale = 0.01
	return v4_
end

function CloudSettings:load(xmlFile, key)
	self.type = xmlFile:getInt(key .. ".cloudType#type", self.type)
	self.densityScale = xmlFile:getFloat(key .. ".cloudType#densityScale", self.densityScale)
	self.baseShapeTiling = xmlFile:getInt(key .. ".cloudType.baseShape#tiling", self.baseShapeTiling)
	self.erosionTiling = xmlFile:getInt(key .. ".cloudType.erosion#tiling", self.erosionTiling)
	self.precipitation = xmlFile:getFloat(key .. ".cloudType#precipitation", self.precipitation)
	self.combinedNoiseEdge0 = xmlFile:getFloat(key .. ".globalCoverage.combinedNoise#edge0", self.combinedNoiseEdge0)
	self.combinedNoiseEdge1 = xmlFile:getFloat(key .. ".globalCoverage.combinedNoise#edge1", self.combinedNoiseEdge1)
	self.noise0Weight = xmlFile:getFloat(key .. ".globalCoverage.noise0#weight", self.noise0Weight)
	self.noise0Edge0 = xmlFile:getFloat(key .. ".globalCoverage.noise0#edge0", self.noise0Edge0)
	self.noise0Edge1 = xmlFile:getFloat(key .. ".globalCoverage.noise0#edge1", self.noise0Edge1)
	self.noise1Weight = xmlFile:getFloat(key .. ".globalCoverage.noise1#weight", self.noise1Weight)
	self.noise1Edge0 = xmlFile:getFloat(key .. ".globalCoverage.noise1#edge0", self.noise1Edge0)
	self.noise1Edge1 = xmlFile:getFloat(key .. ".globalCoverage.noise1#edge1", self.noise1Edge1)
	self.noise2Weight = xmlFile:getFloat(key .. ".globalCoverage.noise2#weight", self.noise2Weight)
	self.noise2Edge0 = xmlFile:getFloat(key .. ".globalCoverage.noise2#edge0", self.noise2Edge0)
	self.noise2Edge1 = xmlFile:getFloat(key .. ".globalCoverage.noise2#edge1", self.noise2Edge1)
	self.erosionWeight = xmlFile:getFloat(key .. ".globalCoverage.erosionWeight#weight", self.erosionWeight)
	self.cirrusCoverage = xmlFile:getFloat(key .. ".cirrusCoverage#weight", self.cirrusCoverage)
	self.envMapCloudProbeIndex = xmlFile:getInt(key .. "#envMapCloudProbeIndex", 1)
	self.curlNoiseTiling = xmlFile:getInt(key .. ".cloudType.curlNoise#tiling", self.curlNoiseTiling)
	self.curlNoiseHeightFractionModifier = xmlFile:getFloat(key .. ".cloudType.curlNoise#heightFractionModifier", self.curlNoiseHeightFractionModifier)
	self.curlNoiseModifier = xmlFile:getInt(key .. ".cloudType.curlNoise#modifier", self.curlNoiseModifier)
	self.groundAlbedo = xmlFile:getVector(key .. ".groundAlbedo#color", self.groundAlbedo, 3)
	return true
end

function CloudSettings:save(xmlFile, key)
	xmlFile:setInt(key .. ".cloudType#type", self.type)
	xmlFile:setFloat(key .. ".cloudType#densityScale", self.densityScale)
	xmlFile:setInt(key .. ".cloudType.baseShape#tiling", self.baseShapeTiling)
	xmlFile:setInt(key .. ".cloudType.erosion#tiling", self.erosionTiling)
	xmlFile:setFloat(key .. ".cloudType#precipitation", self.precipitation)
	xmlFile:setFloat(key .. ".globalCoverage.combinedNoise#edge0", self.combinedNoiseEdge0)
	xmlFile:setFloat(key .. ".globalCoverage.combinedNoise#edge1", self.combinedNoiseEdge1)
	xmlFile:setFloat(key .. ".globalCoverage.noise0#weight", self.noise0Weight)
	xmlFile:setFloat(key .. ".globalCoverage.noise0#edge0", self.noise0Edge0)
	xmlFile:setFloat(key .. ".globalCoverage.noise0#edge1", self.noise0Edge1)
	xmlFile:setFloat(key .. ".globalCoverage.noise1#weight", self.noise1Weight)
	xmlFile:setFloat(key .. ".globalCoverage.noise1#edge0", self.noise1Edge0)
	xmlFile:setFloat(key .. ".globalCoverage.noise1#edge1", self.noise1Edge1)
	xmlFile:setFloat(key .. ".globalCoverage.noise2#weight", self.noise2Weight)
	xmlFile:setFloat(key .. ".globalCoverage.noise2#edge0", self.noise2Edge0)
	xmlFile:setFloat(key .. ".globalCoverage.noise2#edge1", self.noise2Edge1)
	xmlFile:setFloat(key .. ".globalCoverage.erosionWeight#weight", self.erosionWeight)
	xmlFile:setFloat(key .. ".cirrusCoverage#weight", self.cirrusCoverage)
	xmlFile:setInt(key .. "#envMapCloudProbeIndex", self.envMapCloudProbeIndex)
	xmlFile:setFloat(key .. ".cloudType.curlNoise#tiling", self.curlNoiseTiling)
	xmlFile:setFloat(key .. ".cloudType.curlNoise#heightFractionModifier", self.curlNoiseHeightFractionModifier)
	xmlFile:setFloat(key .. ".cloudType.curlNoise#modifier", self.curlNoiseModifier)
	xmlFile:setString(key .. ".groundAlbedo#color", string.format("%.3f %.3f %.3f", self.groundAlbedo[1], self.groundAlbedo[2], self.groundAlbedo[3]))
	return true
end

-- Local values: ret
function CloudSettings:clone()
	local v12_ = self.new()
	v12_:copyAttributes(self)
	return v12_
end

function CloudSettings:copyAttributes(src)
	self.type = src.type
	self.densityScale = src.densityScale
	self.baseShapeTiling = src.baseShapeTiling
	self.erosionTiling = src.erosionTiling
	self.precipitation = src.precipitation
	self.combinedNoiseEdge0 = src.combinedNoiseEdge0
	self.combinedNoiseEdge1 = src.combinedNoiseEdge1
	self.noise0Weight = src.noise0Weight
	self.noise0Edge0 = src.noise0Edge0
	self.noise0Edge1 = src.noise0Edge1
	self.noise1Weight = src.noise1Weight
	self.noise1Edge0 = src.noise1Edge0
	self.noise1Edge1 = src.noise1Edge1
	self.noise2Weight = src.noise2Weight
	self.noise2Edge0 = src.noise2Edge0
	self.noise2Edge1 = src.noise2Edge1
	self.erosionWeight = src.erosionWeight
	self.cirrusCoverage = src.cirrusCoverage
	self.envMapCloudProbeIndex = src.envMapCloudProbeIndex
	self.curlNoiseTiling = src.curlNoiseTiling
	self.curlNoiseHeightFractionModifier = src.curlNoiseHeightFractionModifier
	self.curlNoiseModifier = src.curlNoiseModifier
	self.groundAlbedo = table.clone(src.groundAlbedo)
end
