local util = require(script.Parent.util)
local module = {}

local projectSettingKey = `WakaTimeProject_{game.GameId}`
function module.setProjectName(plugin: Plugin, value: string)
	value = util.trimString(value)
	-- Setting the project name to "" is a valid state, used for marking that it should be purposefully not sent.
	plugin:SetSetting(projectSettingKey, value)
end

function module.getSavedProjectName(plugin: Plugin)
	return plugin:GetSetting(projectSettingKey)
end

function module.getProjectName(plugin: Plugin): string?
	local existingName = module.getSavedProjectName(plugin)
	if existingName then
		return existingName
	end

	if game.Name == "Server" or game.Name == "Game" then
		if game.GameId == 0 then
			return nil
		end
		return `{game.GameId}`
	end

	return game.Name
end

function module.getWakaTimeKey(plugin: Plugin)
	return plugin:GetSetting("WakaTimeKey") :: string?
end

function module.setWakaTimeKey(plugin: Plugin, value: string)
	plugin:SetSetting("WakaTimeKey", value)
end

function module.getWakaTimeUrl(plugin: Plugin)
	local value = plugin:GetSetting("WakaTimeUrl") :: string?
	return if value == nil or value == "" then "https://api.wakatime.com/api/v1" else value
end

function module.setWakaTimeUrl(plugin: Plugin, value: string)
	plugin:SetSetting("WakaTimeUrl", value)
end

function module.getShouldLogPlayTime(plugin: Plugin)
	local value = plugin:GetSetting("WakaTimeShouldLogPlayTime")
	return if value == nil then true else value
end

function module.setShouldLogPlayTime(plugin: Plugin, value: boolean)
	plugin:SetSetting("WakaTimeShouldLogPlayTime", value)
end

function module.getShouldLogEditTime(plugin: Plugin)
	local value = plugin:GetSetting("WakaTimeShouldLogEditTime")
	return if value == nil then true else value
end

function module.setShouldLogEditTime(plugin: Plugin, value: boolean)
	plugin:SetSetting("WakaTimeShouldLogEditTime", value)
end

function module.getShouldLogCodingTime(plugin: Plugin)
	local value = plugin:GetSetting("WakaTimeShouldLogCodingTime")
	return if value == nil then true else value
end

function module.setShouldLogCodingTime(plugin: Plugin, value: boolean)
	plugin:SetSetting("WakaTimeShouldLogCodingTime", value)
end

return module
