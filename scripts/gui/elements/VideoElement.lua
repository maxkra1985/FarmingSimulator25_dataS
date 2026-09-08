-- Local values: VideoElement_mt
VideoElement = {}
local VideoElement_mt = Class(VideoElement, GuiElement)
Gui.registerGuiElement("Video", VideoElement)

-- Upvalues: VideoElement_mt
-- Local values: self
function VideoElement.new(target, custom_mt)
	-- upvalues: (copy) VideoElement_mt
	local v4_ = VideoElement:superClass().new(target, custom_mt or VideoElement_mt)
	v4_.videoFilename = nil
	v4_.allowStop = true
	v4_.isLooping = false
	v4_.volume = 1
	v4_.duration = 0
	v4_.subtitles = {}
	v4_.subtitlesElement = nil
	v4_.subtitleElementId = nil
	v4_.currentSubtitleIndex = 0
	v4_.playbackBarElement = nil
	v4_.playbackBarElementId = nil
	v4_.timeLeftElement = nil
	v4_.timeLeftElementId = nil
	return v4_
end

function VideoElement:loadFromXML(xmlFile, key)
	VideoElement:superClass().loadFromXML(self, xmlFile, key)
	self.videoFilename = getXMLString(xmlFile, key .. "#videoFilename") or self.videoFilename
	self.volume = getXMLFloat(xmlFile, key .. "#volume") or self.volume
	self.allowStop = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowStop"), self.allowStop)
	self.isLooping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLooping"), self.isLooping)
	self.subtitleElementId = getXMLString(xmlFile, key .. "#subtitleElementId") or self.subtitleElementId
	self.playbackBarElementId = Utils.getNoNil(getXMLString(xmlFile, key .. "#playbackBarElementId"), self.playbackBarElementId)
	self.timeLeftElementId = Utils.getNoNil(getXMLString(xmlFile, key .. "#timeLeftElementId"), self.timeLeftElementId)
	self:addCallback(xmlFile, key .. "#onEndVideo", "onEndVideoCallback")
	self:changeVideo(self.videoFilename)
end

function VideoElement:loadProfile(profile, applyProfile)
	VideoElement:superClass().loadProfile(self, profile, applyProfile)
	self.videoFilename = profile:getValue("videoFilename", self.videoFilename)
	self.volume = profile:getNumber("volume", self.volume)
	self.allowStop = profile:getBool("allowStop", self.allowStop)
	self.isLooping = profile:getBool("isLooping", self.isLooping)
	self.subtitleElementId = profile:getValue("subtitleElementId", self.subtitleElementId)
	self.playbackBarElementId = profile:getValue("playbackBarElementId", self.playbackBarElementId)
	self.timeLeftElementId = profile:getValue("timeLeftElementId", self.timeLeftElementId)
end

function VideoElement:copyAttributes(src)
	VideoElement:superClass().copyAttributes(self, src)
	self:changeVideo(src.videoFilename)
	self.volume = src.volume
	self.allowStop = src.allowStop
	self.isLooping = src.isLooping
	self.onEndVideoCallback = src.onEndVideoCallback
	self.subtitles = src.subtitles
	self.subtitleElementId = src.subtitleElementId
	self.playbackBarElementId = src.playbackBarElementId
	self.timeLeftElementId = src.timeLeftElementId
end

-- Local values: subtitlesElement, playbackBarElement, timeLeftElement
function VideoElement:onGuiSetupFinished()
	VideoElement:superClass().onGuiSetupFinished(self)
	if self.subtitleElementId ~= nil then
		local v14_ = self.parent:getDescendantById(self.subtitleElementId)
		if v14_ == nil then
			Logging.warning("subtitleElementId \'%s\' not found for \'%s\'!", self.subtitleElementId, self.parent.name)
		else
			self.subtitlesElement = v14_
		end
	end
	if self.playbackBarElementId ~= nil then
		local v15_ = self.parent:getDescendantById(self.playbackBarElementId)
		if v15_ == nil then
			Logging.warning("playbackBarElementId \'%s\' not found for \'%s\'!", self.playbackBarElementId, self.parent.name)
		else
			self.playbackBarElement = v15_
		end
	end
	if self.timeLeftElementId ~= nil then
		local v16_ = self.parent:getDescendantById(self.timeLeftElementId)
		if v16_ ~= nil then
			self.timeLeftElement = v16_
			return
		end
		Logging.warning("timeLeftElementId \'%s\' not found for \'%s\'!", self.timeLeftElementId, self.parent.name)
	end
end

function VideoElement:delete()
	self:disposeVideo()
	VideoElement:superClass().delete(self)
end

