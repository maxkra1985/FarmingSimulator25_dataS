-- Local values: Binding_mt
Binding = {}
local Binding_mt = Class(Binding)
Binding.AXIS_COMPONENT = {
	["POSITIVE"] = "+",
	["NEGATIVE"] = "-"
}
Binding.INPUT_COMPONENT = {
	["POSITIVE"] = "+",
	["NEGATIVE"] = "-"
}
Binding.MAX_ALTERNATIVES_KB_MOUSE = 3
Binding.MAX_ALTERNATIVES_GAMEPAD = GS_IS_CONSOLE_VERSION and 3 or 2
Binding.PRESSED_MAGNITUDE_THRESHOLD = 0.1
Binding.PS_JAPAN_BUTTON_SWAP_MAP = {
	["BUTTON_2"] = "BUTTON_3",
	["BUTTON_3"] = "BUTTON_2"
}

-- Upvalues: Binding_mt
-- Local values: self
function Binding.new(deviceId, axisNames, axisComponent, inputComponent, neutralInput, index)
	-- upvalues: (copy) Binding_mt
	local v8_ = Binding_mt
	local v9_ = setmetatable({}, v8_)
	v9_.axisComponent = axisComponent
	v9_.index = index
	if v9_.axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
		v9_.axisDirection = 1
	else
		v9_.axisDirection = -1
	end
	v9_.id = nil
	v9_.comboMask = 0
	v9_.deviceId = nil
	v9_.deviceCategory = InputDevice.CATEGORY.UNKNOWN
	v9_.internalDeviceId = nil
	v9_.axisNameSet = nil
	v9_.inputString = ""
	v9_.unmodifiedAxis = nil
	v9_.modifierAxisSet = nil
	v9_.axisNames = {}
	v9_.inputComponent = nil
	v9_.inputDirection = 0
	v9_.neutralInput = neutralInput
	v9_.isMouse = false
	v9_.isKeyboard = false
	v9_.isGamepad = false
	v9_.isPrimary = false
	v9_:updateData(deviceId, nil, axisNames, inputComponent, true)
	v9_.isAnalog = false
	v9_.inputValue = 0
	v9_.isInputActive = false
	v9_.isDownFlank = false
	v9_.isUpFlank = false
	v9_.recievedDownFlankInCurrentContext = false
	v9_.enteredNewContextThisFrame = false
	v9_.isPressed = false
	v9_.isShadowed = false
	v9_.isActive = true
	v9_.hasFrameTriggered = false
	return v9_
end

-- Local values: deviceId, axisNamesText, axisNames, axisComponent, inputComponent, neutralInput, index
function Binding.createFromXML(xmlFile, elementTag)
	local v12_ = getXMLString(xmlFile, elementTag .. "#device")
	local v13_ = (getXMLString(xmlFile, elementTag .. "#input") or ""):split(" ")
	local v14_ = getXMLString(xmlFile, elementTag .. "#axisComponent")
	if v14_ ~= Binding.AXIS_COMPONENT.POSITIVE and v14_ ~= Binding.AXIS_COMPONENT.NEGATIVE then
		v14_ = Binding.AXIS_COMPONENT.POSITIVE
	end
	local v15_ = getXMLString(xmlFile, elementTag .. "#inputComponent")
	if v15_ ~= Binding.INPUT_COMPONENT.POSITIVE and v15_ ~= Binding.INPUT_COMPONENT.NEGATIVE then
		v15_ = Binding.INPUT_COMPONENT.POSITIVE
		if #v13_ > 0 and v13_[#v13_]:sub(v13_[#v13_]:len()) == "-" then
			v15_ = Binding.INPUT_COMPONENT.NEGATIVE
		end
	end
	local v16_ = getXMLInt(xmlFile, elementTag .. "#neutralInput") or 0
	local v17_ = getXMLInt(xmlFile, elementTag .. "#index") or -1
	return Binding.new(v12_, v13_, v14_, v15_, v16_, v17_)
end

-- Local values: inputValue
function Binding:saveToXMLFile(xmlFile, elementTag)
	setXMLString(xmlFile, elementTag .. "#device", self.deviceId)
	local v21_ = table.concat(self.axisNames, " ")
	setXMLString(xmlFile, elementTag .. "#input", v21_)
	setXMLString(xmlFile, elementTag .. "#axisComponent", self.axisComponent)
	setXMLInt(xmlFile, elementTag .. "#neutralInput", self.neutralInput)
	setXMLInt(xmlFile, elementTag .. "#index", self.index)
