-- Local values: HumanModel_mt
HumanModel = {}
local HumanModel_mt = Class(HumanModel)

function HumanModel.registerXMLPaths(xmlSchema, baseKey)
	I3DUtil.registerI3dMappingXMLPaths(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.mesh#node", "The index of the mesh node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.skeleton#node", "The index of the skeleton root node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.animationRoot#node", "The index of the animation root node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.hips#node", "The index of the hips node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.suspension#node", "The index of the suspension node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.leftHand#node", "The index of the left hand node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.rightHand#node", "The index of the right hand node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.leftFoot#node", "The index of the left foot node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.rightFoot#node", "The index of the right foot node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.head#node", "The index of the head node", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.spine#node", "The index of the spine node", nil, true)
	xmlSchema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".model.spine#offset", "The offset of the spine to the link node while loaded in a vehicle", "0 0 0")
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".sounds#filename", "The path of the xml file for the sounds", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".animation#filename", "The path of the xml file for the animation", nil, true)
end

-- Upvalues: HumanModel_mt
-- Local values: self
function HumanModel.new(customMt)
	-- upvalues: (copy) HumanModel_mt
	local v5_ = customMt or HumanModel_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isDeleted = false
	v6_.isLoaded = false
	v6_.sharedLoadRequestIds = {}
	v6_.modelParts = {}
	v6_.rootNode = nil
	v6_.skeleton = nil
	v6_.initIKChains = true
	v6_.mesh = nil
	v6_.isParentVisible = true
	v6_.isBaseFullyLoaded = false
	v6_.isStyleFullyLoaded = false
	v6_.isVisible = true
	v6_.thirdPersonHeadNode = nil
	v6_.thirdPersonHipsNode = nil
	v6_.thirdPersonSpineNode = nil
	v6_.thirdPersonLeftHandNode = nil
	v6_.thirdPersonRightHandNode = nil
	v6_.thirdPersonLeftFootNode = nil
	v6_.thirdPersonRightFootNode = nil
	v6_.thirdPersonSuspensionNode = nil
	v6_.faceNode = nil
	v6_.hairNode = nil
	v6_.headgearNode = nil
	v6_.glassesNode = nil
	v6_.facegearNode = nil
	v6_.beardNode = nil
	v6_.topNode = nil
	v6_.glovesNode = nil
	v6_.bottomNode = nil
	v6_.footwearNode = nil
	v6_.onepieceNode = nil
	v6_.animationClipMappings = {}
	v6_.ikChains = {}
	v6_.i3dFilename = nil
	v6_.i3dMappings = {}
	v6_.components = {}
	v6_.particleSystemsInformation = {
		["systems"] = {
			["swim"] = {},
			["plunge"] = {}
		},
		["swimNode"] = nil,
		["plungeNode"] = nil
	}
	return v6_
end

-- Local values: _, sharedLoadRequestId
function HumanModel:delete()
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	self.isDeleted = true
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	for _, v8_ in pairs(self.sharedLoadRequestIds) do
		g_i3DManager:releaseSharedI3DFile(v8_)
	end
	table.clear(self.sharedLoadRequestIds)
	self:reset()
end

-- Local values: filename, nodeId, chainId, _
function HumanModel:reset()
	if self.rootNode ~= nil then
		delete(self.rootNode)
		self.rootNode = nil
		self.skeleton = nil
		self.mesh = nil
		self.thirdPersonHeadNode = nil
		self.thirdPersonHipsNode = nil
		self.thirdPersonSpineNode = nil
		self.thirdPersonLeftHandNode = nil
		self.thirdPersonRightHandNode = nil
		self.thirdPersonLeftFootNode = nil
		self.thirdPersonRightFootNode = nil
		self.thirdPersonSuspensionNode = nil
		self.faceNode = nil
		self.hairNode = nil
		self.headgearNode = nil
		self.glassesNode = nil
		self.facegearNode = nil
		self.beardNode = nil
		self.topNode = nil
		self.glovesNode = nil
		self.bottomNode = nil
		self.footwearNode = nil
		self.onepieceNode = nil
	end
	table.clear(self.components)
	table.clear(self.i3dMappings)
	for _, v10_ in pairs(self.modelParts) do
		if entityExists(v10_) then
			delete(v10_)
		end
	end
	table.clear(self.modelParts)
	table.clear(self.animationClipMappings)
	if self.particleSystemsInformation.swimNode ~= nil then
		delete(self.particleSystemsInformation.swimNode)
	end
	if self.particleSystemsInformation.plungeNode ~= nil then
		delete(self.particleSystemsInformation.plungeNode)
	end
	if self.particleSystemsInformation.systems ~= nil then
		ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.swim)
		ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.plunge)
	end
	table.clear(self.particleSystemsInformation)
	for v11_, _ in pairs(self.ikChains) do
		IKUtil.deleteIKChain(self.ikChains, v11_)
	end
	table.clear(self.ikChains)
