HandToolFlashlight = {}
source("dataS/scripts/handTools/events/FlashlightToggleLightEvent.lua")

function HandToolFlashlight.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolFlashlight")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.flashlight.light#node", "The light node on the flashlight")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.flashlight.light#mesh", "The self illum mesh of the flashlight")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.flashlight.light#distance", "The distance of the light")
	xmlSchema:register(XMLValueType.ANGLE, "handTool.flashlight.light#coneAngle", "The cone angle of the light")
	xmlSchema:register(XMLValueType.COLOR, "handTool.flashlight.light#color", "The color of the light")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.flashlight.light#dropOff", "The drop off of the light")
	xmlSchema:register(XMLValueType.STRING, "handTool.flashlight.light#iesProfile", "The IES Profile")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.flashlight.sounds", "toggle")
	xmlSchema:setXMLSpecializationType()
end

function HandToolFlashlight.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "setFlashlightIsActive", HandToolFlashlight.setFlashlightIsActive)
	SpecializationUtil.registerFunction(handToolType, "updateTransform", HandToolFlashlight.updateTransform)
end

function HandToolFlashlight.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolFlashlight)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolFlashlight)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolFlashlight)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolFlashlight)
end

function HandToolFlashlight.prerequisitesPresent(specializations)
	return true
end

-- Local values: spec, iesProfileFilename
function HandToolFlashlight:onLoad(xmlFile)
	local v6_ = self.spec_flashlight
	v6_.isActive = false
	self.isFlashlight = true
	v6_.lightNode = xmlFile:getValue("handTool.flashlight.light#node", nil, self.components, self.i3dMappings)
	v6_.lightMeshNode = xmlFile:getValue("handTool.flashlight.light#mesh", nil, self.components, self.i3dMappings)
	v6_.lightNodeParent = getParent(v6_.lightNode)
	local v7_, v8_, v9_ = getTranslation(v6_.lightNode)
	v6_.lightNodeOffsetX = v7_
	v6_.lightNodeOffsetY = v8_
	v6_.lightNodeOffsetZ = v9_
	local v10_, v11_, v12_ = localDirectionToLocal(v6_.lightNode, v6_.lightNodeParent, 0, 0, 1)
	v6_.lightNodeForwardX = v10_
	v6_.lightNodeForwardY = v11_
	v6_.lightNodeForwardZ = v12_
	link(getRootNode(), v6_.lightNode)
	v6_.distance = xmlFile:getValue("handTool.flashlight.light#distance", 100)
	v6_.coneAngle = xmlFile:getValue("handTool.flashlight.light#coneAngle", 60)
	v6_.color = Color.fromVector(xmlFile:getValue("handTool.flashlight.light#color", {
		1,
		1,
		1,
		1
	}, true))
	v6_.dropOff = xmlFile:getValue("handTool.flashlight.light#dropOff", 5)
	if v6_.lightNode == nil then
		Logging.xmlError(xmlFile, "Flashlight\'s light node could not be resolved!")
	else
		setLightRange(v6_.lightNode, v6_.distance)
		setLightColor(v6_.lightNode, v6_.color.r, v6_.color.g, v6_.color.b)
		setLightDropOff(v6_.lightNode, v6_.dropOff)
		setLightConeAngle(v6_.lightNode, v6_.coneAngle)
		local v13_ = xmlFile:getValue("handTool.flashlight.light#iesProfile")
		if v13_ ~= nil then
			local v14_ = Utils.getFilename(v13_, self.baseDirectory)
			setLightIESProfile(v6_.lightNode, v14_)
		end
		if self.isClient then
			v6_.samples = {}
			v6_.samples.toggle = g_soundManager:loadSampleFromXML(xmlFile, "handTool.flashlight.sounds", "toggle", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		end
		self:setFlashlightIsActive(false, true)
	end
end

-- Local values: spec
function HandToolFlashlight:onDelete()
	local v16_ = self.spec_flashlight
	if v16_.lightNode ~= nil then
		delete(v16_.lightNode)
		v16_.lightNode = nil
	end
	g_soundManager:deleteSamples(v16_.samples)
	if v16_.lightNodeParent ~= nil then
		delete(v16_.lightNodeParent)
		v16_.lightNodeParent = nil
	end
end

function HandToolFlashlight:onUpdate(dt)
	self:updateTransform(self:getIsHeld())
	self:raiseActive()
end

function HandToolFlashlight:onHeldEnd()
	self:setFlashlightIsActive(false, true)
end

-- Local values: spec, changed
function HandToolFlashlight:setFlashlightIsActive(isActive, noEventSend)
	local v22_ = self.spec_flashlight
	local v23_ = v22_.isActive ~= isActive
	v22_.isActive = isActive
	if v22_.lightNode ~= nil then
		setVisibility(v22_.lightNode, isActive)
	end
	if v22_.lightMeshNode ~= nil then
		setVisibility(v22_.lightMeshNode, isActive)
	end
	if v23_ and (v22_.samples ~= nil and not g_soundManager:getIsSamplePlaying(v22_.samples.toggle)) then
		g_soundManager:playSample(v22_.samples.toggle)
	end
	FlashlightToggleLightEvent.sendEvent(self, v22_.isActive, noEventSend)
end

-- Local values: spec, worldPositionX, worldPositionY, worldPositionZ, worldForwardX, worldForwardY, worldForwardZ, player, cameraPositionX, cameraPositionY, cameraPositionZ, cameraPitch, cameraYaw, graphics, model, yaw, headPositionX, headPositionY, headPositionZ
function HandToolFlashlight:updateTransform(isHeld)
	local v26_ = self.spec_flashlight
	if isHeld then
		if v26_.lightNodeParent == nil or not entityExists(v26_.lightNodeParent) then
			v26_.lightNodeParent = nil
		else
			local v27_, v28_, v29_ = localToWorld(v26_.lightNodeParent, v26_.lightNodeOffsetX, v26_.lightNodeOffsetY, v26_.lightNodeOffsetZ)
			local v30_, v31_, v32_ = localDirectionToLocal(v26_.lightNodeParent, getRootNode(), v26_.lightNodeForwardX, v26_.lightNodeForwardY, v26_.lightNodeForwardZ)
			setWorldTranslation(v26_.lightNode, v27_, v28_, v29_)
			setDirection(v26_.lightNode, v30_, v31_, v32_, 0, 1, 0)
		end
	else
		local v33_ = self:getCarryingPlayer()
		if v33_ == nil then
			return
		elseif v33_.camera == nil or not v33_.camera.isFirstPerson then
			local v34_ = v33_.graphicsComponent
			if v34_ == nil then
				return
			else
				local v35_ = v34_.model
				if v35_ ~= nil and (v35_.thirdPersonHeadNode ~= nil and entityExists(v35_.thirdPersonHeadNode)) then
					local v36_ = v34_:getModelYaw()
					local v37_, v38_, v39_ = localToWorld(v35_.thirdPersonHeadNode, 0, -0.2, 0)
					setWorldTranslation(v26_.lightNode, v37_, v38_, v39_)
					setWorldRotation(v26_.lightNode, 0, MathUtil.getValidLimit(v36_ + 3.141592653589793), 0)
				end
			end
		else
			local v40_, v41_, v42_ = v33_.camera:getCameraPosition()
			local v43_, v44_ = v33_.camera:getRotation()
			setWorldTranslation(v26_.lightNode, v40_, v41_, v42_)
			setWorldRotation(v26_.lightNode, -v43_, MathUtil.getValidLimit(v44_ + 3.141592653589793), 0)
			return
		end
	end
end
