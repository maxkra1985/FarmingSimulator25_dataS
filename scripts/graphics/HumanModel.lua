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
function HumanModel.new(customMt)
	local self = setmetatable({}, customMt or HumanModel_mt)
	self.isDeleted = false
	self.isLoaded = false
	self.sharedLoadRequestIds = {}
	self.modelParts = {}
	self.rootNode = nil
	self.skeleton = nil
	self.initIKChains = true
	self.mesh = nil
	self.isParentVisible = true
	self.isBaseFullyLoaded = false
	self.isStyleFullyLoaded = false
	self.isVisible = true
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
	self.animationClipMappings = {}
	self.ikChains = {}
	self.i3dFilename = nil
	self.i3dMappings = {}
	self.components = {}
	self.particleSystemsInformation = { systems = { swim = {}, plunge = {} }, swimNode = nil, plungeNode = nil }
	return self
end
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
	for _, sharedLoadRequestId in pairs(self.sharedLoadRequestIds) do
		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end
	table.clear(self.sharedLoadRequestIds)
	self:reset()
end
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
	for filename, nodeId in pairs(self.modelParts) do
		if entityExists(nodeId) then
			delete(nodeId)
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
	for chainId, _ in pairs(self.ikChains) do
		IKUtil.deleteIKChain(self.ikChains, chainId)
	end
	table.clear(self.ikChains)
end
function HumanModel:loadEmpty()
	self.rootNode = createTransformGroup("model_rootNode_dummy")
	link(getRootNode(), self.rootNode)
end
function HumanModel:load(xmlFilename, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.xmlFile = XMLFile.loadIfExists("playerXML", xmlFilename, PlayerSystem.xmlSchema)
	if self.xmlFile == nil then
		asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
	else
		local onModelLoadedCallback = function(_, loadingState)
			if self.xmlFile ~= nil then
				self.xmlFile:delete()
				self.xmlFile = nil
			end
			self:updateVisibility()
			if asyncCallbackFunction ~= nil then
				asyncCallbackFunction(asyncCallbackObject, loadingState, asyncCallbackArguments)
			end
		end
		self:loadFromXMLFileAsync(self.xmlFile, isRealPlayer, isOwner, isAnimated, onModelLoadedCallback)
	end
end
function HumanModel:loadFromXMLFileAsync(xmlFile, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.xmlFilename = xmlFile:getFilename()
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFilename)
	local i3dFilename = xmlFile:getValue("player.filename", nil)
	self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
	self.isRealPlayer = isRealPlayer
	self.isStyleFullyLoaded = false
	self.isBaseFullyLoaded = false
	self:updateVisibility()
	self.asyncLoadCallbackFunction = asyncCallbackFunction
	self.asyncLoadCallbackObject = asyncCallbackObject
	self.asyncLoadCallbackArguments = asyncCallbackArguments
	local oldSharedLoadRequestId = self.sharedLoadRequestId
	for _, sharedLoadRequestId in pairs(self.sharedLoadRequestIds) do
		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end
	table.clear(self.sharedLoadRequestIds)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.loadFileFinished, self, { xmlFile = xmlFile, isRealPlayer = isRealPlayer, isOwner = isOwner, isAnimated = isAnimated })
	if oldSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(oldSharedLoadRequestId)
	end
