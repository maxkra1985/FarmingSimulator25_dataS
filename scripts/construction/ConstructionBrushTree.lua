-- Local values: ConstructionBrushTree_mt
ConstructionBrushTree = {}
local ConstructionBrushTree_mt = Class(ConstructionBrushTree, ConstructionBrush)
ConstructionBrushTree.ERROR = {
	["NOT_ENOUGH_MONEY"] = 200,
	["TOO_MANY_TREES"] = 201
}
ConstructionBrushTree.ERROR_MESSAGES = {
	[ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushTree.ERROR.TOO_MANY_TREES] = "ui_construction_tooManyTrees"
}

-- Upvalues: ConstructionBrushTree_mt
-- Local values: self
function ConstructionBrushTree.new(subclass_mt, cursor)
	-- upvalues: (copy) ConstructionBrushTree_mt
	local v4_ = ConstructionBrushTree:superClass().new(subclass_mt or ConstructionBrushTree_mt, cursor)
	v4_.supportsPrimaryButton = true
	v4_.supportsTertiaryButton = true
	v4_.supportsPrimaryAxis = true
	v4_.requiredPermission = Farm.PERMISSION.LANDSCAPING
	return v4_
end

function ConstructionBrushTree:delete()
	ConstructionBrushTree:superClass().delete(self)
end

function ConstructionBrushTree:activate()
	ConstructionBrushTree:superClass().activate(self)
	self.cursor:setRotationEnabled(true)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setShapeSize(1)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	self:loadTree()
	self:randomlyRotateCursor()
end

function ConstructionBrushTree:deactivate()
	self:unloadTree()
	self.cursor:setTerrainOnly(false)
	ConstructionBrushTree:superClass().deactivate(self)
end

function ConstructionBrushTree:setTree(treeType, stage, variationIndex)
	if not self.isActive then
		self.treeType = treeType
		self.treeStage = stage
		self.variationIndex = variationIndex
	end
end

function ConstructionBrushTree:setParameters(treeType, treeStage, treeVariationIndex)
	self:setTree(treeType, tonumber(treeStage), (tonumber(treeVariationIndex)))
end

function ConstructionBrushTree:update(dt)
	ConstructionBrushTree:superClass().update(self, dt)
	self:updateTreePosition()
end

-- Local values: treeDesc, stage, variation, storeItemNameCleaned
function ConstructionBrushTree:draw()
	if g_isDevelopmentVersion then
		if self.treeType == nil then
			return
		else
			local v19_ = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
			if v19_ == nil then
				return
			else
				local v20_ = v19_.stages[self.treeStage]
				if v20_ == nil then
					return
				else
					local v21_ = v20_[self.variationIndex]
					if v21_ ~= nil then
						local v22_ = string.gsub(v21_.filename, getUserProfileAppPath(), "")
						renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, v22_)
					end
				end
			end
		end
	else
		return
	end
end

-- Local values: x, y, z, rotY, err, message
function ConstructionBrushTree:updateTreePosition()
	if self.tree ~= nil then
		local v24_, v25_, v26_ = self.cursor:getHitTerrainPosition()
		if self.cursor.isVisible then
			if v24_ == nil then
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_spaceAlreadyOccupied"))
			else
				local v27_ = self.cursor:getRotation()
				setWorldTranslation(self.tree, v24_, v25_, v26_)
				setRotation(self.tree, 0, v27_, 0)
				local v28_ = self:verifyPlacement(v24_, v25_, v26_)
				if v28_ == nil then
					self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
				else
					local v29_ = g_i18n:getText(ConstructionBrushTree.ERROR_MESSAGES[v28_] or ConstructionBrush.ERROR_MESSAGES[v28_])
					self.cursor:setErrorMessage(v29_)
				end
			end
		end
		setVisibility(self.tree, self.cursor.isVisible)
	end
end

-- Local values: err, enoughMoney
function ConstructionBrushTree:verifyPlacement(x, y, z)
	local v34_ = self:verifyAccess(x, y, z)
	if v34_ == nil then
		if g_currentMission:getMoney() >= self:getPrice() then
			if g_treePlantManager:canPlantTree() then
				return nil
			else
				return ConstructionBrushTree.ERROR.TOO_MANY_TREES
			end
		else
			return ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY
		end
	else
		return v34_
	end
end

-- Local values: basePrice, treeDesc, numStages
function ConstructionBrushTree:getPrice()
	local v36_ = g_currentMission.economyManager:getBuyPrice(self.storeItem)
	local v37_ = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
	if v37_ ~= nil and v37_.stages ~= nil then
		local v38_ = #v37_.stages
		if v38_ > 0 then
			return MathUtil.lerp(0, v36_, self.treeStage / v38_)
		end
	end
	return v36_
