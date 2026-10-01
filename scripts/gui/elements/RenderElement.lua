RenderElement = {}
local RenderElement_mt = Class(RenderElement, GuiElement)
Gui.registerGuiElement("Render", RenderElement)
function RenderElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or RenderElement_mt)
	self.cameraPath = nil
	self.overlay = nil
	self.useAlpha = true
	self.shapesMask = 255
	self.lightMask = 67108864
	self.renderShadows = false
	self.bloomQuality = 0
	self.enableDof = false
	self.ssaoQuality = 0
	self.asyncShaderCompilation = false
	self.atmosphereQuality = AtmosphereQuality.OFF
	self.isRenderDirty = false
	return self
end
function RenderElement:delete()
	self:destroyScene()
	RenderElement:superClass().delete(self)
end
function RenderElement:loadFromXML(xmlFile, key)
	RenderElement:superClass().loadFromXML(self, xmlFile, key)
	self.filename = getXMLString(xmlFile, key .. "#filename") or self.filename
	self.cameraPath = getXMLString(xmlFile, key .. "#cameraNode") or self.cameraPath
	self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor") or self.superSamplingFactor
	self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
	self.lightMask = getXMLInt(xmlFile, key .. "#lightMask") or self.lightMask
	self.renderShadows = Utils.getNoNil(getXMLBool(xmlFile, key .. "#renderShadows"), self.renderShadows)
	self.bloomQuality = getXMLInt(xmlFile, key .. "#bloomQuality") or self.bloomQuality
	self.enableDof = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enableDof"), self.enableDof)
	self.ssaoQuality = getXMLInt(xmlFile, key .. "#ssaoQuality") or self.ssaoQuality
	self.asyncShaderCompilation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#asyncShaderCompilation"), self.asyncShaderCompilation)
	local atmosphereQualityName = getXMLString(xmlFile, key .. "#atmosphereQuality")
	if not string.isNilOrWhitespace(atmosphereQualityName) then
		local atmosphereQuality = AtmosphereQuality[atmosphereQualityName]
		if atmosphereQuality ~= nil then
			self.atmosphereQuality = atmosphereQuality
		else
			Logging.xmlWarning(xmlFile, "Invalid atmosphereQuality name '%s'", tostring(atmosphereQualityName))
		end
	end
	self:addCallback(xmlFile, key .. "#onRenderLoad", "onRenderLoadCallback")
end
function RenderElement:loadProfile(profile, applyProfile)
	RenderElement:superClass().loadProfile(self, profile, applyProfile)
	self.filename = profile:getValue("filename")
	self.cameraPath = profile:getValue("cameraNode")
	self.superSamplingFactor = profile:getNumber("superSamplingFactor")
	local atmosphereQualityName = profile:getValue("atmosphereQuality")
	if not string.isNilOrWhitespace(atmosphereQualityName) then
		local atmosphereQuality = AtmosphereQuality[atmosphereQualityName]
		if atmosphereQuality ~= nil then
			self.atmosphereQuality = atmosphereQuality
		else
			Logging.warning("Invalid atmosphereQuality name '%s'", tostring(atmosphereQualityName))
		end
	end
	if applyProfile then
		self:destroyScene()
		self:setScene(self.filename)
	end
end
function RenderElement:copyAttributes(src)
	RenderElement:superClass().copyAttributes(self, src)
	self.filename = src.filename
	self.cameraPath = src.cameraPath
	self.superSamplingFactor = src.superSamplingFactor
	self.atmosphereQuality = src.atmosphereQuality
	self.onRenderLoadCallback = src.onRenderLoadCallback
end
function RenderElement:createScene()
	self:setScene(self.filename)
end
function RenderElement:destroyScene()
	if self.loadingRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.loadingRequestId)
		self.loadingRequestId = nil
	end
	if self.overlay ~= nil then
		delete(self.overlay)
		self.overlay = nil
	end
	if self.scene then
		delete(self.scene)
		self.scene = nil
	end
