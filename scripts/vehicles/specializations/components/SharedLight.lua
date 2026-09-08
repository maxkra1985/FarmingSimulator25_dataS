-- Local values: SharedLight_mt
SharedLight = {}
SharedLight.FS22_RENAMED_LIGHTS = {
	["frontLight_01"] = "frontLight01",
	["frontLightCone_01"] = "frontLight02",
	["frontLightOval_01"] = "frontLight03",
	["frontLightOval_02"] = "frontLight04",
	["frontLightOval_03"] = "frontLight05",
	["frontLightRectangle_01"] = "frontLight06White",
	["frontLightRectangle_01Orange"] = "frontLight06Orange",
	["frontLightRectangle_02"] = "frontLight07",
	["rear2ChamberLed_01"] = "rearLight01",
	["rear2ChamberLight_02"] = "rearLight02",
	["rear2ChamberLight_03"] = "rearLight03",
	["rear2ChamberLight_04"] = "rearLight04",
	["rear2ChamberLight_05"] = "rearLight05",
	["rear2ChamberLight_06"] = "rearLight06",
	["rear2ChamberLight_07"] = "rearLight07",
	["rear3ChamberLight_01"] = "rearLight08",
	["rear3ChamberLight_02"] = "rearLight09",
	["rear3ChamberLight_03"] = "rearLight10",
	["rear3ChamberLight_04"] = "rearLight11",
	["rear3ChamberLight_05"] = "rearLight12",
	["rear4ChamberLight_01"] = "rearLight13",
	["rear4ChamberLight_02"] = "rearLight14",
	["rear5ChamberLight_01"] = "rearLight15",
	["rear5ChamberLight_02"] = "rearLight16",
	["rearLEDLight_01"] = "rearLight17",
	["rearLight_01"] = "rearLight18",
	["rearLightCircle_01Orange"] = "rearLight19Orange",
	["rearLightCircle_01Red"] = "rearLight19Red",
	["rearLightCircleLEDRed_01"] = "rearLight20",
	["rearLightCircleOrange_01"] = "rearLight21Orange",
	["rearLightCircleRed_01"] = "rearLight21Red",
	["rearLightCircleWhite_02"] = "rearLight22White",
	["rearLightCircleRed_02"] = "rearLight22Red",
	["rearLightCircleOrange_02"] = "rearLight22Orange",
	["rearLightOvalLEDWhite_01"] = "rearLight22White",
	["rearLightOvalLEDRed_01"] = "rearLight23Red",
	["rearLightOvalLEDOrange_01"] = "rearLight23Orange",
	["rearLightOvalLEDChromeWhite_01"] = "rearLight24",
	["rearLightOvalLEDRed_02"] = "rearLight25",
	["rearLightOvalWhite_01"] = "rearLight26White",
	["rearLightOvalRed_01"] = "rearLight26Red",
	["rearLightOvalOrange_01"] = "rearLight26Orange",
	["rearLightSquare_01Orange"] = "rearLight27Orange",
	["rearMultipointLight_04"] = "rearLight28",
	["rearMultipointLight_05"] = "rearLight29",
	["rearMultipointLEDLight_01"] = "rearLight30",
	["rearMultipointLight_01"] = "rearLight31",
	["rearMultipointLight_02"] = "rearLight32",
	["rearMultipointLight_03"] = "rearLight33",
	["rear3ChamberLight_06"] = "rearLight34",
	["rear3ChamberLight_07"] = "rearLight35",
	["rear2ChamberLight_01"] = "rearLight36",
	["sideMarker_01"] = "sideMarker01",
	["sideMarker_02"] = "sideMarker02",
	["sideMarker_03"] = "sideMarker03",
	["sideMarker_04"] = "sideMarker04",
	["sideMarker_05"] = "sideMarker05",
	["sideMarker_06"] = "sideMarker06",
	["sideMarker_04White"] = "sideMarker05White",
	["sideMarker_04Red"] = "sideMarker05Red",
	["sideMarker_04Orange"] = "sideMarker05Orange",
	["sideMarker_05White"] = "sideMarker06White",
	["sideMarker_05Orange"] = "sideMarker06Orange",
	["sideMarker_05Red"] = "sideMarker06Red",
	["sideMarker_06White"] = "sideMarker07White",
	["sideMarker_06Orange"] = "sideMarker07Orange",
	["sideMarker_06Red"] = "sideMarker07Red",
	["sideMarker_07White"] = "sideMarker08White",
	["sideMarker_07Orange"] = "sideMarker08Orange",
	["sideMarker_08White"] = "sideMarker09White",
	["sideMarker_08Orange"] = "sideMarker09Orange",
	["sideMarker_09White"] = "sideMarker10White",
	["sideMarker_09Orange"] = "sideMarker10Orange",
	["sideMarker_09Red"] = "sideMarker10Red",
	["sideMarker_10Orange"] = "sideMarker11Orange",
	["sideMarker_10Red"] = "sideMarker11Red",
	["sideMarker_14White"] = "sideMarker14White",
	["turnLight_01"] = "turnLight01",
	["sideMarker_09Orange_turn"] = "turnLight02",
	["rear2ChamberTurnLed_01"] = "turnLight03",
	["workingLightCircle_01"] = "workingLight01",
	["workingLightCircle_02"] = "workingLight02",
	["workingLightOval_01"] = "workingLight03",
	["workingLightOval_02"] = "workingLight04",
	["workingLightOval_03"] = "workingLight05",
	["workingLightOval_04"] = "workingLight06",
	["workingLightOval_05"] = "workingLight07",
	["workingLightSquare_01"] = "workingLight08",
	["workingLightSquare_02"] = "workingLight09",
	["workingLightSquare_03"] = "workingLight10",
	["workingLightSquare_04"] = "workingLight11",
	["rearPlateNumberLight_01"] = "plateNumberLight01",
	["hellaRear2ChamberLightLED_01_left"] = "hellaRearLight01_left",
	["hellaRear2ChamberLightLED_01_right"] = "hellaRearLight01_right",
	["hellaTurnlight_01_left"] = "hellaTurnlight01_left",
	["hellaTurnlight_01_right"] = "hellaTurnlight01_right",
	["hellaWorkingLightOval_01_back"] = "hellaWorkingLight01",
	["hellaWorkingLightOval_01_front"] = "hellaWorkingLight01",
	["hellaWorkingLightRound_01_back"] = "hellaWorkingLight02",
	["hellaWorkingLightRound_01_front"] = "hellaWorkingLight02",
	["hellaWorkingLightRound_02_back"] = "hellaWorkingLight03",
	["hellaWorkingLightRound_02_front"] = "hellaWorkingLight03",
	["hellaWorkingLightSquare_01_front"] = "hellaWorkingLight05",
	["hellaWorkingLightSquare_01_back"] = "hellaWorkingLight05",
	["hellaWorkingLightSquare_01_reverse"] = "hellaWorkingLight05",
	["hellaWorkingLightSquare_02_front"] = "hellaWorkingLight06",
	["hellaWorkingLightSquare_02_back"] = "hellaWorkingLight06"
}
local SharedLight_mt = Class(SharedLight)

