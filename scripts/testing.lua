-- Local values: tests
g_currentTest = nil
local v_u_1_ = {
	["TestAnimalCluster"] = {
		["className"] = "TestAnimalCluster",
		["filename"] = "dataS/scripts/animals/husbandry/cluster/TestAnimalCluster.lua"
	},
	["TestI3DManager"] = {
		["className"] = "TestI3DManager",
		["filename"] = "dataS/scripts/i3d/TestI3DManager.lua"
	},
	["TestDebugElements"] = {
		["className"] = "TestDebugElements",
		["filename"] = "dataS/scripts/debug/TestDebugElements.lua"
	},
	["TestXML"] = {
		["className"] = "TestXML",
		["filename"] = "dataS/scripts/xml/TestXML.lua"
	},
	["TestPolygon"] = {
		["className"] = "TestPolygon",
		["filename"] = "dataS/scripts/collections/TestPolygon.lua"
	},
	["TestMathUtil"] = {
		["className"] = "TestMathUtil",
		["filename"] = "dataS/scripts/utils/TestMathUtil.lua"
	}
}
function initTesting()
	-- upvalues: (copy) v_u_1_
	local v2_ = StartParams.getValue("test")
	if v2_ ~= nil then
		local v3_ = v_u_1_[v2_]
		if v3_ ~= nil then
			source(v3_.filename)
			g_currentTest = ClassUtil.getClassObject(v3_.className)
			if g_currentTest ~= nil then
				g_currentTest.init()
				Logging.info("Started test \'%s\'", v2_)
				return true
			end
			Logging.error("Test \'%s\' not defined", v2_)
		end
	end
	return false
end