end
function HumanModel:loadFileFinished(rootNode, failedReason, arguments)
	if rootNode == 0 then
		Logging.error("Unable to load player model %q", self.i3dFilename)
		self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
	else
		local xmlFile = arguments.xmlFile
		if xmlFile == nil or g_xmlManager:getFileByHandle(xmlFile:getHandle()) == nil then
			Logging.error("Unable to load player xml %q", self.xmlFilename)
			self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
			return
		end
		self:reset()
		I3DUtil.loadI3DComponents(rootNode, self.components)
		I3DUtil.loadI3DMapping(xmlFile, "player", self.components, self.i3dMappings)
		self.rootNode = rootNode
		local animationFilename = xmlFile:getValue("player.animation#filename")
		if animationFilename ~= nil then
			self.animationFilename = Utils.getFilename(animationFilename, self.baseDirectory)
		else
			Logging.xmlWarning(xmlFile, "No animation filename defined at %q", "player.animation#filename")
		end
		local soundFilename = xmlFile:getValue("player.sounds#filename")
		if soundFilename ~= nil then
			self.soundFilename = Utils.getFilename(soundFilename, self.baseDirectory)
		else
			Logging.xmlWarning(xmlFile, "No sounds filename defined at %q", "player.sound#filename")
		end
		self.skeleton = xmlFile:getValue("player.model.skeleton#node", nil, self.components, self.i3dMappings)
		if self.skeleton == nil then
			Logging.devError("Failed to find skeleton root node in '%s'", self.i3dFilename)
		end
		self.mesh = xmlFile:getValue("player.model.mesh#node", nil, self.components, self.i3dMappings)
		if self.mesh == nil then
			Logging.devError("Failed to find player mesh in '%s'", self.i3dFilename)
		end
		self.thirdPersonHipsNode = xmlFile:getValue("player.model.hips#node", nil, self.components, self.i3dMappings)
		self.thirdPersonSpineNode = xmlFile:getValue("player.model.spine#node", nil, self.components, self.i3dMappings)
		self.thirdPersonSpineNodeOffset = xmlFile:getValue("player.model.spine#offset", nil, true)
		self.thirdPersonSuspensionNode = xmlFile:getValue("player.model.suspension#node", nil, self.components, self.i3dMappings)
		self.thirdPersonLeftHandNode = xmlFile:getValue("player.model.leftHand#node", nil, self.components, self.i3dMappings)
		self.thirdPersonRightHandNode = xmlFile:getValue("player.model.rightHand#node", nil, self.components, self.i3dMappings)
		self.thirdPersonLeftFootNode = xmlFile:getValue("player.model.leftFoot#node", nil, self.components, self.i3dMappings)
		self.thirdPersonRightFootNode = xmlFile:getValue("player.model.rightFoot#node", nil, self.components, self.i3dMappings)
		self.thirdPersonHeadNode = xmlFile:getValue("player.model.head#node", nil, self.components, self.i3dMappings)
		if self.mesh ~= nil then
			setClipDistance(self.mesh, 200)
		end
		if self.initIKChains then
			self:loadIKChains(xmlFile, rootNode, arguments.isRealPlayer)
		end
		if arguments.isRealPlayer then
			self.animRootThirdPerson = xmlFile:getValue("player.model.animationRoot#node", nil, self.components, self.i3dMappings)
			if self.animRootThirdPerson == nil then
				Logging.devError("Failed to find animation root node in '%s'", self.i3dFilename)
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
			self.particleSystemsInformation.systems = { swim = {}, plunge = {} }
			self.particleSystemsInformation.swimNode = createTransformGroup("swimFXNode")
			self.particleSystemsInformation.plungeNode = createTransformGroup("plungeFXNode")
			link(getRootNode(), self.particleSystemsInformation.swimNode)
			link(getRootNode(), self.particleSystemsInformation.plungeNode)
			ParticleUtil.loadParticleSystem(xmlFile:getHandle(), self.particleSystemsInformation.systems.swim, "player.particleSystems.swim", self.particleSystemsInformation.swimNode, false, nil, self.baseDirectory)
			ParticleUtil.loadParticleSystem(xmlFile:getHandle(), self.particleSystemsInformation.systems.plunge, "player.particleSystems.plunge", self.particleSystemsInformation.plungeNode, false, nil, self.baseDirectory)
		elseif not arguments.isAnimated then
			local linkNode = createTransformGroup("characterLinkNode")
			link(self.rootNode, linkNode)
			link(linkNode, self.skeleton)
			local ox = 0
			local oy = 0
			local oz = 0
			if self.thirdPersonSpineNodeOffset ~= nil then
				ox = -self.thirdPersonSpineNodeOffset[1]
				oy = -self.thirdPersonSpineNodeOffset[2]
				oz = -self.thirdPersonSpineNodeOffset[3]
			end
			local x, y, z = localToLocal(self.thirdPersonSpineNode, self.skeleton, ox, oy, oz)
			setTranslation(linkNode, -x, -y, -z)
		else
			link(self.rootNode, self.skeleton)
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
function HumanModel:loadIKChains(xmlFile, rootNode, isRealPlayer)
	self.ikChains = {}
	for i, key in xmlFile:iterator("player.ikChains.ikChain") do
		IKUtil.loadIKChain(xmlFile:getHandle(), key, rootNode, rootNode, self.ikChains)
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
function HumanModel:loadFromStyleAsync(playerStyle, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self:updateVisibility()
	if playerStyle.xmlFilename ~= self.xmlFilename then
		Logging.error("Can't set player style with different filename to player model. %s ~= %s", playerStyle.xmlFilename, self.xmlFilename)
	else
		if self.setStyleFinishCallback ~= nil then
			self.setStyleFinishCallback(self.setStyleFinishCallbackTarget, HumanModelLoadingState.CANCELED, self.setStyleFinishCallbackArguments)
		end
		self.setStyleFinishCallback = asyncCallbackFunction
		self.setStyleFinishCallbackTarget = asyncCallbackObject
		self.setStyleFinishCallbackArguments = asyncCallbackArguments
		local oldIds = self.sharedLoadRequestIds
		self.sharedLoadRequestIds = {}
		for filename, node in pairs(self.modelParts) do
			delete(node)
			self.modelParts[filename] = nil
		end
		local required = playerStyle:getRequiredNodeFiles()
		local filesAwaiter = AsyncAwaiter.new(function()
			self:onAllModelPartsLoaded(playerStyle)
		end)
		for _, filename in ipairs(required) do
			if self.sharedLoadRequestIds[filename] == nil then
				filesAwaiter:addDependency(filename)
				local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, true, self.onModelPartLoaded, self, { filename = filename, filesAwaiter = filesAwaiter })
				self.sharedLoadRequestIds[filename] = sharedLoadRequestId
			end
		end
		for filename, sharedLoadRequestId in pairs(oldIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
		if filesAwaiter:getDependenciesCount() == 0 then
			self:onAllModelPartsLoaded(playerStyle)
		end
	end
end
function HumanModel:onModelPartLoaded(node, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		self.modelParts[args.filename] = node
	end
	args.filesAwaiter:onDependencyAvailable(args.filename)
end
function HumanModel:onAllModelPartsLoaded(playerStyle)
	local loadSuccess = not self.isDeleted
	if loadSuccess then
		self:applyFromStyle(playerStyle, false)
		self.isStyleFullyLoaded = true
		self:updateVisibility()
	end
	for filename, node in pairs(self.modelParts) do
		if node ~= 0 then
			delete(node)
		end
		self.modelParts[filename] = nil
	end
	if self.setStyleFinishCallback ~= nil then
		local callbackTarget = self.setStyleFinishCallbackTarget
		local callback = self.setStyleFinishCallback
		local callbackArguments = self.setStyleFinishCallbackArguments
		self.setStyleFinishCallbackTarget = nil
		self.setStyleFinishCallback = nil
		self.setStyleFinishCallbackArguments = nil
		callback(callbackTarget, loadSuccess and HumanModelLoadingState.OK or HumanModelLoadingState.FAILED, callbackArguments)
	end
	self:updateVisibility()
end
function HumanModel:applyFromStyle(style, hideBody)
	if self.modelParts == nil or table.size(self.modelParts) == 0 then
		Logging.error("applyToStyle should only be called immediately after all model parts have been loaded!")
		return
	end
	self:setFaceNodeFromStyle(style.configs.face, style.bodyParts, hideBody)
	self:setTopNodeFromStyle(style.configs.top, style.configs.gloves)
	self:setBottomNodeFromStyle(style.configs.bottom, style.configs.footwear)
	self:setFootwearNodeFromStyle(style.configs.footwear, style.configs.bottom, style.configs.onepiece)
	self:setGlovesNodeFromStyle(style.configs.gloves)
	local hideGlasses = self:setHeadgearNodeFromStyle(style.configs.headgear, hideBody)
	self:setGlassesNodeFromStyle(style.configs.glasses, hideGlasses)
	self:setHairNodeFromStyle(style.configs.hairStyle, style.configs.headgear, style.configs.onepiece, style.hatHairstyleIndex)
	self:setFacegearNodeFromStyle(style.configs.facegear, style.configs.beard, style.configs.face)
	self:setOnepieceNodeFromStyle(style.configs.onepiece, style.configs.gloves, style.configs.footwear)
	self:setBeltVisibilityFromStyle(style.configs.top, style.configs.bottom, style.configs.onepiece)
end
function HumanModel:setFaceNodeFromStyle(faceConfig, bodyParts, hideBody)
	if self.faceNode ~= nil and entityExists(self.faceNode) then
		delete(self.faceNode)
	end
	self.faceNode = nil
	if faceConfig.selectedItemIndex == 0 then
		return
	end
	local selectedFace = faceConfig:getSelectedItem()
	local skinColor = selectedFace.skinColor
	for _, part in ipairs(bodyParts) do
		local node = self.i3dMappings[part.nodeName].nodeId
		if node == nil then
			continue
		end
		setVisibility(node, not hideBody)
		setShaderParameter(node, "colorScaleR", skinColor.r, skinColor.g, skinColor.b, 1, false)
	end
	local faceNode = nil
	if not string.isNilOrWhitespace(selectedFace.filename) then
		local originalFaceNode = self.modelParts[selectedFace.filename]
		if originalFaceNode ~= nil then
			faceNode = clone(originalFaceNode, false, false, false)
		end
	end
	if faceNode == nil then
		Logging.error("Could not clone player's face!")
	else
		local faceSourceNode = I3DUtil.indexToObject(faceNode, selectedFace.nodePath)
		local attachmentNode = self.i3dMappings[selectedFace.attachPoint].nodeId
		link(attachmentNode, faceSourceNode)
		self.faceNode = faceSourceNode
		local oldFaceSkeleton = getChildAt(faceNode, 0)
		I3DUtil.setShapeBonesRec(faceSourceNode, self.skeleton, oldFaceSkeleton, true)
		I3DUtil.iterateRecursively(faceSourceNode, function(node)
			if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "sssColor") then
				setShaderParameter(node, "colorScaleR", skinColor.r, skinColor.g, skinColor.b, 1, false)
			end
		end)
		delete(faceNode)
	end
end
function HumanModel:setTopNodeFromStyle(topConfig, glovesConfig)
	if self.topNode ~= nil and entityExists(self.topNode) then
		delete(self.topNode)
	end
	self.topNode = nil
	if topConfig.selectedItemIndex == 0 then
		return
	else
		local selectedGloves = glovesConfig:getSelectedItem()
		local extent = selectedGloves ~= nil and selectedGloves.extent or "hands"
		self.topNode = topConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, extent)
	end