-- Upvalues: SharedLight_mt
-- Local values: self
function SharedLight.new(vehicle, staticLights, customMt)
	-- upvalues: (copy) SharedLight_mt
	local v5_ = customMt or SharedLight_mt
	local v6_ = setmetatable({}, v5_)
	v6_.vehicle = vehicle
	v6_.staticLights = staticLights
	v6_.reverseLight = false
	v6_.turnLightLeft = false
	v6_.turnLightRight = false
	return v6_
end

function SharedLight:delete()
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
end

function SharedLight:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end

function SharedLight:onFinished(success)
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, success)
			return
		end
		self.callback(success)
	end
end

function SharedLight:setRotationNodes(rotationNodes)
	self.rotationNodes = rotationNodes
end

function SharedLight:setLightTypes(lightTypes, excludedLightTypes)
	self.lightTypes = lightTypes
	self.excludedLightTypes = excludedLightTypes
end

-- Local values: xmlFile, xmlFilename, linkNode, isReference, filename, runtimeLoaded, xmlName, i3dName, rotationNodes, _, rotKey, name, lightTypes, excludedLightTypes
function SharedLight:loadFromVehicleXML(key, baseDirectory, callback)
	local v22_ = self.vehicle.xmlFile
	local v23_ = v22_:getValue(key .. "#filename")
	if v23_ ~= nil then
		local v24_ = Utils.getFilename(v23_, baseDirectory)
		local v25_ = v22_:getValue(key .. "#linkNode", "0>", self.vehicle.components, self.vehicle.i3dMappings)
		if v25_ == nil then
			Logging.xmlWarning(v22_, "Missing light linkNode in \'%s\'!", key)
			return
		end
		local v26_, v27_, v28_ = getReferenceInfo(v25_)
		if v26_ and v28_ then
			local v29_ = Utils.getFilenameInfo(v24_, true)
			local v30_ = Utils.getFilenameInfo(v27_, true)
			if v29_ ~= v30_ then
				Logging.xmlWarning(v22_, "Shared light \'%s\' loading different file from XML compared to i3D. (XML: %s vs i3D: %s)", getName(v25_), v29_, v30_)
			end
			Logging.xmlWarning(v22_, "Shared light link node \'%s\' is a runtime loaded reference. Please load functional lights via XML and non-functional (e.g. reflectors) as i3D reference, but not both!", getName(v25_))
			return
		end
		if not getVisibility(v25_) then
			Logging.xmlWarning(v22_, "Shared light link node \'%s\' is hidden!", getName(v25_))
			return
		end
		local v31_ = {}
		for _, v32_ in v22_:iterator(key .. ".rotationNode") do
			local v33_ = v22_:getValue(v32_ .. "#name")
			if v33_ ~= nil then
				v31_[v33_] = v22_:getValue(v32_ .. "#rotation", nil, true)
			end
		end
		local v34_ = v22_:getValue(key .. "#lightTypes", nil, true)
		local v35_ = v22_:getValue(key .. "#excludedLightTypes", nil, true)
		self.reverseLight = v22_:getValue(key .. "#reverseLight", self.reverseLight)
		self.turnLightLeft = v22_:getValue(key .. "#turnLightLeft", self.turnLightLeft)
		self.turnLightRight = v22_:getValue(key .. "#turnLightRight", self.turnLightRight)
		self.functionMappingData = StaticLightCompound.loadFunctionMappingData(v22_, key)
		self.additionalAttributes = {}
		self.vehicle:loadAdditionalLightAttributesFromXML(v22_, key, self.additionalAttributes)
		self:setRotationNodes(v31_)
		self:setLightTypes(v34_, v35_)
		self:setCallback(function(p36_)
			-- upvalues: (copy) callback, (copy) self
			callback(p36_, p36_ and self or nil)
		end)
		self:loadFromXML(v25_, v24_, baseDirectory)
	end
