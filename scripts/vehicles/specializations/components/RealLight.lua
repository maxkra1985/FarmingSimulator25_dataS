-- Local values: RealLight_mt
RealLight = {}
RealLight.SCATTERING_MAX_ANGLE = 60
RealLight.DEFAULT_LIGHT_PROFILE = {}
RealLight.DEFAULT_LIGHT_PROFILE.worklight = {
	["iesProfile"] = "data/shared/ies/workLight.ies",
	["intensityScale"] = 1.25
}
RealLight.DEFAULT_LIGHT_PROFILE.highbeam = {
	["iesProfile"] = "data/shared/ies/highBeam.ies",
	["intensityScale"] = 2
}
RealLight.DEFAULT_LIGHT_PROFILE.backlight = {
	["iesProfile"] = "data/shared/ies/backLight.ies",
	["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.brakelight = {
	["iesProfile"] = "data/shared/ies/backLight.ies",
	["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.frontlight = {
	["iesProfile"] = "data/shared/ies/frontLight.ies",
	["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.turnlight = {
	["iesProfile"] = "data/shared/ies/turnLight.ies",
	["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.reverselight = {
	["iesProfile"] = "data/shared/ies/workLight.ies",
	["intensityScale"] = 1.25
}
local RealLight_mt = Class(RealLight)

-- Upvalues: RealLight_mt
-- Local values: self
function RealLight.new(vehicle, customMt)
	-- upvalues: (copy) RealLight_mt
	local v4_ = customMt or RealLight_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.chargeFunction = nil
	return v5_
end

-- Local values: lightsProfile, xmlIESProfile, iesProfile, shadowLightOffset, x, y, z, tx, ty, tz, maxLightRange, maxConeAngle, i, lightSource, _x, _y, _z, _tx, _ty, _tz, numLightSources, dx, dy, dz, ox, oy, oz, i, lightSource
function RealLight:loadFromXML(xmlFile, baseKey, components, i3dMappings, loadLightTypes)
	self.node = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings)
	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing light source node in \'%s\'", baseKey)
		return false
	end
	if not getHasClassId(self.node, ClassIds.LIGHT_SOURCE) then
		Logging.xmlWarning(xmlFile, "Defined node is not a light source \'%s\'", baseKey)
		return false
	end
	self.lightSources = { self.node }
	I3DUtil.iterateRecursively(self.node, function(p12_)
		-- upvalues: (copy) xmlFile, (copy) baseKey, (copy) self
		if not getVisibility(p12_) then
			Logging.xmlWarning(xmlFile, "Real light source \'%s\' is hidden in \'%s\'!", getName(p12_), baseKey)
		end
		if getHasClassId(p12_, ClassIds.LIGHT_SOURCE) then
			local v13_ = self.lightSources
			table.insert(v13_, p12_)
		end
	end)
	self.defaultColor = self.defaultColor or { getLightColor(self.node) }
	self.intensityScale = xmlFile:getValue(baseKey .. "#intensityScale", 1)
	self.curIntensityScale = self.intensityScale
	setVisibility(self.node, false)
	if loadLightTypes ~= false then
		self.lightTypes = xmlFile:getValue(baseKey .. "#lightTypes", nil, true)
		self.excludedLightTypes = xmlFile:getValue(baseKey .. "#excludedLightTypes", nil, true)
	end
	if self.lightTypes == nil then
		self.lightTypes = {}
	end
	if self.excludedLightTypes == nil then
		self.excludedLightTypes = {}
	end
	local v14_ = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	local v15_ = xmlFile:getValue(baseKey .. "#iesProfile")
	if v15_ == nil then
		local v16_ = getLightIESProfile(self.lightSources[1])
		if v16_ ~= "" then
			self.xmlIESProfile = v16_
		end
	else
		self.xmlIESProfile = Utils.getFilename(v15_, self.vehicle.baseDirectory)
	end
	self.useLightScattering = xmlFile:getValue(baseKey .. "#useLightScattering")
	self:updateIESProfile(v14_ == GS_PROFILE_VERY_HIGH and true or v14_ == GS_PROFILE_ULTRA)
	self:updateLightScattering()
	self.hasMergedShadows = false
	self.hasShadows = xmlFile:getValue(baseKey .. "#hasShadows", getLightRange(self.node) > 7.5)
	if self.hasShadows and #self.lightSources > 1 then
		local v17_ = xmlFile:getValue(baseKey .. "#shadowLightOffset", nil, true)
		local v18_ = 0
		local v19_ = 0
		local v20_ = 0
		local v21_ = 0
		local v22_ = 0
		local v23_ = 0
		local v24_ = 0
		local v25_ = 0
		for _, v26_ in ipairs(self.lightSources) do
			local v27_ = getLightRange
			v20_ = math.max(v20_, v27_(v26_))
			local v28_ = getLightConeAngle
			v21_ = math.max(v21_, v28_(v26_))
			local v29_, v30_, v31_ = localToLocal(v26_, getParent(self.node), 0, 0, 0)
			v22_ = v22_ + v29_
			v23_ = v23_ + v30_
			v24_ = v24_ + v31_
			local v32_, v33_, v34_ = localToLocal(v26_, getParent(self.node), 0, 0, -20)
			v25_ = v25_ + v32_
			v18_ = v18_ + v33_
			v19_ = v19_ + v34_
		end
		local v35_ = #self.lightSources
		if v35_ > 1 then
			v22_ = v22_ / v35_
			v23_ = v23_ / v35_
			v24_ = v24_ / v35_
			v25_ = v25_ / v35_
			v18_ = v18_ / v35_
			v19_ = v19_ / v35_
		end
		self.shadowLightSource = createLightSource(getName(self.node) .. "_shadow", LightType.SPOT, 0.85, 0.85, 1, v20_)
		local v36_ = setLightConeAngle
		local v37_ = self.shadowLightSource
		local v38_ = RealLight.getMergedConeAngleSize
		local v39_ = self.lightSources
		v36_(v37_, (math.max(v21_, v38_(v39_))))
		setLightShadowMap(self.shadowLightSource, true, 512)
		setVisibility(self.shadowLightSource, false)
		link(getParent(self.node), self.shadowLightSource)
		setTranslation(self.shadowLightSource, v22_, v23_, v24_)
		setLightSoftShadowSize(self.shadowLightSource, 0.008)
		setLightSoftShadowDistance(self.shadowLightSource, 15)
		setLightSoftShadowDepthBiasFactor(self.shadowLightSource, 0.02)
		local v40_, v41_, v42_ = MathUtil.vector3Normalize(v25_ - v22_, v18_ - v23_, v19_ - v24_)
		setDirection(self.shadowLightSource, -v40_, -v41_, -v42_, 0, 1, 0)
		if v17_ ~= nil then
			local v43_, v44_, v45_ = localToLocal(self.shadowLightSource, getParent(self.shadowLightSource), v17_[1], v17_[2], -v17_[3])
			setTranslation(self.shadowLightSource, v43_, v44_, v45_)
		end
		for _, v46_ in ipairs(self.lightSources) do
			setLightShadowMap(v46_, true, 512)
		end
	end
	if xmlFile:getRootName() == "vehicle" then
		self.vehicle:loadAdditionalLightAttributesFromXML(xmlFile, baseKey, self)
	end
	return true
end

-- Local values: i, lightType, i, excludedLightType
function RealLight:merge(otherLight)
	for _, v49_ in ipairs(self.lightTypes) do
		table.addElement(otherLight.lightTypes, v49_)
	end
	for _, v50_ in ipairs(self.excludedLightTypes) do
		table.addElement(otherLight.excludedLightTypes, v50_)
	end
	return otherLight
end

-- Local values: i, lightSource, nodeName, searchString, profile, iesProfile, iesProfile
function RealLight:updateIESProfile(iesEnabled)
	for _, v53_ in ipairs(self.lightSources) do
		local v54_ = string.lower(getName(v53_))
		for v55_, v56_ in pairs(RealLight.DEFAULT_LIGHT_PROFILE) do
			if string.contains(v54_, v55_) then
				if iesEnabled then
					if self.xmlIESProfile == nil then
						if getLightIESProfile(v53_) == "" then
							setLightIESProfile(v53_, v56_.iesProfile)
						end
					else
						setLightIESProfile(v53_, self.xmlIESProfile)
					end
				elseif getLightIESProfile(v53_) ~= "" then
					setLightIESProfile(v53_, "")
					self.curIntensityScale = self.intensityScale
				end
				self.curIntensityScale = self.intensityScale * v56_.intensityScale
				break
			end
		end
	end
end

-- Local values: lightsProfile, isDefaultLightOrHighBeam, i, lightType, i, lightSource, useLightScattering, coneAngle
function RealLight:updateLightScattering()
	local v58_ = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	local v59_ = false
	for _, v60_ in ipairs(self.lightTypes) do
		if v60_ == Lights.LIGHT_TYPE_DEFAULT or v60_ == Lights.LIGHT_TYPE_HIGHBEAM then
			v59_ = true
			break
		end
	end
	for _, v61_ in ipairs(self.lightSources) do
		local v62_ = false
		if self.useLightScattering == true then
			v62_ = GS_PROFILE_HIGH <= v58_
		elseif self.useLightScattering == nil then
			if v59_ then
				v62_ = GS_PROFILE_HIGH <= v58_
			elseif #self.lightTypes > 0 then
				v62_ = GS_PROFILE_VERY_HIGH <= v58_
			end
			if v62_ then
				v62_ = getLightRange(v61_) > 7.5
			end
		end
		if v62_ then
			setLightUseLightScattering(v61_, true)
			if getLightConeAngle(v61_) > RealLight.SCATTERING_MAX_ANGLE then
				setLightScatteringConeAngle(v61_, RealLight.SCATTERING_MAX_ANGLE)
			end
			setLightScatteringIntensity(v61_, 1)
		elseif getLightUseLightScattering(v61_) then
			setLightUseLightScattering(v61_, false)
		end
	end
end

-- Local values: lightsProfile, _, component, _, lightSource, _, component, _, lightSource
function RealLight:updateMergedShadows()
	if self.hasShadows then
		if g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE) == GS_PROFILE_ULTRA then
			if #self.lightSources > 1 then
				if not self.mergedShadowLightCreated then
					local v64_ = mergeLightShadows
					local v65_ = self.lightSources
					v64_(table.unpack(v65_))
					setMergedShadowSettingsLight(self.node, self.shadowLightSource)
					for _, v66_ in ipairs(self.vehicle.components) do
						addMergedShadowIgnoreShapes(self.lightSources[1], v66_.node)
					end
					self.mergedShadowLightCreated = true
				end
				for _, v67_ in ipairs(self.lightSources) do
					setLightShadowMap(v67_, true, 512)
					setLightShadowPriority(self.node, 1)
				end
				setMergedShadowActive(self.node, true)
			else
				setLightShadowMap(self.node, true, 512)
				setLightShadowPriority(self.node, 0.5)
				for _, v68_ in ipairs(self.vehicle.components) do
					addLightShadowIgnoreShapes(self.lightSources[1], v68_.node)
				end
			end
		elseif #self.lightSources > 1 then
			setMergedShadowActive(self.node, false)
			for _, v69_ in ipairs(self.lightSources) do
				setLightShadowMap(v69_, false, 512)
			end
		else
			setLightShadowMap(self.node, false, 512)
		end
	else
		return
	end
end

function RealLight:finalize()
	self:updateMergedShadows()
end

function RealLight:onLightsProfileChanged(lightsProfile)
	self:updateIESProfile(lightsProfile == GS_PROFILE_VERY_HIGH and true or lightsProfile == GS_PROFILE_ULTRA)
	self:updateLightScattering()
	self:updateMergedShadows()
end

-- Local values: isActive, chargeScale, _, lightType, _, excludedLightType
function RealLight:setLightTypesMask(lightsTypesMask)
	if not self.vehicle:getIsLightActive(self) then
		self:setState(false, 0)
		return
	end
	local v75_ = false
	local v76_ = 1
	if self.lightTypes == nil then
		v75_ = false
	else
		for _, v77_ in pairs(self.lightTypes) do
			local v78_ = 2 ^ v77_
			if bit32.band(lightsTypesMask, v78_) ~= 0 or v77_ == -1 and self.vehicle:getIsActiveForLights(true) then
				if v75_ then
					if self.vehicle.spec_lights.maxLightState < v77_ then
						v76_ = 2
					end
				else
					v75_ = true
				end
			end
		end
		if v75_ and self.excludedLightTypes ~= nil then
			for _, v79_ in pairs(self.excludedLightTypes) do
				local v80_ = 2 ^ v79_
				if bit32.band(lightsTypesMask, v80_) ~= 0 then
					v75_ = false
					break
				end
			end
		end
	end
	if self.chargeFunction ~= nil then
		v76_ = self.chargeFunction(self.chargeFunctionTarget)
	end
	self:setState(v75_, v76_)
end

function RealLight:setIsBlinking(isBlinking) end

function RealLight:setState(isActive, chargeScale)
	self:setCharge(chargeScale or (isActive and 1 or 0))
	setVisibility(self.node, isActive)
end

-- Local values: color, _, lightSource
function RealLight:setCharge(alpha)
	local v86_ = alpha * self.curIntensityScale
	local v87_ = self.defaultColor
	for _, v88_ in ipairs(self.lightSources) do
		setLightColor(v88_, v87_[1] * v86_, v87_[2] * v86_, v87_[3] * v86_)
	end
end

function RealLight:setChargeFunction(func, funcTarget)
	self.chargeFunction = func
	self.chargeFunctionTarget = funcTarget
end

-- Local values: _, lightSource1, _, lightSource2, coneAngle, dx, dz, lx, ly, lz, radius, angle
function RealLight.getAreShadowsMergable(lightSources)
	for _, v93_ in ipairs(lightSources) do
		for _, v94_ in ipairs(lightSources) do
			if v93_ ~= v94_ then
				local v95_ = getLightConeAngle(v94_)
				local v96_, v97_ = MathUtil.getDirectionFromYRotation(v95_ * 0.5)
				local v98_, v99_, v100_ = localDirectionToLocal(v94_, v93_, v96_, 0, -v97_)
				local v101_ = v98_ ^ 2 + v99_ ^ 2
				local v102_ = math.sqrt(v101_)
				local v103_ = math.abs(v100_)
				local v104_ = math.abs(v100_) ^ 2 + v102_ ^ 2
				local v105_ = v103_ / math.sqrt(v104_)
				local v106_ = math.acos(v105_)
				if v100_ > 0 then
					v106_ = 3.141592653589793 - v106_
				end
				if v106_ + v95_ * 0.5 > 3.141592653589793 then
					return false
				end
				local v107_, v108_ = MathUtil.getDirectionFromYRotation(-v95_ * 0.5)
				local v109_, v110_, v111_ = localDirectionToLocal(v94_, v93_, v107_, 0, -v108_)
				local v112_ = v109_ ^ 2 + v110_ ^ 2
				local v113_ = math.sqrt(v112_)
				local v114_ = math.abs(v111_)
				local v115_ = math.abs(v111_) ^ 2 + v113_ ^ 2
				local v116_ = v114_ / math.sqrt(v115_)
				local v117_ = math.acos(v116_)
				if v111_ > 0 then
					v117_ = 3.141592653589793 - v117_
				end
				if v117_ + v95_ * 0.5 > 3.141592653589793 then
					return false
				end
			end
		end
	end
	return true
end

-- Local values: mergedConeAngle, _, lightSource1, _, lightSource2, coneAngle, dx, dz, lx, ly, lz, radius, angle
function RealLight.getMergedConeAngleSize(lightSources)
	local v119_ = 0
	for _, v120_ in ipairs(lightSources) do
		for _, v121_ in ipairs(lightSources) do
			if v120_ ~= v121_ then
				local v122_ = getLightConeAngle(v121_)
				local v123_, v124_ = MathUtil.getDirectionFromYRotation(v122_ * 0.5)
				local v125_, v126_, v127_ = localDirectionToLocal(v121_, v120_, v123_, 0, -v124_)
				local v128_ = v125_ ^ 2 + v126_ ^ 2
				local v129_ = math.sqrt(v128_)
				local v130_ = math.abs(v127_)
				local v131_ = math.abs(v127_) ^ 2 + v129_ ^ 2
				local v132_ = v130_ / math.sqrt(v131_)
				local v133_ = math.acos(v132_)
				if v127_ > 0 then
					v133_ = 3.141592653589793 - v133_
				end
				local v134_ = v133_ + v122_ * 0.5
				local v135_ = math.max(v119_, v134_)
				local v136_, v137_ = MathUtil.getDirectionFromYRotation(-v122_ * 0.5)
				local v138_, v139_, v140_ = localDirectionToLocal(v121_, v120_, v136_, 0, -v137_)
				local v141_ = v138_ ^ 2 + v139_ ^ 2
				local v142_ = math.sqrt(v141_)
				local v143_ = math.abs(v140_)
				local v144_ = math.abs(v140_) ^ 2 + v142_ ^ 2
				local v145_ = v143_ / math.sqrt(v144_)
				local v146_ = math.acos(v145_)
				if v140_ > 0 then
					v146_ = 3.141592653589793 - v146_
				end
				local v147_ = v146_ + v122_ * 0.5
				v119_ = math.max(v135_, v147_)
			end
		end
	end
	return v119_
end

-- Local values: _, key, light, otherLight
function RealLight.loadLightsFromXML(lights, xmlFile, baseKey, vehicle, components, i3dMappings, loadLightTypes)
	local v155_ = lights == nil and {} or lights
	for _, v156_ in xmlFile:iterator(baseKey) do
		local v157_ = RealLight.new(vehicle)
		if v157_:loadFromXML(xmlFile, v156_, components, i3dMappings, loadLightTypes) then
			local v158_ = vehicle:getRealLightFromNode(v157_.node)
			if v158_ ~= nil then
				v157_ = v157_:merge(v158_)
			end
			table.insert(v155_, v157_)
		end
	end
	return v155_
end

function RealLight.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Real light node")
	schema:register(XMLValueType.FLOAT, basePath .. "#intensityScale", "Additional scale of the light source intensity", 1)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
	schema:register(XMLValueType.BOOL, basePath .. "#hasShadows", "Defines if the light has shadows or not (Only in ULTRA game setting)", "Automatically when range is greater 7.5m")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#shadowLightOffset", "Offset of the shadow light calculation from the center of all light sources (in lighting direction)")
	schema:register(XMLValueType.STRING, basePath .. "#iesProfile", "Path to IES profile file (Only used in very high and above)")
	schema:register(XMLValueType.BOOL, basePath .. "#useLightScattering", "Defines if light scattering is used", "automatically calculated based on lightType and range")
end

-- Local values: performanceClass, vehicle, i, childVehicle, _, profile, _, lights, _, realLight
function RealLight.consoleCommandDebugIES(_, enabled)
	if RealLight.IES_DEBUG_ENABLED == nil then
		local v162_ = Utils.getPerformanceClassId()
		RealLight.IES_DEBUG_ENABLED = v162_ == GS_PROFILE_VERY_HIGH and true or v162_ == GS_PROFILE_ULTRA
	end
	local v163_
	if enabled == nil then
		v163_ = not RealLight.IES_DEBUG_ENABLED
	else
		v163_ = enabled == "true"
	end
	RealLight.IES_DEBUG_ENABLED = v163_
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local v164_ = g_localPlayer:getCurrentVehicle()
		for v165_ = 1, #v164_.childVehicles do
			local v166_ = v164_.childVehicles[v165_]
			Logging.info("IES Profiles Enabled: \'%s\' on \'%s\'", v163_, v164_:getFullName())
			if v166_.spec_lights ~= nil then
				for _, v167_ in pairs(v166_.spec_lights.realLights) do
					for _, v168_ in pairs(v167_) do
						for _, v169_ in ipairs(v168_) do
							v169_:updateIESProfile(v163_)
						end
					end
				end
			end
		end
	end
end
addConsoleCommand("gsVehicleDebugLightIESProfiles", "Enables and disables IES profiles on the light source (only the automatically assigned profiles)", "RealLight.consoleCommandDebugIES", nil)
