AnimalWorkerTaskGrooming = {}
AnimalWorkerTaskGrooming.TASK_NAME = "grooming"
AnimalWorkerTaskGrooming.DEFAULT_BASE_PRICE = 25
AnimalWorkerTaskGrooming.DEFAULT_PRICE_PER_ANIMAL = 55
function AnimalWorkerTaskGrooming.register(system)
	local task = {}
	task.name = AnimalWorkerTaskGrooming.TASK_NAME
	task.title = "ui_animalWorker_taskGrooming"
	task.schedule = { hour = AnimalWorkerTaskSystem.DEFAULT_HOUR }
	task.defaultBasePrice = AnimalWorkerTaskGrooming.DEFAULT_BASE_PRICE
	task.defaultPricePerAnimal = AnimalWorkerTaskGrooming.DEFAULT_PRICE_PER_ANIMAL
	task.subTypeField = "rideableFilename"
	task.platformGameplayFlag = "needHorseCleaning"
	task.supportsMethod = "getSupportsGrooming"
	task.needsMethod = "getNeedsGrooming"
	task.applyMethod = "applyGrooming"
	system:registerTask(task)
end
