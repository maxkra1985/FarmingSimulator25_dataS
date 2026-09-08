PlaceableWeatherStation = {}

function PlaceableWeatherStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableWeatherStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWeatherStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWeatherStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWeatherStation)
end

function PlaceableWeatherStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WeatherStation")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".weatherStation.sounds", "idle")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableWeatherStation:onLoad(savegame)
	local v5_ = self.spec_weatherStation
	if self.isClient then
		v5_.sample = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.weatherStation.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
	end
end

-- Local values: spec
function PlaceableWeatherStation:onDelete()
	g_currentMission.placeableSystem:removeWeatherStation(self)
	if self.isClient then
		local v7_ = self.spec_weatherStation
		g_soundManager:deleteSample(v7_.sample)
	end
end

-- Local values: spec
function PlaceableWeatherStation:onFinalizePlacement()
	g_currentMission.placeableSystem:addWeatherStation(self)
	if self.isClient then
		local v9_ = self.spec_weatherStation
		if v9_.sample ~= nil then
			g_soundManager:playSample(v9_.sample)
		end
	end
end
