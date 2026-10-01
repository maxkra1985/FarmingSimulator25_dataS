RealLight = {}
RealLight.SCATTERING_MAX_ANGLE = 60
RealLight.DEFAULT_LIGHT_PROFILE = {}
RealLight.DEFAULT_LIGHT_PROFILE.worklight = { iesProfile = "data/shared/ies/workLight.ies", intensityScale = 1.25 }
RealLight.DEFAULT_LIGHT_PROFILE.highbeam = { iesProfile = "data/shared/ies/highBeam.ies", intensityScale = 2 }
RealLight.DEFAULT_LIGHT_PROFILE.backlight = { iesProfile = "data/shared/ies/backLight.ies", intensityScale = 1 }
RealLight.DEFAULT_LIGHT_PROFILE.brakelight = { iesProfile = "data/shared/ies/backLight.ies", intensityScale = 1 }
RealLight.DEFAULT_LIGHT_PROFILE.frontlight = { iesProfile = "data/shared/ies/frontLight.ies", intensityScale = 1 }
RealLight.DEFAULT_LIGHT_PROFILE.turnlight = { iesProfile = "data/shared/ies/turnLight.ies", intensityScale = 1 }
RealLight.DEFAULT_LIGHT_PROFILE.reverselight = { iesProfile = "data/shared/ies/workLight.ies", intensityScale = 1.25 }
local RealLight_mt = Class(RealLight)
function RealLight.new(vehicle, customMt)
	local self = setmetatable({}, customMt or RealLight_mt)
	self.vehicle = vehicle
	self.chargeFunction = nil
	return self
