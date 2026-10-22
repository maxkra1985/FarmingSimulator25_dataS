AnimalWorkerTaskRiding = {}
AnimalWorkerTaskRiding.TASK_NAME = "riding"
AnimalWorkerTaskRiding.DEFAULT_BASE_PRICE = 30
AnimalWorkerTaskRiding.DEFAULT_PRICE_PER_ANIMAL = 10
function AnimalWorkerTaskRiding.register(system)
	local task = {}
	task.name = AnimalWorkerTaskRiding.TASK_NAME
	task.title = "ui_animalWorker_taskRiding"
	task.schedule = { hour = AnimalWorkerTaskSystem.DEFAULT_HOUR }
	task.defaultBasePrice = AnimalWorkerTaskRiding.DEFAULT_BASE_PRICE
	task.defaultPricePerAnimal = AnimalWorkerTaskRiding.DEFAULT_PRICE_PER_ANIMAL
	task.subTypeField = "rideableFilename"
	task.supportsMethod = "getSupportsExercise"
	task.needsMethod = "getNeedsExercise"
	task.applyMethod = "applyExercise"
	system:registerTask(task)
end
