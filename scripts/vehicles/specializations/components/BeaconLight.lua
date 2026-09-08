-- Local values: BeaconLight_mt
BeaconLight = {}
BeaconLight.LIGHT_TYPE_BITMASK = 8
local BeaconLight_mt = Class(BeaconLight)

-- Upvalues: BeaconLight_mt
-- Local values: self
function BeaconLight.new(vehicle, customMt)
	-- upvalues: (copy) BeaconLight_mt
	local v4_ = customMt or BeaconLight_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.components = {}
	v5_.i3dMappings = {}
	v5_.staticLights = {}
	v5_.speed = 1
	v5_.realLightRangeScale = 1
	v5_.intensity = 1
	v5_.lastCameraDistance = 0
	v5_.requiresDirtyUpdate = false
	v5_.hasDynamicStaticLights = false
	v5_.isActive = false
	v5_.realLightActive = false
	return v5_
end

function BeaconLight:delete()
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	g_currentMission:removeUpdateable(self)
end

function BeaconLight:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end

-- Local values: xmlFilename, linkNode, isReference, _, runtimeLoaded, speed, realLight, useRealLights, realLightRangeScale, intensity, mountType, variationName, beaconLight, hasDynamicStaticLights, staticLights, _, staticLightKey, staticLight, speed, intensity, realLight, realLightRangeScale, beaconLight
function BeaconLight.loadFromVehicleXML(targetTable, xmlFile, key, vehicle)
	local v14_ = xmlFile:getValue(key .. "#filename", nil, vehicle.baseDirectory)
	if v14_ == nil then
		local v15_ = false
		local v16_ = {}
		for _, v17_ in xmlFile:iterator(key .. ".staticLight") do
			local v18_ = {
				["node"] = xmlFile:getValue(v17_ .. "#node", nil, vehicle.components, vehicle.i3dMappings)
			}
			if v18_.node ~= nil then
				v18_.intensity = xmlFile:getValue(v17_ .. "#intensity", 1)
				v18_.multiBlink = xmlFile:getValue(v17_ .. "#multiBlink", false)
				v18_.multiBlinkParameters = xmlFile:getValue(v17_ .. "#multiBlinkParameters", "2 5 50 0", true)
				v18_.uvOffsetParameter = xmlFile:getValue(v17_ .. "#uvOffsetParameter", 0)
				v18_.minDistance = xmlFile:getValue(v17_ .. "#minDistance", 0)
				v18_.intensityScaleMinDistance = xmlFile:getValue(v17_ .. ".intensityScale#minDistance")
				v18_.intensityScaleMinIntensity = xmlFile:getValue(v17_ .. ".intensityScale#minIntensity")
				v18_.intensityScaleMaxDistance = xmlFile:getValue(v17_ .. ".intensityScale#maxDistance")
				v18_.intensityScaleMaxIntensity = xmlFile:getValue(v17_ .. ".intensityScale#maxIntensity")
				local v19_
				if v18_.intensityScaleMinDistance == nil or (v18_.intensityScaleMinIntensity == nil or v18_.intensityScaleMaxDistance == nil) then
					v19_ = false
				else
					v19_ = v18_.intensityScaleMaxIntensity ~= nil
				end
				v18_.hasDynamicIntensity = v19_
				v15_ = v15_ or (v18_.hasDynamicIntensity or v18_.minDistance > 0)
				table.insert(v16_, v18_)
			end
		end
		if v16_ ~= nil and #v16_ > 0 then
			local v20_ = xmlFile:getValue(key .. "#speed")
			local v21_ = xmlFile:getValue(key .. "#intensity", 1)
			local v22_ = xmlFile:getValue(key .. "#realLight", nil, vehicle.components, vehicle.i3dMappings)
			local v23_ = xmlFile:getValue(key .. "#realLightRange", 1)
			local v24_ = BeaconLight.new(vehicle)
			v24_:setXMLSettings(v20_, v21_, nil, nil)
			v24_:setRealLight(true, v22_, v23_)
			v24_.staticLights = v16_
			v24_.hasStaticLights = true
			v24_.hasDynamicStaticLights = v15_
			v24_:onFinished(true)
			table.insert(targetTable, v24_)
			return v24_
		end
	else
		local v25_ = xmlFile:getValue(key .. "#node", nil, vehicle.components, vehicle.i3dMappings)
		if v25_ ~= nil then
			local v26_, _, v27_ = getReferenceInfo(v25_)
			if not (v26_ and v27_) then
				local v28_ = xmlFile:getValue(key .. "#speed")
				local v29_ = xmlFile:getValue(key .. "#realLight", nil, vehicle.components, vehicle.i3dMappings)
				local v30_ = xmlFile:getValue(key .. "#useRealLights", v29_ == nil)
				local v31_ = xmlFile:getValue(key .. "#realLightRange", 1)
				local v32_ = xmlFile:getValue(key .. "#intensity", 1)
				local v33_ = xmlFile:getValue(key .. "#mountType")
				local v34_ = xmlFile:getValue(key .. "#variationName")
				local v_u_35_ = BeaconLight.new(vehicle)
				v_u_35_:setXMLSettings(v28_, v32_, v33_, v34_)
				v_u_35_:setRealLight(v30_, v29_, v31_)
				v_u_35_:setCallback(function(p36_)
					-- upvalues: (copy) targetTable, (copy) v_u_35_
					if p36_ then
						local v37_ = targetTable
						local v38_ = v_u_35_
						table.insert(v37_, v38_)
					end
				end)
				v_u_35_:loadFromXML(v25_, v14_, vehicle.baseDirectory)
				return v_u_35_
			end
			Logging.xmlWarning(xmlFile, "Beacon light link node \'%s\' is a runtime loaded reference, please load beacon lights only via XML!", getName(v25_))
			return
		end
		Logging.xmlWarning(xmlFile, "Missing link node for beacon light in \'%s\'", key)
	end
	return nil