end

-- Local values: _, axisName, axisName, s, i, axis, isKbMouse
function Binding:updateData(deviceId, deviceCategory, axisNames, inputComponent, isInit)
	if axisNames ~= nil then
		self.axisNames = {}
		for _, v27_ in ipairs(axisNames) do
			local v28_ = self.axisNames
			table.insert(v28_, v27_)
		end
	end
	local v29_ = inputComponent or self.inputComponent
	if v29_ and v29_ ~= Binding.INPUT_COMPONENT.POSITIVE then
		self.inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
		self.inputDirection = -1
	else
		self.inputComponent = Binding.INPUT_COMPONENT.POSITIVE
		self.inputDirection = 1
	end
	if #self.axisNames > 0 then
		local v30_ = self.axisNames[#self.axisNames]
		local v31_ = v30_:sub(v30_:len())
		if v31_ == "-" or v31_ == "+" then
			v30_ = v30_:sub(1, v30_:len() - 1)
		end
		if self.inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
			v30_ = v30_ .. "-"
		elseif InputBinding.getIsPhysicalFullAxis(v30_) then
			v30_ = v30_ .. "+"
		end
		self.axisNames[#self.axisNames] = v30_
	end
	self.deviceId = deviceId or self.deviceId
	self.deviceCategory = deviceCategory or self.deviceCategory
	self.axisNameSet = table.toSet(self.axisNames)
	self.inputString = table.concat(self.axisNames, " ")
	self.unmodifiedAxis = self.axisNames[#self.axisNames]
	self.modifierAxisSet = {}
	for v32_ = 1, #self.axisNames - 1 do
		local v33_ = self.axisNames[v32_]
		self.modifierAxisSet[v33_] = v33_
	end
	local v34_ = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	local v35_
	if v34_ then
		v35_ = self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
	else
		v35_ = v34_
	end
	self.isMouse = v35_
	local v36_
	if v34_ then
		v36_ = not self.isMouse
	else
		v36_ = v34_
	end
	self.isKeyboard = v36_
	local v37_
	if self.deviceId == nil then
		v37_ = false
	else
		v37_ = not v34_
	end
	self.isGamepad = v37_
	self.isPrimary = self.index == 1
end

-- Local values: isPressed, downFlank, upFlank
function Binding:updateInput(inputValue, allInputActive)
	local v41_
	if self.axisDirection >= 0 then
		self.inputValue = math.max(inputValue, 0)
		v41_ = Binding.PRESSED_MAGNITUDE_THRESHOLD <= inputValue
	else
		self.inputValue = math.min(inputValue, 0)
		v41_ = inputValue <= -Binding.PRESSED_MAGNITUDE_THRESHOLD
	end
	self.isShadowed = false
	self.hasFrameTriggered = false
	local v42_ = v41_ and not self.isPressed
	if v42_ then
		v42_ = not self.enteredNewContextThisFrame
	end
	local v43_ = not v41_
	if v43_ then
		v43_ = self.isPressed
	end
	self.isDownFlank = v42_
	self.isUpFlank = v43_
	self.isPressed = v41_
	self.enteredNewContextThisFrame = false
	if self.recievedDownFlankInCurrentContext or v42_ then
		v42_ = v41_ or v43_
	end
	self.recievedDownFlankInCurrentContext = v42_
	self.isInputActive = allInputActive or v43_
end

function Binding:setIsAnalog(isAnalog)
	self.isAnalog = isAnalog
end

-- Local values: isKbMouse
function Binding:setIndex(index)
	self.index = index
	self.isPrimary = index == 1
	local v48_ = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	if v48_ then
		v48_ = self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
	end
	self.isMouse = v48_
end

function Binding:setActive(isActive)
	self.isActive = isActive
end

function Binding:setFrameTriggered(hasTriggered)
	self.hasFrameTriggered = hasTriggered
end

function Binding:getFrameTriggered()
	return self.hasFrameTriggered
end

function Binding:setComboMask(comboMask)
	self.comboMask = comboMask
end

function Binding:getComboMask()
	return self.comboMask
end

-- Local values: sameDevice, sameInput
function Binding:hasCollisionWith(otherBinding)
	if self == otherBinding then
		return false
	else
		return self.deviceId == otherBinding.deviceId and table.equalLists(self.axisNames, otherBinding.axisNames, true)
	end
end

-- Local values: sameDevice, sameInput, sameInputComponent
function Binding:hasEventCollision(otherBinding)
	if self == otherBinding then
		return true
	end
	local v61_ = self.deviceId == otherBinding.deviceId
	local v62_ = table.equalLists(self.axisNames, otherBinding.axisNames, true)
	local v63_ = self.inputComponent == otherBinding.inputComponent
	if v61_ then
		if not v62_ then
			v63_ = v62_
		end
	else
		v63_ = v61_
	end
	return v63_
end

-- Local values: clone
function Binding:clone()
	local v65_ = Binding.new(self.deviceId, self.axisNames, self.axisComponent, self.inputComponent, self.neutralInput, self.index)
	v65_:updateData(self.deviceId, self.deviceCategory, self.axisNames, self.inputComponent, false)
	v65_.internalDeviceId = self.internalDeviceId
	v65_.isAnalog = self.isAnalog
	v65_.comboMask = self.comboMask
	v65_.isActive = self.isActive
	return v65_
end

function Binding:copyInputStateFrom(src)
	self.isDownFlank = src.isDownFlank
	self.isUpFlank = src.isUpFlank
	self.isPressed = src.isPressed
	self.isInputActive = src.isInputActive
	self.recievedDownFlankInCurrentContext = src.recievedDownFlankInCurrentContext
	self.enteredNewContextThisFrame = src.enteredNewContextThisFrame
end

function Binding:resetInputState()
	self.enteredNewContextThisFrame = true
	self.recievedDownFlankInCurrentContext = false
end

-- Local values: sameComponent, sameCategory, sameIndex, sameDevice
function Binding:isSameSlot(otherBinding)
	local v71_ = self.axisComponent == otherBinding.axisComponent
	local v72_ = not (self.isKeyboard and otherBinding.isKeyboard) and (not (self.isMouse and otherBinding.isMouse) and self.isGamepad)
	if v72_ then
		v72_ = otherBinding.isGamepad
	end
	local v73_ = self.index == otherBinding.index
	local v74_ = self.deviceId == otherBinding.deviceId
	if v71_ then
		if v72_ then
			if not v73_ then
				v74_ = v73_
			end
		else
			v74_ = v72_
		end
	else
		v74_ = v71_
	end
	return v74_
end

-- Local values: sameComponent, sameCategory, sameIndex
function Binding:isSameSlotWithParams(axisComponent, isKbMouse, slotIndex)
	local v79_ = self.axisComponent == axisComponent
	local v80_ = (self.isKeyboard or self.isMouse) == isKbMouse
	local v81_ = self.index == slotIndex
	if v79_ then
		if not v80_ then
			v81_ = v80_
		end
	else
		v81_ = v79_
	end
	return v81_
end

function Binding.getOppositeAxisComponent(axisComponent)
	if axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
		return Binding.AXIS_COMPONENT.NEGATIVE
	elseif axisComponent == Binding.AXIS_COMPONENT.NEGATIVE then
		return Binding.AXIS_COMPONENT.POSITIVE
	else
		return nil
	end
end

function Binding.getOppositeInputComponent(inputComponent)
	if inputComponent == Binding.INPUT_COMPONENT.POSITIVE then
		return Binding.INPUT_COMPONENT.NEGATIVE
	elseif inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
		return Binding.INPUT_COMPONENT.POSITIVE
	else
		return nil
	end
end

function Binding:makeId()
	if self.id == nil then
		self.id = string.format("%s|%s|%s|%s|%s", self.deviceId, table.concat(self.axisNames, ";"), self.axisComponent, self.neutralInput, self.index)
	end
end

function Binding:toString()
	return string.format("[(%s), deviceId: %s, axisComponent: %s, index: %s, isActive: %s, isShadowed: %s isInverted: %s, isDown: %s, isUp: %s, inputValue: %s]", table.concat(self.axisNames, ", "), self.deviceId, self.axisComponent, self.index, self.isActive, self.isShadowed, self.isInverted, self.isDownFlank, self.isUpFlank, self.inputValue)
end
Binding_mt.__tostring = Binding.toString
