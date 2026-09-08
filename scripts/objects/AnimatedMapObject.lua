-- Local values: AnimatedMapObject_mt
AnimatedMapObject = {}
local AnimatedMapObject_mt = Class(AnimatedMapObject, AnimatedObject)
InitStaticObjectClass(AnimatedMapObject, "AnimatedMapObject")
g_xmlManager:addCreateSchemaFunction(function()
	AnimatedMapObject.xmlSchema = XMLSchema.new("animatedObjects")
end)
g_xmlManager:addInitSchemaFunction(function()
	AnimatedObject.registerXMLPaths(AnimatedMapObject.xmlSchema, "animatedObjects")
	AnimatedObject.registerSavegameXMLPaths(OnCreateObjectSystem.xmlSchemaSavegame, "onCreateLoadedObjects.object(?)")
end)

-- Local values: object
function AnimatedMapObject:onCreate(id)
	local v3_ = AnimatedMapObject.new(g_server ~= nil, g_client ~= nil)
	if v3_:load(id) then
		g_currentMission.onCreateObjectSystem:add(v3_, true)
		v3_:register(true)
	else
		v3_:delete()
	end
end

-- Upvalues: AnimatedMapObject_mt
function AnimatedMapObject.new(isServer, isClient, customMt)
	-- upvalues: (copy) AnimatedMapObject_mt
	return AnimatedObject.new(isServer, isClient, customMt or AnimatedMapObject_mt)
end

function AnimatedMapObject:delete()
	g_currentMission.onCreateObjectSystem:remove(self)
	AnimatedMapObject:superClass().delete(self)
end

-- Local values: xmlFilename, baseDir, saveId, xmlFile, key, result
function AnimatedMapObject:load(nodeId)
	local v10_ = getUserAttribute(nodeId, "xmlFilename")
	if v10_ == nil then
		Logging.error("Missing \'xmlFilename\' user attribute for AnimatedMapObject node \'%s\'!", getName(nodeId))
		return false
	end
	local v11_ = g_currentMission.loadingMapBaseDirectory
	if v11_ == "" then
		v11_ = Utils.getNoNil(self.baseDirectory, v11_)
	end
	local v12_ = Utils.getFilename(v10_, v11_)
	local v_u_13_ = getUserAttribute(nodeId, "saveId") or getUserAttribute(nodeId, "index")
	if v_u_13_ == nil then
		Logging.error("Missing \'saveId\' user attribute for AnimatedMapObject node \'%s\'!", getName(nodeId))
		return false
	end
	local v_u_14_ = XMLFile.load("AnimatedObject", v12_, AnimatedMapObject.xmlSchema)
	if v_u_14_ == nil then
		return false
	end
	local v_u_15_ = nil
	v_u_14_:iterate("animatedObjects.animatedObject", function(_, p16_)
		-- upvalues: (copy) v_u_14_, (copy) v_u_13_, (ref) v_u_15_
		if (v_u_14_:getString(p16_ .. "#saveId") or v_u_14_:getString(p16_ .. "#index")) == v_u_13_ then
			v_u_15_ = p16_
			return true
		end
	end)
	if v_u_15_ == nil then
		Logging.error("saveId \'%s\' not found in AnimatedObject xml \'%s\'!", v_u_13_, v12_)
		return false
	end
	local v17_ = AnimatedMapObject:superClass().load(self, nodeId, v_u_14_, v_u_15_, v12_)
	v_u_14_:delete()
	return v17_
end