end

function BeaconLight:setXMLSettings(speed, intensity, mountType, variationName)
	self.speed = speed or self.speed
	self.intensity = intensity or self.intensity
	self.mountType = mountType
	self.variationName = variationName
end

function BeaconLight:setRealLight(useRealLights, customRealLight, realLightRangeScale)
	self.useRealLights = Utils.getNoNil(useRealLights, self.useRealLights)
	self.customRealLight = customRealLight
	self.realLightRangeScale = realLightRangeScale or self.realLightRangeScale
end

-- Local values: filename
function BeaconLight:loadFromXML(linkNode, xmlFilename, baseDirectory)
	self.xmlFile = XMLFile.loadIfExists("BeaconLight", xmlFilename, BeaconLight.xmlSchema)
	if self.xmlFile == nil then
		if self.vehicle == nil then
			Logging.warning("Unable to load shared lights from xml \'%s\'", xmlFilename)
		else
			Logging.xmlWarning(self.vehicle.xmlFile, "Unable to load shared lights from xml \'%s\'", xmlFilename)
		end
		self:onFinished(false)
		return false
	end
	local v52_ = self.xmlFile:getValue("beaconLight.filename")
	if v52_ ~= nil then
		self.filename = Utils.getFilename(v52_, baseDirectory)
		self.linkNode = linkNode
		if self.vehicle == nil then
			self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, nil)
		else
			self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, nil)
		end
		return true
	end
	Logging.xmlWarning(self.xmlFile, "Missing light i3d filename!")
	self.xmlFile:delete()
	self.xmlFile = nil
	self:onFinished(false)
	return false
end