end

function HumanModel:loadEmpty()
	self.rootNode = createTransformGroup("model_rootNode_dummy")
	link(getRootNode(), self.rootNode)
end

-- Local values: onModelLoadedCallback
function HumanModel:load(xmlFilename, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.xmlFile = XMLFile.loadIfExists("playerXML", xmlFilename, PlayerSystem.xmlSchema)
	if self.xmlFile == nil then
		asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
	else
		self:loadFromXMLFileAsync(self.xmlFile, isRealPlayer, isOwner, isAnimated, function(_, p21_)
			-- upvalues: (copy) self, (copy) asyncCallbackFunction, (copy) asyncCallbackObject, (copy) asyncCallbackArguments
			if self.xmlFile ~= nil then
				self.xmlFile:delete()
				self.xmlFile = nil
			end
			self:updateVisibility()
			if asyncCallbackFunction ~= nil then
				asyncCallbackFunction(asyncCallbackObject, p21_, asyncCallbackArguments)
			end
		end)
	end
end

-- Local values: i3dFilename, oldSharedLoadRequestId, _, sharedLoadRequestId
function HumanModel:loadFromXMLFileAsync(xmlFile, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.xmlFilename = xmlFile:getFilename()
	local v30_, v31_ = Utils.getModNameAndBaseDirectory(self.xmlFilename)
	self.customEnvironment = v30_
	self.baseDirectory = v31_
	local v32_ = xmlFile:getValue("player.filename", nil)
	self.i3dFilename = Utils.getFilename(v32_, self.baseDirectory)
	self.isRealPlayer = isRealPlayer
	self.isStyleFullyLoaded = false
	self.isBaseFullyLoaded = false
	self:updateVisibility()
	self.asyncLoadCallbackFunction = asyncCallbackFunction
	self.asyncLoadCallbackObject = asyncCallbackObject
	self.asyncLoadCallbackArguments = asyncCallbackArguments
	local v33_ = self.sharedLoadRequestId
	for _, v34_ in pairs(self.sharedLoadRequestIds) do
		g_i3DManager:releaseSharedI3DFile(v34_)
	end
	table.clear(self.sharedLoadRequestIds)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.loadFileFinished, self, {
		["xmlFile"] = xmlFile,
		["isRealPlayer"] = isRealPlayer,
		["isOwner"] = isOwner,
		["isAnimated"] = isAnimated
	})
	if v33_ ~= nil then
		g_i3DManager:releaseSharedI3DFile(v33_)
	end
end

-- Local values: xmlFile, animationFilename, soundFilename, linkNode, ox, oy, oz, x, y, z
function HumanModel:loadFileFinished(rootNode, failedReason, arguments)
	if rootNode == 0 then
		Logging.error("Unable to load player model %q", self.i3dFilename)
		self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
		return
	else
		local v38_ = arguments.xmlFile
		if v38_ == nil or g_xmlManager:getFileByHandle(v38_:getHandle()) == nil then
			Logging.error("Unable to load player xml %q", self.xmlFilename)
			self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
		else
			self:reset()
			I3DUtil.loadI3DComponents(rootNode, self.components)
			I3DUtil.loadI3DMapping(v38_, "player", self.components, self.i3dMappings)
			self.rootNode = rootNode
			local v39_ = v38_:getValue("player.animation#filename")
			if v39_ == nil then
				Logging.xmlWarning(v38_, "No animation filename defined at %q", "player.animation#filename")
			else
				self.animationFilename = Utils.getFilename(v39_, self.baseDirectory)
			end
			local v40_ = v38_:getValue("player.sounds#filename")
			if v40_ == nil then
				Logging.xmlWarning(v38_, "No sounds filename defined at %q", "player.sound#filename")
			else
				self.soundFilename = Utils.getFilename(v40_, self.baseDirectory)
			end
			self.skeleton = v38_:getValue("player.model.skeleton#node", nil, self.components, self.i3dMappings)
			if self.skeleton == nil then
				Logging.devError("Failed to find skeleton root node in \'%s\'", self.i3dFilename)
			end
			self.mesh = v38_:getValue("player.model.mesh#node", nil, self.components, self.i3dMappings)
			if self.mesh == nil then
				Logging.devError("Failed to find player mesh in \'%s\'", self.i3dFilename)
			end
			self.thirdPersonHipsNode = v38_:getValue("player.model.hips#node", nil, self.components, self.i3dMappings)
			self.thirdPersonSpineNode = v38_:getValue("player.model.spine#node", nil, self.components, self.i3dMappings)
			self.thirdPersonSpineNodeOffset = v38_:getValue("player.model.spine#offset", nil, true)
			self.thirdPersonSuspensionNode = v38_:getValue("player.model.suspension#node", nil, self.components, self.i3dMappings)
			self.thirdPersonLeftHandNode = v38_:getValue("player.model.leftHand#node", nil, self.components, self.i3dMappings)
			self.thirdPersonRightHandNode = v38_:getValue("player.model.rightHand#node", nil, self.components, self.i3dMappings)
			self.thirdPersonLeftFootNode = v38_:getValue("player.model.leftFoot#node", nil, self.components, self.i3dMappings)
			self.thirdPersonRightFootNode = v38_:getValue("player.model.rightFoot#node", nil, self.components, self.i3dMappings)
			self.thirdPersonHeadNode = v38_:getValue("player.model.head#node", nil, self.components, self.i3dMappings)
			if self.mesh ~= nil then
				setClipDistance(self.mesh, 200)
			end
			if self.initIKChains then
				self:loadIKChains(v38_, rootNode, arguments.isRealPlayer)
			end
			if arguments.isRealPlayer then
				self.animRootThirdPerson = v38_:getValue("player.model.animationRoot#node", nil, self.components, self.i3dMappings)
				if self.animRootThirdPerson == nil then
					Logging.devError("Failed to find animation root node in \'%s\'", self.i3dFilename)
					self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.INVALID_CONTENT, self.asyncLoadCallbackArguments)
					return
				end
				self.skeletonRootNode = createTransformGroup("player_skeletonRootNode")
				link(getRootNode(), self.rootNode)
				link(self.rootNode, self.skeletonRootNode)
				if self.animRootThirdPerson ~= nil then
					link(self.skeletonRootNode, self.animRootThirdPerson)
					if self.skeleton ~= nil then
						link(self.animRootThirdPerson, self.skeleton)
					end
				end
				self.particleSystemsInformation.systems = {
					["swim"] = {},
					["plunge"] = {}
				}
				self.particleSystemsInformation.swimNode = createTransformGroup("swimFXNode")
				self.particleSystemsInformation.plungeNode = createTransformGroup("plungeFXNode")
				link(getRootNode(), self.particleSystemsInformation.swimNode)
				link(getRootNode(), self.particleSystemsInformation.plungeNode)
				ParticleUtil.loadParticleSystem(v38_:getHandle(), self.particleSystemsInformation.systems.swim, "player.particleSystems.swim", self.particleSystemsInformation.swimNode, false, nil, self.baseDirectory)
				ParticleUtil.loadParticleSystem(v38_:getHandle(), self.particleSystemsInformation.systems.plunge, "player.particleSystems.plunge", self.particleSystemsInformation.plungeNode, false, nil, self.baseDirectory)
			elseif arguments.isAnimated then
				link(self.rootNode, self.skeleton)
			else
				local v41_ = createTransformGroup("characterLinkNode")
				link(self.rootNode, v41_)
				link(v41_, self.skeleton)
				local v42_, v43_, v44_
				if self.thirdPersonSpineNodeOffset == nil then
					v42_ = 0
					v43_ = 0
					v44_ = 0
				else
					v42_ = -self.thirdPersonSpineNodeOffset[1]
					v43_ = -self.thirdPersonSpineNodeOffset[2]
					v44_ = -self.thirdPersonSpineNodeOffset[3]
				end
				local v45_, v46_, v47_ = localToLocal(self.thirdPersonSpineNode, self.skeleton, v42_, v43_, v44_)
				setTranslation(v41_, -v45_, -v46_, -v47_)
			end
			self.faceFocusNode = createTransformGroup("player_faceFocusNode")
			setTranslation(self.faceFocusNode, 0, 1.8, 0)
			link(self.rootNode, self.faceFocusNode)
			self.isLoaded = true
			self.isBaseFullyLoaded = true
			self:updateVisibility()
			self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.OK, self.asyncLoadCallbackArguments)
		end
	end