end

function ConstructionBrushTree:randomlyRotateCursor()
	self.cursor:setRotation(math.random() * 2 * 3.141592653589793)
end

-- Local values: treeDesc, stage, variation, node, sharedLoadRequestId, failedReason
function ConstructionBrushTree:loadTree()
	if self.treeType == nil or self.treeStage == nil then
		Logging.error("Tree brush has no tree type or stage set")
		return
	else
		local v41_ = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
		if v41_ == nil then
			Logging.error("Tree type %s does not exist", self.treeType)
			return
		else
			local v42_ = v41_.stages[self.treeStage]
			if v42_ == nil then
				Logging.error("Tree type %s does not have a stage \'%d\'", self.treeType, self.treeStage)
				return
			else
				self.variationIndex = self.variationIndex or math.random(1, #v42_)
				local v43_ = v42_[self.variationIndex]
				if v43_ == nil then
					Logging.error("Tree type %s does not have stage %d variation %d", self.treeType, self.treeStage, self.variationIndex)
				else
					self.treeGrowthFactor = self.treeStage / #v41_.stages
					self.treeTypeIndex = v41_.index
					setSplitShapesLoadingFileId(-1)
					setSplitShapesNextFileId(true)
					local v44_, v45_, v46_ = g_i3DManager:loadSharedI3DFile(v43_.filename, false, false)
					self.sharedLoadRequestId = v45_
					self:onTreeLoaded(v44_, v46_)
				end
			end
		end
	end
end

function ConstructionBrushTree:onTreeLoaded(node, failedReason)
	if node == nil or node == 0 then
		Logging.warning("Failed to load tree")
		return
	elseif self.isActive then
		link(getRootNode(), node)
		I3DUtil.setShaderParameterRec(node, "windSnowLeafScale", 0, 0, 1, 80)
		self.tree = node
	else
		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
			self.sharedLoadRequestId = nil
		end
		delete(node)
	end
end

function ConstructionBrushTree:unloadTree()
	if self.tree ~= nil then
		delete(self.tree)
		self.tree = nil
		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
			self.sharedLoadRequestId = nil
		end
		self.treeFilename = nil
	end
end

-- Local values: x, y, z, rx, ry, rz, growing, pitch
function ConstructionBrushTree:onButtonPrimary()
	if self.tree ~= nil then
		local v51_, v52_, v53_ = self.cursor:getHitTerrainPosition()
		if v51_ ~= nil and self:verifyPlacement(v51_, v52_, v53_) == nil then
			local v54_ = self.cursor:getRotation()
			if g_server == nil then
				g_client:getServerConnection():sendEvent(TreePlantEvent.new(self.treeTypeIndex, v51_, v52_, v53_, 0, v54_, 0, self.treeStage, self.variationIndex, nil, false, self:getPrice(), g_localPlayer.farmId))
			else
				g_treePlantManager:plantTree(self.treeTypeIndex, v51_, v52_, v53_, 0, v54_, 0, self.treeStage, self.variationIndex, false)
				g_currentMission:addMoney(-self:getPrice(), g_localPlayer.farmId, MoneyType.SHOP_PROPERTY_BUY, true)
			end
			local v55_ = 1 - self.treeGrowthFactor
			self:playSound(ConstructionSound.ID.TREE, v55_)
			self:randomlyRotateCursor()
		end
	end
end

function ConstructionBrushTree:onButtonTertiary()
	self:randomlyRotateCursor()
end

-- Local values: treeDesc, treeStage, stage, variationIndex
function ConstructionBrushTree:onAxisPrimary(inputValue)
	if self.treeType == nil then
		return
	else
		local v59_ = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
		if v59_ == nil then
			Logging.error("Tree type %s does not exist", self.treeType)
		else
			local v60_
			if inputValue < 1 then
				local v61_ = self.treeStage - 1
				v60_ = v61_ < 1 and #v59_.stages or v61_
			else
				local v62_ = self.treeStage + 1
				v60_ = #v59_.stages < v62_ and 1 or v62_
			end
			local v63_ = v59_.stages[v60_]
			local v64_ = math.random(1, #v63_)
			self:deactivate()
			self:setTree(self.treeType, v60_, v64_)
			self:activate()
		end
	end
end

function ConstructionBrushTree:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushTree:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_RANDOM_ROTATE"
end

function ConstructionBrushTree:getAxisPrimaryText()
	if self.treeType ~= nil then
		return "$l10n_action_changeTreeSize"
	end
end