-- Local values: variationKey, _variationIndex, _variationKey, name, node, yOffset, mountTypeIndex, mountTypeKey, name, node, node, _
function BeaconLight:onI3DLoaded(i3dNode, failedReason, args)
	if self.vehicle == nil or not self.vehicle.isDeleted then
		if i3dNode ~= 0 then
			I3DUtil.loadI3DComponents(i3dNode, self.components)
			I3DUtil.loadI3DMapping(self.xmlFile, "beaconLight", self.components, self.i3dMappings)
			self.node = self.xmlFile:getValue("beaconLight.rootNode#node", "0", self.components, self.i3dMappings)
			if self.node ~= nil then
				self.nodesToRemove = {}
				self.variationRootNode = nil
				local v55_ = nil
				for v56_, v57_ in self.xmlFile:iterator("beaconLight.variations.variation") do
					local v58_ = self.xmlFile:getValue(v57_ .. "#name")
					if v58_ ~= nil then
						if self.variationName == nil and v56_ == 1 or self.variationName ~= nil and string.lower(v58_) == string.lower(self.variationName) then
							self.variationRootNode = self.xmlFile:getValue(v57_ .. "#rootNode", nil, self.components, self.i3dMappings)
							v55_ = v57_
						else
							local v59_ = self.xmlFile:getValue(v57_ .. "#rootNode", nil, self.components, self.i3dMappings)
							if v59_ ~= nil then
								self.nodesToRemove[v59_] = true
							end
						end
					end
				end
				self:loadVariationFromXML(self.xmlFile, "beaconLight")
				if v55_ ~= nil then
					self:loadVariationFromXML(self.xmlFile, v55_)
				end
				local v60_ = 0
				for v61_, v62_ in self.xmlFile:iterator("beaconLight.mountTypes.mountType") do
					local v63_ = self.xmlFile:getValue(v62_ .. "#name")
					if v63_ ~= nil then
						local v64_ = self.xmlFile:getValue(v62_ .. "#node", nil, self.components, self.i3dMappings)
						if self.mountType == nil and v61_ == 1 or self.mountType ~= nil and string.lower(v63_) == string.lower(self.mountType) then
							v60_ = self.xmlFile:getValue(v62_ .. "#yOffset", 0)
							if v64_ ~= nil then
								setVisibility(v64_, true)
							end
						elseif v64_ ~= nil then
							self.nodesToRemove[v64_] = true
						end
					end
				end
				for v65_, _ in pairs(self.nodesToRemove) do
					if v65_ ~= self.variationRootNode then
						delete(v65_)
					end
				end
				self.nodesToRemove = nil
				link(self.linkNode, self.node)
				setTranslation(self.node, 0, v60_, 0)
			end
			delete(i3dNode)
		end
		self.xmlFile:delete()
		self.xmlFile = nil
		local v66_
		if self.node == nil then
			v66_ = false
		else
			v66_ = self.hasStaticLights
		end
		self:onFinished(v66_)
	end
end

-- Local values: _, staticLight
function BeaconLight:onFinished(success)
	for _, v69_ in ipairs(self.staticLights) do
		v69_.useLightControlShaderParameter = getHasShaderParameter(v69_.node, "lightControl")
		if v69_.useLightControlShaderParameter then
			setShaderParameter(v69_.node, "lightControl", 0, nil, nil, nil, false)
		else
			setShaderParameter(v69_.node, "lightIds0", 0, 0, 0, 0, false)
			setShaderParameter(v69_.node, "lightIds1", 0, 0, 0, 0, false)
			setShaderParameter(v69_.node, "lightTypeBitMask", BeaconLight.LIGHT_TYPE_BITMASK, 0, 0, 0, false)
			setShaderParameter(v69_.node, "lightUvOffsetBitMask", v69_.uvOffsetParameter, 0, 0, 0, false)
		end
		setShaderParameter(v69_.node, "blinkMulti", v69_.multiBlinkParameters[1], v69_.multiBlinkParameters[2], v69_.multiBlinkParameters[3], v69_.multiBlinkParameters[4], false)
		if v69_.multiBlink or (v69_.minDistance > 0 or v69_.hasDynamicIntensity) then
			self.requiresDirtyUpdate = true
		end
	end
	if self.speed > 0 and self.rotatorNode ~= nil then
		setRotation(self.rotatorNode, 0, math.random(0, 6.283185307179586), 0)
		self.requiresDirtyUpdate = true
	end
	if (not self.useRealLights or self.customRealLight ~= nil) and self.realLightNode ~= nil then
		delete(self.realLightNode)
		self.realLightNode = nil
	end
	if self.customRealLight ~= nil then
		self.realLightNode = self.customRealLight
	end
	if self.realLightNode ~= nil then
		self.defaultColor = { getLightColor(self.realLightNode) }
		setVisibility(self.realLightNode, false)
		self.defaultLightRange = getLightRange(self.realLightNode)
		setLightRange(self.realLightNode, self.defaultLightRange * self.realLightRangeScale)
		setLightShadowPriority(self.realLightNode, 0.25)
	end
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, success)
			return
		end
		self.callback(success)
	end
end

