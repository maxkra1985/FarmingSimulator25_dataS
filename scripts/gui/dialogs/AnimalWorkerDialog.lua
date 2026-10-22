AnimalWorkerDialog = {}
local AnimalWorkerDialog_mt = Class(AnimalWorkerDialog, MessageDialog)
AnimalWorkerDialog.INFO_REFRESH_INTERVAL = 1000
function AnimalWorkerDialog.register()
	local dialog = AnimalWorkerDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/AnimalWorkerDialog.xml", "AnimalWorkerDialog", dialog)
	AnimalWorkerDialog.INSTANCE = dialog
end
function AnimalWorkerDialog.show(husbandry, callback, performCallback, target)
	if AnimalWorkerDialog.INSTANCE == nil then
		return
	else
		local dialog = AnimalWorkerDialog.INSTANCE
		dialog:setCallback(callback, performCallback, target)
		dialog.husbandry = husbandry
		g_gui:showDialog("AnimalWorkerDialog")
	end
end
function AnimalWorkerDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or AnimalWorkerDialog_mt)
	self.husbandry = nil
	self.callbackFunc = nil
	self.performCallbackFunc = nil
	self.target = nil
	self.refreshTimer = 0
	self.taskRows = {}
	self.elementToRow = {}
	self.pendingPerformRow = nil
	return self
end
function AnimalWorkerDialog.createFromExistingGui(gui, guiName)
	AnimalWorkerDialog.register()
	AnimalWorkerDialog.show(gui.husbandry, gui.callbackFunc, gui.performCallbackFunc, gui.target)
end
function AnimalWorkerDialog:onGuiSetupFinished()
	AnimalWorkerDialog:superClass().onGuiSetupFinished(self)
	self.templateTaskRow:unlinkElement()
	FocusManager:removeElement(self.templateTaskRow)
	self.maxTaskBoxHeight = self.taskBoxContainer.size[2]
	self.dialogFrameHeight = self.dialogElement.size[2] - self.maxTaskBoxHeight
end
function AnimalWorkerDialog:delete()
	self.templateTaskRow:delete()
	AnimalWorkerDialog:superClass().delete(self)
end
function AnimalWorkerDialog:setCallback(callbackFunc, performCallbackFunc, target)
	self.callbackFunc = callbackFunc
	self.performCallbackFunc = performCallbackFunc
	self.target = target
end
function AnimalWorkerDialog:onOpen()
	AnimalWorkerDialog:superClass().onOpen(self)
	if self.husbandry == nil then
		return
	else
		self:assignTaskRows()
		self.refreshTimer = AnimalWorkerDialog.INFO_REFRESH_INTERVAL
		self:refreshInfo()
	end
end
function AnimalWorkerDialog:onClose()
	AnimalWorkerDialog:superClass().onClose(self)
	self.pendingPerformRow = nil
	g_messageCenter:unsubscribe(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, self)
	if g_gui.currentlyReloading then
		return
	else
		self.husbandry = nil
		self.callbackFunc = nil
		self.performCallbackFunc = nil
		self.target = nil
	end
end
function AnimalWorkerDialog:update(dt)
	AnimalWorkerDialog:superClass().update(self, dt)
	if self.husbandry == nil then
		return
	else
		self.refreshTimer = self.refreshTimer - dt
		if self.refreshTimer <= 0 then
			self.refreshTimer = AnimalWorkerDialog.INFO_REFRESH_INTERVAL
			self:refreshInfo()
		end
	end
end
function AnimalWorkerDialog:assignTaskRows()
	for i = #self.taskBox.elements, 1, -1 do
		self.taskBox.elements[i]:delete()
		self.taskBox.elements[i] = nil
	end
	self.taskRows = {}
	self.elementToRow = {}
	local canHire = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.HIRE_ASSISTANT)
	local focusElements = {}
	for _, task in ipairs(self.husbandry:getAnimalWorkerAvailableTasks()) do
		local rowElement = self.templateTaskRow:clone(self.taskBox)
		local row = {}
		row.task = task
		row.enabled = self.husbandry:getAnimalWorkerTaskIsEnabled(task)
		row.titleElement = rowElement:getDescendantByName("title")
		row.cadenceElement = rowElement:getDescendantByName("cadence")
		row.infoElement = rowElement:getDescendantByName("info")
		row.option = rowElement:getDescendantByName("option")
		row.performButton = rowElement:getDescendantByName("performButton")
		row.titleElement:setText(AnimalWorkerTaskSystem.getTaskTitle(task))
		row.cadenceElement:setText(AnimalWorkerDialog.getCadenceText(task))
		local option = row.option
		function row.titleElement.getIsFocused()
			return option:getIsFocused()
		end
		row.option:setTexts({ g_i18n:getText("ui_animalWorker_taskDisabled"), g_i18n:getText("ui_animalWorker_taskEnabled") })
		row.option:setIsChecked(row.enabled, true)
		row.option:setDisabled(not canHire)
		row.performButton:setDisabled(not canHire)
		self.elementToRow[row.option] = row
		self.elementToRow[row.performButton] = row
		table.insert(focusElements, row.option)
		table.insert(focusElements, row.performButton)
		table.insert(self.taskRows, row)
	end
	local contentHeight = self.taskBox:invalidateLayout()
	self:setTaskBoxHeight(contentHeight)
	self:linkFocusElements(focusElements)
