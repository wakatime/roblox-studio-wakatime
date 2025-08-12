local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local StudioService = game:GetService("StudioService")
local storageHandler = require(script.Parent.storageHandler)
local util = require(script.Parent.util)
local module = {}

local ACTIVITY_PLAYTEST: "Playtesting" = "Playtesting"
local ACTIVITY_EDITING: "Editing" = "Editing"

-- If we send a heartbeat right as Studio loads up, things like the place name aren't loaded fully.
local lastSentTime = DateTime.now().UnixTimestamp - 100
type StudioActivity = typeof(ACTIVITY_PLAYTEST) | typeof(ACTIVITY_EDITING) | ScriptDocument
local lastSentActivity: StudioActivity = ACTIVITY_EDITING

local function enoughTimeHasPassed()
	local now = DateTime.now().UnixTimestamp
	local diff = now - lastSentTime
	return diff >= 120
end

local function getCurrentActivity(): StudioActivity
	local document = if StudioService.ActiveScript
		then ScriptEditorService:FindScriptDocument(StudioService.ActiveScript)
		else nil
	if document then
		return document
	elseif RunService:IsRunning() then
		return ACTIVITY_PLAYTEST
	else
		return ACTIVITY_EDITING
	end
end

-- Note: we're not calling it file, because we're logging playtesting and editing as well
local function currentlyFocusedActivityHasChanged(current: StudioActivity)
	return current ~= lastSentActivity
end

local function sendHeartbeat(plugin: Plugin, activity: StudioActivity)
	local apiKey = storageHandler.getWakaTimeKey(plugin)
	local apiUrl = storageHandler.getWakaTimeUrl(plugin)
	if not apiKey or not apiUrl then
		return
	end
	apiKey = util.encode(apiKey)

	local now = DateTime.now().UnixTimestamp
	local bodyToSend = {
		time = now,
		branch = `{game.PlaceId}`,
		plugin = `Roblox Studio/{settings().Diagnostics.RobloxVersion} roblox-studio-wakatime/1.0.0`,
	}
	local projectName = storageHandler.getProjectName(plugin)
	if projectName and #projectName > 0 then
		bodyToSend.project = projectName
	end

	if activity == ACTIVITY_PLAYTEST then
		if not storageHandler.getShouldLogPlayTime(plugin) then
			return
		end
		bodyToSend.entity = "Roblox Studio"
		bodyToSend.type = "app"
		bodyToSend.category = "manual testing"
	elseif activity == ACTIVITY_EDITING then
		if not storageHandler.getShouldLogEditTime(plugin) then
			return
		end
		bodyToSend.entity = "Roblox Studio"
		bodyToSend.type = "app"
		bodyToSend.category = "building"
	else
		if not storageHandler.getShouldLogCodingTime(plugin) then
			return
		end
		local associatedScript = activity:GetScript()
		bodyToSend.entity = if associatedScript then util.instanceToPath(associatedScript) else activity.Name
		bodyToSend.type = "file"
		bodyToSend.category = "coding"
		bodyToSend.language = "Luau"
		bodyToSend.lines = activity:GetLineCount()
		local startLine, startCharacter = activity:GetSelectionStart()
		bodyToSend.lineno = startLine
		bodyToSend.cursorpos = startCharacter
	end

	lastSentTime = now
	lastSentActivity = activity

	local ok, response = pcall(HttpService.RequestAsync, HttpService, {
		Url = apiUrl .. "/users/current/heartbeats",
		Method = "POST",
		Body = HttpService:JSONEncode(bodyToSend),
		Headers = {
			["Authorization"] = `Basic {apiKey}`,
			["Content-Type"] = "application/json",
		},
	})
	if ok then
		-- print("Sent WakaTime heartbeat", bodyToSend, response.Body)
	else
		warn("Failed to call WakaTime API.", response.Body)
	end
end

function module.onActivityCallback(plugin: Plugin, force: boolean?)
	local currentActivity = getCurrentActivity()
	if not ((force == true) or enoughTimeHasPassed() or currentlyFocusedActivityHasChanged(currentActivity)) then
		return
	end

	sendHeartbeat(plugin, currentActivity)
end

return module