-- Local values: _, staticLightKey, staticLight, baseDirectory, customEnvironment, material
function BeaconLight:loadVariationFromXML(xmlFile, key)
	self.rotatorNode = xmlFile:getValue(key .. ".rotator#node", self.rotatorNode, self.components, self.i3dMappings)
	self.speed = xmlFile:getValue(key .. ".rotator#speed", self.speed or 0.015)
	self.realLightNode = xmlFile:getValue(key .. ".realLight#node", self.realLightNode, self.components, self.i3dMappings)
	if self.realLightNode ~= nil and not getHasClassId(self.realLightNode, ClassIds.LIGHT_SOURCE) then
		Logging.xmlWarning(xmlFile, "Node \'%s\' defined as light source for beacon light, but is not a light source!", getName(self.realLightNode))
		self.realLightNode = nil
	end
	if not xmlFile:getValue(key .. ".realLight#useRealLight", true) and self.realLightNode ~= nil then
		delete(self.realLightNode)
		self.realLightNode = nil
	end
	for _, v73_ in xmlFile:iterator(key .. ".staticLight") do
		local v74_ = {
			["node"] = xmlFile:getValue(v73_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v74_.node ~= nil then
			if v74_.node == nil or getHasClassId(v74_.node, ClassIds.SHAPE) then
				v74_.intensity = xmlFile:getValue(v73_ .. "#intensity", 1)
				v74_.multiBlink = xmlFile:getValue(v73_ .. "#multiBlink", false)
				v74_.multiBlinkParameters = xmlFile:getValue(v73_ .. "#multiBlinkParameters", "2 5 50 0", true)
				v74_.uvOffsetParameter = xmlFile:getValue(v73_ .. "#uvOffsetParameter", 0)
				v74_.minDistance = xmlFile:getValue(v73_ .. "#minDistance", 0)
				v74_.intensityScaleMinDistance = xmlFile:getValue(v73_ .. ".intensityScale#minDistance")
				v74_.intensityScaleMinIntensity = xmlFile:getValue(v73_ .. ".intensityScale#minIntensity")
				v74_.intensityScaleMaxDistance = xmlFile:getValue(v73_ .. ".intensityScale#maxDistance")
				v74_.intensityScaleMaxIntensity = xmlFile:getValue(v73_ .. ".intensityScale#maxIntensity")
				local v75_
				if v74_.intensityScaleMinDistance == nil or (v74_.intensityScaleMinIntensity == nil or v74_.intensityScaleMaxDistance == nil) then
					v75_ = false
				else
					v75_ = v74_.intensityScaleMaxIntensity ~= nil
				end
				v74_.hasDynamicIntensity = v75_
				self.hasDynamicStaticLights = self.hasDynamicStaticLights or (v74_.hasDynamicIntensity or v74_.minDistance > 0)
				local v76_ = self.staticLights
				table.insert(v76_, v74_)
			else
				Logging.xmlWarning(xmlFile, "Node \'%s\' defined as shader node for beacon light, but is not a shape!", getName(v74_.node))
			end
		end
	end
	self.hasStaticLights = #self.staticLights > 0
	self.device = BeaconLightManager.loadDeviceFromXML(xmlFile, key .. ".device") or self.device
	if xmlFile:hasProperty(key .. ".material") then
		local v77_, v78_
		if self.vehicle == nil then
			v77_ = ""
			v78_ = ""
		else
			v77_ = self.vehicle.baseDirectory
			v78_ = self.vehicle.customEnvironment
		end
		local v79_ = VehicleMaterial.new(v77_)
		if v79_:loadFromXML(xmlFile, key .. ".material", v78_) then
			v79_:apply(self.node)
		end
	end
end

-- Local values: staticLight, blink, pause, freq, timeOffset, mTime, alpha, r, g, b, numChildren, i, cameraDistance, _, staticLight, alpha, value
function BeaconLight:update(dt)
	if self.rotatorNode ~= nil then
		rotate(self.rotatorNode, 0, self.speed * dt, 0)
	end
	if self.realLightActive and (self.hasStaticLights and self.staticLights[1].multiBlink) then
		local v82_ = self.staticLights[1]
		local v83_ = v82_.multiBlinkParameters[1]
		local v84_ = v82_.multiBlinkParameters[2]
		local v85_ = v82_.multiBlinkParameters[3]
		local v86_ = v82_.multiBlinkParameters[4]
		local v87_ = getShaderTimeSec() * v85_ + v86_
		local v88_ = math.sin(v87_)
		local v89_ = v87_ % ((v83_ * 2 + v84_ * 2) * 3.141592653589793) - (v83_ * 2 - 1) * 3.141592653589793
		local v90_ = v88_ - math.max(v89_, 0) + 0.2
		local v91_ = math.clamp(v90_, 0, 1)
		local v92_ = self.defaultColor[1]
		local v93_ = self.defaultColor[2]
		local v94_ = self.defaultColor[3]
		setLightColor(self.realLightNode, v92_ * v91_, v93_ * v91_, v94_ * v91_)
		for v95_ = 0, getNumOfChildren(self.realLightNode) - 1 do
			setLightColor(getChildAt(self.realLightNode, v95_), v92_ * v91_, v93_ * v91_, v94_ * v91_)
		end
	end
	if self.hasDynamicStaticLights then
		local v96_ = self.node == nil and 0 or calcDistanceFrom(self.node, g_cameraManager:getActiveCamera())
		local v97_ = self.lastCameraDistance - v96_
		if math.abs(v97_) > 1 then
			for _, v98_ in ipairs(self.staticLights) do
				if v98_.hasDynamicIntensity then
					local v99_ = (v96_ - v98_.intensityScaleMinDistance) / (v98_.intensityScaleMaxDistance - v98_.intensityScaleMinDistance)
					local v100_ = math.max(v99_, 0)
					local v101_ = math.min(v100_, 1)
					local v102_ = (v98_.intensityScaleMinIntensity + (v98_.intensityScaleMaxIntensity - v98_.intensityScaleMinIntensity) * v101_) * self.intensity
					if v98_.useLightControlShaderParameter then
						setShaderParameter(v98_.node, "lightControl", v102_, nil, nil, nil, false)
					else
						setShaderParameter(v98_.node, "lightIds0", v102_, v102_, 0, 0, false)
					end
				end
				if v98_.minDistance > 0 then
					setVisibility(v98_.node, v98_.minDistance <= v96_)
				end
			end
			self.lastCameraDistance = v96_
		end
	end
end

-- Local values: _, staticLight, value, alpha
function BeaconLight:setIsActive(isActive)
	if self.requiresDirtyUpdate then
		if isActive then
			g_currentMission:addUpdateable(self)
		else
			g_currentMission:removeUpdateable(self)
		end
	end
	if self.realLightNode ~= nil then
		if g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHTS) then
			self.realLightActive = isActive
		else
			self.realLightActive = false
		end
		setVisibility(self.realLightNode, self.realLightActive)
	end
	if self.node ~= nil and isActive then
		self.lastCameraDistance = calcDistanceFrom(self.node, g_cameraManager:getActiveCamera())
	end
	for _, v105_ in ipairs(self.staticLights) do
		local v106_ = isActive and (v105_.intensity or 0) or 0
		if isActive and v105_.hasDynamicIntensity then
			local v107_ = (self.lastCameraDistance - v105_.intensityScaleMinDistance) / (v105_.intensityScaleMaxDistance - v105_.intensityScaleMinDistance)
			local v108_ = math.max(v107_, 0)
			local v109_ = math.min(v108_, 1)
			v106_ = v105_.intensityScaleMinIntensity + (v105_.intensityScaleMaxIntensity - v105_.intensityScaleMinIntensity) * v109_
		end
		local v110_ = v106_ * self.intensity
		if v105_.useLightControlShaderParameter then
			setShaderParameter(v105_.node, "lightControl", v110_, nil, nil, nil, false)
		else
			setShaderParameter(v105_.node, "lightIds0", v110_, v110_, 0, 0, false)
		end
		if v105_.minDistance > 0 then
			if isActive then
				setVisibility(v105_.node, self.lastCameraDistance >= v105_.minDistance)
			else
				setVisibility(v105_.node, false)
			end
		end
	end
	self.isActive = isActive
end

-- Local values: device
function BeaconLight:setDeviceIsActive(isActive)
	local v113_ = self.device
	if v113_ ~= nil then
		if isActive then
			if v113_.deviceId == nil then
				v113_.deviceId = g_beaconLightManager:activateBeaconLight(v113_.mode, v113_.numLEDScale, v113_.rpm, v113_.brightnessScale)
				return
			end
		elseif v113_.deviceId ~= nil then
			g_beaconLightManager:deactivateBeaconLight(v113_.deviceId)
			v113_.deviceId = nil
		end
	end
end

function BeaconLight:onLightsRealBeaconLightChanged()
	if self.realLightNode ~= nil then
		if self.isActive and not g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHTS) then
			self.realLightActive = false
		else
			self.realLightActive = self.isActive
		end
		setVisibility(self.realLightNode, self.realLightActive)
	end
