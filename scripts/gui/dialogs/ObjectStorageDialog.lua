-- Local values: ObjectStorageDialog_mt
ObjectStorageDialog = {}
local ObjectStorageDialog_mt = Class(ObjectStorageDialog, YesNoDialog)
function ObjectStorageDialog.register()
	local v2_ = ObjectStorageDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ObjectStorageDialog.xml", "ObjectStorageDialog", v2_)
	ObjectStorageDialog.INSTANCE = v2_
end

-- Local values: dialog
function ObjectStorageDialog.show(callback, target, title, objectInfos, maxUnloadAmount)
	if ObjectStorageDialog.INSTANCE ~= nil then
		local v8_ = ObjectStorageDialog.INSTANCE
		v8_:setCallback(callback, target)
		v8_:setTitle(title)
		v8_:setText(nil)
		v8_:setObjectInfos(objectInfos, maxUnloadAmount)
		g_gui:showDialog("ObjectStorageDialog")
	end
end

-- Upvalues: ObjectStorageDialog_mt
-- Local values: self
function ObjectStorageDialog.new(target, custom_mt)
	-- upvalues: (copy) ObjectStorageDialog_mt
	local v11_ = YesNoDialog.new(target, custom_mt or ObjectStorageDialog_mt)
	v11_.selectedInfo = nil
	v11_.selectedInfoIndex = 1
	v11_.selectedAmount = 1
	v11_.maxUnloadAmount = math.huge
	return v11_
end

-- Local values: callback, target, title, objectInfos
function ObjectStorageDialog.createFromExistingGui(gui, guiName)
	ObjectStorageDialog.register()
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	local v15_ = gui.dialogTitle
	local v16_ = gui.objectInfos
	ObjectStorageDialog.show(v13_, v14_, v15_, v16_)
end

function ObjectStorageDialog:onClickOk()
	self.callbackArgs = self.selectedAmount
	self:sendCallback(self.selectedInfoIndex)
	self.objectInfos = nil
end

function ObjectStorageDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)
	return false
end

-- Local values: amountTexts, i
function ObjectStorageDialog:onClickItems(state)
	self.selectedInfoIndex = state
	self.selectedInfo = self.objectInfos[state]
	local v21_ = {}
	if self.selectedInfo ~= nil then
		local v22_ = self.maxUnloadAmount
		local v23_ = self.selectedInfo.numObjects
		for v24_ = 1, math.min(v22_, v23_) do
			local v25_ = string.format
			local v26_ = self.selectedInfo.numObjects
			table.insert(v21_, v25_("%d / %d", v24_, v26_))
		end
	end
	self.amountElement:setTexts(v21_)
	self.selectedAmount = #v21_
	self.amountElement:setState(self.selectedAmount, true)
end

function ObjectStorageDialog:onClickAmount(state)
	self.selectedAmount = state
end

function ObjectStorageDialog:setTitle(title)
	ObjectStorageDialog:superClass().setTitle(self, title)
	self.dialogTitle = title
end

-- Local values: objectInfoTable, _, objectInfo
function ObjectStorageDialog:setObjectInfos(objectInfos, maxUnloadAmount)
	self.objectInfos = objectInfos
	self.maxUnloadAmount = maxUnloadAmount or self.maxUnloadAmount
	local v34_ = {}
	for _, v35_ in pairs(objectInfos) do
		if v35_.objects[1] ~= nil then
			local v36_ = v35_.objects[1]
			table.insert(v34_, v36_:getDialogText())
		end
	end
	self.itemsElement:setTexts(v34_)
	self.itemsElement:setState(1, true)
end