end

-- Local values: old, new, newPath, filename
function SharedLight:loadFromXML(linkNode, xmlFilename, baseDirectory)
	self.xmlFile = XMLFile.loadIfExists("sharedLight", xmlFilename, SharedLight.xmlSchema)
	if self.xmlFile == nil then
		for v41_, v42_ in pairs(SharedLight.FS22_RENAMED_LIGHTS) do
			if xmlFilename:find(v41_) then
				local v43_ = xmlFilename:gsub(v41_, v42_)
				if fileExists(v43_) then
					if self.vehicle == nil then
						Logging.warning("Light \'%s\' has been renamed to \'%s\' in \'%s\'!", v41_, v42_)
					else
						Logging.xmlWarning(self.vehicle.xmlFile, "Light has been renamed from \'%s\' to \'%s\'!", v41_, v42_)
					end
					self:onFinished(false)
					return false
				end
			end
		end
		if self.vehicle == nil then
			Logging.warning("Unable to load shared lights from xml \'%s\'", xmlFilename)
		else
			Logging.xmlWarning(self.vehicle.xmlFile, "Unable to load shared lights from xml \'%s\'", xmlFilename)
		end
		self:onFinished(false)
		return false
	end
	local v44_ = self.xmlFile:getValue("light.filename")
	if v44_ ~= nil then
		self.filename = Utils.getFilename(v44_, baseDirectory)
		self.linkNode = linkNode
		if self.vehicle == nil or self.vehicle.loadSubSharedI3DFile == nil then
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

