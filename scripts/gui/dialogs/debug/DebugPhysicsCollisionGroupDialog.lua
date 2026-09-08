-- Local values: DebugPhysicsCollisionGroupDialog_mt
DebugPhysicsCollisionGroupDialog = {}
local DebugPhysicsCollisionGroupDialog_mt = Class(DebugPhysicsCollisionGroupDialog, InfoDialog)
function DebugPhysicsCollisionGroupDialog.register()
	local v2_ = DebugPhysicsCollisionGroupDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/debug/DebugPhysicsCollisionGroupDialog.xml", "DebugPhysicsCollisionGroupDialog", v2_)
	DebugPhysicsCollisionGroupDialog.INSTANCE = v2_
	if g_isDevelopmentVersion then
		g_messageCenter:subscribe(MessageType.DEBUG_MODE_CHANGED, DebugPhysicsCollisionGroupDialog.onDebugModeChanged, DebugPhysicsCollisionGroupDialog)
	end
end
function DebugPhysicsCollisionGroupDialog.show()
	if DebugPhysicsCollisionGroupDialog.INSTANCE ~= nil then
		g_gui:showDialog("DebugPhysicsCollisionGroupDialog")
	end
end

function DebugPhysicsCollisionGroupDialog.onDebugModeChanged(_, debugMode)
	if debugMode == DebugMode.PHYSICS and Input.isKeyPressed(Input.KEY_lalt) then
		DebugPhysicsCollisionGroupDialog.show()
	else
		g_gui:closeDialogByName("DebugPhysicsCollisionGroupDialog")
	end
end

-- Upvalues: DebugPhysicsCollisionGroupDialog_mt
-- Local values: self
function DebugPhysicsCollisionGroupDialog.new(target, custom_mt)
	-- upvalues: (copy) DebugPhysicsCollisionGroupDialog_mt
	local v6_ = TextInputDialog.new(target, custom_mt or DebugPhysicsCollisionGroupDialog_mt)
	addConsoleCommand("gsDebugPhysicsCollisionsGroup", "Opens a dialog to modify collision group debug options", "openDialog", v6_)
	return v6_
end

function DebugPhysicsCollisionGroupDialog.createFromExistingGui(gui, guiName)
	DebugPhysicsCollisionGroupDialog.register()
	DebugPhysicsCollisionGroupDialog.show()
end

-- Local values: clonedElement, flagName, flag, option, flagName, bit, flag, option
function DebugPhysicsCollisionGroupDialog:onGuiSetupFinished()
	DebugPhysicsCollisionGroupDialog:superClass().onGuiSetupFinished(self)
	self.binaryTemplate:unlinkElement()
	FocusManager:removeElement(self.binaryTemplate)
	self.sliderTemplate:unlinkElement()
	FocusManager:removeElement(self.sliderTemplate)
	self.binaryTemplate:getDescendantByName("option"):setTexts({ "Hide", "Show" })
	self.sliderTemplate:getDescendantByName("option"):setTexts({ "Hide", "Show", "No Depth" })
	self.elementsBox:addElement(self.titlePhysics)
	self.elementsBox:addElement(self.subtitlePhysics)
	for v8_, v9_ in pairs(PhysicsDebugDrawMode) do
		local v10_ = self.sliderTemplate:clone(self.elementsBox)
		v10_:getDescendantByName("title"):setText(string.gsub(v8_, "COLLISION_GEOMETRIES_", ""))
		local v11_ = v10_:getDescendantByName("option")
		v11_.bit = math.log(v9_, 2)
		v11_.flag = v9_
	end
	self.elementsBox:addElement(self.titleCollisions)
	for v12_, v13_, v14_ in CollisionFlag.iteratorFlags() do
		local v15_ = self.binaryTemplate:clone(self.elementsBox)
		v15_:getDescendantByName("title"):setText(v12_)
		v15_.isCollisionOption = true
		local v16_ = v15_:getDescendantByName("option")
		v16_.bit = v13_
		v16_.flag = v14_
	end
	self.elementsBox:invalidateLayout()
