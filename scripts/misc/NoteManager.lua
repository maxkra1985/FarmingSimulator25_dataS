-- Local values: NoteManager_mt
NoteManager = {}
NoteManager.NOTES_DIRECTORY = getUserProfileAppPath() .. "notes/"
local NoteManager_mt = Class(NoteManager, AbstractManager)

-- Upvalues: NoteManager_mt
-- Local values: self
function NoteManager.new(customMt)
	-- upvalues: (copy) NoteManager_mt
	return AbstractManager.new(customMt or NoteManager_mt)
end

-- Local values: colorWhite, _, color
function NoteManager:initDataStructures()
	self.sessionDirectory = nil
	self.sessionTimestamp = nil
	self.mapTitle = nil
	self.currentNoteIndex = 1
	local v4_ = {
		1,
		1,
		1,
		1
	}
	self.colors = {}
	local v5_ = self.colors
	table.insert(v5_, {
		["color"] = v4_
	})
	for _, v6_ in ipairs(DebugUtil.COLORS) do
		local v7_ = self.colors
		local v8_ = {
			["color"] = {
				v6_[1],
				v6_[2],
				v6_[3],
				1
			}
		}
		table.insert(v7_, v8_)
	end
	self.lastColor = v4_
	if not self.initialized then
		addConsoleCommand("gsNoteExport", "Exports currently created note nodes as i3d file", "consoleCommandExportNotes", self)
		addConsoleCommand("gsNoteList", "Lists currently created note nodes in console/log", "consoleCommandListNotes", self)
		self.initialized = true
	end
end

-- Local values: _, eventId
function NoteManager:registerInputActionEvent()
	if g_currentMission ~= nil then
		local _, v10_ = g_inputBinding:registerActionEvent(InputAction.ADD_NOTE, self, self.onAddNote, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v10_, false)
	end
end

function NoteManager:unloadMapData()
	self:exportNotes()
	self:resetNotes()
end

function NoteManager:resetNotes()
	if self.notesRoot ~= nil and entityExists(self.notesRoot) then
		delete(self.notesRoot)
	end
	self.notesRoot = nil
	self.sessionDirectory = nil
	self.currentNoteIndex = 1
end

function NoteManager:loadNotes() end

-- Local values: filename
function NoteManager:onAddNote()
	if self.sessionDirectory == nil then
		createFolder(NoteManager.NOTES_DIRECTORY)
		self.mapTitle = string.gsub(g_currentMission.missionInfo.mapTitle, " ", "")
		self.sessionTimestamp = getDate("%Y_%m_%d__%H_%M")
		self.sessionDirectory = NoteManager.NOTES_DIRECTORY .. self.sessionTimestamp .. "_" .. self.mapTitle .. "/"
		createFolder(self.sessionDirectory)
	end
	local v14_ = string.format("note_%d.jpg", self.currentNoteIndex)
	self.lastNoteScreenshotFilepath = self.sessionDirectory .. v14_
	saveScreenshot(self.lastNoteScreenshotFilepath)
	TextInputDialog.show(self.onNoteTextEntered, self, nil, "Enter note text", false, nil, "Add Note", 200, nil, false)
end

function NoteManager:onNoteTextEntered(text, ok)
	if ok then
		local v18_ = string.trim(text)
		if v18_ ~= "" then
			ColorPickerDialog.show(self.onNotePickColor, self, {
				["text"] = v18_,
				["colors"] = self.colors
			}, self.colors, nil, nil, self.lastColor, true)
			return
		end
	end
	self:cancelCurrentNote()
end

-- Local values: color, note
function NoteManager:onNotePickColor(colorIndex, args, customColor)
	if colorIndex == nil then
		self:cancelCurrentNote()
	else
		if self.notesRoot == nil then
			self.notesRoot = createTransformGroup("noteNodes")
			link(getRootNode(), self.notesRoot)
		end
		local v22_ = args.colors[colorIndex].color
		self.lastColor = v22_
		local v23_ = createNoteNode(self.notesRoot, string.format("[%d] %s", self.currentNoteIndex, args.text), v22_[1], v22_[2], v22_[3], false)
		setName(v23_, string.format("note_%d", self.currentNoteIndex))
		if g_isDevelopmentVersion and self.currentNoteIndex == 1 then
			executeConsoleCommand("enableNoteRendering true", true)
		end
		self.currentNoteIndex = self.currentNoteIndex + 1
		Logging.info("created note \'%s\' at %.1f %.1f %.1f", getNoteNodeText(v23_), getWorldTranslation(v23_))
		self.lastNoteScreenshotFilepath = nil
	end
end

function NoteManager:cancelCurrentNote()
	if self.lastNoteScreenshotFilepath ~= nil and fileExists(self.lastNoteScreenshotFilepath) then
		deleteFile(self.lastNoteScreenshotFilepath)
	end
end

-- Local values: filename, filepath, numNotes
function NoteManager:exportNotes()
	if self.notesRoot == nil then
		return 0
	end
	local v26_ = string.format("notes_%s_%s.i3d", self.sessionTimestamp, self.mapTitle)
	local v27_ = self.sessionDirectory .. v26_
	Logging.info("Exporting notes to %s", v27_)
	exportNoteNodes(v27_)
	return getNumOfChildren(self.notesRoot)
end

function NoteManager:consoleCommandExportNotes()
	return self.notesRoot == nil and "Error: No notes to export, add notes first" or string.format("Exported %d notes", self:exportNotes())
end

-- Local values: numNotes, i, noteNode, wx, wy, wz
function NoteManager:consoleCommandListNotes()
	if self.notesRoot == nil then
		return "No existing notes"
	end
	local v30_ = getNumOfChildren(self.notesRoot)
	for v31_ = 0, v30_ - 1 do
		local v32_ = getChildAt(self.notesRoot, v31_)
		local v33_, v34_, v35_ = getWorldTranslation(v32_)
		print(string.format("%s [Pos: %.1f %1.f %1.f]", getNoteNodeText(v32_), v33_, v34_, v35_))
	end
	return string.format("Listed %d notes", v30_)
end
g_noteManager = NoteManager.new()
