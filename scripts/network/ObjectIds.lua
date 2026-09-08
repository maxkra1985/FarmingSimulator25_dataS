-- Local values: objectId, nextObjectId
ObjectIds = {}
ObjectIds.objectClasses = {}
ObjectIds.objectIdNext = 0
ObjectIds.objectIdsUsed = {}
ObjectIds.objectIdToClass = {}
local objectId = 0

function InitObjectClass(classObject, className)
	if g_currentMission == nil then
		if ObjectIds.objectClasses[className] == nil then
			classObject.className = className
			ObjectIds.objectClasses[className] = classObject
		else
			printError("Error: Same class name used multiple times " .. className)
			printCallstack()
		end
	else
		printError("Error: Object initialization only allowed at compile time")
		printCallstack()
		return
	end
end

-- Upvalues: objectId
-- Local values: id
function InitStaticObjectClass(classObject, className)
	-- upvalues: (ref) objectId
	if g_server == nil and g_client == nil then
		objectId = objectId + 1
		local v6_ = objectId
		Logging.devInfo("Auto assign object class id \'%d\' for class \'%s\'", v6_, className)
		classObject.className = className
		ObjectIds.assignObjectClassObjectId(classObject, className, v6_)
	else
		printError("Error: Object initialization only allowed at compile time")
		printCallstack()
	end
end

function ObjectIds.getObjectClassByName(className)
	return ObjectIds.objectClasses[className]
end

function ObjectIds.getObjectClassById(id)
	return ObjectIds.objectIdToClass[id]
end
function ObjectIds.assignObjectClassIds()
	for v9_, v10_ in pairs(ObjectIds.objectClasses) do
		ObjectIds.assignObjectClassObjectId(v10_, v9_, ObjectIds.objectIdNext)
	end
end

-- Local values: classObject
function ObjectIds.assignObjectClassId(className, id)
	local v13_ = ObjectIds.objectClasses[className]
	if v13_ ~= nil then
		ObjectIds.assignObjectClassObjectId(v13_, className, id)
	end
end

function ObjectIds.assignObjectClassObjectId(classObject, className, id)
	if id == nil then
		printError("Error: Invalid object id, it is nil")
		printCallstack()
		return
	elseif ObjectIds.MAX_OBJECT_ID < id then
		printError("Error: Invalid object id, maximum is " .. ObjectIds.MAX_OBJECT_ID)
		printCallstack()
	elseif rawget(classObject, "classId") == nil then
		if ObjectIds.objectIdsUsed[id] ~= nil then
			printError("Error: Same object id used multiple times " .. id)
			printCallstack()
			return
		end
		ObjectIds.objectIdsUsed[id] = true
		local v16_ = ObjectIds
		local v17_ = ObjectIds.objectIdNext
		v16_.objectIdNext = math.max(v17_, id) + 1
		classObject.classId = id
		ObjectIds.objectIdToClass[id] = classObject
	end
end
ObjectIds.SEND_NUM_BITS = 16
ObjectIds.MAX_OBJECT_ID = 2 ^ ObjectIds.SEND_NUM_BITS - 1
