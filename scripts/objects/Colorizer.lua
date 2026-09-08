-- Local values: Colorizer_mt
Colorizer = {}
local Colorizer_mt = Class(Colorizer)

function Colorizer:onCreate(id)
	g_currentMission:addNonUpdateable(Colorizer.new(id))
	print("function Colorizer:onCreate(id)")
end

-- Upvalues: Colorizer_mt
-- Local values: self, colors, xmlFileName, xmlFile, i, key, colorName, rgb, color, numberOfColorObjects, objectIndex, currentColorObject, colorIndex
function Colorizer.new(name)
	-- upvalues: (copy) Colorizer_mt
	local v4_ = Colorizer_mt
	local v5_ = setmetatable({}, v4_)
	v5_.me = name
	local v6_ = {}
	local v7_ = Utils.getNoNil(getUserAttribute(name, "xmlFile"), "")
	local v8_ = Utils.getFilename(v7_, g_currentMission.loadingMapBaseDirectory)
	if v8_ ~= "" then
		local v9_ = loadXMLFile("colors.xml", v8_)
		local v10_ = 0
		while true do
			local v11_ = string.format("colors.color(%d)", v10_)
			local v12_ = getXMLString(v9_, v11_ .. "#colorName")
			local v13_ = getXMLString(v9_, v11_ .. "#color")
			if v13_ == nil then
				break
			end
			local v14_ = string.getVector(v13_, 3)
			if v14_ ~= nil then
				table.insert(v6_, {
					["color"] = v14_,
					["colorName"] = v12_
				})
			end
			v10_ = v10_ + 1
		end
		delete(v9_)
		for v15_ = 1, getNumOfChildren(name) do
			local v16_ = getChildAt(name, v15_ - 1)
			local v17_ = math.random(1, #v6_)
			setShaderParameter(v16_, "colorTint", v6_[v17_][1], v6_[v17_][2], v6_[v17_][3], 1, false)
		end
	end
	return v5_
end

function Colorizer:delete() end