end

-- Local values: i, key
function HumanModel:loadIKChains(xmlFile, rootNode, isRealPlayer)
	self.ikChains = {}
	for _, v52_ in xmlFile:iterator("player.ikChains.ikChain") do
		IKUtil.loadIKChain(xmlFile:getHandle(), v52_, rootNode, rootNode, self.ikChains)
	end
	IKUtil.setIKChainInactive(self.ikChains, "spine")
	if isRealPlayer then
		IKUtil.deleteIKChain(self.ikChains, "rightFoot")
		IKUtil.deleteIKChain(self.ikChains, "leftFoot")
		IKUtil.deleteIKChain(self.ikChains, "rightArm")
		IKUtil.deleteIKChain(self.ikChains, "leftArm")
		IKUtil.deleteIKChain(self.ikChains, "spine")
	end
end

-- Local values: oldIds, filename, node, required, filesAwaiter, _, filename, sharedLoadRequestId, filename, sharedLoadRequestId
function HumanModel:loadFromStyleAsync(playerStyle, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self:updateVisibility()
	if playerStyle.xmlFilename == self.xmlFilename then
		if self.setStyleFinishCallback ~= nil then
			self.setStyleFinishCallback(self.setStyleFinishCallbackTarget, HumanModelLoadingState.CANCELED, self.setStyleFinishCallbackArguments)
		end
		self.setStyleFinishCallback = asyncCallbackFunction
		self.setStyleFinishCallbackTarget = asyncCallbackObject
		self.setStyleFinishCallbackArguments = asyncCallbackArguments
		local v58_ = self.sharedLoadRequestIds
		self.sharedLoadRequestIds = {}
		for v59_, v60_ in pairs(self.modelParts) do
			delete(v60_)
			self.modelParts[v59_] = nil
		end
		local v61_ = playerStyle:getRequiredNodeFiles()
		local v62_ = AsyncAwaiter.new(function()
			-- upvalues: (copy) self, (copy) playerStyle
			self:onAllModelPartsLoaded(playerStyle)
		end)
		for _, v63_ in ipairs(v61_) do
			if self.sharedLoadRequestIds[v63_] == nil then
				v62_:addDependency(v63_)
				local v64_ = g_i3DManager:loadSharedI3DFileAsync(v63_, false, true, self.onModelPartLoaded, self, {
					["filename"] = v63_,
					["filesAwaiter"] = v62_
				})
				self.sharedLoadRequestIds[v63_] = v64_
			end
		end
		for _, v65_ in pairs(v58_) do
			g_i3DManager:releaseSharedI3DFile(v65_)
		end
		if v62_:getDependenciesCount() == 0 then
			self:onAllModelPartsLoaded(playerStyle)
		end
	else
		Logging.error("Can\'t set player style with different filename to player model. %s ~= %s", playerStyle.xmlFilename, self.xmlFilename)
	end
end

function HumanModel:onModelPartLoaded(node, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		self.modelParts[args.filename] = node
	end
	args.filesAwaiter:onDependencyAvailable(args.filename)
end

-- Local values: loadSuccess, filename, node, callbackTarget, callback, callbackArguments
function HumanModel:onAllModelPartsLoaded(playerStyle)
	local v72_ = not self.isDeleted
	if v72_ then
		self:applyFromStyle(playerStyle, false)
		self.isStyleFullyLoaded = true
		self:updateVisibility()
	end
	for v73_, v74_ in pairs(self.modelParts) do
		if v74_ ~= 0 then
			delete(v74_)
		end
		self.modelParts[v73_] = nil
	end
	if self.setStyleFinishCallback ~= nil then
		local v75_ = self.setStyleFinishCallbackTarget
		local v76_ = self.setStyleFinishCallback
		local v77_ = self.setStyleFinishCallbackArguments
		self.setStyleFinishCallbackTarget = nil
		self.setStyleFinishCallback = nil
		self.setStyleFinishCallbackArguments = nil
		v76_(v75_, v72_ and HumanModelLoadingState.OK or HumanModelLoadingState.FAILED, v77_)
	end
	self:updateVisibility()
end

-- Local values: hideGlasses
function HumanModel:applyFromStyle(style, hideBody)
	if self.modelParts == nil or table.size(self.modelParts) == 0 then
		Logging.error("applyToStyle should only be called immediately after all model parts have been loaded!")
	else
		self:setFaceNodeFromStyle(style.configs.face, style.bodyParts, hideBody)
		self:setTopNodeFromStyle(style.configs.top, style.configs.gloves)
		self:setBottomNodeFromStyle(style.configs.bottom, style.configs.footwear)
		self:setFootwearNodeFromStyle(style.configs.footwear, style.configs.bottom, style.configs.onepiece)
		self:setGlovesNodeFromStyle(style.configs.gloves)
		local v81_ = self:setHeadgearNodeFromStyle(style.configs.headgear, hideBody)
		self:setGlassesNodeFromStyle(style.configs.glasses, v81_)
		self:setHairNodeFromStyle(style.configs.hairStyle, style.configs.headgear, style.configs.onepiece, style.hatHairstyleIndex)
		self:setFacegearNodeFromStyle(style.configs.facegear, style.configs.beard, style.configs.face)
		self:setOnepieceNodeFromStyle(style.configs.onepiece, style.configs.gloves, style.configs.footwear)
		self:setBeltVisibilityFromStyle(style.configs.top, style.configs.bottom, style.configs.onepiece)
	end
end

-- Local values: selectedFace, skinColor, _, part, node, faceNode, originalFaceNode, faceSourceNode, attachmentNode, oldFaceSkeleton
function HumanModel:setFaceNodeFromStyle(faceConfig, bodyParts, hideBody)
	if self.faceNode ~= nil and entityExists(self.faceNode) then
		delete(self.faceNode)
	end
	self.faceNode = nil
	if faceConfig.selectedItemIndex == 0 then
		return
	else
		local v86_ = faceConfig:getSelectedItem()
		local v_u_87_ = v86_.skinColor
		for _, v88_ in ipairs(bodyParts) do
			local v89_ = self.i3dMappings[v88_.nodeName].nodeId
			if v89_ ~= nil then
				setVisibility(v89_, not hideBody)
				setShaderParameter(v89_, "colorScaleR", v_u_87_.r, v_u_87_.g, v_u_87_.b, 1, false)
			end
		end
		local v90_ = nil
		if not string.isNilOrWhitespace(v86_.filename) then
			local v91_ = self.modelParts[v86_.filename]
			if v91_ ~= nil then
				v90_ = clone(v91_, false, false, false)
			end
		end
		if v90_ == nil then
			Logging.error("Could not clone player\'s face!")
		else
			local v92_ = I3DUtil.indexToObject(v90_, v86_.nodePath)
			local v93_ = self.i3dMappings[v86_.attachPoint].nodeId
			link(v93_, v92_)
			self.faceNode = v92_
			local v94_ = getChildAt(v90_, 0)
			I3DUtil.setShapeBonesRec(v92_, self.skeleton, v94_, true)
			I3DUtil.iterateRecursively(v92_, function(p95_)
				-- upvalues: (copy) v_u_87_
				if getHasClassId(p95_, ClassIds.SHAPE) and getHasShaderParameter(p95_, "sssColor") then
					setShaderParameter(p95_, "colorScaleR", v_u_87_.r, v_u_87_.g, v_u_87_.b, 1, false)
				end
			end)
			delete(v90_)
		end
	end
end

-- Local values: selectedGloves, extent
function HumanModel:setTopNodeFromStyle(topConfig, glovesConfig)
	if self.topNode ~= nil and entityExists(self.topNode) then
		delete(self.topNode)
	end
	self.topNode = nil
	if topConfig.selectedItemIndex ~= 0 then
		local v99_ = glovesConfig:getSelectedItem()
		local v100_ = v99_ == nil and "hands" or (v99_.extent or "hands")
		self.topNode = topConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, v100_)
	end
end

-- Local values: footwearItem, footwearExtent
function HumanModel:setBottomNodeFromStyle(bottomConfig, footwearConfig)
	if self.bottomNode ~= nil and entityExists(self.bottomNode) then
		delete(self.bottomNode)
	end
	self.bottomNode = nil
	if bottomConfig.selectedItemIndex ~= 0 then
		local v104_ = footwearConfig:getSelectedItem()
		local v105_ = v104_ == nil and "low" or (v104_.extent or "low")
		self.bottomNode = bottomConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, v105_)
	end