end
function HumanModel:setBottomNodeFromStyle(bottomConfig, footwearConfig)
	if self.bottomNode ~= nil and entityExists(self.bottomNode) then
		delete(self.bottomNode)
	end
	self.bottomNode = nil
	if bottomConfig.selectedItemIndex == 0 then
		return
	else
		local footwearItem = footwearConfig:getSelectedItem()
		local footwearExtent = footwearItem ~= nil and footwearItem.extent or "low"
		self.bottomNode = bottomConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, footwearExtent)
	end
end
function HumanModel:setFootwearNodeFromStyle(footwearConfig, bottomConfig, onepieceConfig)
	if self.footwearNode ~= nil and entityExists(self.footwearNode) then
		delete(self.footwearNode)
	end
	self.footwearNode = nil
	if footwearConfig.selectedItemIndex == 0 then
		return
	else
		local extent = "high"
		if onepieceConfig.selectedItemIndex ~= 0 then
			local onepieceItem = onepieceConfig:getSelectedItem()
			if onepieceItem ~= nil then
				extent = onepieceItem.extent or extent
			end
		elseif bottomConfig.selectedItemIndex ~= 0 then
			local bottomItem = bottomConfig:getSelectedItem()
			if bottomItem ~= nil then
				extent = bottomItem.extent or extent
			end
		end
		self.footwearNode = footwearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, extent)
	end
