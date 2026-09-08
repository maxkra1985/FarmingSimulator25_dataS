-- Local values: RenderElement_mt
RenderElement = {}
local RenderElement_mt = Class(RenderElement, GuiElement)
Gui.registerGuiElement("Render", RenderElement)

-- Upvalues: RenderElement_mt
-- Local values: self
function RenderElement.new(target, custom_mt)
	-- upvalues: (copy) RenderElement_mt
	local v4_ = GuiElement.new(target, custom_mt or RenderElement_mt)
	v4_.cameraPath = nil
	v4_.overlay = nil
	v4_.useAlpha = true
	v4_.shapesMask = 255
	v4_.lightMask = 67108864
	v4_.renderShadows = false
	v4_.bloomQuality = 0
	v4_.enableDof = false
	v4_.ssaoQuality = 0
	v4_.asyncShaderCompilation = false
	v4_.atmosphereQuality = AtmosphereQuality.OFF
	v4_.isRenderDirty = false
	return v4_
end

function RenderElement:delete()
	self:destroyScene()
	RenderElement:superClass().delete(self)
end

-- Local values: atmosphereQualityName, atmosphereQuality
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
	local v9_ = getXMLString(xmlFile, key .. "#atmosphereQuality")
	if not string.isNilOrWhitespace(v9_) then
		local v10_ = AtmosphereQuality[v9_]
		if v10_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid atmosphereQuality name \'%s\'", (tostring(v9_)))
		else
			self.atmosphereQuality = v10_
		end
	end
	self:addCallback(xmlFile, key .. "#onRenderLoad", "onRenderLoadCallback")
end

-- Local values: atmosphereQualityName, atmosphereQuality
function RenderElement:loadProfile(profile, applyProfile)
	RenderElement:superClass().loadProfile(self, profile, applyProfile)
	self.filename = profile:getValue("filename")
	self.cameraPath = profile:getValue("cameraNode")
	self.superSamplingFactor = profile:getNumber("superSamplingFactor")
	local v14_ = profile:getValue("atmosphereQuality")
	if not string.isNilOrWhitespace(v14_) then
		local v15_ = AtmosphereQuality[v14_]
		if v15_ == nil then
			Logging.warning("Invalid atmosphereQuality name \'%s\'", (tostring(v14_)))
		else
			self.atmosphereQuality = v15_
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
	if self.loadingRequestId == nil then
		self.isLoading = true
		self.filename = i3dFilename
		self.loadingRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, false, false, RenderElement.onSceneLoaded, self, nil)
	else
		Logging.error("Could not create scene. Another scene is already loaded. Destroy the scene first!")
	end
end

function RenderElement:onSceneLoaded(node, failedReason, args)
	self.isLoading = false
	if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
		Logging.error("Failed to load RenderElement scene from \'%s\'", self.filename)
	end
	if failedReason == LoadI3DFailedReason.NONE then
		self.scene = node
		link(getRootNode(), node)
		setVisibility(node, false)
		self:createOverlay()
	elseif node ~= 0 then
		delete(node)
	end
end

-- Local values: resolutionX, resolutionY, aspectRatio, camera, overlay
function RenderElement:createOverlay()
	if self.overlay ~= nil then
		delete(self.overlay)
		self.overlay = nil
	end
	local v26_ = g_screenWidth * self.absSize[1]
	local v27_ = math.ceil(v26_) * self.superSamplingFactor
	local v28_ = g_screenHeight * self.absSize[2]
	local v29_ = math.ceil(v28_) * self.superSamplingFactor
	local v30_ = v27_ / v29_
	local v31_ = I3DUtil.indexToObject(self.scene, self.cameraPath)
	if v31_ == nil then
		Logging.error("Could not find camera node \'%s\' in render overlay scene \'%s\'", self.cameraPath, self.filename)
		return
	else
		local v32_ = createRenderOverlay(self.scene, v31_, v30_, v27_, v29_, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation, self.atmosphereQuality)
		if v32_ == 0 then
			Logging.error("Could not create render overlay for scene \'%s\'", self.filename)
		else
			self.overlay = v32_
			self.isRenderDirty = true
			self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
		end
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

-- Local values: posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4, oldX1, oldY1, oldX2, oldY2, posX2, posY2, p1, p2, p3, p4
function RenderElement:draw(clipX1, clipY1, clipX2, clipY2)
	if not self.isLoading and self.overlay ~= nil then
		local v42_ = self.absPosition[1]
		local v43_ = self.absPosition[2]
		local v44_ = self.size[1]
		local v45_ = self.size[2]
		local v46_, v47_, v48_, v49_, v50_, v51_, v52_, v53_, v54_, v55_
		if clipX1 == nil then
			v46_ = v43_
			v47_ = v42_
			v48_ = 0
			v49_ = 0
			v50_ = 1
			v51_ = 1
			v52_ = 0
			v53_ = 1
			v54_ = 0
			v55_ = 1
		else
			local v56_ = v44_ + v42_
			local v57_ = v45_ + v43_
			local v58_ = v42_ + v44_
			local v59_ = v43_ + v45_
			v47_ = math.max(v42_, clipX1)
			v46_ = math.max(v43_, clipY1)
			local v60_ = math.min(v58_, clipX2) - v47_
			v44_ = math.max(v60_, 0)
			local v61_ = math.min(v59_, clipY2) - v46_
			v45_ = math.max(v61_, 0)
			v49_ = (v47_ - v42_) / (v56_ - v42_)
			v48_ = (v46_ - v43_) / (v57_ - v43_)
			v51_ = (v47_ + v44_ - v42_) / (v56_ - v42_)
			v50_ = (v46_ + v45_ - v43_) / (v57_ - v43_)
			v55_ = v51_
			v54_ = v49_
			v53_ = v50_
			v52_ = v48_
		end
		if v49_ ~= v51_ and v52_ ~= v50_ then
			setOverlayUVs(self.overlay, v49_, v52_, v54_, v50_, v51_, v48_, v55_, v53_)
			renderOverlay(self.overlay, v47_, v46_, v44_, v45_)
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