end

-- Local values: extent, onepieceItem, bottomItem
function HumanModel:setFootwearNodeFromStyle(footwearConfig, bottomConfig, onepieceConfig)
	if self.footwearNode ~= nil and entityExists(self.footwearNode) then
		delete(self.footwearNode)
	end
	self.footwearNode = nil
	if footwearConfig.selectedItemIndex ~= 0 then
		local v110_ = "high"
		if onepieceConfig.selectedItemIndex == 0 then
			if bottomConfig.selectedItemIndex ~= 0 then
				local v111_ = bottomConfig:getSelectedItem()
				if v111_ ~= nil then
					v110_ = v111_.extent or v110_
				end
			end
		else
			local v112_ = onepieceConfig:getSelectedItem()
			if v112_ ~= nil then
				v110_ = v112_.extent or v110_
			end
		end
		self.footwearNode = footwearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, v110_)
	end
end

function HumanModel:setGlovesNodeFromStyle(glovesConfig)
	if self.glovesNode ~= nil and entityExists(self.glovesNode) then
		delete(self.glovesNode)
	end
	self.glovesNode = nil
	if glovesConfig.selectedItemIndex ~= 0 then
		self.glovesNode = glovesConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	end
end

-- Local values: headgearItem
function HumanModel:setHeadgearNodeFromStyle(headgearConfig)
	if self.headgearNode ~= nil and entityExists(self.headgearNode) then
		delete(self.headgearNode)
	end
	self.headgearNode = nil
	if headgearConfig.selectedItemIndex == 0 then
		return false
	end
	self.headgearNode = headgearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	return headgearConfig:getSelectedItem().hideGlasses