end
function HumanModel:setGlovesNodeFromStyle(glovesConfig)
	if self.glovesNode ~= nil and entityExists(self.glovesNode) then
		delete(self.glovesNode)
	end
	self.glovesNode = nil
	if glovesConfig.selectedItemIndex == 0 then
		return
	else
		self.glovesNode = glovesConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	end
end
function HumanModel:setHeadgearNodeFromStyle(headgearConfig)
	if self.headgearNode ~= nil and entityExists(self.headgearNode) then
		delete(self.headgearNode)
	end
	self.headgearNode = nil
	if headgearConfig.selectedItemIndex == 0 then
		return false
	else
		self.headgearNode = headgearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
		local headgearItem = headgearConfig:getSelectedItem()
		return headgearItem.hideGlasses
	end
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
function HumanModel:setHairNodeFromStyle(hairStyleConfig, headgearConfig, onepieceConfig, hatHairstyleIndex)
	if self.hairNode ~= nil and entityExists(self.hairNode) then
		delete(self.hairNode)
	end
	self.hairNode = nil
	if hairStyleConfig.selectedItemIndex == 0 then
		return
	else
		local onepieceItem = onepieceConfig:getSelectedItem()
		if hatHairstyleIndex ~= nil and (headgearConfig.selectedItemIndex ~= 0 or onepieceConfig.selectedItemIndex ~= 0 and onepieceItem.disabledOptions.headgear) then
			self.hairNode = hairStyleConfig:cloneAndEnableItemIndex(hatHairstyleIndex, self.modelParts, self.skeleton, self.i3dMappings)
			return
		end
		self.hairNode = hairStyleConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	end
