PlaceableWeighingStation = {}

function PlaceableWeighingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableWeighingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onWeighingTriggerCallback", PlaceableWeighingStation.onWeighingTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "updateWeightDisplay", PlaceableWeighingStation.updateWeightDisplay)
	SpecializationUtil.registerFunction(placeableType, "setWeightDisplay", PlaceableWeighingStation.setWeightDisplay)
end

function PlaceableWeighingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWeighingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWeighingStation)
end

function PlaceableWeighingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WeighingStation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".weighingStation#triggerNode", "Vehicle trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".weighingStation.display(?)#node", "Display start node")
	schema:register(XMLValueType.STRING, basePath .. ".weighingStation.display(?)#font", "Display font name")
	schema:register(XMLValueType.STRING, basePath .. ".weighingStation.display(?)#alignment", "Display text alignment")
	schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#size", "Display text size")
	schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#scaleX", "Display text x scale")
	schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#scaleY", "Display text y scale")
	schema:register(XMLValueType.STRING, basePath .. ".weighingStation.display(?)#mask", "Display text mask")
	schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#emissiveScale", "Display emissive scale")
	schema:register(XMLValueType.COLOR, basePath .. ".weighingStation.display(?)#color", "Display text color")
	schema:register(XMLValueType.COLOR, basePath .. ".weighingStation.display(?)#hiddenColor", "Display text hidden color")
	schema:setXMLSpecializationType()
end

-- Local values: spec, key
function PlaceableWeighingStation:onLoad(savegame)
	local v_u_6_ = self.spec_weighingStation
	v_u_6_.trigger = self.xmlFile:getValue("placeable.weighingStation#triggerNode", nil, self.components, self.i3dMappings)
	if v_u_6_.trigger == nil then
		Logging.xmlError(self.xmlFile, "Missing vehicle triggerNode for weighing station")
	else
		addTrigger(v_u_6_.trigger, "onWeighingTriggerCallback", self)
		v_u_6_.triggerVehicleNodes = {}
		v_u_6_.vehicles = {}
		v_u_6_.displays = {}
		self.xmlFile:iterate("placeable.weighingStation.display", function(_, p7_)
			-- upvalues: (copy) self, (copy) v_u_6_
			local v8_ = self.xmlFile:getValue(p7_ .. "#node", nil, self.components, self.i3dMappings)
			if v8_ ~= nil then
				local v9_ = string.upper(self.xmlFile:getValue(p7_ .. "#font", "DIGIT"))
				local v10_ = g_materialManager:getFontMaterial(v9_, self.customEnvironment)
				if v10_ ~= nil then
					local v11_ = {}
					local v12_ = self.xmlFile:getValue(p7_ .. "#alignment", "RIGHT")
					local v13_ = RenderText["ALIGN_" .. string.upper(v12_)] or RenderText.ALIGN_RIGHT
					local v14_ = self.xmlFile:getValue(p7_ .. "#size", 0.03)
					local v15_ = self.xmlFile:getValue(p7_ .. "#scaleX", 1)
					local v16_ = self.xmlFile:getValue(p7_ .. "#scaleY", 1)
					local v17_ = self.xmlFile:getValue(p7_ .. "#mask", "00.0")
					local v18_ = self.xmlFile:getValue(p7_ .. "#emissiveScale", 0.2)
					local v19_ = self.xmlFile:getValue(p7_ .. "#color", {
						0.9,
						0.9,
						0.9,
						1
					}, true)
					local v20_ = self.xmlFile:getValue(p7_ .. "#hiddenColor", nil, true)
					v11_.displayNode = v8_
					local v21_, v22_ = Utils.maskToFormat(v17_)
					v11_.formatStr = v21_
					v11_.formatPrecision = v22_
					v11_.characterLine = CharacterLine.new(v8_, v10_, v17_:len())
					v11_.characterLine:setSizeAndScale(v14_, v15_, v16_)
					v11_.characterLine:setTextAlignment(v13_)
					v11_.characterLine:setColor(v19_, v20_, v18_)
					local v23_ = v_u_6_.displays
					table.insert(v23_, v11_)
				end
			end
		end)
		self:setWeightDisplay(0)
	end
end

-- Local values: spec
function PlaceableWeighingStation:onDelete()
	local v25_ = self.spec_weighingStation
	if v25_.trigger ~= nil then
		removeTrigger(v25_.trigger)
		v25_.trigger = nil
	end
end

-- Local values: spec, node, _, vehicle, mass, vehicle
function PlaceableWeighingStation:updateWeightDisplay()
	local v27_ = self.spec_weighingStation
	for v28_, _ in pairs(v27_.triggerVehicleNodes) do
		if entityExists(v28_) then
			local v29_ = g_currentMission:getNodeObject(v28_)
			if v29_ ~= nil and v29_.getTotalMass ~= nil then
				v27_.vehicles[v29_] = true
			end
		else
			v27_.triggerVehicleNodes[v28_] = nil
		end
	end
	local v30_ = 0
	for v31_ in pairs(v27_.vehicles) do
		v30_ = v30_ + v31_:getTotalMass(true)
	end
	table.clear(v27_.vehicles)
	self:setWeightDisplay(v30_ * 1000)
end

-- Local values: spec, _, display, int, floatPart, value
function PlaceableWeighingStation:setWeightDisplay(mass)
	local v34_ = self.spec_weighingStation
	for _, v35_ in ipairs(v34_.displays) do
		local v36_, v37_ = math.modf(mass)
		local v38_ = string.format
		local v39_ = v35_.formatStr
		local v40_ = v37_ * 10 ^ v35_.formatPrecision
		local v41_ = math.floor(v40_)
		local v42_ = v38_(v39_, v36_, (math.abs(v41_)))
		v35_.characterLine:setText(v42_)
	end
end

-- Local values: spec
function PlaceableWeighingStation:onWeighingTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local v47_ = self.spec_weighingStation
		if onEnter then
			v47_.triggerVehicleNodes[otherId] = true
		else
			v47_.triggerVehicleNodes[otherId] = nil
		end
		self:updateWeightDisplay()
	end
end