end
function AnimalWorkerDialog:setTaskBoxHeight(contentHeight)
	local boxHeight = math.min(contentHeight, self.maxTaskBoxHeight)
	self.taskBoxContainer:setSize(nil, boxHeight)
	self.dialogElement:setSize(nil, self.dialogFrameHeight + boxHeight)
	self.taskBox:invalidateLayout()
end
function AnimalWorkerDialog:linkFocusElements(focusElements)
	if #focusElements == 0 then
		return
	else
		for index, element in ipairs(focusElements) do
			local nextElement = focusElements[index + 1] or focusElements[1]
			FocusManager:linkElements(element, FocusManager.BOTTOM, nextElement)
			FocusManager:linkElements(nextElement, FocusManager.TOP, element)
		end
		FocusManager:setFocus(focusElements[1])
	end
end
function AnimalWorkerDialog:refreshInfo()
	if self.husbandry == nil then
		return
	else
		for _, row in ipairs(self.taskRows) do
			local numTotal = AnimalWorkerTaskSystem.getTaskNumTotalAnimals(row.task, self.husbandry)
			local cost = 0
			if 0 < numTotal then
				cost = self.husbandry:getAnimalWorkerTaskCost(row.task, numTotal)
			end
			local infoText = string.format(g_i18n:getText("ui_animalWorker_rowInfo"), g_i18n:formatMoney(cost, 0, true))
			row.infoElement:setText(infoText)
		end
	end
end
function AnimalWorkerDialog.getCadenceText(task)
	if AnimalWorkerTaskSystem.getTaskIsDaily(task) then
		return g_i18n:getText("ui_animalWorker_cadenceDaily")
	else
		return g_i18n:getText("ui_animalWorker_cadenceYearly")
	end
end
function AnimalWorkerDialog:sendCallback()
	local husbandry = self.husbandry
	local callbackFunc = self.callbackFunc
	local target = self.target
	local changedRows = {}
	for _, row in ipairs(self.taskRows) do
		if row.enabled == husbandry:getAnimalWorkerTaskIsEnabled(row.task) then
			continue
		end
		table.insert(changedRows, row)
	end
	self:close()
	if callbackFunc == nil then
		return
	else
		for _, row in ipairs(changedRows) do
			if target ~= nil then
				callbackFunc(target, husbandry, row.task, row.enabled)
			else
				callbackFunc(husbandry, row.task, row.enabled)
			end
		end
	end
end
function AnimalWorkerDialog:onClickTaskEnabled(state, element)
	local row = self.elementToRow[element]
	if row == nil then
		return
	else
		row.enabled = row.option:getIsChecked()
		self:refreshInfo()
	end
end
function AnimalWorkerDialog:onClickTaskPerform(element)
	self:performRow(self.elementToRow[element])
end
function AnimalWorkerDialog:performRow(row)
	if row == nil or self.husbandry == nil then
		return
	end
	local numPending = AnimalWorkerTaskSystem.getTaskNumPendingAnimals(row.task, self.husbandry)
	if numPending == 0 then
		InfoDialog.show(g_i18n:getText("ui_animalWorker_performNone"))
	else
		local cost = self.husbandry:getAnimalWorkerTaskCost(row.task, numPending)
		local text = string.namedFormat(g_i18n:getText("ui_animalWorker_performConfirm"), "taskName", AnimalWorkerTaskSystem.getTaskTitle(row.task), "price", g_i18n:formatMoney(cost, 0, true))
		self.pendingPerformRow = row
		YesNoDialog.show(self.onPerformConfirmed, self, text)
	end
end
function AnimalWorkerDialog:onPerformConfirmed(yes)
	local row = self.pendingPerformRow
	self.pendingPerformRow = nil
	if not yes or row == nil then
		return
	end
	if self.husbandry == nil or self.performCallbackFunc == nil then
		return
	end
	g_messageCenter:subscribeOneshot(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, self.onPerformAnswer, self)
	local numHandled = nil
	local cost = nil
	if self.target ~= nil then
		numHandled, cost = self.performCallbackFunc(self.target, self.husbandry, row.task)
	else
		numHandled, cost = self.performCallbackFunc(self.husbandry, row.task)
	end
	if numHandled == nil then
		return
	else
		g_messageCenter:unsubscribe(PlaceableHusbandryAnimalWorkerPerformAnswerEvent, self)
		self:showPerformResult(numHandled, cost)
	end
end
function AnimalWorkerDialog:onPerformAnswer(placeable, task, numHandled, cost)
	if placeable ~= self.husbandry then
		return
	else
		self:showPerformResult(numHandled, cost)
	end
end
function AnimalWorkerDialog:showPerformResult(numHandled, cost)
	if numHandled <= 0 then
		InfoDialog.show(g_i18n:getText("ui_animalWorker_performFailed"))
	else
		local text = string.namedFormat(g_i18n:getText("ui_animalWorker_performSuccess"), "numAnimals", numHandled, "price", g_i18n:formatMoney(cost, 0, true))
		InfoDialog.show(text)
		self:refreshInfo()
	end
end
function AnimalWorkerDialog:onClickApply(element)
	self:sendCallback()
end
function AnimalWorkerDialog:onClickCancel(element)
	self:close()
end
function AnimalWorkerDialog:onClickBack()
	self:close()
	return true
end