-- Local values: staticLightCompound, material, material
function SharedLight:onI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.node = self.xmlFile:getValue("light.rootNode#node", "0", i3dNode)
		if self.node ~= nil then
			if self.reverseLight then
				StaticLight.loadLightsFromXML(self.staticLights.reverseLights, self.xmlFile, "light.defaultLight", self.vehicle, i3dNode, nil, false, self)
			elseif self.turnLightLeft then
				StaticLight.loadLightsFromXML(self.staticLights.turnLightsLeft, self.xmlFile, "light.defaultLight", self.vehicle, i3dNode, nil, false, self)
			elseif self.turnLightRight then
				StaticLight.loadLightsFromXML(self.staticLights.turnLightsRight, self.xmlFile, "light.defaultLight", self.vehicle, i3dNode, nil, false, self)
			else
				StaticLight.loadLightsFromXML(self.staticLights.defaultLights, self.xmlFile, "light.defaultLight", self.vehicle, i3dNode, nil, true, self)
			end
			StaticLight.loadLightsFromXML(self.staticLights.topLights, self.xmlFile, "light.topLight", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.bottomLights, self.xmlFile, "light.bottomLight", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.brakeLights, self.xmlFile, "light.brakeLight", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.reverseLights, self.xmlFile, "light.reverseLight", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.dayTimeLights, self.xmlFile, "light.dayTimeLight", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.turnLightsLeft, self.xmlFile, "light.turnLightLeft", self.vehicle, i3dNode, nil, false, self)
			StaticLight.loadLightsFromXML(self.staticLights.turnLightsRight, self.xmlFile, "light.turnLightRight", self.vehicle, i3dNode, nil, false, self)
			if self.rotationNodes ~= nil then
				self.xmlFile:iterate("light.rotationNode", function(_, p47_)
					-- upvalues: (copy) self, (copy) i3dNode
					local v48_ = self.xmlFile:getValue(p47_ .. "#name")
					if v48_ ~= nil then
						local v49_ = self.xmlFile:getValue(p47_ .. "#node", nil, i3dNode)
						if self.rotationNodes[v48_] ~= nil then
							local v50_ = setRotation
							local v51_ = self.rotationNodes[v48_]
							v50_(v49_, unpack(v51_))
						end
					end
				end)
			end
			if self.xmlFile:hasProperty("light.staticLightCompound") then
				local v52_ = StaticLightCompound.new(self.vehicle)
				if v52_:loadFromXML(self.xmlFile, "light.staticLightCompound", i3dNode, nil, nil, self) then
					v52_:setLightTypes(self.lightTypes, self.excludedLightTypes)
					v52_:setOverwriteSettings(self.turnLightLeft, self.turnLightRight, self.reverseLight)
					self.staticLightCompound = v52_
				end
			end
			if self.xmlFile:hasProperty("light.baseMaterial") then
				local v53_ = VehicleMaterial.new(self.vehicle.baseDirectory)
				if v53_:loadFromXML(self.xmlFile, "light.baseMaterial", self.vehicle.customEnvironment) then
					v53_:apply(self.node, "sharedLightBase_mat")
				end
			end
			if self.xmlFile:hasProperty("light.glassMaterial") then
				local v54_ = VehicleMaterial.new(self.vehicle.baseDirectory)
				if v54_:loadFromXML(self.xmlFile, "light.glassMaterial", self.vehicle.customEnvironment) then
					v54_:apply(self.node, "sharedLightGlass_mat")
				end
			end
			link(self.linkNode, self.node)
		end
		delete(i3dNode)
	end
	self.xmlFile:delete()
	self.xmlFile = nil
	self:onFinished(self.node ~= nil)
end

