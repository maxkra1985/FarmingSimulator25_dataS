SpecializationUtil = {}
function SpecializationUtil.raiseAsyncEvent(p_u_1_, p_u_2_, ...)
	if p_u_1_.eventListeners[p_u_2_] == nil then
		local v3_ = p_u_1_.type and p_u_1_.type.name or "<unknown>"
		printError(string.format("Error: Event %q is not registered for type %q!", p_u_2_, v3_))
		printCallstack()
	else
		local v_u_4_ = { ... }
		for _, v_u_5_ in ipairs(p_u_1_.eventListeners[p_u_2_]) do
			p_u_1_:addAsyncTask(function()
				-- upvalues: (copy) v_u_5_, (copy) p_u_2_, (copy) p_u_1_, (copy) v_u_4_
				local v6_ = v_u_4_
				v_u_5_[p_u_2_](p_u_1_, unpack(v6_))
			end, v_u_5_.className, false)
		end
	end
end
function SpecializationUtil.raiseEvent(p7_, p8_, ...)
	if p7_.eventListeners[p8_] == nil then
		local v9_ = p7_.type and p7_.type.name or "<unknown>"
		printError(string.format("Error: Event %q is not registered for type %q!", p8_, v9_))
		printCallstack()
	else
		for _, v10_ in ipairs(p7_.eventListeners[p8_]) do
			v10_[p8_](p7_, ...)
		end
	end
end

function SpecializationUtil.registerFunction(objectType, funcName, func)
	if string.isNilOrWhitespace(funcName) then
		Logging.error("Given function name is is \'nil\' or empty!")
		printCallstack()
		return
	elseif func == nil then
		Logging.error("Given reference for Function \'%s\' is \'nil\'!", funcName)
		printCallstack()
		return
	elseif objectType.functions[funcName] == nil then
		if objectType.events[funcName] == nil then
			objectType.functions[funcName] = func
		else
			Logging.error("Function \'%s\' already registered as event in type \'%s\'!", funcName, objectType.name)
			printCallstack()
		end
	else
		Logging.error("Function \'%s\' already registered as function in type \'%s\'!", funcName, objectType.name)
		printCallstack()
		return
	end
end

function SpecializationUtil.registerOverwrittenFunction(objectType, funcName, func)
	if string.isNilOrWhitespace(funcName) then
		Logging.error("Given function name is is \'nil\' or empty!")
		printCallstack()
		return
	elseif func == nil then
		Logging.error("Given reference for OverwrittenFunction \'%s\' is \'nil\'!", funcName)
		printCallstack()
	elseif objectType.functions[funcName] ~= nil then
		objectType.functions[funcName] = Utils.overwrittenFunction(objectType.functions[funcName], func)
	end
end

function SpecializationUtil.registerEvent(objectType, eventName)
	if string.isNilOrWhitespace(eventName) then
		Logging.error("Given name for event is \'nil\' or empty!")
		printCallstack()
		return
	elseif objectType.functions[eventName] == nil then
		if objectType.events[eventName] == nil then
			objectType.events[eventName] = eventName
			objectType.eventListeners[eventName] = {}
		else
			Logging.error("Event \'%s\' already registered as event in type \'%s\'!", eventName, objectType.name)
			printCallstack()
		end
	else
		Logging.error("Event \'%s\' already registered as function in type \'%s\'!", eventName, objectType.name)
		printCallstack()
		return
	end
end

-- Local values: className, found, _, registeredSpec
function SpecializationUtil.registerEventListener(objectType, eventName, specClass)
	if string.isNilOrWhitespace(eventName) then
		Logging.error("Given event name is is \'nil\' or empty!")
		printCallstack()
		return
	end
	local v22_ = specClass.className
	if objectType.eventListeners == nil then
		Logging.error("Invalid type for specialization \'%s\'!", v22_)
		printCallstack()
		return
	end
	if specClass[eventName] == nil then
		Logging.error("Event listener function \'%s\' not defined in specialization \'%s\'!", eventName, v22_)
		printCallstack()
		return
	end
	if objectType.eventListeners[eventName] == nil then
		return
	end
	local v23_ = false
	for _, v24_ in pairs(objectType.eventListeners[eventName]) do
		if v24_ == specClass then
			v23_ = true
			break
		end
	end
	if v23_ then
		Logging.error("Event listener for \'%s\' already registered in specialization \'%s\'!", eventName, v22_)
		printCallstack()
	else
		local v25_ = objectType.eventListeners[eventName]
		table.insert(v25_, specClass)
	end
end

-- Local values: listeners, i
function SpecializationUtil.removeEventListener(object, eventName, specClass)
	local v29_ = object.eventListeners[eventName]
	if v29_ ~= nil then
		for v30_ = #v29_, 1, -1 do
			if v29_[v30_] == specClass then
				table.remove(v29_, v30_)
			end
		end
	end
end

-- Local values: _, v
function SpecializationUtil.hasSpecialization(spec, specializations)
	for _, v33_ in pairs(specializations) do
		if v33_ == spec then
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

-- Local values: funcName, func
function SpecializationUtil.copyTypeFunctionsInto(typeDef, target)
	for v38_, v39_ in pairs(typeDef.functions) do
		target[v38_] = v39_
	end
end

-- Local values: i, specEntryName, stopLoading, env
function SpecializationUtil.createSpecializationEnvironments(target, failureCallback)
	for v42_ = 1, #target.specializations do
		local v43_ = "spec_" .. target.specializationNames[v42_]
		if target[v43_] == nil then
			local v44_ = setmetatable({}, {
				["__index"] = target
			})
			v44_.actionEvents = {}
			target[v43_] = v44_
		elseif failureCallback(target.specializationNames[v42_], v43_) then
			return false
		end
	end
	return true
end

-- Local values: task
function SpecializationUtil.createLoadingTask(typeClass, target)
	local v47_ = {
		["target"] = target
	}
	local v48_ = typeClass.loadingTasks
	table.insert(v48_, v47_)
	return v47_
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
	if SpecializationUtil.getIsValidLoadingStep(loadingStep) then
		typeClass.loadingStep = loadingStep
	else
		printCallstack()
		Logging.error("Invalid loading step \'%s\'!", loadingStep)
	end
end

-- Local values: _, value
function SpecializationUtil.getIsValidLoadingStep(loadingStep)
	for _, v54_ in pairs(SpecializationLoadStep) do
		if v54_ == loadingStep then
			return true
		end
	end
	return false
end

-- Local values: name, value
function SpecializationUtil.getLoadingStepName(loadingStep)
	for v56_, v57_ in pairs(SpecializationLoadStep) do
		if v57_ == loadingStep then
			return v56_
		end
	end
	return nil
end