end
function HumanModel:setFacegearNodeFromStyle(facegearConfig, beardConfig, faceConfig)
	if self.facegearNode ~= nil and entityExists(self.facegearNode) then
		delete(self.facegearNode)
	end
	if self.beardNode ~= nil and entityExists(self.beardNode) then
		delete(self.beardNode)
	end
	self.facegearNode = nil
	self.beardNode = nil
	if facegearConfig.selectedItemIndex ~= 0 then
		self.facegearNode = facegearConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
	else
		local selectedFace = faceConfig:getSelectedItem()
		if selectedFace ~= nil and beardConfig.selectedItemIndex ~= 0 then
			for i = beardConfig.selectedItemIndex, #beardConfig.items do
				local item = beardConfig.items[i]
				if item.faceName == nil or item.faceName == selectedFace.name or faceConfig.selectedItemIndex == 0 and item.faceName == faceConfig.items[1].name then
					self.beardNode = beardConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings)
					return
				end
			end
		end
	end
end
function HumanModel:setOnepieceNodeFromStyle(onepieceConfig, glovesConfig, footwearConfig)
	if self.onepieceNode ~= nil and entityExists(self.onepieceNode) then
		delete(self.onepieceNode)
	end
	self.onepieceNode = nil
	if onepieceConfig.selectedItemIndex == 0 then
		return
	else
		local extentToCompare = glovesConfig:getSelectedItem() ~= nil and glovesConfig:getSelectedItem().extent or "hands"
		local extentToCompare2 = footwearConfig:getSelectedItem() ~= nil and footwearConfig:getSelectedItem().extent or "low"
		self.onepieceNode = onepieceConfig:cloneAndEnableSelection(self.modelParts, self.skeleton, self.i3dMappings, extentToCompare, extentToCompare2)
	end
end
function HumanModel:setBeltVisibilityFromStyle(topConfig, bottomConfig, onepieceConfig)
	if bottomConfig.selectedItemIndex == 0 or topConfig.selectedItemIndex == 0 and onepieceConfig.selectedItemIndex ~= 0 then
		return
	end
	local hideBelt = false
	if topConfig.selectedItemIndex ~= 0 then
		local item = topConfig:getSelectedItem()
		if item ~= nil then
			hideBelt = item.hideBelt
		end
	end
	local selectedBottom = bottomConfig:getSelectedItem()
	if selectedBottom ~= nil and selectedBottom.belt ~= nil then
		local node = I3DUtil.indexToObject(self.bottomNode, selectedBottom.belt)
		if node ~= nil then
			setVisibility(node, not hideBelt)
		end
	end
end
function HumanModel:iterateShapesRecursively(callback)
	local shapeCheck = function(node)
		if getHasClassId(node, ClassIds.SHAPE) then
			return callback(node)
		else
			return true
		end
	end
	I3DUtil.iterateRecursively(self.rootNode, shapeCheck)
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
function HumanModel:getIsInCameraFrustum(camera, aspectRatio)
	if not self.isLoaded then
		return false
	else
		camera = camera or g_cameraManager:getActiveCamera()
		aspectRatio = aspectRatio or g_presentedScreenAspectRatio
		local hasShapeInFrustum = false
		local checkShapeIsInFrustum = function(shapeNode)
			if not getIsInCameraFrustum(shapeNode, camera, aspectRatio) then
				return true
			else
				hasShapeInFrustum = true
				return false
			end
		end
		self:iterateShapesRecursively(checkShapeIsInFrustum)
		return hasShapeInFrustum
	end
end
function HumanModel:getVisibility()
	return getVisibility(self.rootNode)
end
function HumanModel:updateVisibility()
	local isVisible = self.isVisible and self.isBaseFullyLoaded and self.isStyleFullyLoaded and self.isParentVisible
	if self.rootNode ~= nil then
		setVisibility(self.rootNode, isVisible)
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
function HumanModel:debugDraw(x, y, textSize)
	local function drawBones(boneNode, parentX, parentY, parentZ)
		local boneX, boneY, boneZ = getWorldTranslation(boneNode)
		drawDebugLine(parentX, parentY, parentZ, 0, 0, 0, boneX, boneY, boneZ, 1, 0, 0, false)
		for i = 0, getNumOfChildren(boneNode) - 1 do
			drawBones(getChildAt(boneNode, i), boneX, boneY, boneZ)
		end
	end
	if self.skeleton ~= nil then
		local boneX, boneY, boneZ = getWorldTranslation(getChildAt(self.skeleton, 0))
		drawBones(getChildAt(self.skeleton, 0), boneX, boneY, boneZ)
	end
end
