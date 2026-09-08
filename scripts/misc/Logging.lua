-- Local values: getFilename
Logging = {}
local function v_u_3_(p1_)
	local v2_ = type(p1_)
	if v2_ == "number" then
		return getXMLFilename(p1_)
	elseif v2_ == "table" and (p1_.isa ~= nil and p1_:isa(XMLFile)) then
		return p1_:getFilename()
	elseif v2_ == "string" and string.endsWith(p1_, ".xml") then
		return p1_
	else
		return nil
	end
end
function Logging.xmlWarning(p4_, p5_, ...)
	-- upvalues: (copy) v_u_3_
	local v6_ = v_u_3_(p4_)
	printWarning(string.format("  Warning (%s): " .. p5_, v6_, ...))
end
function Logging.xmlError(p7_, p8_, ...)
	-- upvalues: (copy) v_u_3_
	local v9_ = v_u_3_(p7_)
	printError(string.format("  Error (%s): " .. p8_, v9_, ...))
end
function Logging.xmlInfo(p10_, p11_, ...)
	-- upvalues: (copy) v_u_3_
	local v12_ = v_u_3_(p10_)
	print(string.format("  Info (%s): " .. p11_, v12_, ...))
end
function Logging.i3dWarning(p13_, p14_, ...)
	local v15_ = I3DUtil.getNodeNameAndIndexPath(p13_)
	printWarning(string.format("  Warning (%s): " .. p14_, v15_, ...))
end
function Logging.i3dError(p16_, p17_, ...)
	local v18_ = I3DUtil.getNodeNameAndIndexPath(p16_)
	printError(string.format("  Error (%s): " .. p17_, v18_, ...))
end
function Logging.i3dInfo(p19_, p20_, ...)
	local v21_ = I3DUtil.getNodeNameAndIndexPath(p19_)
	print(string.format("  Info (%s): " .. p20_, v21_, ...))
end
function Logging.xmlDevWarning(p22_, p23_, ...)
	-- upvalues: (copy) v_u_3_
	if g_showDevelopmentWarnings then
		local v24_ = v_u_3_(p22_)
		printWarning(string.format("  DevWarning (%s): " .. p23_, v24_, ...))
	end
end
function Logging.xmlDevError(p25_, p26_, ...)
	-- upvalues: (copy) v_u_3_
	if g_showDevelopmentWarnings then
		local v27_ = v_u_3_(p25_)
		printError(string.format("  DevError (%s): " .. p26_, v27_, ...))
	end
end
function Logging.xmlDevInfo(p28_, p29_, ...)
	-- upvalues: (copy) v_u_3_
	if g_showDevelopmentWarnings then
		local v30_ = v_u_3_(p28_)
		print(string.format("  DevInfo (%s): " .. p29_, v30_, ...))
	end
end
function Logging.warning(p31_, ...)
	printWarning(string.format("  Warning: " .. p31_, ...))
end
function Logging.error(p32_, ...)
	printError(string.format("  Error: " .. p32_, ...))
end
function Logging.info(p33_, ...)
	print(string.format("  Info: " .. p33_, ...))
end
function Logging.fatal(p34_, ...)
	local v35_ = string.format("  Fatal Error: " .. p34_, ...)
	printCallstack()
	requestExit()
	error(v35_)
end
function Logging.devWarning(p36_, ...)
	if g_showDevelopmentWarnings then
		printWarning(string.format("  DevWarning: " .. p36_, ...))
	end
end
function Logging.devError(p37_, ...)
	if g_showDevelopmentWarnings then
		printError(string.format("  DevError: " .. p37_, ...))
	end
end
function Logging.devInfo(p38_, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevInfo: " .. p38_, ...))
	end
end
