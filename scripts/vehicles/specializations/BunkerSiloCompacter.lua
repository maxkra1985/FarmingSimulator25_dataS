BunkerSiloCompacter = {}
BunkerSiloCompacter.XML_PATH = "vehicle.bunkerSiloCompacter"

function BunkerSiloCompacter.prerequisitesPresent(specializations)
	return true
end
function BunkerSiloCompacter.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("BunkerSiloCompacter")
	v1_:register(XMLValueType.FLOAT, BunkerSiloCompacter.XML_PATH .. "#compactingScale", "Compacting scale", 1)
	v1_:register(XMLValueType.BOOL, BunkerSiloCompacter.XML_PATH .. "#useSpeedLimit", "Defines if speed limit is used while compactor has contact with ground", false)
	SoundManager.registerSampleXMLPaths(v1_, BunkerSiloCompacter.XML_PATH .. ".sounds", "rolling")
	SoundManager.registerSampleXMLPaths(v1_, BunkerSiloCompacter.XML_PATH .. ".sounds", "compacting")
	v1_:setXMLSpecializationType()
end

function BunkerSiloCompacter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBunkerSiloCompactorFromXML", BunkerSiloCompacter.loadBunkerSiloCompactorFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getBunkerSiloCompacterScale", BunkerSiloCompacter.getBunkerSiloCompacterScale)
end

function BunkerSiloCompacter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", BunkerSiloCompacter.doCheckSpeedLimit)
end

function BunkerSiloCompacter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BunkerSiloCompacter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BunkerSiloCompacter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BunkerSiloCompacter)
end

-- Local values: spec
function BunkerSiloCompacter:onLoad(savegame)
	local v6_ = self.spec_bunkerSiloCompacter
	self:loadBunkerSiloCompactorFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH)
	if self.isClient then
		v6_.samples = {}
		v6_.samples.rolling = g_soundManager:loadSampleFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH .. ".sounds", "rolling", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v6_.samples.compacting = g_soundManager:loadSampleFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH .. ".sounds", "compacting", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v6_.lastIsCompacting = false
		v6_.lastHasGroundContact = false
	end
	if self.getWheels == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", BunkerSiloCompacter)
	end
end

-- Local values: spec
function BunkerSiloCompacter:onDelete()
	local v8_ = self.spec_bunkerSiloCompacter
	g_soundManager:deleteSamples(v8_.samples)
end

-- Local values: spec
function BunkerSiloCompacter:loadBunkerSiloCompactorFromXML(xmlFile, key)
	local v12_ = self.spec_bunkerSiloCompacter
	v12_.scale = xmlFile:getValue(key .. "#compactingScale", 1)
	v12_.useSpeedLimit = xmlFile:getValue(key .. "#useSpeedLimit", false)
end

function BunkerSiloCompacter:getBunkerSiloCompacterScale()
	return self.spec_bunkerSiloCompacter.scale
end

-- Local values: spec, hasGroundContact, isCompacting, wheels, i, wheel
function BunkerSiloCompacter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v15_ = self.spec_bunkerSiloCompacter
	local v16_ = self:getWheels()
	local v17_ = false
	local v18_ = false
	for v19_ = 1, #v16_ do
		local v20_ = v16_[v19_]
		if v20_.physics.contact ~= WheelContactType.NONE then
			v17_ = true
			if v20_.physics.contact == WheelContactType.GROUND_HEIGHT then
				v18_ = true
				break
			end
		end
	end
	if v15_.lastHasGroundContact ~= v17_ or v15_.lastIsCompacting ~= v18_ then
		if v17_ then
			if v18_ then
				if not g_soundManager:getIsSamplePlaying(v15_.samples.compacting) then
					g_soundManager:playSample(v15_.samples.compacting)
				end
			elseif g_soundManager:getIsSamplePlaying(v15_.samples.compacting) then
				g_soundManager:stopSample(v15_.samples.compacting)
			end
			if not g_soundManager:getIsSamplePlaying(v15_.samples.rolling) then
				g_soundManager:playSample(v15_.samples.rolling)
			end
		else
			if g_soundManager:getIsSamplePlaying(v15_.samples.compacting) then
				g_soundManager:stopSample(v15_.samples.compacting)
			end
			if g_soundManager:getIsSamplePlaying(v15_.samples.rolling) then
				g_soundManager:stopSample(v15_.samples.rolling)
			end
		end
		v15_.lastHasGroundContact = v17_
		v15_.lastIsCompacting = v18_
	end
end

-- Local values: spec
function BunkerSiloCompacter:doCheckSpeedLimit(superFunc)
	local v23_ = self.spec_bunkerSiloCompacter
	if v23_.useSpeedLimit then
		return superFunc(self) or v23_.lastIsCompacting
	else
		return superFunc(self)
	end
end
function BunkerSiloCompacter.getDefaultSpeedLimit()
	return 5
end