end

function DebugPhysicsCollisionGroupDialog:delete()
	self.binaryTemplate:delete()
	self.sliderTemplate:delete()
	if g_isDevelopmentVersion then
		g_messageCenter:unsubscribeAll(DebugPhysicsCollisionGroupDialog)
	end
	DebugPhysicsCollisionGroupDialog:superClass().delete(self)
end

function DebugPhysicsCollisionGroupDialog:openDialog()
	if g_currentMission == nil then
		Logging.warning("Can only open this dialog while a savegame is loaded")
	else
		DebugPhysicsCollisionGroupDialog.show()
	end
end

-- Local values: bitmaskCollision, bitmaskNoDepth, bitmaskPhysicsDrawMode, _, element, option, state
function DebugPhysicsCollisionGroupDialog:onOpen()
	DebugPhysicsCollisionGroupDialog:superClass().onOpen(self)
	local v19_ = getPhysicsDebugDrawCollisionFilterGroup()
	local v20_ = getPhysicsDebugDrawNoDepthMode()
	local v21_ = getPhysicsDebugDrawMode()
	for _, v22_ in pairs(self.elementsBox.elements) do
		local v23_ = v22_:getDescendantByName("option")
		if v23_ ~= nil then
			if v22_.isCollisionOption then
				v23_:setState(Utils.isBitSet(v19_, v23_.bit) and 2 or 1)
			else
				v23_:setState(Utils.isBitSet(v21_, v23_.bit) and (Utils.isBitSet(v20_, v23_.bit) and 3 or 2) or 1)
			end
		end
	end
	setPhysicsDebugDrawEnabled(true)
end

-- Local values: _, element, option
function DebugPhysicsCollisionGroupDialog:selectAll()
	for _, v25_ in pairs(self.elementsBox.elements) do
		local v26_ = v25_:getDescendantByName("option")
		if v26_ ~= nil and v25_.isCollisionOption then
			v26_:setState(2)
		end
	end
	self:applyChanges()
end

-- Local values: _, element, option
function DebugPhysicsCollisionGroupDialog:unselectAll()
	for _, v28_ in pairs(self.elementsBox.elements) do
		local v29_ = v28_:getDescendantByName("option")
		if v29_ ~= nil and v28_.isCollisionOption then
			v29_:setState(1)
		end
	end
	self:applyChanges()
end

function DebugPhysicsCollisionGroupDialog:onClickApply()
	self:applyChanges()
end

function DebugPhysicsCollisionGroupDialog:onClickOk()
	self:applyChanges()
	self:close()
end

-- Local values: flagSumCollision, flagSumPhysicsDrawMode, flagSumNoDepth, _, element, option, state, flag
function DebugPhysicsCollisionGroupDialog:applyChanges()
	local v33_ = 0
	local v34_ = 0
	local v35_ = 0
	for _, v36_ in pairs(self.elementsBox.elements) do
		local v37_ = v36_:getDescendantByName("option")
		if v37_ ~= nil then
			local v38_ = v37_.state
			local v39_ = v37_.flag
			if v38_ >= 2 then
				if v36_.isCollisionOption then
					v33_ = v33_ + v39_
				else
					v34_ = v34_ + v39_
					if v38_ == 3 then
						v35_ = v35_ + v39_
					end
				end
			end
		end
	end
	if getPhysicsDebugDrawCollisionFilterGroup() ~= v33_ then
		setPhysicsDebugDrawCollisionFilterGroup(v33_)
	end
	if getPhysicsDebugDrawNoDepthMode() ~= v35_ then
		setPhysicsDebugDrawNoDepthMode(v35_)
	end
	if getPhysicsDebugDrawMode() ~= v34_ then
		setPhysicsDebugDrawMode(v34_)
	end
end
