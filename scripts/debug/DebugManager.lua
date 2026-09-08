-- Local values: DebugManager_mt
DebugManager = {}
DebugManager.DEFAULT_GROUP = "default"
DebugManager.DEFAULT_GROUP_ELEMENT_LIMIT = 250
local DebugManager_mt = Class(DebugManager, AbstractManager)

-- Upvalues: DebugManager_mt
-- Local values: self
function DebugManager.new(customMt)
	-- upvalues: (copy) DebugManager_mt
	return AbstractManager.new(customMt or DebugManager_mt)
end

function DebugManager:initDataStructures()
	self.drawables = {}
	self.frameElements = {}
	self.elementIdToElement = {}
	self.elementToElementId = {}
	self.groupIdToElements = {}
	self.elementsWithLifetime = {}
	self.hiddenGroups = {}
	self.debugMaterial = nil
	if self.debugMaterialNode ~= nil then
		delete(self.debugMaterialNode)
		self.debugMaterialNode = nil
	end
	self.splineDebugEnabled = false
	self.splineDebugElements = {}
	self.occluderDebugEnabled = false
	if not self.initialized then
		addConsoleCommand("gsDebugManagerClearElements", "Removes all permanent elements and functions from DebugManager", "consoleCommandRemoveElements", self)
		addConsoleCommand("gsDebugManagerGroupsList", "List all currently used debug element groups with visibility and number of elements", "consoleCommandGroupsList", self)
		addConsoleCommand("gsDebugManagerGroupVisibilitySet", "Toggle or set visibility of given group name", "consoleCommandGroupVisibilitySet", self, "groupId; [visibility]")
		addConsoleCommand("gsDebugManagerGroupRemove", "Remove group and its debug elements", "consoleCommandGroupRemove", self)
		addConsoleCommand("gsSplineDebug", "Toggles debug visualization for all splines currently in the scene", "consoleCommandSplineToggleDebug", self, "[displayEPs]")
		addConsoleCommand("gsTerrainLayerDebug", "Toggles debug visualization for terrain layers", "consoleCommandLayerDebug", self, "visualizeAttributeName")
		self.initialized = true
	end
end

-- Local values: debugMatI3d
function DebugManager:getDebugMat()
	if self.debugMaterial == nil then
		local v5_ = loadI3DFile("data/shared/materialHolders/debugMaterialHolder.i3d", false, false, false)
		self.debugMaterialNode = getChildAt(v5_, 0)
		unlink(self.debugMaterialNode)
		self.debugMaterial = getMaterial(self.debugMaterialNode, 0)
		delete(v5_)
	end
	return self.debugMaterial
end

function DebugManager:unloadMapData()
	self.loadedMapData = false
	self:initDataStructures()
end

-- Local values: elementId, elementToRemove
function DebugManager:addElement(debugElement, groupId, lifetime, maxCount)
	if debugElement ~= nil then
		local v12_ = groupId or DebugManager.DEFAULT_GROUP
		if self.elementToElementId[debugElement] == nil then
			local v13_ = Utils.getUniqueId(debugElement, self.elementIdToElement, "debugElement", 10)
			self.elementIdToElement[v13_] = debugElement
			self.elementToElementId[debugElement] = v13_
			self.groupIdToElements[v12_] = self.groupIdToElements[v12_] or {}
			local v14_ = self.groupIdToElements[v12_]
			table.insert(v14_, debugElement)
			if maxCount == nil then
				maxCount = v12_ ~= DebugManager.DEFAULT_GROUP and math.huge or DebugManager.DEFAULT_GROUP_ELEMENT_LIMIT
			end
			if maxCount < #self.groupIdToElements[v12_] then
				self:removeElement(self.groupIdToElements[v12_][1])
			end
			if lifetime ~= nil then
				debugElement.removeTime = g_time + lifetime
				local v15_ = self.elementsWithLifetime
				table.insert(v15_, debugElement)
				table.sort(self.elementsWithLifetime, function(p16_, p17_)
					return p16_.removeTime > p17_.removeTime
				end)
			end
			return v13_
		end
	end
end

