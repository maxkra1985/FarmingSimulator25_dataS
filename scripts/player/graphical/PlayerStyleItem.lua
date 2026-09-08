-- Local values: PlayerStyleItem_mt
PlayerStyleItem = {}
local PlayerStyleItem_mt = Class(PlayerStyleItem)
PlayerStyleItem.EMPTY_NAME = "empty"

-- Local values: baseItemKey
function PlayerStyleItem.registerXMLPaths(xmlSchema, baseKey, itemName)
	local v5_ = baseKey .. "." .. itemName .. "(?)"
	PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, v5_)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#name", "The name of the item", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#filename", "The filename of the item", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".animation#expressionsFilename", "The filename of the expressions for faces", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".animation#filename", "The filename of the animation for faces", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".animation#skeletonNode", "The node path string of the skeleton node for facial animations", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#node", "The node path string of the item. This indexes the i3d node loaded from the i3d file, so cannot be mapped until the instance is created", nil, true)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#node2", "The node path string of the item. This indexes the i3d node loaded from the i3d file, so cannot be mapped until the instance is created", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#brand", "The brand of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#extent", "The main extent of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#extraContentId", "The id of the extra content of this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#attachPoint", "The name of the mapped node that the item is attached to", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#skinColor", "The skin color applied to the item. This only applies to faces", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#iconFilename", "Icon filename of the item", nil, false)
	xmlSchema:register(XMLValueType.BOOL, v5_ .. "#isSelectable", "True if this item is selectable in the wardrobe screen; otherwise false", true)
	xmlSchema:register(XMLValueType.BOOL, v5_ .. "#hidden", "True if this item is hidden; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, v5_ .. "#beltHidden", "True if this top hides the belt; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, v5_ .. "#hideGlasses", "True if this headgear hides the glasses; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.BOOL, v5_ .. "#forHat", "True if this hair style is for a hat; otherwise false", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. "#face", "The type of face this beard is for", nil, false)
	xmlSchema:register(XMLValueType.INT, v5_ .. "#colorable", "How many slots of colorable data this item has", 0, false)
	xmlSchema:register(XMLValueType.INT, v5_ .. "#defaultPrimaryIndex", "The default primary color index (1-based) of the item", nil, false)
	PlayerStyle.registerXMLColorNode(xmlSchema, v5_ .. ".colors")
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".hidesBodypart(?)#name", "The name of the body part to hide", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".extent(?)#node", "The node path string of the extent node", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".extent(?)#type", "The type of the extent", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".disablesOption(?)#name", "The name of the option that is disabled by this item", nil, false)
	xmlSchema:register(XMLValueType.STRING, v5_ .. ".belt#node", "The node path of the belt for tops", nil, false)
end
function PlayerStyleItem.new()
	-- upvalues: (copy) PlayerStyleItem_mt
	local v6_ = PlayerStyleItem_mt
	local v7_ = setmetatable({}, v6_)
	v7_.name = nil
	v7_.filename = nil
	v7_.visualFilename = nil
	v7_.expressionsFilename = nil
	v7_.skeletonNodePath = nil
	v7_.nodePath = nil
	v7_.nodePath2 = nil
	v7_.brandName = nil
	v7_.brand = nil
	v7_.extraContentId = nil
	v7_.attachPoint = nil
	v7_.skinColor = nil
	v7_.iconFilename = nil
	v7_.belt = nil
	v7_.forHat = nil
	v7_.hidden = nil
	v7_.isSelectable = nil
	v7_.hideBelt = nil
	v7_.hideGlasses = nil
	v7_.faceName = nil
	v7_.extent = nil
	v7_.extents = {}
	v7_.hiddenBodyParts = {}
	v7_.hasDisabledItems = false
	v7_.disabledOptions = {}
	v7_.colorableSlots = 0
	v7_.possibleColors = {}
	v7_.defaultPrimaryColorIndex = nil
	return v7_
end

-- Local values: self
function PlayerStyleItem.newEmpty(emptyIconFilename)
	local v9_ = PlayerStyleItem.new(false)
	v9_.name = PlayerStyleItem.EMPTY_NAME
	v9_.iconFilename = emptyIconFilename
	return v9_
end

