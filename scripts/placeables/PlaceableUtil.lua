PlaceableUtil = {}

function PlaceableUtil.loadPlaceable(filename, position, rotation, ownerFarmId, savegameData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments) end

-- Local values: asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments
function PlaceableUtil.loadPlaceableFinished(_, placeable, loadingState, arguments)
	arguments.asyncCallbackFunction(arguments.asyncCallbackObject, placeable, loadingState, arguments.asyncCallbackArguments)
end