-- Local values: x, y, z, dirX, dirZ, ry, _, light, dummyVehicle, spec, lightTypeMask, lightStates, bitIndex, value, files, rowIndex, rowPosition, lastBasePath, lastName, numLightsToLoad, numLightsToLoadTotal, numLightsSuccess, numLightsFailed, _, file, linkNode, name, basePath, wx, wy, wz, rx, ry, rz, x, y, z, sharedLight, filename, wx, wy, wz, rx, ry, rz
function SharedLight.consoleCommandDebug(_, defaultLight, brakeLight, highBeam, workLightBack, workLightFront, turnLightLeft, turnLeftRight, reverseLight)
	if SharedLight.debugRootNode == nil then
		SharedLight.debugRootNode = createTransformGroup("sharedLightDebugRoot")
		link(getRootNode(), SharedLight.debugRootNode)
		local v63_, v64_, v65_ = g_localPlayer:getPosition()
		local v66_, v67_ = g_localPlayer:getCurrentFacingDirection()
		local v68_ = v63_ + v66_ * 4
		local v69_ = v65_ + v67_ * 4
		local v70_ = MathUtil.getYRotationFromDirection(v66_, v67_)
		setWorldTranslation(SharedLight.debugRootNode, v68_, v64_, v69_)
		setWorldRotation(SharedLight.debugRootNode, 0, v70_, 0)
	end
	if SharedLight.debugSharedLights ~= nil then
		for _, v71_ in ipairs(SharedLight.debugSharedLights) do
			v71_:delete()
			delete(v71_.linkNode)
		end
	end
	SharedLight.debugSharedLights = {}
	SharedLight.debugStaticLights = {}
	SharedLight.debugStaticLights.defaultLights = {}
	SharedLight.debugStaticLights.topLights = {}
	SharedLight.debugStaticLights.bottomLights = {}
	SharedLight.debugStaticLights.brakeLights = {}
	SharedLight.debugStaticLights.reverseLights = {}
	SharedLight.debugStaticLights.dayTimeLights = {}
	SharedLight.debugStaticLights.turnLightsLeft = {}
	SharedLight.debugStaticLights.turnLightsRight = {}
	local v_u_72_ = {
		["getIsPowered"] = function(...)
			return true
		end,
		["getIsInShowroom"] = function(...)
			return false
		end,
		["getIsLightActive"] = function(...)
			return true
		end,
		["getIsActiveForLights"] = function(...)
			return true
		end,
		["getStaticLightFromNode"] = function(...)
			return nil
		end,
		["spec_lights"] = {}
	}
	local v_u_73_ = v_u_72_.spec_lights
	v_u_73_.topLightsVisibility = false
	v_u_73_.maxLightState = Lights.LIGHT_TYPE_HIGHBEAM
	v_u_73_.additionalLightTypes = {}
	v_u_73_.additionalLightTypes.bottomLight = v_u_73_.maxLightState + 1
	v_u_73_.additionalLightTypes.topLight = v_u_73_.maxLightState + 2
	v_u_73_.additionalLightTypes.brakeLight = v_u_73_.maxLightState + 3
	v_u_73_.additionalLightTypes.turnLightLeft = v_u_73_.maxLightState + 4
	v_u_73_.additionalLightTypes.turnLightRight = v_u_73_.maxLightState + 5
	v_u_73_.additionalLightTypes.turnLightAny = v_u_73_.maxLightState + 6
	v_u_73_.additionalLightTypes.reverseLight = v_u_73_.maxLightState + 7
	v_u_73_.additionalLightTypes.interiorLight = v_u_73_.maxLightState + 8
	local v74_ = {
		[Lights.LIGHT_TYPE_DEFAULT] = string.lower(defaultLight or "false") == "true",
		[v_u_73_.additionalLightTypes.brakeLight] = string.lower(brakeLight or "false") == "true",
		[Lights.LIGHT_TYPE_HIGHBEAM] = string.lower(highBeam or "false") == "true",
		[Lights.LIGHT_TYPE_WORK_BACK] = string.lower(workLightBack or "false") == "true",
		[Lights.LIGHT_TYPE_WORK_FRONT] = string.lower(workLightFront or "false") == "true",
		[v_u_73_.additionalLightTypes.turnLightLeft] = string.lower(turnLightLeft or "false") == "true",
		[v_u_73_.additionalLightTypes.turnLightRight] = string.lower(turnLeftRight or "false") == "true",
		[v_u_73_.additionalLightTypes.reverseLight] = string.lower(reverseLight or "false") == "true"
	}
	local v_u_75_ = 0
	for v76_, v77_ in pairs(v74_) do
		if v77_ then
			local v78_ = bit32.lshift(1, v76_)
			v_u_75_ = bit32.bor(v_u_75_, v78_)
		end
	end
	local v79_ = Files.getFilesRecursive(getAppBasePath() .. "data/shared/assets/lights")
	table.sort(v79_, function(p80_, p81_)
		return p80_.path < p81_.path
	end)
	local v_u_82_ = 0
	local v_u_83_ = 0
	local v84_ = nil
	local v85_ = nil
	local v86_ = 0
	local v_u_87_ = 0
	local v_u_88_ = 0
	local v89_ = 0
	for _, v90_ in ipairs(v79_) do
		if not v90_.isDirectory and v90_.filename:contains(".xml") then
			v_u_82_ = v_u_82_ + 1
			v_u_83_ = v_u_83_ + 1
			local v91_ = createTransformGroup("linkNode")
			link(SharedLight.debugRootNode, v91_)
			local v92_ = v90_.filename
			local v93_ = string.gsub(v92_, "White", "")
			local v94_ = string.gsub(v93_, "Orange", "")
			local v95_ = string.gsub(v94_, "Red", "")
			local v96_ = string.gsub(v95_, "Reverse", "")
			local v97_ = string.gsub(v96_, ".xml", "")
			local v98_ = string.split(v97_, "_")[1]
			local v99_ = string.gsub(v98_, "%d", "")
			local v100_ = v90_.path:split(v90_.filename)[1]
			local v101_
			if v100_ == v84_ and v99_ == v85_ then
				v99_ = v85_
				v101_ = v86_
				v100_ = v84_
			else
				v89_ = v89_ + 1
				local v102_, v103_, v104_ = localToWorld(SharedLight.debugRootNode, v89_ * 2, 1, -1)
				local v105_, v106_, v107_ = localRotationToWorld(SharedLight.debugRootNode, -1.5707963267948966, 3.141592653589793, 0)
				g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v102_, v103_, v104_, v105_, v106_, v107_, v99_, 0.15), nil, nil, math.huge)
				v101_ = 0
			end
			local v108_ = v89_ * 2
			v86_ = v101_ + 1
			setTranslation(v91_, v108_, 1, v101_)
			setRotation(v91_, 0, 3.141592653589793, 0)
			local v_u_109_ = SharedLight.new(v_u_72_, SharedLight.debugStaticLights)
			v_u_109_:setCallback(function(p110_)
				-- upvalues: (ref) v_u_82_, (ref) v_u_87_, (copy) v_u_109_, (ref) v_u_88_, (copy) v_u_72_, (copy) v_u_73_, (ref) v_u_75_, (ref) v_u_83_
				v_u_82_ = v_u_82_ - 1
				if p110_ then
					v_u_87_ = v_u_87_ + 1
					local v111_ = SharedLight.debugSharedLights
					local v112_ = v_u_109_
					table.insert(v111_, v112_)
				else
					v_u_88_ = v_u_88_ + 1
				end
				if v_u_82_ == 0 then
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.topLights, v_u_73_.additionalLightTypes.topLight)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.bottomLights, v_u_73_.additionalLightTypes.bottomLight)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.brakeLights, v_u_73_.additionalLightTypes.brakeLight)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.reverseLights, v_u_73_.additionalLightTypes.reverseLight)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.turnLightsLeft, v_u_73_.additionalLightTypes.turnLightLeft, true)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.turnLightsLeft, v_u_73_.additionalLightTypes.turnLightAny, true)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.turnLightsRight, v_u_73_.additionalLightTypes.turnLightRight, true)
					Lights.applyAdditionalActiveLightType(v_u_72_, SharedLight.debugStaticLights.turnLightsRight, v_u_73_.additionalLightTypes.turnLightAny, true)
					for _, v113_ in pairs(SharedLight.debugStaticLights) do
						for _, v114_ in ipairs(v113_) do
							v114_:setLightTypesMask(v_u_75_)
						end
					end
					for _, v115_ in ipairs(SharedLight.debugSharedLights) do
						if v115_.staticLightCompound ~= nil then
							v115_.staticLightCompound:setLightTypesMask(v_u_75_, v_u_72_)
						end
					end
					Logging.info("%d Static lights: %d loaded, %d failed to load", v_u_83_, v_u_87_, v_u_88_)
				end
			end)
			if v_u_109_:loadFromXML(v91_, string.gsub(v90_.path, getAppBasePath(), ""), "") then
				local v116_, v117_, v118_ = localToWorld(v91_, 0, 0, -0.2)
				local v119_, v120_, v121_ = localRotationToWorld(v91_, -1.5707963267948966, 0, 0)
				g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v116_, v117_, v118_, v119_, v120_, v121_, v90_.filename, 0.07), nil, nil, math.huge)
				g_debugManager:addElement(DebugGizmo.new():createWithNode(v91_, "", nil, nil, 0.1), nil, nil, math.huge)
				v85_ = v99_
				v84_ = v100_
			else
				v85_ = v99_
				v84_ = v100_
			end
		end
	end
	BeaconLight.spawnDebugBeacons(SharedLight.debugRootNode)
