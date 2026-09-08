-- Local values: eventId, nextEventId
EventIds = {}
EventIds.eventClasses = {}
EventIds.eventIdNext = 0
EventIds.eventIdsUsed = {}
EventIds.eventIdToClass = {}
local eventId = 0

function InitEventClass(classObject, className)
	if g_currentMission == nil then
		if EventIds.eventClasses[className] == nil then
			EventIds.eventClasses[className] = classObject
		else
			printError("Error: Same class name used multiple times " .. className)
			printCallstack()
		end
	else
		printError("Error: Event initialization only allowed at compile time")
		printCallstack()
		return
	end
end

-- Upvalues: eventId
-- Local values: id
function InitStaticEventClass(classObject, className)
	-- upvalues: (ref) eventId
	if g_server == nil and g_client == nil then
		eventId = eventId + 1
		local v6_ = eventId
		Logging.devInfo("Auto assign event class id \'%d\' for class \'%s\'", v6_, className)
		EventIds.assignEventObjectId(classObject, className, v6_)
	else
		printError("Error: Event initialization only allowed at compile time")
		printCallstack()
	end
end

function EventIds.getEventClassByName(className)
	return EventIds.eventClasses[className]
end

function EventIds.getEventClassById(id)
	return EventIds.eventIdToClass[id]
end
function EventIds.assignEventIds()
	for v9_, v10_ in pairs(EventIds.eventClasses) do
		Logging.devInfo("(Server) Assign event id \'%d\' to class \'%s\'", EventIds.eventIdNext, v9_)
		EventIds.assignEventObjectId(v10_, v9_, EventIds.eventIdNext)
	end
end

-- Local values: classObject
function EventIds.assignEventId(className, id)
	local v13_ = EventIds.eventClasses[className]
	if v13_ ~= nil then
		EventIds.assignEventObjectId(v13_, className, id)
		Logging.devInfo("(Client) Assign event id \'%d\' to class \'%s\'", id, className)
	end
end

function EventIds.assignEventObjectId(classObject, className, id)
	if id == nil then
		printError("Error: Invalid event id, it is nil")
		printCallstack()
		return
	elseif EventIds.MAX_EVENT_ID < id then
		printError("Error: Invalid object id, maximum is " .. EventIds.MAX_EVENT_ID)
		printCallstack()
	elseif rawget(classObject, "eventId") == nil then
		if EventIds.eventIdsUsed[id] ~= nil then
			printError("Error: Same event id used multiple times " .. id)
			printCallstack()
			return
		end
		EventIds.eventIdsUsed[id] = true
		local v16_ = EventIds
		local v17_ = EventIds.eventIdNext
		local v18_ = id + 1
		v16_.eventIdNext = math.max(v17_, v18_)
		classObject.eventId = id
		EventIds.eventIdToClass[id] = classObject
	end
end
EventIds.SEND_NUM_BITS = 16
EventIds.MAX_EVENT_ID = 2 ^ EventIds.SEND_NUM_BITS - 1