end

-- Local values: files, _, beaconLight, x, y, z, numLightsToLoad, numLightsToLoadTotal, numLightsSuccess, numLightsFailed, _, file, filename, tempXMLFile, _, mountTypeKey, mountType, _, variationKey, variationName, linkNode, beaconLight, wx, wy, wz, rx, ry, rz
function BeaconLight.spawnDebugBeacons(rootNode)
	local v116_ = Files.getFilesRecursive("data/shared/assets/beaconLights")
	table.sort(v116_, function(p117_, p118_)
		return p117_.path < p118_.path
	end)
	if BeaconLight.debugBeaconLights ~= nil then
		for _, v119_ in ipairs(BeaconLight.debugBeaconLights) do
			v119_:delete()
		end
	end
	BeaconLight.debugBeaconLights = {}
	local v120_ = -1
	local v121_ = 0
	local v122_ = 0
	local v_u_123_ = 0
	local v_u_124_ = 0
	for _, v125_ in ipairs(v116_) do
		if not v125_.isDirectory and v125_.filename:contains(".xml") then
			v120_ = v120_ - 2
			local v126_ = 0
			local v127_ = string.gsub(v125_.path, getAppBasePath(), "")
			local v128_ = XMLFile.loadIfExists("BeaconLight", v127_, BeaconLight.xmlSchema)
			if v128_ ~= nil then
				for _, v129_ in v128_:iterator("beaconLight.mountTypes.mountType") do
					local v130_ = v128_:getValue(v129_ .. "#name")
					for _, v131_ in v128_:iterator("beaconLight.variations.variation") do
						local v132_ = v128_:getValue(v131_ .. "#name")
						local v_u_133_ = v121_ + 1
						local v_u_134_ = v122_ + 1
						v126_ = v126_ + 1
						local v135_ = createTransformGroup("linkNode")
						link(rootNode, v135_)
						setTranslation(v135_, v120_, 1, v126_)
						setRotation(v135_, 0, 3.141592653589793, 0)
						local v_u_136_ = BeaconLight.new(nil)
						v_u_136_:setXMLSettings(nil, nil, v130_, v132_)
						v_u_136_:setRealLight(false)
						v_u_136_:setCallback(function(p137_)
							-- upvalues: (ref) v_u_133_, (ref) v_u_123_, (copy) v_u_136_, (ref) v_u_124_, (ref) v_u_134_
							v_u_133_ = v_u_133_ - 1
							if p137_ then
								v_u_123_ = v_u_123_ + 1
								local v138_ = BeaconLight.debugBeaconLights
								local v139_ = v_u_136_
								table.insert(v138_, v139_)
							else
								v_u_136_:delete()
								v_u_124_ = v_u_124_ + 1
							end
							if v_u_133_ == 0 then
								for _, v140_ in ipairs(BeaconLight.debugBeaconLights) do
									v140_:setIsActive(true)
								end
								Logging.info("%d Beacon lights: %d loaded, %d failed to load", v_u_134_, v_u_123_, v_u_124_)
							end
						end)
						if v_u_136_:loadFromXML(v135_, v127_, "") then
							local v141_, v142_, v143_ = localToWorld(v135_, 0, 0, -0.2)
							local v144_, v145_, v146_ = localRotationToWorld(v135_, -1.5707963267948966, 0, 0)
							g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v141_, v142_, v143_, v144_, v145_, v146_, string.format("%s (%s, %s)", v125_.filename, v130_, v132_), 0.07), nil, nil, math.huge)
							g_debugManager:addElement(DebugGizmo.new():createWithNode(v135_, "", nil, nil, 0.1), nil, nil, math.huge)
							v122_ = v_u_134_
							v121_ = v_u_133_
						else
							v122_ = v_u_134_
							v121_ = v_u_133_
						end
					end
				end
				v128_:delete()
			end
		end
	end
