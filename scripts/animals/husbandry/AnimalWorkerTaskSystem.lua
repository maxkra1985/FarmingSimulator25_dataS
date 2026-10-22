AnimalWorkerTaskSystem = {}
local AnimalWorkerTaskSystem_mt = Class(AnimalWorkerTaskSystem)
AnimalWorkerTaskSystem.DEFAULT_HOUR = 18
AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX = 6
AnimalWorkerTaskSystem.MAX_NUM_TASKS = 2 ^ AnimalWorkerTaskSystem.NUM_BITS_TASK_INDEX - 1
AnimalWorkerTaskSystem.WORK_FIELDS = { "applyMethod", "perform" }
function AnimalWorkerTaskSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or AnimalWorkerTaskSystem_mt)
	self.mission = mission
	self.tasks = {}
	self.tasksByName = {}
	AnimalWorkerTaskRiding.register(self)
	AnimalWorkerTaskGrooming.register(self)
	return self
end
function AnimalWorkerTaskSystem:delete()
	self.tasks = {}
	self.tasksByName = {}
end
function AnimalWorkerTaskSystem:registerTask(task)
	if not AnimalWorkerTaskSystem.getIsTaskValid(task) then
		return false
	elseif self.tasksByName[task.name] ~= nil then
		Logging.error("Animal worker task '%s' is already registered", task.name)
		return false
	elseif AnimalWorkerTaskSystem.MAX_NUM_TASKS <= #self.tasks then
		Logging.error("Could not register animal worker task '%s', the limit of %d tasks is reached", task.name, AnimalWorkerTaskSystem.MAX_NUM_TASKS)
		return false
	else
		table.insert(self.tasks, task)
		self.tasksByName[task.name] = task
		return true
	end
end
function AnimalWorkerTaskSystem:getTasks()
	return self.tasks
end
function AnimalWorkerTaskSystem:getNumTasks()
	return #self.tasks
end
function AnimalWorkerTaskSystem:getTaskByName(name)
	if name == nil then
		return nil
	else
		return self.tasksByName[name]
	end
end
function AnimalWorkerTaskSystem:getTaskByIndex(index)
	if index == nil then
		return nil
	else
		return self.tasks[index]
	end
end
function AnimalWorkerTaskSystem:getTaskIndex(task)
	for index, registeredTask in ipairs(self.tasks) do
		if registeredTask == task then
			return index
		end
	end
	return nil
end
function AnimalWorkerTaskSystem.getIsTaskValid(task)
	if task == nil or type(task.name) ~= "string" or task.name == "" then
		Logging.error("Could not register animal worker task without a name")
		return false
	end
	if type(task.title) ~= "string" then
		Logging.error("Animal worker task '%s' has no title text", task.name)
		return false
	end
	local hasWork = false
	for _, fieldName in ipairs(AnimalWorkerTaskSystem.WORK_FIELDS) do
		if task[fieldName] == nil then
			continue
		end
		hasWork = true
	end
	if not hasWork then
		Logging.error("Animal worker task '%s' neither names a cluster method nor brings a perform callback", task.name)
		return false
	elseif task.subTypeField == nil and task.getIsAvailable == nil then
		Logging.error("Animal worker task '%s' neither names a sub type field nor brings an availability callback", task.name)
		return false
	else
		return AnimalWorkerTaskSystem.getIsScheduleValid(task)
	end
end
function AnimalWorkerTaskSystem.getIsScheduleValid(task)
	local schedule = task.schedule
	if type(schedule) ~= "table" then
		Logging.error("Animal worker task '%s' has no schedule", task.name)
		return false
	elseif schedule.period ~= nil then
		if schedule.dayInPeriod == nil then
			Logging.error("Animal worker task '%s' has a schedule period but no day in period", task.name)
			return false
		else
			return true
		end
	elseif schedule.hour == nil then
		Logging.error("Animal worker task '%s' has a schedule without an hour and without a period", task.name)
		return false
	else
		return true
	end
end
function AnimalWorkerTaskSystem.getTaskIsDaily(task)
	return task.schedule.period == nil
end
function AnimalWorkerTaskSystem.getTaskIsAvailable(task, placeable)
	if task.platformGameplayFlag ~= nil and not Platform.gameplay[task.platformGameplayFlag] then
		return false
	end
	if task.getIsAvailable ~= nil then
		return task.getIsAvailable(placeable)
	else
		return AnimalWorkerTaskUtil.getHasSubTypeField(placeable, task.subTypeField)
	end
end
function AnimalWorkerTaskSystem.getTaskNumTotalAnimals(task, placeable)
	if task.getNumTotalAnimals ~= nil then
		return task.getNumTotalAnimals(placeable)
	else
		return AnimalWorkerTaskUtil.getNumAnimals(placeable, task.supportsMethod)
	end
end
function AnimalWorkerTaskSystem.getTaskNumPendingAnimals(task, placeable)
	if task.getNumPendingAnimals ~= nil then
		return task.getNumPendingAnimals(placeable)
	else
		return AnimalWorkerTaskUtil.getNumAnimals(placeable, task.needsMethod)
	end
end
function AnimalWorkerTaskSystem.performTask(task, placeable)
	if task.perform ~= nil then
		return task.perform(placeable)
	else
		return AnimalWorkerTaskUtil.applyToClusters(placeable, task.applyMethod)
	end
end
function AnimalWorkerTaskSystem.getTaskTitle(task)
	return g_i18n:getText(task.title, task.customEnvironment)
end
