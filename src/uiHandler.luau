local React = require(script.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Packages.ReactRoblox)
local StudioComponents = require(script.Parent.Packages.StudioComponents)
local storageHandler = require(script.Parent.storageHandler)
local util = require(script.Parent.util)
local e = React.createElement
local module = {}

local function getIcon()
	return if settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground).R < 0.5
		then "rbxassetid://121239006179116"
		else "rbxassetid://70875562655977",
		"Settings"
end

local function HeaderText(props: {
	Text: string,
})
	return e(StudioComponents.Label, {
		Text = `<b>{props.Text}</b>`,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		TextColorStyle = Enum.StudioStyleGuideColor.BrightText,
	})
end

local function Checkbox(props: {
	Label: string,
	InitialValue: boolean,
	SetValue: (value: boolean) -> (),
})
	local state, setState = React.useState(props.InitialValue)

	return e(StudioComponents.Checkbox, {
		Label = props.Label,
		Value = state,
		OnChanged = function()
			local newValue = not state
			setState(newValue)
			props.SetValue(newValue)
		end,
	})
end

local function VerticalSpace(props: { Height: number })
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, props.Height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
end

local function MainUI(props: {
	initialProject: string,
	setProject: (value: string) -> (),

	initialApiKey: string,
	setApiKey: (value: string) -> (),

	initialApiUrl: string,
	setApiUrl: (value: string) -> (),

	initialShouldLogPlayTime: boolean,
	setShouldLogPlayTime: (value: boolean) -> (),

	initialShouldLogEditTime: boolean,
	setShouldLogEditTime: (value: boolean) -> (),

	initialShouldLogCodingTime: boolean,
	setShouldLogCodingTime: (value: boolean) -> (),
})
	local projectText, setProjectText = React.useState(props.initialProject)
	local keyText, setKeyText = React.useState(props.initialApiKey)
	local urlText, setUrlText = React.useState(props.initialApiUrl)

	return e(StudioComponents.ScrollFrame, {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}, {
		e(HeaderText, {
			Text = "Experience settings",
		}),

		e(StudioComponents.Label, {
			Text = "Project name",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 30),
		}),
		e(StudioComponents.TextInput, {
			Text = projectText,
			OnChanged = function(newText)
				setProjectText(newText)
				props.setProject(newText)
			end,
			ClearTextOnFocus = false,
			PlaceholderText = "Get it at wakatime.com/api-key",
		}),

		VerticalSpace({
			Height = 15,
		}),
		e(HeaderText, {
			Text = "Global settings",
		}),

		e(StudioComponents.Label, {
			Text = "WakaTime API URL",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 30),
			RichText = true,
		}),
		e(StudioComponents.TextInput, {
			Text = urlText,
			OnChanged = function(newText)
				setUrlText(newText)
				props.setApiUrl(newText)
			end,
			ClearTextOnFocus = false,
			PlaceholderText = "https://api.wakatime.com/api/v1"
		}),

		-- VerticalSpace({ Height = 10 }),

		e(StudioComponents.Label, {
			Text = `WakaTime API key{if #keyText > 0
				then ""
				else " <b>(Please paste your API key here)</b>"}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 30),
			RichText = true,
		}),
		e(StudioComponents.TextInput, {
			Text = keyText,
			OnChanged = function(newText)
				setKeyText(newText)
				props.setApiKey(newText)
			end,
			ClearTextOnFocus = false,
			PlaceholderText = "Get it from wakatime.com or use your key from alternative source",
		}),

		VerticalSpace({ Height = 10 }),

		e(Checkbox, {
			Label = "Log time in the editor",
			InitialValue = props.initialShouldLogEditTime,
			SetValue = props.setShouldLogEditTime,
		}),

		e(Checkbox, {
			Label = "Log time in playtesting",
			InitialValue = props.initialShouldLogPlayTime,
			SetValue = props.setShouldLogPlayTime,
		}),

		e(Checkbox, {
			Label = "Log time in the script editor",
			InitialValue = props.initialShouldLogCodingTime,
			SetValue = props.setShouldLogCodingTime,
		}),
	})
end

function module.init(plugin: Plugin)
	local settingsWidget = plugin:CreateDockWidgetPluginGui(
		"wakatime_widget",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 200, 300, 50, 50)
	)
	settingsWidget.Title = "WakaTime"

	local toolbar = plugin:CreateToolbar("WakaTime")
	local settingsButton =
		toolbar:CreateButton("wakatime_main", "Open the Roblox Studio WakaTime configuration.", getIcon())
	settings().Studio.ThemeChanged:Connect(function()
		settingsButton.Icon = getIcon()
	end)
	settingsButton.Click:Connect(function()
		settingsWidget.Enabled = not settingsWidget.Enabled
	end)
	settingsButton:SetActive(settingsWidget.Enabled)
	settingsWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
		settingsButton:SetActive(settingsWidget.Enabled)
	end)

	local root = ReactRoblox.createRoot(settingsWidget)
	root:render(e(MainUI, {
		initialProject = storageHandler.getProjectName(plugin),
		setProject = function(value)
			storageHandler.setProjectName(plugin, value)
		end,

		initialApiKey = storageHandler.getWakaTimeKey(plugin) or "",
		setApiKey = function(value)
			storageHandler.setWakaTimeKey(plugin, value)
		end,

		initialApiUrl = storageHandler.getWakaTimeUrl(plugin) or "https://api.wakatime.com/api/v1",
		setApiUrl = function(value)
			storageHandler.setWakaTimeUrl(plugin, value)
		end,

		initialShouldLogPlayTime = storageHandler.getShouldLogPlayTime(plugin),
		setShouldLogPlayTime = function(value)
			storageHandler.setShouldLogPlayTime(plugin, value)
		end,

		initialShouldLogEditTime = storageHandler.getShouldLogEditTime(plugin),
		setShouldLogEditTime = function(value)
			storageHandler.setShouldLogEditTime(plugin, value)
		end,

		initialShouldLogCodingTime = storageHandler.getShouldLogCodingTime(plugin),
		setShouldLogCodingTime = function(value)
			storageHandler.setShouldLogCodingTime(plugin, value)
		end,
	}))
end

return module