end
function RenderElement:setScene(i3dFilename)
	if self.loadingRequestId ~= nil then
		Logging.error("Could not create scene. Another scene is already loaded. Destroy the scene first!")
	else
		self.isLoading = true
		self.filename = i3dFilename
		self.loadingRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, false, false, RenderElement.onSceneLoaded, self, nil)
	end
end
function RenderElement:onSceneLoaded(node, failedReason, args)
	self.isLoading = false
	if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
		Logging.error("Failed to load RenderElement scene from '%s'", self.filename)
	end
	if failedReason == LoadI3DFailedReason.NONE then
		self.scene = node
		link(getRootNode(), node)
		setVisibility(node, false)
		self:createOverlay()
	else
		if node ~= 0 then
			delete(node)
		end
	end
end
function RenderElement:createOverlay()
	if self.overlay ~= nil then
		delete(self.overlay)
		self.overlay = nil
	end
	local resolutionX = math.ceil(g_screenWidth * self.absSize[1]) * self.superSamplingFactor
	local resolutionY = math.ceil(g_screenHeight * self.absSize[2]) * self.superSamplingFactor
	local aspectRatio = resolutionX / resolutionY
	local camera = I3DUtil.indexToObject(self.scene, self.cameraPath)
	if camera == nil then
		Logging.error("Could not find camera node '%s' in render overlay scene '%s'", self.cameraPath, self.filename)
		return
	end
	local overlay = createRenderOverlay(self.scene, camera, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation, self.atmosphereQuality)
	if overlay == 0 then
		Logging.error("Could not create render overlay for scene '%s'", self.filename)
	else
		self.overlay = overlay
		self.isRenderDirty = true
		self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
	end
end
function RenderElement:setVisible(visible)
	RenderElement:superClass().setVisible(self, visible)
	setVisibility(self.scene, visible)
end
function RenderElement:update(dt)
	RenderElement:superClass().update(self, dt)
	if self.isRenderDirty and self.overlay ~= nil then
		updateRenderOverlay(self.overlay)
		self.isRenderDirty = false
	end
end
function RenderElement:draw(clipX1, clipY1, clipX2, clipY2)
	if not self.isLoading and self.overlay ~= nil then
		local posX = self.absPosition[1]
		local posY = self.absPosition[2]
		local sizeX = self.size[1]
		local sizeY = self.size[2]
		local u1 = 0
		local v1 = 0
		local u2 = 0
		local v2 = 1
		local u3 = 1
		local v3 = 0
		local u4 = 1
		local v4 = 1
		if clipX1 ~= nil then
			local oldX1 = posX
			local oldY1 = posY
			local oldX2 = sizeX + posX
			local oldY2 = sizeY + posY
			local posX2 = posX + sizeX
			local posY2 = posY + sizeY
			posX = math.max(posX, clipX1)
			posY = math.max(posY, clipY1)
			sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
			sizeY = math.max(math.min(posY2, clipY2) - posY, 0)
			local p1 = (posX - oldX1) / (oldX2 - oldX1)
			local p2 = (posY - oldY1) / (oldY2 - oldY1)
			local p3 = (posX + sizeX - oldX1) / (oldX2 - oldX1)
			local p4 = (posY + sizeY - oldY1) / (oldY2 - oldY1)
			u1 = p1
			v1 = p2
			u2 = p1
			v2 = p4
			u3 = p3
			v3 = p2
			u4 = p3
			v4 = p4
		end
		if u1 ~= u3 and v1 ~= v2 then
			setOverlayUVs(self.overlay, u1, v1, u2, v2, u3, v3, u4, v4)
			renderOverlay(self.overlay, posX, posY, sizeX, sizeY)
		end
	end
	RenderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function RenderElement:canReceiveFocus()
	return false
end
function RenderElement:getSceneRoot()
	return self.scene
end
function RenderElement:setRenderDirty()
	self.isRenderDirty = true
end