end

function BeaconLight.registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "beaconLight.filename", "Path to i3d file", nil, true)
	schema:register(XMLValueType.NODE_INDEX, "beaconLight.rootNode#node", "Root node")
	schema:register(XMLValueType.STRING, "beaconLight.mountTypes.mountType(?)#name", "Name of the mount type")
	schema:register(XMLValueType.NODE_INDEX, "beaconLight.mountTypes.mountType(?)#node", "Node to show while this mount type is used")
	schema:register(XMLValueType.FLOAT, "beaconLight.mountTypes.mountType(?)#yOffset", "Y translation offset of the while beacon light while this mount type is used", 0)
	BeaconLight.registerVariationPaths(schema, "beaconLight")
	schema:register(XMLValueType.STRING, "beaconLight.variations.variation(?)#name", "Name of the variation")
	schema:register(XMLValueType.NODE_INDEX, "beaconLight.variations.variation(?)#rootNode", "Node that contains the variation data. Will be deleted if not used.")
	BeaconLight.registerVariationPaths(schema, "beaconLight.variations.variation(?)")
	I3DUtil.registerI3dMappingXMLPaths(schema, "beaconLight")
end

function BeaconLight.registerVariationPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rotator#node", "Node that is rotating")
	schema:register(XMLValueType.FLOAT, basePath .. ".rotator#speed", "Rotating speed", 0.015)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".staticLight(?)#node", "Light control shader node")
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#intensity", "Light intensity of shader node", 100)
	schema:register(XMLValueType.BOOL, basePath .. ".staticLight(?)#multiBlink", "Uses multiblink functionality", false)
	schema:register(XMLValueType.VECTOR_4, basePath .. ".staticLight(?)#multiBlinkParameters", "Parameters for multi blink function (blink ticks, pause ticks, frequency)", "2 5 50 0")
	schema:register(XMLValueType.INT, basePath .. ".staticLight(?)#uvOffsetParameter", "Parameter for light UV offset bit mask", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#minDistance", "Starting from this camera distance to static light is visible", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minDistance", "Reference distance for default intensity")
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minIntensity", "Intensity to be used at min. distance")
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxDistance", "Reference distance for max intensity")
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxIntensity", "Intensity to be used at max. distance")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".realLight#node", "Real light source node")
	schema:register(XMLValueType.BOOL, basePath .. ".realLight#useRealLight", "Defines if the real light is used at all for this variation", true)
	VehicleMaterial.registerXMLPaths(schema, basePath .. ".material")
	BeaconLightManager.registerXMLPaths(schema, basePath .. ".device")
end

function BeaconLight.registerVehicleXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Link node")
	schema:register(XMLValueType.FILENAME, basePath .. "#filename", "Beacon light xml file")
	schema:register(XMLValueType.FLOAT, basePath .. "#speed", "Beacon light speed override")
	schema:register(XMLValueType.BOOL, basePath .. "#useRealLights", "Use the real lights from the external beacon light file", true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#realLight", "Custom real light to be used from the vehicle file instead of the external beacon light file")
	schema:register(XMLValueType.FLOAT, basePath .. "#realLightRange", "Factor that is applied on real light range of the beacon light", 1)
	schema:register(XMLValueType.INT, basePath .. "#intensity", "Beacon light intensity scale", 1)
	schema:register(XMLValueType.STRING, basePath .. "#mountType", "Name of the mount type to use (SURFACE or POLE for most of the beacon lights)")
	schema:register(XMLValueType.STRING, basePath .. "#variationName", "Name of the variation to use (ROTATE or BLINK for most of the beacon lights)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".staticLight(?)#node", "Static light node inside the vehicle i3d file")
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#intensity", "Intensity of this static light node", 100)
	schema:register(XMLValueType.BOOL, basePath .. ".staticLight(?)#multiBlink", "Uses multiblink functionality", false)
	schema:register(XMLValueType.VECTOR_4, basePath .. ".staticLight(?)#multiBlinkParameters", "Parameters for multi blink function (blink ticks, pause ticks, frequency)", "2 5 50 0")
	schema:register(XMLValueType.INT, basePath .. ".staticLight(?)#uvOffsetParameter", "Parameter for light UV offset bit mask", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#minDistance", "Starting from this camera distance to static light is visible", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minDistance", "Reference distance for default intensity", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minIntensity", "Intensity to be used at min. distance", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxDistance", "Reference distance for max intensity", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxIntensity", "Intensity to be used at max. distance", 0)
end
g_xmlManager:addCreateSchemaFunction(function()
	BeaconLight.xmlSchema = XMLSchema.new("beaconLight")
end)
g_xmlManager:addInitSchemaFunction(function()
	BeaconLight.registerXMLPaths(BeaconLight.xmlSchema)
end)