end

function SharedLight.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Shared light filename")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Link node", "0>")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.STRING, basePath .. ".rotationNode(?)#name", "Rotation node name")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation")
	schema:register(XMLValueType.BOOL, basePath .. "#reverseLight", "All \'defaultLight\' nodes will be used as reverse light", false)
	schema:register(XMLValueType.BOOL, basePath .. "#turnLightLeft", "All \'defaultLight\' nodes will be used as left turn light", false)
	schema:register(XMLValueType.BOOL, basePath .. "#turnLightRight", "All \'defaultLight\' nodes will be used as right turn light", false)
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#name", "Function name", nil, nil, StaticLightCompoundUVSlot.getAllOrderedByName())
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvSlotIndex", "Custom UV slot index to assign the defined function name")
	schema:register(XMLValueType.INT, basePath .. ".function(?)#uvOffset", "Vertical UV offset that is used while this light function is active (value range: 0-64 -> this represents the height of the texture with a resolution of 1/64). This is used for double usage of certain lights with different colors.", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".function(?)#intensityScale", "Custom intensity scale for this light type (is multiplied by the intensity defined in the node)")
	schema:register(XMLValueType.STRING, basePath .. ".function(?)#lightType", "Name of the light type to use", nil, nil, StaticLightCompoundLightType.getAllOrderedByName())