-- Local values: elementId, groupId, groupElements, index
function DebugManager:removeElement(debugElement)
	if debugElement ~= nil then
		local v20_ = self.elementToElementId[debugElement]
		for v21_, v22_ in pairs(self.groupIdToElements) do
			local v23_ = table.find(v22_, debugElement)
			if v23_ then
				table.remove(v22_, v23_)
				if #v22_ == 0 then
					self.groupIdToElements[v21_] = nil
				end
				self.elementIdToElement[v20_] = nil
				self.elementToElementId[debugElement] = nil
				table.removeElement(self.elementsWithLifetime, debugElement)
				return
			end
		end
		Logging.warning("Unable to remove debug element \'%s\', not found", v20_)
		printCallstack()
	end
end

-- Local values: element
function DebugManager:removeElementById(elementId)
	self:removeElement(self.elementIdToElement[elementId])
end

function DebugManager:getElement(elementId)
	return self.elementIdToElement[elementId]
end

-- Local values: elementIndex
function DebugManager:removeGroup(groupId)
	if self.groupIdToElements[groupId] ~= nil then
		for v30_ = #self.groupIdToElements[groupId], 1, -1 do
			self:removeElement(self.groupIdToElements[groupId][v30_])
		end
	end
end

function DebugManager:setGroupVisibility(groupId, isVisible)
	self.hiddenGroups[groupId] = not isVisible or nil
end

