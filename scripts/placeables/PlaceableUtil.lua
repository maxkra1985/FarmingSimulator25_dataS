PlaceableUtil = {}
function PlaceableUtil.loadPlaceable(filename, position, rotation, ownerFarmId, savegameData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments) end
function PlaceableUtil.loadPlaceableFinished(_, placeable, loadingState, arguments)
	local asyncCallbackFunction = arguments.asyncCallbackFunction
	local asyncCallbackObject = arguments.asyncCallbackObject
	local asyncCallbackArguments = arguments.asyncCallbackArguments
	asyncCallbackFunction(asyncCallbackObject, placeable, loadingState, asyncCallbackArguments)
end