end

function HumanModel:setGlassesNodeFromStyle(glassesConfig, hideGlasses)
	if self.glassesNode ~= nil and entityExists(self.glassesNode) then
		delete(self.glassesNode)
	end
	self.glassesNode = nil
	if glassesConfig.selectedItemIndex ~= 0 and not hideGlasses then
		self.glassesNode = glassesConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	end
end

-- Local values: onepieceItem
function HumanModel:setHairNodeFromStyle(hairStyleConfig, headgearConfig, onepieceConfig, hatHairstyleIndex)
	if self.hairNode ~= nil and entityExists(self.hairNode) then
		delete(self.hairNode)
	end
	self.hairNode = nil
	if hairStyleConfig.selectedItemIndex == 0 then
		return
	else
		local v125_ = onepieceConfig:getSelectedItem()
		if hatHairstyleIndex == nil or headgearConfig.selectedItemIndex == 0 and (onepieceConfig.selectedItemIndex == 0 or not v125_.disabledOptions.headgear) then
			self.hairNode = hairStyleConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
		else
			self.hairNode = hairStyleConfig:cloneAndEnableItemIndex(hatHairstyleIndex, self.modelParts, self.skeleton, self.i3dMappings)
		end
	end
end

-- Local values: selectedFace, i, item
function HumanModel:setFacegearNodeFromStyle(facegearConfig, beardConfig, faceConfig)
	if self.facegearNode ~= nil and entityExists(self.facegearNode) then
		delete(self.facegearNode)
	end
	if self.beardNode ~= nil and entityExists(self.beardNode) then
		delete(self.beardNode)
	end
	self.facegearNode = nil
	self.beardNode = nil
	if facegearConfig.selectedItemIndex == 0 then
		local v130_ = faceConfig:getSelectedItem()
		if v130_ ~= nil and beardConfig.selectedItemIndex ~= 0 then
			for v131_ = beardConfig.selectedItemIndex, #beardConfig.items do
				local v132_ = beardConfig.items[v131_]
				if v132_.faceName == nil or (v132_.faceName == v130_.name or faceConfig.selectedItemIndex == 0 and v132_.faceName == faceConfig.items[1].name) then
					self.beardNode = beardConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
					return
				end
			end
		end
	else
		self.facegearNode = facegearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	end