-- Local values: groupId, elements
function DebugManager:listGroups(groupId)
	print("Currently available debug groups:")
	if next(self.groupIdToElements) == nil then
		print("no non-empty groups")
	end
	for v35_, v36_ in pairs(self.groupIdToElements) do
		print(string.format("  %s%s (%d elements)", self.hiddenGroups[v35_] and "[hidden] " or "", v35_, #v36_))
	end
end

-- Local values: match, groupId
function DebugManager:getGroupIdFromSubstring(groupIdSubstring)
	if next(self.groupIdToElements) == nil then
		return groupIdSubstring
	end
	if self.groupIdToElements[groupIdSubstring] ~= nil then
		return groupIdSubstring
	end
	local v39_ = nil
	for v40_ in pairs(self.groupIdToElements) do
		if string.contains(string.upper(v40_), string.upper(groupIdSubstring)) then
			if v39_ ~= nil then
				return groupIdSubstring
			end
			v39_ = v40_
		end
	end
	return v39_
end

-- Local values: index, element, elementId, groupId, groupElements, _, element
function DebugManager:update(dt)
	for v43_ = #self.elementsWithLifetime, 1, -1 do
		local v44_ = self.elementsWithLifetime[v43_]
		if v44_.removeTime == nil then
			local v45_ = table.find(self.elementIds, v44_)
			Logging.error("Element without \'removeTime\' found in \'elementsWithLifetime\' array: %s %s", v44_, v45_)
		end
		if v44_.removeTime >= g_time then
			break
		end
		self:removeElement(v44_)
	end
	for v46_, v47_ in pairs(self.groupIdToElements) do
		if self.hiddenGroups[v46_] == nil then
			for _, v48_ in ipairs(v47_) do
				if v48_.update ~= nil and (v48_.getShouldBeUpdated == nil or v48_:getShouldBeUpdated()) then
					v48_:update(dt)
				end
			end
		end
	end
end

-- Local values: groupId, groupElements, _, element, i
function DebugManager:drawPreUI()
	for v50_, v51_ in pairs(self.groupIdToElements) do
		if self.hiddenGroups[v50_] == nil then
			for _, v52_ in ipairs(v51_) do
				if v52_.draw ~= nil and (v52_.getShouldBeDrawn == nil or v52_:getShouldBeDrawn()) then
					v52_:draw()
				end
			end
		end
	end
	for v53_ = #self.frameElements, 1, -1 do
		self.frameElements[v53_]:draw()
		table.remove(self.frameElements, v53_)
	end
end

-- Local values: _, drawable
function DebugManager:drawPostUI()
	for _, v55_ in pairs(self.drawables) do
		v55_:drawDebug()
	end
end

function DebugManager:addDrawable(drawable, key)
	if drawable.drawDebug == nil then
		Logging.error("DebugManager:addDrawable(): Provided drawable does not have a \'drawDebug\' function")
		printCallstack()
	else
		if key ~= nil and (self.drawables[key] ~= nil and self.drawables[key] ~= drawable) then
			Logging.warning("DebugManager:addDrawable(): Key \'%s\' already has a different drawable registered", key)
		end
		self.drawables[key or drawable] = drawable
	end
end

function DebugManager:removeDrawable(drawableOrKey)
	self.drawables[drawableOrKey] = nil
end

function DebugManager:hasDrawable(drawableOrKey)
	return self.drawables[drawableOrKey] ~= nil
end

function DebugManager:addPermanentElement(element)
	Logging.error("\'DebugManager:addPermanentElement\' is deprected, use addElement instead")
	printCallstack()
end

function DebugManager:removePermanentElement(element)
	Logging.error("\'DebugManager:removePermanentElement\' is deprected, use removeElement or removeElementById instead")
	printCallstack()
end

function DebugManager:addFrameElement(element)
	table.addElement(self.frameElements, element)
end

function DebugManager:addPermanentFunction(funcAndParams)
	Logging.error("\'DebugManager:addPermanentFunction\' is deprected, use DebugFunction instance and addElement instead")
	printCallstack()
end

function DebugManager:removePermanentFunction(funcAndParams)
	Logging.error("\'DebugManager:removePermanentFunction\' is deprected, use DebugFunction instance and addElement instead")
	printCallstack()
end

-- Local values: element
function DebugManager:consoleCommandRemoveElements()
	for v66_ in pairs(self.funcAndParamsToElementId) do
		if v66_.delete ~= nil then
			v66_:delete()
		end
	end
	self.funcAndParamsIdToElement = {}
	self.funcAndParamsToElementId = {}
	self.groupIdToElements = {}
	self.funcAndParamssWithLifetime = {}
	return "Cleared all debug funcAndParamss"
end

function DebugManager:consoleCommandGroupsList()
	self:listGroups()
end

-- Local values: usage, groupId, visibility
function DebugManager:consoleCommandGroupVisibilitySet(groupIdInput, visibilityStr)
	if groupIdInput == nil then
		Logging.error("No groupId given")
		print("Usage: gsDebugManagerGroupVisibilitySet groupId <visibility>")
		self:listGroups()
	else
		local v71_ = self:getGroupIdFromSubstring(groupIdInput)
		if self.groupIdToElements[v71_] ~= nil then
			local v72_
			if visibilityStr == nil then
				v72_ = self.hiddenGroups[v71_] ~= nil
			else
				v72_ = Utils.stringToBoolean(visibilityStr)
			end
			self:setGroupVisibility(v71_, v72_)
			return string.format("Debug funcAndParams group \'%s\' now %s", v71_, v72_ and "visible" or "hidden")
		end
		Logging.error("No group \'%s\' with active funcAndParamss", groupIdInput)
	end
end

-- Local values: usage, groupId
function DebugManager:consoleCommandGroupRemove(groupIdInput)
	if groupIdInput == nil then
		Logging.error("No groupId given")
		print("Usage: gsDebugManagerGroupRemove groupId")
		self:listGroups()
	else
		local v75_ = self:getGroupIdFromSubstring(groupIdInput)
		if self.groupIdToElements[v75_] ~= nil then
			self:removeGroup(v75_)
			return string.format("Removed debug funcAndParams group \'%s", v75_)
		end
		Logging.error("No group \'%s\' with active funcAndParamss", groupIdInput)
	end
end

-- Local values: displayEPs, debugMat, numAffectedNodes, checkNode
function DebugManager:consoleCommandSplineToggleDebug(displayEPsStr)
	self.splineDebugEnabled = not self.splineDebugEnabled
	if not self.splineDebugEnabled then
		g_debugManager:removeGroup("splineDebug")
		return string.format("Removed spline debug funcAndParamss")
	end
	local v_u_78_ = Utils.stringToBoolean(displayEPsStr)
	local v_u_79_ = self:getDebugMat()
	local v_u_80_ = 0
	local function v86_(p81_)
		-- upvalues: (copy) v_u_79_, (copy) v_u_78_, (ref) v_u_80_
		if I3DUtil.getIsSpline(p81_) then
			DebugUtil.setNodeEffectivelyVisible(p81_)
			local v82_, v83_, v84_ = DebugUtil.getDebugColor(p81_):unpack()
			setMaterial(p81_, v_u_79_, 0)
			setShaderParameter(p81_, "color", v82_, v83_, v84_, 0, false)
			setShaderParameter(p81_, "alpha", 1, 0, 0, 0, false)
			local v85_ = DebugSpline.new()
			v85_:createWithNode(p81_, nil, nil, v_u_78_):setColorRGBA(v82_, v83_, v84_):setClipDistance(500)
			g_debugManager:addElement(v85_, "splineDebug")
			v_u_80_ = v_u_80_ + 1
		end
	end
	I3DUtil.iterateRecursively(getRootNode(), v86_)
	return string.format("Added debug visualization to %d splines", v_u_80_)
end

-- Local values: cellSize, radius, cellColor, layerAttributeNames, layerIndexToAttributes, numLayers, layerIndex, layerAttributes, _, layerAttributeName, text, textColor, cellValueToVisualize
function DebugManager:consoleCommandLayerDebug(visualizeAttributeName)
	self.layerDebug = not self.layerDebug
	if not self.layerDebug then
		g_debugManager:removeElement(self.layerDebugBitVectorMap)
		self.layerDebugBitVectorMap = nil
		return "Disabled terrain layer debug"
	end
	self.layerDebugBitVectorMap = DebugBitVectorMap.newSimple(6, 1, false, 0.1, nil, nil, nil, false)
	local v_u_89_ = Color.new(0, 0, 0, 1)
	function self.layerDebugBitVectorMap.getColorForValue(_, p90_)
		-- upvalues: (copy) v_u_89_
		local v91_ = v_u_89_
		local v92_ = v_u_89_
		local v93_ = v_u_89_
		local v94_, v95_, v96_ = Utils.getGreenRedBlendedColor(p90_)
		v91_.r = v94_
		v92_.g = v95_
		v93_.b = v96_
		return v_u_89_
	end
	local v_u_97_ = getTerrainNumOfLayers(g_terrainNode)
	local v_u_98_ = {}
	local v99_ = {
		"viscosity",
		"firmness",
		"firmnessWet",
		"porosityAtZeroRoughness",
		"porosityAtFullRoughness"
	}
	for v100_ = 0, v_u_97_ do
		local v101_ = {}
		v_u_98_[v100_] = v101_
		for _, v102_ in ipairs(v99_) do
			v101_[v102_] = getTerrainLayerXmlAttribute(g_terrainNode, v100_, v102_)
		end
	end
	local v_u_103_ = ""
	local v_u_104_ = nil
	local v_u_105_ = nil
	self.layerDebugBitVectorMap:createWithCustomFunc(function(_, p106_, p107_, p108_, _, _, p109_)
		-- upvalues: (ref) v_u_103_, (copy) v_u_97_, (ref) v_u_104_, (copy) v_u_98_, (copy) visualizeAttributeName, (ref) v_u_105_
		v_u_103_ = ""
		local v110_ = (p106_ + p108_) * 0.5
		local v111_ = (p107_ + p109_) * 0.5
		for v112_ = 0, v_u_97_ do
			if getTerrainLayerAtWorldPos(g_terrainNode, v112_, v110_, 0, v111_) > 0 then
				v_u_103_ = getTerrainLayerName(g_terrainNode, v112_)
				v_u_104_ = DebugUtil.getDebugColor(v112_)
				for v113_, v114_ in pairs(v_u_98_[v112_]) do
					v_u_103_ = v_u_103_ .. string.format("\n %s %.3f", v113_, v114_)
					if v113_ == visualizeAttributeName then
						v_u_105_ = v114_
					end
				end
				local v115_, v116_, v117_, v118_, v119_ = getTerrainAttributesAtWorldPos(g_terrainNode, v110_, 0, v111_, true, true, true, true, true)
				v_u_103_ = v_u_103_ .. string.format("\n rgb %.2f %.2f %.2f", v115_, v116_, v117_)
				v_u_103_ = v_u_103_ .. string.format("\n softness %.3f", v118_)
				if visualizeAttributeName == "softness" then
					v_u_105_ = v118_
				end
				v_u_103_ = v_u_103_ .. string.format("\n materialId %d", v119_)
				break
			end
		end
		local v120_ = getTerrainHeightAtWorldPos(g_terrainNode, v110_, 0, v111_)
		local v121_, v122_, v123_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		local v124_ = 0.03 / MathUtil.vector3Length(v121_ - v110_, v122_ - v120_, v123_ - v111_)
		local v125_ = math.clamp(v124_, 0.001, 0.02)
		Utils.renderTextAtWorldPosition(v110_, v120_, v111_, v_u_103_, v125_, 0, v_u_104_:unpack())
		return v_u_105_
	end)
	g_debugManager:addElement(self.layerDebugBitVectorMap)
	return "Enabled terrain layer debug, " .. (visualizeAttributeName == nil and "no layer attribute name given to visualize" or (string.format("visualizing layer %q as color gradient in F5 debug", visualizeAttributeName) or "no layer attribute name given to visualize"))
end
g_debugManager = DebugManager.new()
