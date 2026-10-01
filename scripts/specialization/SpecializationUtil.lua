SpecializationUtil = {}
function SpecializationUtil.raiseAsyncEvent(object, eventName, ...)
	if object.eventListeners[eventName] == nil then
		local typeName = object.type and object.type.name or "<unknown>"
		printError(string.format("Error: Event %q is not registered for type %q!", eventName, typeName))
		printCallstack()
	else
		local args = { ... }
		for _, spec in ipairs(object.eventListeners[eventName]) do
			object:addAsyncTask(function()
				spec[eventName](object, unpack(args))
			end, spec.className, false)
		end
	end
end
function SpecializationUtil.raiseEvent(object, eventName, ...)
	if object.eventListeners[eventName] == nil then
		local typeName = object.type and object.type.name or "<unknown>"
		printError(string.format("Error: Event %q is not registered for type %q!", eventName, typeName))
		printCallstack()
	else
		for _, spec in ipairs(object.eventListeners[eventName]) do
			spec[eventName](object, ...)
		end
	end
end
function SpecializationUtil.registerFunction(objectType, funcName, func)
	if string.isNilOrWhitespace(funcName) then
		Logging.error("Given function name is is 'nil' or empty!")
		printCallstack()
	elseif func == nil then
		Logging.error("Given reference for Function '%s' is 'nil'!", funcName)
		printCallstack()
	elseif objectType.functions[funcName] ~= nil then
		Logging.error("Function '%s' already registered as function in type '%s'!", funcName, objectType.name)
		printCallstack()
	elseif objectType.events[funcName] ~= nil then
		Logging.error("Function '%s' already registered as event in type '%s'!", funcName, objectType.name)
		printCallstack()
	else
		objectType.functions[funcName] = func
	end
end
function SpecializationUtil.registerOverwrittenFunction(objectType, funcName, func)
	if string.isNilOrWhitespace(funcName) then
		Logging.error("Given function name is is 'nil' or empty!")
		printCallstack()
	elseif func == nil then
		Logging.error("Given reference for OverwrittenFunction '%s' is 'nil'!", funcName)
		printCallstack()
	else
		if objectType.functions[funcName] ~= nil then
			objectType.functions[funcName] = Utils.overwrittenFunction(objectType.functions[funcName], func)
		end
	end
end
function SpecializationUtil.registerEvent(objectType, eventName)
	if string.isNilOrWhitespace(eventName) then
		Logging.error("Given name for event is 'nil' or empty!")
		printCallstack()
	elseif objectType.functions[eventName] ~= nil then
		Logging.error("Event '%s' already registered as function in type '%s'!", eventName, objectType.name)
		printCallstack()
	elseif objectType.events[eventName] ~= nil then
		Logging.error("Event '%s' already registered as event in type '%s'!", eventName, objectType.name)
		printCallstack()
	else
		objectType.events[eventName] = eventName
		objectType.eventListeners[eventName] = {}
	end
end
function SpecializationUtil.registerEventListener(objectType, eventName, specClass)
	if string.isNilOrWhitespace(eventName) then
		Logging.error("Given event name is is 'nil' or empty!")
		printCallstack()
		return
	end
	local className = specClass.className
	if objectType.eventListeners == nil then
		Logging.error("Invalid type for specialization '%s'!", className)
		printCallstack()
		return
	end
	if specClass[eventName] == nil then
		Logging.error("Event listener function '%s' not defined in specialization '%s'!", eventName, className)
		printCallstack()
		return
	end
	if objectType.eventListeners[eventName] == nil then
		return
	end
	local found = false
	for _, registeredSpec in pairs(objectType.eventListeners[eventName]) do
		if registeredSpec == specClass then
			found = true
			break
		end
	end
	if found then
		Logging.error("Event listener for '%s' already registered in specialization '%s'!", eventName, className)
		printCallstack()
	else
		table.insert(objectType.eventListeners[eventName], specClass)
	end
end
function SpecializationUtil.removeEventListener(object, eventName, specClass)
	local listeners = object.eventListeners[eventName]
	if listeners ~= nil then
		for i = #listeners, 1, -1 do
			if listeners[i] == specClass then
				table.remove(listeners, i)
			end
		end
	end
end
function SpecializationUtil.hasSpecialization(spec, specializations)
	for _, v in pairs(specializations) do
		if v == spec then
			return true
		end
	end
	return false
end
function SpecializationUtil.initSpecializationsIntoTypeClass(typeManager, typeDef, target)
	target.type = typeDef
	target.typeName = typeDef.name
	target.specializations = typeDef.specializations
	target.specializationNames = typeDef.specializationNames
	target.specializationsByName = typeDef.specializationsByName
	target.eventListeners = table.clone(typeDef.eventListeners, 2)
	return typeDef
end
function SpecializationUtil.copyTypeFunctionsInto(typeDef, target)
	for funcName, func in pairs(typeDef.functions) do
		target[funcName] = func
	end
end
function SpecializationUtil.createSpecializationEnvironments(target, failureCallback)
	for i = 1, #target.specializations do
		local specEntryName = "spec_" .. target.specializationNames[i]
		if target[specEntryName] ~= nil then
			local stopLoading = failureCallback(target.specializationNames[i], specEntryName)
			if stopLoading then
				return false
			end
		else
			local env = setmetatable({}, { __index = target })
			env.actionEvents = {}
			target[specEntryName] = env
		end
	end
	return true
end
function SpecializationUtil.createLoadingTask(typeClass, target)
	local task = { target = target }
	table.insert(typeClass.loadingTasks, task)
	return task
end
function SpecializationUtil.finishLoadingTask(typeClass, task)
	if not table.removeElement(typeClass.loadingTasks, task) then
		Logging.warning("Loading task was marked as finished, but was never added in the first place. Ensure that every finishLoadingTask call uses a task given from the createLoadingTask function.")
	end
	if typeClass.readyForFinishLoading and #typeClass.loadingTasks == 0 then
		typeClass:onFinishedLoading()
	end
end
function SpecializationUtil.setLoadingStep(typeClass, loadingStep)
	if not SpecializationUtil.getIsValidLoadingStep(loadingStep) then
		printCallstack()
		Logging.error("Invalid loading step '%s'!", loadingStep)
	else
		typeClass.loadingStep = loadingStep
	end
end
function SpecializationUtil.getIsValidLoadingStep(loadingStep)
	for _, value in pairs(SpecializationLoadStep) do
		if value == loadingStep then
			return true
		end
	end
	return false
end
function SpecializationUtil.getLoadingStepName(loadingStep)
	for name, value in pairs(SpecializationLoadStep) do
		if value == loadingStep then
			return name
		end
	end
	return nil
end