end

-- Local values: extentToCompare, extentToCompare2
function HumanModel:setOnepieceNodeFromStyle(onepieceConfig, glovesConfig, footwearConfig)
	if self.onepieceNode ~= nil and entityExists(self.onepieceNode) then
		delete(self.onepieceNode)
	end
	self.onepieceNode = nil
	if onepieceConfig.selectedItemIndex ~= 0 then
		local v137_ = glovesConfig:getSelectedItem() == nil and "hands" or (glovesConfig:getSelectedItem().extent or "hands")
		local v138_ = footwearConfig:getSelectedItem() == nil and "low" or (footwearConfig:getSelectedItem().extent or "low")
		self.onepieceNode = onepieceConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, v137_, v138_)
	end
end

-- Local values: hideBelt, item, selectedBottom, node
function HumanModel:setBeltVisibilityFromStyle(topConfig, bottomConfig, onepieceConfig)
	if bottomConfig.selectedItemIndex ~= 0 and (topConfig.selectedItemIndex ~= 0 or onepieceConfig.selectedItemIndex == 0) then
		local v143_ = false
		if topConfig.selectedItemIndex ~= 0 then
			local v144_ = topConfig:getSelectedItem()
			if v144_ ~= nil then
				v143_ = v144_.hideBelt
			end
		end
		local v145_ = bottomConfig:getSelectedItem()
		if v145_ ~= nil and v145_.belt ~= nil then
			local v146_ = I3DUtil.indexToObject(self.bottomNode, v145_.belt)
			if v146_ ~= nil then
				setVisibility(v146_, not v143_)
			end
		end
	end