end
function RealLight:loadFromXML(xmlFile, baseKey, components, i3dMappings, loadLightTypes)
	self.node = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings)
	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing light source node in '%s'", baseKey)
		return false
	elseif not getHasClassId(self.node, ClassIds.LIGHT_SOURCE) then
		Logging.xmlWarning(xmlFile, "Defined node is not a light source '%s'", baseKey)
		return false
	else
		self.lightSources = { self.node }
		I3DUtil.iterateRecursively(self.node, function(childNode)
			if not getVisibility(childNode) then
				Logging.xmlWarning(xmlFile, "Real light source '%s' is hidden in '%s'!", getName(childNode), baseKey)
			end
			if getHasClassId(childNode, ClassIds.LIGHT_SOURCE) then
				table.insert(self.lightSources, childNode)
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
		local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
		local xmlIESProfile = xmlFile:getValue(baseKey .. "#iesProfile")
		if xmlIESProfile ~= nil then
			self.xmlIESProfile = Utils.getFilename(xmlIESProfile, self.vehicle.baseDirectory)
		else
			local iesProfile = getLightIESProfile(self.lightSources[1])
			if iesProfile ~= "" then
				self.xmlIESProfile = iesProfile
			end
		end
		self.useLightScattering = xmlFile:getValue(baseKey .. "#useLightScattering")
		self:updateIESProfile(lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_ULTRA)
		self:updateLightScattering()
		self.hasMergedShadows = false
		self.hasShadows = xmlFile:getValue(baseKey .. "#hasShadows", 7.5 < getLightRange(self.node))
		if self.hasShadows and 1 < #self.lightSources then
			local shadowLightOffset = xmlFile:getValue(baseKey .. "#shadowLightOffset", nil, true)
			local x = 0
			local y = 0
			local z = 0
			local tx = 0
			local ty = 0
			local tz = 0
			local maxLightRange = 0
			local maxConeAngle = 0
			for i, lightSource in ipairs(self.lightSources) do
				maxLightRange = math.max(maxLightRange, getLightRange(lightSource))
				maxConeAngle = math.max(maxConeAngle, getLightConeAngle(lightSource))
				local _x, _y, _z = localToLocal(lightSource, getParent(self.node), 0, 0, 0)
				x = x + _x
				y = y + _y
				z = z + _z
				local _tx, _ty, _tz = localToLocal(lightSource, getParent(self.node), 0, 0, -20)
				tx = tx + _tx
				ty = ty + _ty
				tz = tz + _tz
			end
			local numLightSources = #self.lightSources
			if 1 < numLightSources then
				x = x / numLightSources
				y = y / numLightSources
				z = z / numLightSources
				tx = tx / numLightSources
				ty = ty / numLightSources
				tz = tz / numLightSources
			end
			self.shadowLightSource = createLightSource(getName(self.node) .. "_shadow", LightType.SPOT, 0.85, 0.85, 1, maxLightRange)
			setLightConeAngle(self.shadowLightSource, math.max(maxConeAngle, RealLight.getMergedConeAngleSize(self.lightSources)))
			setLightShadowMap(self.shadowLightSource, true, 512)
			setVisibility(self.shadowLightSource, false)
			link(getParent(self.node), self.shadowLightSource)
			setTranslation(self.shadowLightSource, x, y, z)
			setLightSoftShadowSize(self.shadowLightSource, 0.008)
			setLightSoftShadowDistance(self.shadowLightSource, 15)
			setLightSoftShadowDepthBiasFactor(self.shadowLightSource, 0.02)
			local dx, dy, dz = MathUtil.vector3Normalize(tx - x, ty - y, tz - z)
			setDirection(self.shadowLightSource, -dx, -dy, -dz, 0, 1, 0)
			if shadowLightOffset ~= nil then
				local ox, oy, oz = localToLocal(self.shadowLightSource, getParent(self.shadowLightSource), shadowLightOffset[1], shadowLightOffset[2], -shadowLightOffset[3])
				setTranslation(self.shadowLightSource, ox, oy, oz)
			end
			for i, lightSource in ipairs(self.lightSources) do
				setLightShadowMap(lightSource, true, 512)
			end
		end
		if xmlFile:getRootName() == "vehicle" then
			self.vehicle:loadAdditionalLightAttributesFromXML(xmlFile, baseKey, self)
		end
		return true
	end
end
function RealLight:merge(otherLight)
	for i, lightType in ipairs(self.lightTypes) do
		table.addElement(otherLight.lightTypes, lightType)
	end
	for i, excludedLightType in ipairs(self.excludedLightTypes) do
		table.addElement(otherLight.excludedLightTypes, excludedLightType)
	end
	return otherLight
end
function RealLight:updateIESProfile(iesEnabled)
	for i, lightSource in ipairs(self.lightSources) do
		local nodeName = string.lower(getName(lightSource))
		for searchString, profile in pairs(RealLight.DEFAULT_LIGHT_PROFILE) do
			if string.contains(nodeName, searchString) then
				if iesEnabled then
					if self.xmlIESProfile ~= nil then
						setLightIESProfile(lightSource, self.xmlIESProfile)
					else
						local iesProfile = getLightIESProfile(lightSource)
						if iesProfile == "" then
							setLightIESProfile(lightSource, profile.iesProfile)
						end
					end
				else
					local iesProfile = getLightIESProfile(lightSource)
					if iesProfile ~= "" then
						setLightIESProfile(lightSource, "")
						self.curIntensityScale = self.intensityScale
					end
				end
				self.curIntensityScale = self.intensityScale * profile.intensityScale
				break
			end
		end
	end
end
function RealLight:updateLightScattering()
	local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	local isDefaultLightOrHighBeam = false
	for i, lightType in ipairs(self.lightTypes) do
		if lightType == Lights.LIGHT_TYPE_DEFAULT or lightType == Lights.LIGHT_TYPE_HIGHBEAM then
			isDefaultLightOrHighBeam = true
		else
		end
		for i, lightSource in ipairs(self.lightSources) do
			local useLightScattering = false
			if self.useLightScattering == true then
				useLightScattering = GS_PROFILE_HIGH <= lightsProfile
			elseif self.useLightScattering == nil then
				if isDefaultLightOrHighBeam then
					useLightScattering = GS_PROFILE_HIGH <= lightsProfile
				elseif 0 < #self.lightTypes then
					useLightScattering = GS_PROFILE_VERY_HIGH <= lightsProfile
				end
				useLightScattering = useLightScattering and 7.5 < getLightRange(lightSource)
			end
			if useLightScattering then
				setLightUseLightScattering(lightSource, true)
				local coneAngle = getLightConeAngle(lightSource)
				if RealLight.SCATTERING_MAX_ANGLE < coneAngle then
					setLightScatteringConeAngle(lightSource, RealLight.SCATTERING_MAX_ANGLE)
				end
				setLightScatteringIntensity(lightSource, 1)
			elseif getLightUseLightScattering(lightSource) then
				setLightUseLightScattering(lightSource, false)
			end
		end
		return
	end
end
function RealLight:updateMergedShadows()
	if not self.hasShadows then
		return
	end
	local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	if lightsProfile == GS_PROFILE_ULTRA then
		if 1 < #self.lightSources then
			if not self.mergedShadowLightCreated then
				mergeLightShadows(table.unpack(self.lightSources))
				setMergedShadowSettingsLight(self.node, self.shadowLightSource)
				for _, component in ipairs(self.vehicle.components) do
					addMergedShadowIgnoreShapes(self.lightSources[1], component.node)
				end
				self.mergedShadowLightCreated = true
			end
			for _, lightSource in ipairs(self.lightSources) do
				setLightShadowMap(lightSource, true, 512)
				setLightShadowPriority(self.node, 1)
			end
			setMergedShadowActive(self.node, true)
		else
			setLightShadowMap(self.node, true, 512)
			setLightShadowPriority(self.node, 0.5)
			for _, component in ipairs(self.vehicle.components) do
				addLightShadowIgnoreShapes(self.lightSources[1], component.node)
			end
		end
	elseif 1 < #self.lightSources then
		setMergedShadowActive(self.node, false)
		for _, lightSource in ipairs(self.lightSources) do
			setLightShadowMap(lightSource, false, 512)
		end
	else
		setLightShadowMap(self.node, false, 512)
	end
end
function RealLight:finalize()
	self:updateMergedShadows()
end
function RealLight:onLightsProfileChanged(lightsProfile)
	self:updateIESProfile(lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_ULTRA)
	self:updateLightScattering()
	self:updateMergedShadows()
end
function RealLight:setLightTypesMask(lightsTypesMask)
	if self.vehicle:getIsLightActive(self) then
		local isActive = false
		local chargeScale = 1
		if self.lightTypes ~= nil then
			for _, lightType in pairs(self.lightTypes) do
				if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 or lightType == -1 and self.vehicle:getIsActiveForLights(true) then
					if not isActive then
						isActive = true
					elseif self.vehicle.spec_lights.maxLightState < lightType then
						chargeScale = 2
					end
				end
			end
			if isActive and self.excludedLightTypes ~= nil then
				for _, excludedLightType in pairs(self.excludedLightTypes) do
					if bit32.band(lightsTypesMask, 2 ^ excludedLightType) == 0 then
						continue
					end
					isActive = false
					if self.chargeFunction ~= nil then
						chargeScale = self.chargeFunction(self.chargeFunctionTarget)
					end
					self:setState(isActive, chargeScale)
					return
				end
			end
		else
			isActive = false
		end
	end
	self:setState(false, 0)
end
function RealLight:setIsBlinking(isBlinking) end
function RealLight:setState(isActive, chargeScale)
	self:setCharge(chargeScale)
	setVisibility(self.node, isActive)
end
function RealLight:setCharge(alpha)
	alpha = alpha * self.curIntensityScale
	local color = self.defaultColor
	for _, lightSource in ipairs(self.lightSources) do
		setLightColor(lightSource, color[1] * alpha, color[2] * alpha, color[3] * alpha)
	end
end
function RealLight:setChargeFunction(func, funcTarget)
	self.chargeFunction = func
	self.chargeFunctionTarget = funcTarget
end
function RealLight.getAreShadowsMergable(lightSources)
	for _, lightSource1 in ipairs(lightSources) do
		for _, lightSource2 in ipairs(lightSources) do
			if lightSource1 == lightSource2 then
				continue
			end
			local coneAngle = getLightConeAngle(lightSource2)
			local dx, dz = MathUtil.getDirectionFromYRotation(coneAngle * 0.5)
			local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
			local radius = math.sqrt(lx ^ 2 + ly ^ 2)
			local angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
			if 0 < lz then
				angle = 3.141592653589793 - angle
			end
			if 3.141592653589793 < angle + coneAngle * 0.5 then
				return false
			end
			dx, dz = MathUtil.getDirectionFromYRotation(-coneAngle * 0.5)
			lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
			radius = math.sqrt(lx ^ 2 + ly ^ 2)
			angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
			if 0 < lz then
				angle = 3.141592653589793 - angle
			end
			if 3.141592653589793 < angle + coneAngle * 0.5 then
				return false
			end
		end
	end
	return true
end
function RealLight.getConeAngleContribution(lightSource1, lightSource2, coneAngle, yRotation)
	local dx, dz = MathUtil.getDirectionFromYRotation(yRotation)
	local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
	local radius = math.sqrt(lx ^ 2 + ly ^ 2)
	local magnitude = math.sqrt(math.abs(lz) ^ 2 + radius ^ 2)
	if magnitude == 0 then
		return coneAngle * 0.5
	else
		local angle = math.acos(math.abs(lz) / magnitude)
		if 0 < lz then
			angle = 3.141592653589793 - angle
		end
		return angle + coneAngle * 0.5
	end
end
function RealLight.getMergedConeAngleSize(lightSources)
	local mergedConeAngle = 0
	for _, lightSource1 in ipairs(lightSources) do
		for _, lightSource2 in ipairs(lightSources) do
			if lightSource1 == lightSource2 then
				continue
			end
			local coneAngle = getLightConeAngle(lightSource2)
			local positiveEdge = RealLight.getConeAngleContribution(lightSource1, lightSource2, coneAngle, coneAngle * 0.5)
			mergedConeAngle = math.max(mergedConeAngle, positiveEdge)
			local negativeEdge = RealLight.getConeAngleContribution(lightSource1, lightSource2, coneAngle, -coneAngle * 0.5)
			mergedConeAngle = math.max(mergedConeAngle, negativeEdge)
		end
	end
	return mergedConeAngle
end
function RealLight.loadLightsFromXML(lights, xmlFile, baseKey, vehicle, components, i3dMappings, loadLightTypes)
	if lights == nil then
		lights = {}
	end
	for _, key in xmlFile:iterator(baseKey) do
		local light = RealLight.new(vehicle)
		if light:loadFromXML(xmlFile, key, components, i3dMappings, loadLightTypes) then
			local otherLight = vehicle:getRealLightFromNode(light.node)
			if otherLight ~= nil then
				light = light:merge(otherLight)
			end
			table.insert(lights, light)
		end
	end
	return lights
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
function RealLight.consoleCommandDebugIES(_, enabled)
	if RealLight.IES_DEBUG_ENABLED == nil then
		local performanceClass = Utils.getPerformanceClassId()
		RealLight.IES_DEBUG_ENABLED = performanceClass == GS_PROFILE_VERY_HIGH or performanceClass == GS_PROFILE_ULTRA
	end
	if enabled ~= nil then
		enabled = enabled == "true"
	else
		enabled = not RealLight.IES_DEBUG_ENABLED
	end
	RealLight.IES_DEBUG_ENABLED = enabled
	if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
		local vehicle = g_localPlayer:getCurrentVehicle()
		for i = 1, #vehicle.childVehicles do
			local childVehicle = vehicle.childVehicles[i]
			Logging.info("IES Profiles Enabled: '%s' on '%s'", enabled, vehicle:getFullName())
			if childVehicle.spec_lights == nil then
				continue
			end
			for _, profile in pairs(childVehicle.spec_lights.realLights) do
				for _, lights in pairs(profile) do
					for _, realLight in ipairs(lights) do
						realLight:updateIESProfile(enabled)
					end
				end
			end
		end
	end
end
addConsoleCommand("gsVehicleDebugLightIESProfiles", "Enables and disables IES profiles on the light source (only the automatically assigned profiles)", "RealLight.consoleCommandDebugIES", nil)