-- Local values: cleanName, xmlFile
function VideoElement:loadSubtitles(filename)
	if filename ~= nil then
		local v20_ = Utils.getFilenameInfo(self.videoFilename)
		if v20_ ~= nil then
			local v_u_21_ = XMLFile.loadIfExists("Subtitles", v20_ .. ".xml")
			if v_u_21_ ~= nil then
				self.subtitles = {}
				v_u_21_:iterate("Subtitles.Subtitle", function(_, p22_)
					-- upvalues: (copy) v_u_21_, (copy) self
					local v23_ = {
						["startTime"] = v_u_21_:getFloat(p22_ .. "#startTime"),
						["endTime"] = v_u_21_:getFloat(p22_ .. "#endTime"),
						["text"] = g_i18n:convertText(v_u_21_:getString(p22_ .. "#text"))
					}
					if v23_.startTime ~= nil and (v23_.endTime ~= nil and v23_.text ~= nil) then
						local v24_ = self.subtitles
						table.insert(v24_, v23_)
					end
				end)
			end
		end
	end
end

-- Local values: ret
function VideoElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = VideoElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
		if not eventUsed and self.allowStop then
			local v32_ = true
			if isDown and self.overlay ~= nil then
				self:disposeVideo()
				self:onEndVideo()
			end
			return v32_
		end
	end
	return eventUsed
end

function VideoElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if not self:getIsActive() then
		return eventUsed
	end
	VideoElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
	if isDown and self.overlay ~= nil then
		self:disposeVideo()
		self:onEndVideo()
	end
	return true
end

-- Local values: videoCurrentTime, currentSubtitle, index, subtitle, currentTime, playbackTime, currentTime, timeLeft, timeLeftMinutes, timeLeftSeconds
function VideoElement:update(dt)
	VideoElement:superClass().update(self, dt)
	if self.overlay == nil then
		return
	end
	if not isVideoOverlayReadyToPlay(self.overlay) then
		return
	end
	if self.playPending then
		playVideoOverlay(self.overlay)
		self.playPending = false
	end
	if isVideoOverlayPlaying(self.overlay) then
		updateVideoOverlay(self.overlay)
		if self.subtitlesElement ~= nil then
			local v41_ = getVideoOverlayCurrentTime(self.overlay)
			local v42_ = self.subtitles[self.currentSubtitleIndex]
			if v41_ ~= nil and (v42_ ~= nil and v42_.endTime <= v41_) then
				self.subtitlesElement:setText("")
			end
			if v42_ == nil or v42_.endTime <= v41_ then
				for v43_ = self.currentSubtitleIndex + 1, #self.subtitles do
					local v44_ = self.subtitles[v43_]
					if v44_.startTime <= v41_ and v41_ <= v44_.endTime then
						self.subtitlesElement:setText(v44_.text)
						self.currentSubtitleIndex = v43_
						break
					end
				end
			end
		end
		if self.playbackBarElement ~= nil then
			local v45_ = (getVideoOverlayCurrentTime(self.overlay) or 1) / self.duration
			local v46_ = math.min(v45_, 1)
			self.playbackBarElement.absSize[1] = self.playbackBarElement.size[1] * v46_
		end
		if self.timeLeftElement ~= nil then
			local v47_ = getVideoOverlayCurrentTime(self.overlay) or 1
			local v48_ = self.duration - v47_
			local v49_ = math.max(0, v48_)
			local v50_ = v49_ / 60
			local v51_ = math.floor(v50_)
			local v52_ = v49_ % 60
			self.timeLeftElement:setText(string.format("-%02d:%02d", v51_, v52_))
			return
		end
	else
		self:disposeVideo()
		self:onEndVideo()
	end
end

-- Local values: textSize
function VideoElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self.overlay ~= nil then
		if isVideoOverlayReadyToPlay(self.overlay) then
			if isVideoOverlayPlaying(self.overlay) then
				renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
			end
		else
			setTextColor(1, 1, 1, 1)
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_CENTER)
			local v58_ = getCorrectTextSize(0.02)
			renderText(self.absPosition[1] + self.size[1] * 0.5, self.absPosition[2] + self.size[2] * 0.5, v58_, g_i18n:getText("ui_loading"))
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end
	VideoElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function VideoElement:onEndVideo()
	if self.onEndVideoCallback ~= nil then
		if self.target ~= nil then
			self.onEndVideoCallback(self.target)
			return
		end
		self.onEndVideoCallback()
	end
end

function VideoElement:disposeVideo()
	if self.overlay ~= nil then
		self:stopVideo()
		delete(self.overlay)
		self.overlay = nil
	end
	if self.subtitlesElement ~= nil then
		self.subtitlesElement:setText("")
	end
end

function VideoElement:getIsActive()
	return self:getIsVisible()
end

function VideoElement:playVideo()
	if self.overlay ~= nil then
		self.playPending = true
		self.currentSubtitleIndex = 0
	end
end

function VideoElement:stopVideo()
	self.playPending = false
	if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
		stopVideoOverlay(self.overlay)
	end
end

-- Local values: videoFilename
function VideoElement:changeVideo(newVideoFilename, volume, duration)
	self:disposeVideo()
	self.videoFilename = newVideoFilename
	if self.videoFilename ~= nil then
		local v68_ = string.gsub(self.videoFilename, "$l10nSuffix", g_languageSuffix)
		self.overlay = createVideoOverlay(v68_, self.isLooping, volume or self.volume)
		self.duration = duration
		self:loadSubtitles(v68_)
	end
end
