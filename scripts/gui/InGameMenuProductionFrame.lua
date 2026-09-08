-- Local values: InGameMenuProductionFrame_mt
InGameMenuProductionFrame = {}
local InGameMenuProductionFrame_mt = Class(InGameMenuProductionFrame, TabbedMenuFrameElement)
InGameMenuProductionFrame.UPDATE_INTERVAL = 5000
InGameMenuProductionFrame.STATUS_BAR_LOW = 0.2
InGameMenuProductionFrame.STATUS_BAR_HIGH = 0.8
InGameMenuProductionFrame.POINTS_OWNED = 1
InGameMenuProductionFrame.POINTS_UNOWNED = 2
function InGameMenuProductionFrame.register()
	local v2_ = InGameMenuProductionFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuProductionFrame.xml", "ProductionFrame", v2_, true)
end

-- Upvalues: InGameMenuProductionFrame_mt
-- Local values: self
function InGameMenuProductionFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuProductionFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuProductionFrame_mt)
	v5_.hasCustomMenuButtons = true
	v5_.timeSinceLastStateUpdate = 0
	v5_.productionPoints = {}
	return v5_
end

-- Local values: newGui
function InGameMenuProductionFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuProductionFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuProductionFrame:delete()
	self.recipeItemTemplate:delete()
	InGameMenuProductionFrame:superClass().delete(self)
end

-- Local values: i, dot, isNotReloading
function InGameMenuProductionFrame:initialize()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	self.recipeItemTemplate:unlinkElement()
	self.hotspotButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonHotspot()
		end,
		["profile"] = "buttonHotspot"
	}
	self.visitButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("action_visit"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonVisit()
		end,
		["profile"] = "buttonVisitPlace"
	}
	self.activateButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_activate"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonActivate()
		end,
		["profile"] = "buttonOK"
	}
	self.toggleStorageModeButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("ui_production_changeOutputMode"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonToggleOutputMode()
		end,
		["profile"] = "buttonOK"
	}
	self.pointsSelector:setTexts({ g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_OWNED), g_i18n:getText(InGameMenuProductionFrame.SYMBOL_L10N.TEXT_UNOWNED) })
	for v_u_11_ = 1, 2 do
		self.pointsDotBox.elements[v_u_11_].getIsSelected = function()
			-- upvalues: (copy) self, (copy) v_u_11_
			return self.pointsSelector:getState() == v_u_11_
		end
	end
	self.pointsDotBox:invalidateLayout()
	FocusManager:linkElements(self.pointsList, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.productsList)
	FocusManager:linkElements(self.pointsList, FocusManager.TOP, self.pointsSelector)
	FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.productsList, FocusManager.LEFT, self.pointsList)
	FocusManager:linkElements(self.productsList, FocusManager.RIGHT, self.detailsSlider)
	FocusManager:linkElements(self.productsList, FocusManager.TOP, nil)
	FocusManager:linkElements(self.productsList, FocusManager.BOTTOM, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.LEFT, self.productsList)
	FocusManager:linkElements(self.detailsSlider, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.TOP, nil)
	FocusManager:linkElements(self.detailsSlider, FocusManager.BOTTOM, nil)
	local v_u_12_ = not self.isReloading
	if v_u_12_ then
		v_u_12_ = not g_gui.currentlyReloading
	end
	function self.pointsBoxBg.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v13_ = self.pointsList:getIsFocused()
		if v13_ then
			v13_ = v_u_12_
		end
		return v13_
	end
	function self.pointsBoxArrow.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v14_ = self.pointsList:getIsFocused()
		if v14_ then
			v14_ = v_u_12_
		end
		return v14_
	end
	function self.productsBoxBg.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v15_ = self.productsList:getIsFocused()
		if v15_ then
			v15_ = v_u_12_
		end
		return v15_
	end
	function self.productsBoxBgTop.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v16_ = self.productsList:getIsFocused()
		if v16_ then
			v16_ = v_u_12_
		end
		return v16_
	end
	function self.productsBoxBgArrow.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v17_ = self.productsList:getIsFocused()
		if v17_ then
			v17_ = v_u_12_
		end
		return v17_
	end
	function self.detailsBoxBg.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v18_ = self.detailsSlider:getIsFocused()
		if v18_ then
			v18_ = v_u_12_
		end
		return v18_
	end
	function self.detailsBoxBgTop.getIsSelected()
		-- upvalues: (copy) self, (copy) v_u_12_
		local v19_ = self.detailsSlider:getIsFocused()
		if v19_ then
			v19_ = v_u_12_
		end
		return v19_
	end
