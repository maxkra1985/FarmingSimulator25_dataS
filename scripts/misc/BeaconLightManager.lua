-- Local values: BeaconLightManager_mt
BeaconLightManager = {}
BeaconLightManager.MASK_ALL = 4294967295
BeaconLightManager.MODE = {}
BeaconLightManager.MODE.ROTATE_LEFT = 0
BeaconLightManager.MODE.ROTATE_RIGHT = 1
BeaconLightManager.MODE.BLINK = 2
BeaconLightManager.MODE.ROTATE_LEFT_RIGHT = 3
BeaconLightManager.MODE.DOUBLE_ROTATE_CROSS = 4
BeaconLightManager.MODE.DOUBLE_ROTATE_LEFT = 5
BeaconLightManager.MODE.DOUBLE_ROTATE_RIGHT = 6
BeaconLightManager.MODE.DOUBLE_BLINK_TRIPLE_WAIT = 7
local BeaconLightManager_mt = Class(BeaconLightManager, AbstractManager)

-- Upvalues: BeaconLightManager_mt
-- Local values: self
function BeaconLightManager.new(customMt)
	-- upvalues: (copy) BeaconLightManager_mt
	local v3_ = customMt or BeaconLightManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.nextBeaconLightId = 1
	v4_.beaconLights = {}
	v4_.maxNumBeaconLights = 1
	v4_.lastBrightnessScale = nil
	return v4_
end

function BeaconLightManager:getNumOfLights()
	return getNumOfBeaconLights()
end

-- Local values: mask, brightnessScale, id
function BeaconLightManager:activateBeaconLight(mode, numLEDs, rpm, brightness)
	if #self.beaconLights >= self.maxNumBeaconLights then
		return nil
	end
	local v10_ = BeaconLightManager.MASK_ALL
	local v11_ = g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS)
	if v11_ > 0 then
		setBeaconLights(v10_, mode, numLEDs, rpm, brightness * v11_)
	end
	local v12_ = self.nextBeaconLightId
	self.nextBeaconLightId = self.nextBeaconLightId + 1
	local v13_ = self.beaconLights
	table.insert(v13_, {
		["id"] = v12_,
		["mask"] = v10_,
		["mode"] = mode,
		["numLEDs"] = numLEDs,
		["rpm"] = rpm,
		["brightness"] = brightness,
		["brightnessScale"] = v11_
	})
	return v12_
end

-- Local values: brightnessScale, k, beaconLight
function BeaconLightManager:deactivateBeaconLight(id)
	if id ~= nil then
		local v16_ = g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS)
		for v17_, v18_ in ipairs(self.beaconLights) do
			if v18_.id == id then
				if v16_ > 0 then
					setBeaconLights(v18_.mask, 0, 0, 100, 0)
				end
				table.remove(self.beaconLights, v17_)
				return
			end
		end
	end
end

-- Local values: brightnessScale, k, beaconLight
function BeaconLightManager:updateBeaconLights()
	if #self.beaconLights > 0 then
		local v20_ = g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS)
		for _, v21_ in ipairs(self.beaconLights) do
			if v20_ > 0 then
				setBeaconLights(v21_.mask, v21_.mode, v21_.numLEDs, v21_.rpm, v21_.brightness * v20_)
				v21_.brightnessScale = v20_
			elseif v20_ == 0 and v21_.brightnessScale > 0 then
				setBeaconLights(v21_.mask, 0, 0, 100, 0)
				v21_.brightnessScale = 0
			end
		end
	end
end

function BeaconLightManager.getModeByName(modeName)
	if modeName == nil then
		return nil
	end
	local v23_ = string.upper(modeName)
	return BeaconLightManager.MODE[v23_]
end

function BeaconLightManager.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. "#mode", "Real beacon light mode")
	schema:register(XMLValueType.FLOAT, baseKey .. "#rpm", "Real beacon rpm")
	schema:register(XMLValueType.FLOAT, baseKey .. "#numLEDScale", "Real beacon num led factor (0-1)")
	schema:register(XMLValueType.FLOAT, baseKey .. "#brightnessScale", "Real beacon brightness factor (0-1)")
end

-- Local values: deviceModeName, deviceMode, device
function BeaconLightManager.loadDeviceFromXML(xmlFile, baseKey)
	local v28_ = xmlFile:getValue(baseKey .. "#mode")
	if v28_ ~= nil then
		local v29_ = BeaconLightManager.getModeByName(v28_)
		if v29_ ~= nil then
			return {
				["mode"] = v29_,
				["rpm"] = xmlFile:getValue(baseKey .. "#rpm", 100),
				["numLEDScale"] = xmlFile:getValue(baseKey .. "#numLEDScale", 1),
				["brightnessScale"] = xmlFile:getValue(baseKey .. "#brightnessScale", 1)
			}
		end
	end
	return nil
end
g_beaconLightManager = BeaconLightManager.new()