end

-- Local values: shapeCheck
function HumanModel:iterateShapesRecursively(callback)
	I3DUtil.iterateRecursively(self.rootNode, function(p149_)
		-- upvalues: (copy) callback
		return not getHasClassId(p149_, ClassIds.SHAPE) and true or callback(p149_)
	end)
end

function HumanModel:getSkeletonNode()
	return self.skeleton
end

function HumanModel:setSkeletonRotation(yRot)
	if self.skeletonRootNode ~= nil then
		setRotation(self.skeletonRootNode, 0, yRot, 0)
	end
end

function HumanModel:getMass()
	return 80
end

-- Local values: hasShapeInFrustum, checkShapeIsInFrustum
function HumanModel:getIsInCameraFrustum(camera, aspectRatio)
	if not self.isLoaded then
		return false
	end
	local v_u_156_ = camera or g_cameraManager:getActiveCamera()
	local v_u_157_ = aspectRatio or g_presentedScreenAspectRatio
	local v_u_158_ = false
	self:iterateShapesRecursively(function(p159_)
		-- upvalues: (ref) v_u_156_, (ref) v_u_157_, (ref) v_u_158_
		if not getIsInCameraFrustum(p159_, v_u_156_, v_u_157_) then
			return true
		end
		v_u_158_ = true
		return false
	end)
	return v_u_158_