end

function InGameMenuProductionFrame:onFrameOpen()
	InGameMenuProductionFrame:superClass().onFrameOpen(self)
	self.chainManager = g_currentMission.productionChainManager
	self:updateProductionLists()
	if #self.productionPoints == 0 then
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
	end
	if self.pointsList:getItemCount() > 0 then
		FocusManager:setFocus(self.pointsList)
	else
		FocusManager:setFocus(self.pointsSelector)
	end
end

function InGameMenuProductionFrame:unloadMapData()
	self.selectedProductionPoint = nil
end

function InGameMenuProductionFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

function InGameMenuProductionFrame:getProductionPoints()
	return self.productionPoints
end

-- Local values: productions, index, listProdPoint
function InGameMenuProductionFrame:setSelectedProductionPoint(productionPoint)
	local v27_
	if productionPoint.isOwned then
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_OWNED, true)
		v27_ = self.productionPoints
	else
		self.pointsSelector:setState(InGameMenuProductionFrame.POINTS_UNOWNED, true)
		v27_ = self.unownedProductionPoints
	end
	for v28_, v29_ in ipairs(v27_) do
		if v29_ == productionPoint then
			self.pointsList:setSelectedIndex(v28_)
			return
		end
	end
end

-- Local values: _, productionPoint, hotspot, production, productionPoint, state
function InGameMenuProductionFrame:updateMenuButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if self.pointsList:getIsFocused() then
		local _, v31_ = self:getSelectedProduction()
		if v31_ ~= nil then
			local v32_
			if v31_.owningPlaceable == nil then
				v32_ = nil
			else
				v32_ = v31_.owningPlaceable:getHotspot()
			end
			if v32_ == nil and v31_.getHotspot ~= nil then
				v32_ = v31_:getHotspot()
			end
			if v32_ ~= nil then
				if v32_ == g_currentMission.currentMapTargetHotspot then
					self.hotspotButtonInfo.text = g_i18n:getText("action_untag")
				else
					self.hotspotButtonInfo.text = g_i18n:getText("action_tag")
				end
				local v33_ = self.menuButtonInfo
				local v34_ = self.hotspotButtonInfo
				table.insert(v33_, v34_)
				if v32_:getBeVisited() and Platform.gameplay.canVisitPOI then
					local v35_ = self.menuButtonInfo
					local v36_ = self.visitButtonInfo
					table.insert(v35_, v36_)
				end
			end
		end
	elseif (self.productsList:getIsFocused() or self.detailsSlider:getIsFocused()) and self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
		local v37_, v38_ = self:getSelectedProduction()
		if v37_ ~= nil and not v37_.outputs[1].isFactory then
			if v38_.getIsProductionEnabled ~= nil then
				local v39_ = v38_:getIsProductionEnabled(v37_.id)
				self.activateButtonInfo.text = v39_ and g_i18n:getText("button_deactivate") or g_i18n:getText("button_activate")
				local v40_ = self.menuButtonInfo
				local v41_ = self.activateButtonInfo
				table.insert(v40_, v41_)
			end
			if v37_.primaryProductFillType ~= FillType.UNKNOWN then
				local v42_ = self.menuButtonInfo
				local v43_ = self.toggleStorageModeButtonInfo
				table.insert(v42_, v43_)
			end
		end
	end
	self:setMenuButtonInfoDirty()
end

function InGameMenuProductionFrame:getSelectedProduction()
	return self.selectedProduction, self.selectedProductionPoint
