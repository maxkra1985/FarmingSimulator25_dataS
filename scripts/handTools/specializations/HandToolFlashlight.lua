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
function HandToolFlashlight:onLoad(xmlFile)
	local spec = self.spec_flashlight
	spec.isActive = false
	self.isFlashlight = true
	spec.lightNode = xmlFile:getValue("handTool.flashlight.light#node", nil, self.components, self.i3dMappings)
	spec.lightMeshNode = xmlFile:getValue("handTool.flashlight.light#mesh", nil, self.components, self.i3dMappings)
	spec.lightNodeParent = getParent(spec.lightNode)
	spec.lightNodeOffsetX, spec.lightNodeOffsetY, spec.lightNodeOffsetZ = getTranslation(spec.lightNode)
	spec.lightNodeForwardX, spec.lightNodeForwardY, spec.lightNodeForwardZ = localDirectionToLocal(spec.lightNode, spec.lightNodeParent, 0, 0, 1)
	link(getRootNode(), spec.lightNode)
	spec.distance = xmlFile:getValue("handTool.flashlight.light#distance", 100)
	spec.coneAngle = xmlFile:getValue("handTool.flashlight.light#coneAngle", 60)
	spec.color = Color.fromVector(xmlFile:getValue("handTool.flashlight.light#color", { 1, 1, 1, 1 }, true))
	spec.dropOff = xmlFile:getValue("handTool.flashlight.light#dropOff", 5)
	if spec.lightNode == nil then
		Logging.xmlError(xmlFile, "Flashlight's light node could not be resolved!")
	else
		setLightRange(spec.lightNode, spec.distance)
		setLightColor(spec.lightNode, spec.color.r, spec.color.g, spec.color.b)
		setLightDropOff(spec.lightNode, spec.dropOff)
		setLightConeAngle(spec.lightNode, spec.coneAngle)
		local iesProfileFilename = xmlFile:getValue("handTool.flashlight.light#iesProfile")
		if iesProfileFilename ~= nil then
			iesProfileFilename = Utils.getFilename(iesProfileFilename, self.baseDirectory)
			setLightIESProfile(spec.lightNode, iesProfileFilename)
		end
		if self.isClient then
			spec.samples = {}
			spec.samples.toggle = g_soundManager:loadSampleFromXML(xmlFile, "handTool.flashlight.sounds", "toggle", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		end
		self:setFlashlightIsActive(false, true)
	end
end
function HandToolFlashlight:onDelete()
	local spec = self.spec_flashlight
	if spec.lightNode ~= nil then
		delete(spec.lightNode)
		spec.lightNode = nil
	end
	g_soundManager:deleteSamples(spec.samples)
	if spec.lightNodeParent ~= nil then
		delete(spec.lightNodeParent)
		spec.lightNodeParent = nil
	end
end
function HandToolFlashlight:onUpdate(dt)
	self:updateTransform(self:getIsHeld())
	self:raiseActive()
end
function HandToolFlashlight:onHeldEnd()
	self:setFlashlightIsActive(false, true)
end
function HandToolFlashlight:setFlashlightIsActive(isActive, noEventSend)
	local spec = self.spec_flashlight
	local changed = spec.isActive ~= isActive
	spec.isActive = isActive
	if spec.lightNode ~= nil then
		setVisibility(spec.lightNode, isActive)
	end
	if spec.lightMeshNode ~= nil then
		setVisibility(spec.lightMeshNode, isActive)
	end
	if changed and (spec.samples ~= nil and not g_soundManager:getIsSamplePlaying(spec.samples.toggle)) then
		g_soundManager:playSample(spec.samples.toggle)
	end
	FlashlightToggleLightEvent.sendEvent(self, spec.isActive, noEventSend)
end
function HandToolFlashlight:updateTransform(isHeld)
	local spec = self.spec_flashlight
	if isHeld then
		if spec.lightNodeParent == nil or not entityExists(spec.lightNodeParent) then
			spec.lightNodeParent = nil
			return
		end
		local worldPositionX, worldPositionY, worldPositionZ = localToWorld(spec.lightNodeParent, spec.lightNodeOffsetX, spec.lightNodeOffsetY, spec.lightNodeOffsetZ)
		local worldForwardX, worldForwardY, worldForwardZ = localDirectionToLocal(spec.lightNodeParent, getRootNode(), spec.lightNodeForwardX, spec.lightNodeForwardY, spec.lightNodeForwardZ)
		setWorldTranslation(spec.lightNode, worldPositionX, worldPositionY, worldPositionZ)
		setDirection(spec.lightNode, worldForwardX, worldForwardY, worldForwardZ, 0, 1, 0)
	else
		local player = self:getCarryingPlayer()
		if player == nil then
			return
		end
		if player.camera ~= nil and player.camera.isFirstPerson then
			local cameraPositionX, cameraPositionY, cameraPositionZ = player.camera:getCameraPosition()
			local cameraPitch, cameraYaw = player.camera:getRotation()
			setWorldTranslation(spec.lightNode, cameraPositionX, cameraPositionY, cameraPositionZ)
			setWorldRotation(spec.lightNode, -cameraPitch, MathUtil.getValidLimit(cameraYaw + 3.141592653589793), 0)
			return
		end
		local graphics = player.graphicsComponent
		if graphics == nil then
			return
		else
			local model = graphics.model
			if model == nil or model.thirdPersonHeadNode == nil or not entityExists(model.thirdPersonHeadNode) then
				return
			end
			local yaw = graphics:getModelYaw()
			local headPositionX, headPositionY, headPositionZ = localToWorld(model.thirdPersonHeadNode, 0, -0.2, 0)
			setWorldTranslation(spec.lightNode, headPositionX, headPositionY, headPositionZ)
			setWorldRotation(spec.lightNode, 0, MathUtil.getValidLimit(yaw + 3.141592653589793), 0)
		end
	end
end