end

function HumanModel:getVisibility()
	return getVisibility(self.rootNode)
end

-- Local values: isVisible
function HumanModel:updateVisibility()
	local v162_ = self.isVisible and (self.isBaseFullyLoaded and self.isStyleFullyLoaded)
	if v162_ then
		v162_ = self.isParentVisible
	end
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, v162_)
	end
end

function HumanModel:setVisibility(isVisible)
	self.isVisible = isVisible
	self:updateVisibility()
end

function HumanModel:setParentVisibility(visible)
	self.isParentVisible = visible
	self:updateVisibility()
end

function HumanModel:showHead()
	self:setIsHeadVisible(true)
end

function HumanModel:hideHead()
	self:setIsHeadVisible(false)
end

function HumanModel:setIsHeadVisible(isHeadVisible)
	if self.hairNode ~= nil then
		setVisibility(self.hairNode, isHeadVisible)
	end
	if self.glassesNode ~= nil then
		setVisibility(self.glassesNode, isHeadVisible)
	end
	if self.faceNode ~= nil then
		setVisibility(self.faceNode, isHeadVisible)
	end
	if self.headgearNode ~= nil then
		setVisibility(self.headgearNode, isHeadVisible)
	end
	if self.facegearNode ~= nil then
		setVisibility(self.facegearNode, isHeadVisible)
	end
	if self.beardNode ~= nil then
		setVisibility(self.beardNode, isHeadVisible)
	end
end

function HumanModel:getRootNode()
	return self.rootNode
end

function HumanModel:setIKDirty()
	IKUtil.setIKChainDirty(self.ikChains, "rightFoot")
	IKUtil.setIKChainDirty(self.ikChains, "leftFoot")
	IKUtil.setIKChainDirty(self.ikChains, "rightArm")
	IKUtil.setIKChainDirty(self.ikChains, "leftArm")
	IKUtil.setIKChainDirty(self.ikChains, "spine")
end

function HumanModel:getIKChains()
	return self.ikChains
end

function HumanModel:updateFX(x, y, z, isInWater, plungedInWater, waterY)
	if isInWater then
		setWorldTranslation(self.particleSystemsInformation.swimNode, x, waterY, z)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.swim, true)
	else
		ParticleUtil.resetNumOfEmittedParticles(self.particleSystemsInformation.systems.swim)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.swim, false)
	end
	if plungedInWater then
		setWorldTranslation(self.particleSystemsInformation.plungeNode, x, waterY, z)
		ParticleUtil.resetNumOfEmittedParticles(self.particleSystemsInformation.systems.plunge)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.plunge, true)
	end
end

-- Local values: drawBones, boneX, boneY, boneZ
function HumanModel:debugDraw(x, y, textSize)
	local function v_u_189_(p181_, p182_, p183_, p184_)
		-- upvalues: (copy) v_u_189_
		local v185_, v186_, v187_ = getWorldTranslation(p181_)
		drawDebugLine(p182_, p183_, p184_, 0, 0, 0, v185_, v186_, v187_, 1, 0, 0, false)
		for v188_ = 0, getNumOfChildren(p181_) - 1 do
			v_u_189_(getChildAt(p181_, v188_), v185_, v186_, v187_)
		end
	end
	if self.skeleton ~= nil then
		local v190_, v191_, v192_ = getWorldTranslation(getChildAt(self.skeleton, 0))
		v_u_189_(getChildAt(self.skeleton, 0), v190_, v191_, v192_)
	end
end