end

function InGameMenuProductionFrame:update(dt)
	InGameMenuProductionFrame:superClass().update(self, dt)
	self.timeSinceLastStateUpdate = self.timeSinceLastStateUpdate + dt
	if self.timeSinceLastStateUpdate >= InGameMenuProductionFrame.UPDATE_INTERVAL then
		self.timeSinceLastStateUpdate = 0
		self:updateProductionLists()
	end
end

function InGameMenuProductionFrame:getNumberOfSections(list, section)
	return list == self.detailsList and (self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and (self.selectedProduction.outputs[1].isFactory and 3 or 4) or 2) or 1
end

-- Local values: isUnowned, production, fillTypeDesc, name, production, fillTypeDesc, name
function InGameMenuProductionFrame:getTitleForSectionHeader(list, section)
	if list == self.detailsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			if section == 1 then
				return g_i18n:getText("ui_productions_outgoingProducts")
			end
			if section == 2 then
				local v52_ = self:getSelectedProduction()
				local v53_ = g_fillTypeManager:getFillTypeByIndex(v52_.primaryProductFillType)
				local v54_ = v52_.name or v53_.title
				return g_i18n:getText("ui_productions_recipe") .. ": " .. v54_
			end
		else
			if section == 1 then
				return g_i18n:getText("ui_productions_incomingMaterials")
			end
			if section == 2 and not self.selectedProduction.outputs[1].isFactory then
				return g_i18n:getText("ui_productions_outgoingProducts")
			end
			if section == 4 or section == 3 and self.selectedProduction.outputs[1].isFactory then
				local v55_ = self:getSelectedProduction()
				local v56_ = g_fillTypeManager:getFillTypeByIndex(v55_.primaryProductFillType)
				local v57_ = v55_.name or v56_.title
				return g_i18n:getText("ui_productions_recipe") .. ": " .. v57_
			end
		end
	end
	return nil
end