-- Local values: attachmentPointName, brandName, i, hiddenBodyPartKey, bodyPartName, i, disabledOptionKey, name, i, extentKey, node, extentType
function PlayerStyleItem:loadFromConfigurationXMLFile(xmlFile, itemKey, defaultColors, attachmentPoints, isHair)
	self.name = xmlFile:getValue(itemKey .. "#name", nil)
	self.filename = Utils.getFilename(xmlFile:getValue(itemKey .. "#filename", nil))
	self.nodePath = xmlFile:getValue(itemKey .. "#node", nil)
	if string.isNilOrWhitespace(self.name) or (string.isNilOrWhitespace(self.filename) or string.isNilOrWhitespace(self.nodePath)) then
		Logging.xmlError(xmlFile, "Node at %s was missing name, filename, or node path!", itemKey)
		return
	else
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
			local v16_ = self.attachPoint
			self.attachPoint = attachmentPoints[v16_]
			if self.attachPoint == nil then
				Logging.xmlError(xmlFile, "Item %s has an invalid attachment point %s!", self.name, v16_)
			end
			local v17_ = xmlFile:getValue(itemKey .. "#brand", nil)
			if not string.isNilOrWhitespace(v17_) and g_brandManager ~= nil then
				self.brand = g_brandManager:getBrandByName(v17_)
				self.brandName = v17_
			end
			self.colorableSlots = xmlFile:getValue(itemKey .. "#colorable", isHair and 1 or 0)
			if self.colorableSlots > 0 then
				self.possibleColors = PlayerStyle.loadColors(xmlFile, itemKey .. ".colors")
				if self.possibleColors == nil or #self.possibleColors == 0 then
					self.possibleColors = defaultColors
				end
				if not isHair then
					self.defaultPrimaryColorIndex = xmlFile:getValue(itemKey .. "#defaultPrimaryIndex", nil)
					if self.defaultPrimaryColorIndex == nil or (self.defaultPrimaryColorIndex < 1 or self.defaultPrimaryColorIndex > #self.possibleColors) then
						Logging.xmlWarning(xmlFile, "Item \'%s\' has no valid default color. The color must exist in its palette.", self.name)
					end
				end
			end
			for _, v18_ in xmlFile:iterator(itemKey .. ".hidesBodypart") do
				local v19_ = xmlFile:getValue(v18_ .. "#name", nil)
				local v20_ = self.hiddenBodyParts
				table.insert(v20_, v19_)
			end
			for _, v21_ in xmlFile:iterator(itemKey .. ".disablesOption") do
				local v22_ = xmlFile:getValue(v21_ .. "#name", nil)
				if v22_ ~= nil then
					if PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME[v22_] then
						self.disabledOptions[v22_] = v22_
						self.hasDisabledItems = true
					else
						Logging.xmlWarning(xmlFile, "Item \'%s\' tries to disable a non existing option \'%s\' in \'%s\'", self.name, v22_, v21_)
					end
				end
			end
			self.extent = xmlFile:getValue(itemKey .. "#extent", nil)
			for _, v23_ in xmlFile:iterator(itemKey .. ".extent") do
				local v24_ = xmlFile:getValue(v23_ .. "#node", nil)
				local v25_ = xmlFile:getValue(v23_ .. "#type", nil)
				self.extents[v25_] = v24_
			end
		end
	end
end

-- Local values: modelPart
function PlayerStyleItem:clonePart(modelParts)
	local v28_ = modelParts[self.filename]
	if v28_ ~= nil and v28_ ~= 0 then
		return clone(v28_, false, false, false)
	end
	Logging.error("Could not load model part with name %s from model parts table!", self.filename)
	Logging.info("Current model parts:")
	print_r(modelParts)
	return nil
end

-- Local values: itemFileNode, itemNode, itemNode2, attachmentNode, oldSkeleton, _, partName, partNode, seenExtents, extentType, nodePath, showExtent, extentNode
function PlayerStyleItem:cloneAndEnable(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
	if string.isNilOrWhitespace(self.filename) then
		return nil, nil
	end
	local v35_ = self:clonePart(modelParts)
	if v35_ == nil then
		return nil, nil
	end
	I3DUtil.iterateRecursively(v35_, function(p36_)
		if getHasClassId(p36_, ClassIds.SHAPE) then
			local v37_, v38_, v39_ = getShapeBoundingSphere(p36_)
			setShapeBoundingSphere(p36_, v37_, v38_, v39_, 2)
		end
	end)
	local v40_ = I3DUtil.indexToObject(v35_, self.nodePath)
	local v41_
	if self.nodePath2 == nil then
		v41_ = nil
	else
		v41_ = I3DUtil.indexToObject(v35_, self.nodePath2) or nil
	end
	if v40_ == nil then
		Logging.error("Could not get node from path %s in file %s", self.nodePath, self.filename)
		return nil, nil
	end
	local v42_ = i3dMappings[self.attachPoint].nodeId
	if v42_ ~= nil then
		link(v42_, v40_)
		if v41_ ~= nil then
			link(v42_, v41_)
		end
	end
	if i3dMappings[self.attachPoint].rootNode ~= skeleton then
		local v43_ = getChildAt(v35_, 0)
		I3DUtil.setShapeBonesRec(v40_, skeleton, v43_, true)
		if v41_ ~= nil then
			I3DUtil.setShapeBonesRec(v41_, skeleton, v43_, true)
		end
	end
	for _, v44_ in ipairs(self.hiddenBodyParts) do
		local v45_
		if i3dMappings[v44_] == nil then
			v45_ = nil
		else
			v45_ = i3dMappings[v44_].nodeId or nil
		end
		if v45_ == nil then
			Logging.error("Could not hide body part with name %s as it does not exist!", v44_)
			return nil
		end
		setVisibility(v45_, false)
	end
	if extentToCompare ~= nil and self.extents ~= nil then
		local v46_ = self.extents[extentToCompare] == nil and "hands" or extentToCompare
		local v47_ = {}
		for v48_, v49_ in pairs(self.extents) do
			local v50_ = v48_ == v46_ and true or v48_ == extentToCompare2
			local v51_ = I3DUtil.indexToObject(v40_, v49_)
			if v51_ ~= nil and v47_[v51_] == nil then
				setVisibility(v51_, v50_)
				if v50_ then
					v47_[v51_] = true
				end
			end
		end
	end
	delete(v35_)
	return v40_, v41_
end

-- Local values: color, primaryColor, secondaryColor
function PlayerStyleItem:applyColorToNode(node, selectedColorIndex)
	if node == nil then
		return
	elseif self.colorableSlots <= 0 then
		return
	else
		local v55_ = self.possibleColors[selectedColorIndex]
		if v55_ == nil then
			Logging.error("Color with index %d does not exist for item %s!", selectedColorIndex, self.name)
		else
			local v56_ = v55_.primary
			if node ~= nil then
				setShaderParameterRecursive(node, "colorScaleR", v56_.r, v56_.g, v56_.b, v56_.a, false)
				local v57_ = v55_.secondary
				if self.colorableSlots >= 2 and v57_ ~= nil then
					setShaderParameterRecursive(node, "colorScaleG", v57_.r, v57_.g, v57_.b, v57_.a, false)
				end
			end
		end
	end
end

-- Local values: color
function PlayerStyleItem:applyColorToHair(node, node2, selectedColorIndex)
	local v62_ = self.possibleColors[selectedColorIndex]
	if v62_ == nil then
		Logging.error("Color with index %d does not exist for item %s!", selectedColorIndex, self.name)
	else
		if node ~= nil then
			setShaderParameterRecursive(node, "primaryColor", v62_.primary.r, v62_.primary.g, v62_.primary.b, 1, false)
			setShaderParameterRecursive(node, "secondaryColor", v62_.secondary.r, v62_.secondary.g, v62_.secondary.b, 1, false)
			setShaderParameterRecursive(node, "fakeSpecularColor", v62_.secondary.r, v62_.secondary.g, v62_.secondary.b, 1, false)
		end
		if node2 ~= nil then
			setShaderParameterRecursive(node2, "primaryColor", v62_.primary.r, v62_.primary.g, v62_.primary.b, 1, false)
			setShaderParameterRecursive(node2, "secondaryColor", v62_.secondary.r, v62_.secondary.g, v62_.secondary.b, 1, false)
			setShaderParameterRecursive(node2, "fakeSpecularColor", v62_.secondary.r, v62_.secondary.g, v62_.secondary.b, 1, false)
		end
	end
end
