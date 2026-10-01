PlayerStyleItem = {}
local PlayerStyleItem_mt = Class(PlayerStyleItem)
PlayerStyleItem.EMPTY_NAME = "empty"
function PlayerStyleItem.registerXMLPaths(xmlSchema, baseKey, itemName)
	local baseItemKey = baseKey .. "." .. itemName .. "(?)"
	PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, baseItemKey)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#name", "The name of the item", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#filename", "The filename of the item", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".animation#expressionsFilename", "The filename of the expressions for faces", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".animation#filename", "The filename of the animation for faces", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".animation#skeletonNode", "The node path string of the skeleton node for facial animations", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#node", "The node path string of the item. This indexes the i3d node loaded from the i3d file, so cannot be mapped until the instance is created", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#node2", "The node path string of the item. This indexes the i3d node loaded from the i3d file, so cannot be mapped until the instance is created", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#brand", "The brand of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#extent", "The main extent of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#extraContentId", "The id of the extra content of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#attachPoint", "The name of the mapped node that the item is attached to", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#skinColor", "The skin color applied to the item. This only applies to faces", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#iconFilename", "Icon filename of the item", nil, false)
	xmlSchema:register(XMLValueType.BOOL, baseItemKey .. "#isSelectable", "True if this item is selectable in the wardrobe screen; otherwise false", true)
	xmlSchema:register(XMLValueType.BOOL, baseItemKey .. "#hidden", "True if this item is hidden; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, baseItemKey .. "#beltHidden", "True if this top hides the belt; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, baseItemKey .. "#hideGlasses", "True if this headgear hides the glasses; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, baseItemKey .. "#forHat", "True if this hair style is for a hat; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. "#face", "The type of face this beard is for", nil, false)
	xmlSchema:register(XMLValueType.INT, baseItemKey .. "#colorable", "How many slots of colorable data this item has", 0, false)
	xmlSchema:register(XMLValueType.INT, baseItemKey .. "#defaultPrimaryIndex", "The default primary color index (1-based) of the item", nil, false)
	PlayerStyle.registerXMLColorNode(xmlSchema, baseItemKey .. ".colors")
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".hidesBodypart(?)#name", "The name of the body part to hide", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".extent(?)#node", "The node path string of the extent node", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".extent(?)#type", "The type of the extent", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".disablesOption(?)#name", "The name of the option that is disabled by this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseItemKey .. ".belt#node", "The node path of the belt for tops", nil, false)
end
function PlayerStyleItem.new()
	local self = setmetatable({}, PlayerStyleItem_mt)
	self.name = nil
	self.filename = nil
	self.visualFilename = nil
	self.expressionsFilename = nil
	self.skeletonNodePath = nil
	self.nodePath = nil
	self.nodePath2 = nil
	self.brandName = nil
	self.brand = nil
	self.extraContentId = nil
	self.attachPoint = nil
	self.skinColor = nil
	self.iconFilename = nil
	self.belt = nil
	self.forHat = nil
	self.hidden = nil
	self.isSelectable = nil
	self.hideBelt = nil
	self.hideGlasses = nil
	self.faceName = nil
	self.extent = nil
	self.extents = {}
	self.hiddenBodyParts = {}
	self.hasDisabledItems = false
	self.disabledOptions = {}
	self.colorableSlots = 0
	self.possibleColors = {}
	self.defaultPrimaryColorIndex = nil
	return self
end
function PlayerStyleItem.newEmpty(emptyIconFilename)
	local self = PlayerStyleItem.new(false)
	self.name = PlayerStyleItem.EMPTY_NAME
	self.iconFilename = emptyIconFilename
	return self
end
function PlayerStyleItem:loadFromConfigurationXMLFile(xmlFile, itemKey, defaultColors, attachmentPoints, isHair)
	self.name = xmlFile:getValue(itemKey .. "#name", nil)
	self.filename = Utils.getFilename(xmlFile:getValue(itemKey .. "#filename", nil))
	self.nodePath = xmlFile:getValue(itemKey .. "#node", nil)
	if string.isNilOrWhitespace(self.name) or string.isNilOrWhitespace(self.filename) or string.isNilOrWhitespace(self.nodePath) then
		Logging.xmlError(xmlFile, "Node at %s was missing name, filename, or node path!", itemKey)
		return
	end
	self.expressionsFilename = Utils.getFilename(xmlFile:getValue(itemKey .. ".animation#expressionsFilename", nil))
	self.visualFilename = Utils.getFilename(xmlFile:getValue(itemKey .. ".animation#filename", nil))
	self.skeletonNodePath = xmlFile:getValue(itemKey .. ".animation#skeletonNode", nil)
	self.node2 = xmlFile:getValue(itemKey .. "#node2", nil)
	self.extraContentId = xmlFile:getValue(itemKey .. "#extraContentId", nil)
	self.attachPoint = xmlFile:getValue(itemKey .. "#attachPoint", nil)
	self.skinColor = Color.parseFromString(xmlFile:getValue(itemKey .. "#skinColor", nil), true)
	self.iconFilename = Utils.getFilename(xmlFile:getValue(itemKey .. "#iconFilename", nil))
	self.belt = xmlFile:getValue(itemKey .. ".belt#node", nil)
	self.forHat = xmlFile:getValue(itemKey .. "#forHat", nil)
	self.hidden = xmlFile:getValue(itemKey .. "#hidden", nil)
	self.isSelectable = xmlFile:getValue(itemKey .. "#isSelectable", true)
	self.hideBelt = xmlFile:getValue(itemKey .. "#beltHidden", nil)
	self.hideGlasses = xmlFile:getValue(itemKey .. "#hideGlasses", nil)
	self.faceName = xmlFile:getValue(itemKey .. "#face", nil)
	if self.attachPoint == nil then
		Logging.xmlError(xmlFile, "Item %s has no attachment point!", self.name)
	else
		local attachmentPointName = self.attachPoint
		self.attachPoint = attachmentPoints[attachmentPointName]
		if self.attachPoint == nil then
			Logging.xmlError(xmlFile, "Item %s has an invalid attachment point %s!", self.name, attachmentPointName)
		end
		local brandName = xmlFile:getValue(itemKey .. "#brand", nil)
		if not string.isNilOrWhitespace(brandName) and g_brandManager ~= nil then
			self.brand = g_brandManager:getBrandByName(brandName)
			self.brandName = brandName
		end
		self.colorableSlots = xmlFile:getValue(itemKey .. "#colorable", isHair and 1 or 0)
		if 0 < self.colorableSlots then
			self.possibleColors = PlayerStyle.loadColors(xmlFile, itemKey .. ".colors")
			if self.possibleColors == nil or #self.possibleColors == 0 then
				self.possibleColors = defaultColors
			end
			if not isHair then
				self.defaultPrimaryColorIndex = xmlFile:getValue(itemKey .. "#defaultPrimaryIndex", nil)
				if self.defaultPrimaryColorIndex == nil or self.defaultPrimaryColorIndex < 1 or #self.possibleColors < self.defaultPrimaryColorIndex then
					Logging.xmlWarning(xmlFile, "Item '%s' has no valid default color. The color must exist in its palette.", self.name)
				end
			end
		end
		for i, hiddenBodyPartKey in xmlFile:iterator(itemKey .. ".hidesBodypart") do
			local bodyPartName = xmlFile:getValue(hiddenBodyPartKey .. "#name", nil)
			table.insert(self.hiddenBodyParts, bodyPartName)
		end
		for i, disabledOptionKey in xmlFile:iterator(itemKey .. ".disablesOption") do
			local name = xmlFile:getValue(disabledOptionKey .. "#name", nil)
			if name == nil then
				continue
			end
			if PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME[name] then
				self.disabledOptions[name] = name
				self.hasDisabledItems = true
			else
				Logging.xmlWarning(xmlFile, "Item '%s' tries to disable a non existing option '%s' in '%s'", self.name, name, disabledOptionKey)
			end
		end
		self.extent = xmlFile:getValue(itemKey .. "#extent", nil)
		for i, extentKey in xmlFile:iterator(itemKey .. ".extent") do
			local node = xmlFile:getValue(extentKey .. "#node", nil)
			local extentType = xmlFile:getValue(extentKey .. "#type", nil)
			self.extents[extentType] = node
		end
	end
end
function PlayerStyleItem:clonePart(modelParts)
	local modelPart = modelParts[self.filename]
	if modelPart == nil or modelPart == 0 then
		Logging.error("Could not load model part with name %s from model parts table!", self.filename)
		Logging.info("Current model parts:")
		print_r(modelParts)
		return nil
	end
	return clone(modelPart, false, false, false)
end
function PlayerStyleItem:cloneAndEnable(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
	if string.isNilOrWhitespace(self.filename) then
		return nil, nil
	end
	local itemFileNode = self:clonePart(modelParts)
	if itemFileNode == nil then
		return nil, nil
	end
	I3DUtil.iterateRecursively(itemFileNode, function(node)
		if getHasClassId(node, ClassIds.SHAPE) then
			local x, y, z = getShapeBoundingSphere(node)
			setShapeBoundingSphere(node, x, y, z, 2)
		end
	end)
	local itemNode = I3DUtil.indexToObject(itemFileNode, self.nodePath)
	local itemNode2 = self.nodePath2 ~= nil and I3DUtil.indexToObject(itemFileNode, self.nodePath2) or nil
	if itemNode == nil then
		Logging.error("Could not get node from path %s in file %s", self.nodePath, self.filename)
		return nil, nil
	else
		local attachmentNode = i3dMappings[self.attachPoint].nodeId
		if attachmentNode ~= nil then
			link(attachmentNode, itemNode)
			if itemNode2 ~= nil then
				link(attachmentNode, itemNode2)
			end
		end
		if i3dMappings[self.attachPoint].rootNode ~= skeleton then
			local oldSkeleton = getChildAt(itemFileNode, 0)
			I3DUtil.setShapeBonesRec(itemNode, skeleton, oldSkeleton, true)
			if itemNode2 ~= nil then
				I3DUtil.setShapeBonesRec(itemNode2, skeleton, oldSkeleton, true)
			end
		end
		for _, partName in ipairs(self.hiddenBodyParts) do
			local partNode = i3dMappings[partName] ~= nil and i3dMappings[partName].nodeId or nil
			if partNode == nil then
				Logging.error("Could not hide body part with name %s as it does not exist!", partName)
				return nil
			end
			setVisibility(partNode, false)
		end
		if extentToCompare ~= nil and self.extents ~= nil then
			if self.extents[extentToCompare] == nil then
				extentToCompare = "hands"
			end
			local seenExtents = {}
			for extentType, nodePath in pairs(self.extents) do
				local showExtent = extentType == extentToCompare or extentType == extentToCompare2
				local extentNode = I3DUtil.indexToObject(itemNode, nodePath)
				if extentNode == nil then
					continue
				end
				if seenExtents[extentNode] == nil then
					setVisibility(extentNode, showExtent)
					if showExtent then
						seenExtents[extentNode] = true
					end
				end
			end
		end
		delete(itemFileNode)
		itemFileNode = nil
		return itemNode, itemNode2
	end
end
function PlayerStyleItem:applyColorToNode(node, selectedColorIndex)
	if node == nil then
		return
	end
	if self.colorableSlots <= 0 then
		return
	end
	local color = self.possibleColors[selectedColorIndex]
	if color == nil then
		Logging.error("Color with index %d does not exist for item %s!", selectedColorIndex, self.name)
	else
		local primaryColor = color.primary
		if node ~= nil then
			setShaderParameterRecursive(node, "colorScaleR", primaryColor.r, primaryColor.g, primaryColor.b, primaryColor.a, false)
			local secondaryColor = color.secondary
			if 2 <= self.colorableSlots and secondaryColor ~= nil then
				setShaderParameterRecursive(node, "colorScaleG", secondaryColor.r, secondaryColor.g, secondaryColor.b, secondaryColor.a, false)
			end
		end
	end
end
function PlayerStyleItem:applyColorToHair(node, node2, selectedColorIndex)
	local color = self.possibleColors[selectedColorIndex]
	if color == nil then
		Logging.error("Color with index %d does not exist for item %s!", selectedColorIndex, self.name)
	else
		if node ~= nil then
			setShaderParameterRecursive(node, "primaryColor", color.primary.r, color.primary.g, color.primary.b, 1, false)
			setShaderParameterRecursive(node, "secondaryColor", color.secondary.r, color.secondary.g, color.secondary.b, 1, false)
			setShaderParameterRecursive(node, "fakeSpecularColor", color.secondary.r, color.secondary.g, color.secondary.b, 1, false)
		end
		if node2 ~= nil then
			setShaderParameterRecursive(node2, "primaryColor", color.primary.r, color.primary.g, color.primary.b, 1, false)
			setShaderParameterRecursive(node2, "secondaryColor", color.secondary.r, color.secondary.g, color.secondary.b, 1, false)
			setShaderParameterRecursive(node2, "fakeSpecularColor", color.secondary.r, color.secondary.g, color.secondary.b, 1, false)
		end
	end
end