end

function SharedLight.registerExternalXMLPaths(schema)
	schema:register(XMLValueType.STRING, "light.filename", "Path to i3d file", nil, true)
	schema:register(XMLValueType.NODE_INDEX, "light.rootNode#node", "Node index", "0")
	StaticLight.registerXMLPaths(schema, "light.defaultLight(?)")
	StaticLight.registerXMLPaths(schema, "light.topLight(?)")
	StaticLight.registerXMLPaths(schema, "light.bottomLight(?)")
	StaticLight.registerXMLPaths(schema, "light.brakeLight(?)")
	StaticLight.registerXMLPaths(schema, "light.reverseLight(?)")
	StaticLight.registerXMLPaths(schema, "light.dayTimeLight(?)")
	StaticLight.registerXMLPaths(schema, "light.turnLightLeft(?)")
	StaticLight.registerXMLPaths(schema, "light.turnLightRight(?)")
	schema:register(XMLValueType.STRING, "light.rotationNode(?)#name", "Name for reference in vehicle xml")
	schema:register(XMLValueType.NODE_INDEX, "light.rotationNode(?)#node", "Node")
	VehicleMaterial.registerXMLPaths(schema, "light.baseMaterial")
	VehicleMaterial.registerXMLPaths(schema, "light.glassMaterial")
	StaticLightCompound.registerXMLPaths(schema, "light.staticLightCompound")
end
g_xmlManager:addCreateSchemaFunction(function()
	SharedLight.xmlSchema = XMLSchema.new("sharedLight")
end)
g_xmlManager:addInitSchemaFunction(function()
	SharedLight.registerExternalXMLPaths(SharedLight.xmlSchema)
end)
addConsoleCommand("gsVehicleDebugSharedLights", "Spawns all shared lights in front of the player", "SharedLight.consoleCommandDebug", nil, "[defaultLight]; [brakeLight]; [highBeam]; [workLightBack]; [workLightFront]; [turnLightLeft]; [turnLeftRight]; [reverseLight]")
