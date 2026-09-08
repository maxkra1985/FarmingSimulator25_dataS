-- Local values: FerryState_mt
FerryState = {}
local FerryState_mt = Class(FerryState)

function FerryState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#index", "Animated object index")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#direction", "Animated object direction")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#time", "Animated object time")
	schema:register(XMLValueType.BOOL, basePath .. ".animatedObject(?)#reset", "Animated object reset on state deactivate")
end

-- Upvalues: FerryState_mt
-- Local values: self
function FerryState.new(ferry, customMt)
	-- upvalues: (copy) FerryState_mt
	local v6_ = customMt or FerryState_mt
	local v7_ = setmetatable({}, v6_)
	v7_.ferry = ferry
	v7_.animatedObjects = {}
	return v7_
end

-- Local values: _, animKey, index, object, animatedObject
function FerryState:load(xmlFile, key)
	for _, v11_ in xmlFile:iterator(key .. ".animatedObject") do
		local v12_ = xmlFile:getValue(v11_ .. "#index")
		local v13_ = self.ferry.animatedObjects[v12_]
		if v13_ ~= nil then
			local v14_ = {
				["object"] = v13_,
				["direction"] = xmlFile:getValue(v11_ .. "#direction", 1),
				["time"] = xmlFile:getValue(v11_ .. "#time", 1),
				["reset"] = xmlFile:getValue(v11_ .. "#reset", false)
			}
			local v15_ = self.animatedObjects
			table.insert(v15_, v14_)
		end
	end
	return true
end

-- Local values: isDone, _, animatedObject, animation
function FerryState:isDone()
	local v17_ = true
	for _, v18_ in ipairs(self.animatedObjects) do
		local v19_ = v18_.object.animation
		if v19_.direction ~= 0 and v19_.direction ~= v18_.direction then
			return false
		end
		local v20_ = v19_.time - v18_.time
		if math.abs(v20_) > 0.001 then
			return false
		end
	end
	return v17_
end

function FerryState:update(dt) end

-- Local values: _, animatedObject
function FerryState:activate()
	if self.ferry.isServer then
		for _, v22_ in ipairs(self.animatedObjects) do
			if v22_.reset then
				v22_.object:setAnimTime(0)
			end
			v22_.object:setDirection(v22_.direction)
		end
	end
end

function FerryState:deactivate() end

function FerryState:raiseActive()
	return true
end

function FerryState:getCanFinishState()
	return false
end