-- Local values: _, productionPoint
function InGameMenuProductionFrame:getNumberOfItemsInSection(list, section)
	if list == self.pointsList then
		return self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and #self.productionPoints or #self.unownedProductionPoints
	end
	if list ~= self.productsList then
		return list == self.detailsList and (self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED and (section == 1 and #self.selectedProductionPoint.sortedInputFillTypes or (section == 2 and #self.selectedProductionPoint.sortedOutputFillTypes or 1)) or 1) or 0
	end
	local _, v61_ = self:getSelectedProduction()
	return v61_ ~= nil and #v61_.sortedProductions or 0
end

-- Local values: isOwned
function InGameMenuProductionFrame:getCellTypeForItemInSection(list, section, index)
	if list == self.detailsList then
		local v65_
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			section = section + 2
			v65_ = false
		else
			v65_ = true
		end
		if self.selectedProduction.outputs[1].isFactory and v65_ then
			if section == 1 then
				return "fillTypeCell"
			end
			if section == 2 then
				return "detailsCell"
			end
			if section == 3 then
				return "recipeCell"
			end
		else
			if section <= 2 then
				return "fillTypeCell"
			end
			if section == 3 then
				return "detailsCell"
			end
			if section == 4 then
				return "recipeCell"
			end
		end
	end
	return nil
end

-- Local values: productionPoint, filename, isPreplaced, icon, iconPreplaced, _, productionPoint, production, fillTypeDesc, warning, outputModeText, fillType, outputMode, production, productionPoint, fillType, fillTypeDesc, fillLayoutFunc, inputLayout, outputLayout, fillLevel, capacity, status, statusKey, isError
function InGameMenuProductionFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.pointsList then
		local v71_ = self.productionPoints[index]
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED then
			v71_ = self.unownedProductionPoints[index]
		end
		cell:getAttribute("name"):setText(v71_:getName())
		local v72_, v73_
		if v71_.owningPlaceable == nil then
			v72_ = v71_:getImageFilename()
			if v71_.customImageFilename == nil then
				v73_ = false
			else
				v73_ = true
			end
		else
			v72_ = v71_.owningPlaceable:getImageFilename()
			v73_ = v71_.owningPlaceable.customImageFilename ~= nil
		end
		local v74_ = cell:getAttribute("icon")
		local v75_
		if v72_ == nil then
			v75_ = false
		else
			v75_ = not v73_
		end
		v74_:setVisible(v75_)
		local v76_ = cell:getAttribute("iconPreplaced")
		local v77_
		if v72_ == nil then
			v77_ = false
		else
			v77_ = v73_
		end
		v76_:setVisible(v77_)
		if v73_ then
			v76_:setImageFilename(v72_)
		else
			v74_:setImageFilename(v72_)
		end
	elseif list == self.productsList then
		local _, v78_ = self:getSelectedProduction()
		local v_u_79_ = v78_.sortedProductions[index]
		local v80_ = g_fillTypeManager:getFillTypeByIndex(v_u_79_.primaryProductFillType)
		if v80_ ~= nil then
			cell:getAttribute("icon"):setImageFilename(v80_.hudOverlayFilename)
		end
		cell:getAttribute("icon"):setVisible(v80_ ~= nil)
		cell:getAttribute("icon").getIsSelected = function()
			-- upvalues: (copy) v_u_79_
			return v_u_79_.status ~= ProductionPoint.PROD_STATUS.INACTIVE
		end
		cell:getAttribute("warning").getDoRenderText = function()
			-- upvalues: (copy) v_u_79_
			local v81_ = v_u_79_.status
			return v81_ == ProductionPoint.PROD_STATUS.MISSING_INPUTS and true or v81_ == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE
		end
		cell:getAttribute("name"):setText(v_u_79_.name or v80_.title)
		local v82_ = v_u_79_.primaryProductFillType
		local v83_
		if v78_.getOutputDistributionMode == nil then
			v83_ = ""
		else
			local v84_ = v78_:getOutputDistributionMode(v82_)
			v83_ = g_i18n:getText("ui_production_output_storing")
			if v84_ == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
				v83_ = g_i18n:getText("ui_production_output_selling")
			elseif v84_ == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
				v83_ = g_i18n:getText("ui_production_output_distributing")
			end
		end
		cell:getAttribute("activity"):setText(v83_)
	elseif list == self.detailsList then
		local v85_, v86_ = self:getSelectedProduction()
		local v87_ = v85_.primaryProductFillType
		if cell.name == "fillTypeCell" then
			if section == 1 then
				v87_ = v86_.sortedInputFillTypes[index]
			else
				v87_ = v86_.sortedOutputFillTypes[index]
			end
		end
		local v88_ = g_fillTypeManager:getFillTypeByIndex(v87_)
		if v87_ ~= FillType.UNKNOWN then
			if cell.name == "recipeCell" then
				local function v94_(p89_, p90_)
					-- upvalues: (copy) self
					for _ = 1, #p89_.elements do
						p89_.elements[1]:delete()
					end
					for _, v91_ in pairs(p90_) do
						local v92_ = self.recipeItemTemplate:clone(p89_)
						local v93_ = g_fillTypeManager:getFillTypeByIndex(v91_.type)
						v92_:getDescendantByName("amount"):setText(g_i18n:formatNumber(v91_.amount, 2))
						v92_:getDescendantByName("name"):setText("x " .. v93_.title)
						v92_:getDescendantByName("icon"):setImageFilename(v93_.hudOverlayFilename)
					end
				end
				local v95_ = cell:getAttribute("inputLayout")
				v94_(v95_, v85_.inputs)
				v95_:invalidateLayout()
				cell:setSize(nil, v95_.maxFlowSize)
				self.detailsList.cellDatabase.recipeCell.size[2] = v95_.maxFlowSize
				cell:getAttribute("arrowLayout"):invalidateLayout()
				local v96_ = cell:getAttribute("outputLayout")
				v94_(v96_, v85_.outputs)
				v96_:invalidateLayout()
				if v96_.maxFlowSize > v95_.maxFlowSize then
					cell:setSize(nil, v96_.maxFlowSize)
					self.detailsList.cellDatabase.recipeCell.size[2] = v96_.maxFlowSize
					v95_:invalidateLayout()
					cell:getAttribute("arrowLayout"):invalidateLayout()
					v96_:invalidateLayout()
				end
				self.detailsList:buildSectionInfo()
				return
			end
			if cell.name == "fillTypeCell" then
				cell:getAttribute("icon"):setImageFilename(v88_.hudOverlayFilename)
				cell:getAttribute("fillType"):setText(v88_.title)
				local v97_ = v86_:getFillLevel(v87_)
				local v98_ = v86_:getCapacity(v87_)
				cell:getAttribute("fillLevel"):setText(g_i18n:formatVolume(v97_, 0) .. " / " .. g_i18n:formatVolume(v98_, 0))
				if v98_ >= 1 then
					cell:getAttribute("fillPercent"):setText(g_i18n:formatNumber(v97_ / v98_ * 100, 0) .. "%")
					self:setStatusBarValue(cell:getAttribute("bar"), v97_ / v98_, true)
				else
					cell:getAttribute("fillPercent"):setText("0%")
					self:setStatusBarValue(cell:getAttribute("bar"), 0, true)
				end
			end
			if cell.name == "detailsCell" then
				cell:getAttribute("separator"):setVisible(section ~= 1)
				cell:getAttribute("iconLarge"):setImageFilename(v88_.hudOverlayFilename)
				local v99_ = v85_.status
				local v100_ = ProductionPoint.PROD_STATUS_TO_L10N[v85_.status] or ProductionPoint.PROD_STATUS_TO_L10N[ProductionPoint.PROD_STATUS.RUNNING]
				local v_u_101_ = (v99_ == ProductionPoint.PROD_STATUS.MISSING_INPUTS or v99_ == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE) and true or v99_ == ProductionPoint.PROD_STATUS.INACTIVE
				cell:getAttribute("infoStatus").getIsSelected = function()
					-- upvalues: (copy) v_u_101_
					return v_u_101_
				end
				cell:getAttribute("infoStatus"):setLocaKey(v100_)
				cell:getAttribute("infoCycles"):setText(MathUtil.round(v85_.cyclesPerMonth, 2))
				cell:getAttribute("infoCosts"):setValue(g_i18n:formatMoney(v85_.costsPerActiveMonth, 0, true))
			end
		end
	end
end

-- Local values: profile, fullWidth, minSize
function InGameMenuProductionFrame:setStatusBarValue(statusBarElement, value, lowIsDanger)
	local v105_ = InGameMenuProductionFrame.PROFILES.STATUS_BAR
	if lowIsDanger and value < InGameMenuProductionFrame.STATUS_BAR_LOW or not lowIsDanger and InGameMenuProductionFrame.STATUS_BAR_HIGH < value then
		v105_ = InGameMenuProductionFrame.PROFILES.STATUS_BAR_DANGER
	end
	statusBarElement:applyProfile(v105_)
	local v106_ = statusBarElement.parent.absSize[1] - statusBarElement.margin[1] * 2
	local v107_ = statusBarElement.startSize == nil and 0 or statusBarElement.startSize[1] + statusBarElement.endSize[1]
	local v108_ = v106_ * math.min(1, value)
	statusBarElement:setSize(math.max(v107_, v108_), nil)
end

-- Local values: e, cell
function InGameMenuProductionFrame:onListSelectionChanged(list, section, index)
	if list == self.pointsList then
		if self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED then
			self.selectedProductionPoint = self.productionPoints[index]
		else
			self.selectedProductionPoint = self.unownedProductionPoints[index]
		end
		if self.selectedProductionPoint ~= nil then
			self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
			self.selectedStorage = nil
			self.productsList:reloadData()
			if not self.isReloading then
				self.productsList:setSelectedIndex(1)
			end
		end
	elseif list == self.productsList and self.selectedProductionPoint ~= nil then
		self.selectedProduction = self.selectedProductionPoint.sortedProductions[self.productsList:getSelectedIndexInSection()]
		self.selectedStorage = nil
		for v112_ = #self.detailsList.elements, 1, -1 do
			local v113_ = self.detailsList.elements[v112_]
			self.detailsList:queueReusableCell(v113_)
		end
		self.detailsList:buildSectionInfo()
		self.detailsList:updateView()
	end
	if self.selectedProductionPoint ~= nil then
		if self.selectedProductionPoint.storage == nil then
			if self.selectedProductionPoint.spec_factory ~= nil then
				self.selectedStorage = self.selectedProductionPoint.spec_factory.storage.sortedFillTypes[index]
			end
		else
			self.selectedStorage = self.selectedProductionPoint.storage.sortedFillTypes[index]
		end
		self:updateMenuButtons()
	end
end

-- Local values: production, productionPoint, state
function InGameMenuProductionFrame:onButtonActivate()
	if g_currentMission:getHasPlayerPermission("manageProductions") then
		local v115_, v116_ = self:getSelectedProduction()
		if v115_ ~= nil then
			local v117_ = v116_:getIsProductionEnabled(v115_.id)
			v116_:setProductionState(v115_.id, not v117_)
			self:updateProductionLists()
		end
	else
		InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
	end
end

-- Local values: production, productionPoint, fillType
function InGameMenuProductionFrame:onButtonToggleOutputMode()
	if g_currentMission:getHasPlayerPermission("manageProductions") then
		local v119_, v120_ = self:getSelectedProduction()
		local v121_ = v119_.primaryProductFillType
		if v121_ ~= FillType.UNKNOWN then
			v120_:toggleOutputDistributionMode(v121_)
			self.productsList:reloadData()
		end
	else
		InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"), nil, nil, DialogElement.TYPE_WARNING)
	end
end

-- Local values: _, productionPoint, hotspot
function InGameMenuProductionFrame:onButtonHotspot()
	local _, v123_ = self:getSelectedProduction()
	if v123_ ~= nil then
		local v124_ = v123_.owningPlaceable ~= nil and v123_.owningPlaceable:getHotspot() or v123_:getHotspot()
		if v124_ ~= nil then
			if g_currentMission.currentMapTargetHotspot == v124_ then
				g_currentMission:setMapTargetHotspot(nil)
			else
				g_currentMission:setMapTargetHotspot(v124_)
			end
			self:updateMenuButtons()
			return
		end
		g_currentMission:setMapTargetHotspot(nil)
	end
end

-- Local values: _, productionPoint, hotspot, x, y, z
function InGameMenuProductionFrame:onButtonVisit()
	local _, v126_ = self:getSelectedProduction()
	if v126_ ~= nil then
		local v127_ = v126_.owningPlaceable ~= nil and v126_.owningPlaceable:getHotspot() or v126_:getHotspot()
		if v127_ ~= nil then
			local v128_, v129_, v130_ = v127_:getTeleportWorldPosition()
			if v128_ ~= nil and (v129_ ~= nil and v130_ ~= nil) then
				if g_localPlayer:getCurrentVehicle() ~= nil then
					g_localPlayer:leaveVehicle()
				end
				g_localPlayer:teleportTo(v128_, v129_, v130_)
				g_gui:changeScreen(nil)
			end
		end
	end
end

-- Local values: productionPoints, unownedProductionPoints, factories, _, factory, unownedFactories, _, factory, pointSortFunc, hasPoints
function InGameMenuProductionFrame:updateProductionLists()
	local v132_ = table.copyIndex(self.chainManager:getProductionPointsForFarmId(self.playerFarm.farmId))
	self.productionPoints = {}
	local v133_ = table.copyIndex(self.chainManager:getUnownedProductionPoints())
	self.unownedProductionPoints = {}
	local v134_ = self.chainManager:getFactoriesForFarmId(self.playerFarm.farmId)
	for _, v135_ in pairs(v134_) do
		table.insert(v132_, v135_)
	end
	local v136_ = self.chainManager:getUnownedFactories()
	for _, v137_ in pairs(v136_) do
		table.insert(v133_, v137_)
	end
	local function v155_(p138_, p139_)
		for _, v140_ in ipairs(p138_) do
			table.insert(p139_, v140_)
			v140_.sortedProductions = {}
			if v140_.productions ~= nil then
				for _, v141_ in ipairs(v140_.productions) do
					local v142_ = v140_.sortedProductions
					table.insert(v142_, v141_)
				end
				table.sort(v140_.sortedProductions, function(p143_, p144_)
					local v145_ = p143_.name
					if v145_ == nil then
						v145_ = g_fillTypeManager:getFillTypeTitleByIndex(p143_.primaryProductFillType)
					end
					local v146_ = p144_.name
					if v146_ == nil then
						v146_ = g_fillTypeManager:getFillTypeTitleByIndex(p144_.primaryProductFillType)
					end
					return v145_ < v146_
				end)
				v140_.sortedInputFillTypes = {}
				v140_.sortedOutputFillTypes = {}
				for _, v147_ in ipairs(v140_.inputFillTypeIdsArray) do
					local v148_ = v140_.sortedInputFillTypes
					table.insert(v148_, v147_)
				end
				table.sort(v140_.sortedInputFillTypes, function(p149_, p150_)
					return g_fillTypeManager:getFillTypeTitleByIndex(p149_) < g_fillTypeManager:getFillTypeTitleByIndex(p150_)
				end)
				for _, v151_ in ipairs(v140_.outputFillTypeIdsArray) do
					local v152_ = v140_.sortedOutputFillTypes
					table.insert(v152_, v151_)
				end
				table.sort(v140_.sortedOutputFillTypes, function(p153_, p154_)
					return g_fillTypeManager:getFillTypeTitleByIndex(p153_) < g_fillTypeManager:getFillTypeTitleByIndex(p154_)
				end)
			end
		end
	end
	v155_(v132_, self.productionPoints)
	v155_(v133_, self.unownedProductionPoints)
	table.sort(self.productionPoints, function(p156_, p157_)
		return p156_:getName() < p157_:getName()
	end)
	table.sort(self.unownedProductionPoints, function(p158_, p159_)
		return p158_:getName() < p159_:getName()
	end)
	self.isReloading = true
	self.pointsList:reloadData()
	local v160_ = self.pointsList:getItemCount() > 0
	self.productsBoxBg:setVisible(v160_)
	self.productsContainer:setVisible(v160_)
	local v161_ = self.noPointsOwnedText
	local v162_ = not v160_
	if v162_ then
		v162_ = self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_OWNED
	end
	v161_:setVisible(v162_)
	local v163_ = self.allPointsBoughtText
	local v164_ = not v160_
	if v164_ then
		v164_ = self.pointsSelector:getState() == InGameMenuProductionFrame.POINTS_UNOWNED
	end
	v163_:setVisible(v164_)
	if v160_ then
		self.productsList:reloadData()
	end
	self.detailsBoxBg:setVisible(v160_)
	self.detailsContainer:setVisible(v160_)
	self.isReloading = false
	self:updateMenuButtons()
end
InGameMenuProductionFrame.SYMBOL_L10N = {
	["TEXT_OWNED"] = "ui_productionsOwned",
	["TEXT_UNOWNED"] = "ui_productionsAvailable",
	["TEXT_NO_POINTS"] = "ui_noProductionPoints",
	["TEXT_ALL_POINTS_OWNED"] = "ui_allProductionPointsOwned",
	["TEXT_STORAGE"] = "statistic_storage",
	["TEXT_OUTGOING"] = "ui_productionsOutgoing",
	["TEXT_DEACTIVATED"] = "ui_productionsDeactivated"
}
InGameMenuProductionFrame.PROFILES = {
	["STATUS_BAR"] = "fs25_productionDetailsListItemBar",
	["STATUS_BAR_DANGER"] = "fs25_productionDetailsListItemBarDanger"
}
