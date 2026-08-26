-- File: hub.lua
-- Caelus Neko Hub recovery build.
-- Runs the known-good 3.32.7 runtime unchanged, then installs two safe UI fixes:
--   1) saved Custom Nekos appear in Pendalar -> Nekos;
--   2) Pendalar tab scrolling uses actual content height.
--
-- This file intentionally does NOT source-patch the 6,204-line runtime before
-- launch, so an optional UI fix cannot prevent the hub from opening.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local environment = (type(getgenv) == "function" and getgenv()) or _G
local RunService = game:GetService("RunService")

local BASE_HUB_URL =
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/3791149/hub.lua"

local function executorFunction(name)
	local value = rawget(environment, name)
	if type(value) == "function" then
		return value
	end

	value = rawget(_G, name)
	if type(value) == "function" then
		return value
	end

	return nil
end

local function requestFunction()
	for _, name in ipairs({"request", "http_request", "httprequest"}) do
		local candidate = executorFunction(name)
		if candidate then
			return candidate
		end
	end

	local syn = rawget(environment, "syn")
	if type(syn) == "table" and type(syn.request) == "function" then
		return syn.request
	end

	local http = rawget(environment, "http")
	if type(http) == "table" and type(http.request) == "function" then
		return http.request
	end

	return nil
end

local function fetch(url)
	local request = requestFunction()
	local lastProblem = "request failed"

	for attempt = 1, 3 do
		if request then
			local ok, response = pcall(request, {
				Url = url,
				Method = "GET",
				Headers = {
					["Cache-Control"] = "no-cache",
				},
			})

			if ok and type(response) == "table" then
				local body = response.Body or response.body
				local status = tonumber(
					response.StatusCode
						or response.Status
						or response.status
				)

				if type(body) == "string"
					and #body > 1000
					and (not status or status < 400)
				then
					return body
				end

				lastProblem =
					"HTTP "
					.. tostring(status or "?")
					.. " / empty body"
			else
				lastProblem = tostring(response)
			end
		end

		local ok, body = pcall(function()
			return game:HttpGet(
				url
					.. "?recovery="
					.. tostring(os.time())
					.. "-"
					.. tostring(attempt)
			)
		end)

		if ok and type(body) == "string" and #body > 1000 then
			return body
		end

		lastProblem = tostring(body or lastProblem)

		if attempt < 3 then
			task.wait(0.4 * attempt)
		end
	end

	error(
		"[Caelus Neko Recovery] Could not download the known-good hub: "
			.. tostring(lastProblem),
		0
	)
end

local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy

	for key, item in pairs(value) do
		copy[deepCopy(key, seen)] = deepCopy(item, seen)
	end

	return copy
end

local function runBaseHub()
	local source = fetch(BASE_HUB_URL)

	if type(loadstring) ~= "function" then
		error("[Caelus Neko Recovery] loadstring() is unavailable.", 0)
	end

	local chunk, compileProblem =
		loadstring(source, "=CaelusNekoKnownGoodBase")

	if not chunk then
		error(
			"[Caelus Neko Recovery] Known-good base compile failed: "
				.. tostring(compileProblem),
			0
		)
	end

	local ok, runtimeProblem = pcall(chunk)
	if not ok then
		error(
			"[Caelus Neko Recovery] Known-good base runtime failed: "
				.. tostring(runtimeProblem),
			0
		)
	end
end

runBaseHub()

local ui = environment.CaelusPendalarNekoUI
local api = environment.CaelusNekoAPI
local state = api and api.Session

if type(ui) ~= "table"
	or type(api) ~= "table"
	or type(state) ~= "table"
	or not ui.GuiRoot
then
	warn(
		"[Caelus Neko Recovery] Base hub opened, but Pendalar was unavailable. "
			.. "The base hub is still running."
	)
	return
end

local main =
	ui.GuiRoot:FindFirstChild("Main")
	or ui.GuiRoot:FindFirstChild("Main", true)

if not main then
	warn(
		"[Caelus Neko Recovery] Pendalar Main was not found. "
			.. "The base hub is still running."
	)
	return
end

local runtime = {
	destroyed = false,
	connections = {},
	scrollConnections = {},
	savedSignature = nil,
}

local previous = environment.CaelusNekoPendalarRecovery
if type(previous) == "table" and type(previous.Destroy) == "function" then
	pcall(function()
		previous:Destroy()
	end)
end
environment.CaelusNekoPendalarRecovery = runtime

local function remember(connection)
	if connection then
		table.insert(runtime.connections, connection)
	end
	return connection
end

local function disconnectScroll(scrollingFrame)
	local connections = runtime.scrollConnections[scrollingFrame]
	if not connections then
		return
	end

	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	runtime.scrollConnections[scrollingFrame] = nil
end

local function tabScroll(tabName)
	local tab = main:FindFirstChild(tabName)
	if not tab then
		return nil
	end

	return tab:FindFirstChildOfClass("ScrollingFrame")
end

local function bindScroll(scrollingFrame)
	if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
		return
	end

	disconnectScroll(scrollingFrame)

	local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
	if not layout then
		return
	end

	scrollingFrame.Active = true
	scrollingFrame.ScrollingEnabled = true
	scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
	scrollingFrame.ScrollBarThickness = math.max(scrollingFrame.ScrollBarThickness, 5)

	local queued = false

	local function update()
		if queued then
			return
		end

		queued = true
		task.defer(function()
			queued = false

			if runtime.destroyed
				or not scrollingFrame.Parent
				or not layout.Parent
			then
				return
			end

			local viewport = math.ceil(scrollingFrame.AbsoluteSize.Y)
			local content = math.ceil(layout.AbsoluteContentSize.Y) + 64
			local height = math.max(content, viewport + 1)

			scrollingFrame.CanvasSize = UDim2.fromOffset(0, height)

			local maxY = math.max(0, height - viewport)
			if scrollingFrame.CanvasPosition.Y > maxY then
				scrollingFrame.CanvasPosition = Vector2.new(
					scrollingFrame.CanvasPosition.X,
					maxY
				)
			end
		end)
	end

	runtime.scrollConnections[scrollingFrame] = {
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update),
		scrollingFrame.ChildAdded:Connect(update),
		scrollingFrame.ChildRemoved:Connect(update),
		scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update),
	}

	update()
end

local function bindAllScrolls()
	for _, tabName in ipairs({
		"Nekos",
		"Settings",
		"Neko Editor",
		"Scripts",
		"Credits",
	}) do
		bindScroll(tabScroll(tabName))
	end
end

local function sortedSavedPresets()
	local presets = {}

	for _, preset in pairs(state.savedPresets or {}) do
		if type(preset) == "table"
			and type(preset.name) == "string"
			and preset.name ~= ""
		then
			table.insert(presets, preset)
		end
	end

	table.sort(presets, function(left, right)
		return string.lower(left.name) < string.lower(right.name)
	end)

	return presets
end

local function signatureForSavedPresets()
	local parts = {}

	for _, preset in ipairs(sortedSavedPresets()) do
		local assetCount =
			type(preset.assetIds) == "table" and #preset.assetIds or 0

		table.insert(
			parts,
			table.concat({
				tostring(preset.name),
				tostring(preset.version or ""),
				tostring(assetCount),
				tostring(preset.use3DPants ~= false),
			}, "|")
		)
	end

	return table.concat(parts, "\n")
end

local function clearSavedButtons(scrollingFrame)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:GetAttribute("CaelusRecoverySavedNeko") == true then
			child:Destroy()
		end
	end
end

local function makeCorner(parent)
	local corner = Instance.new("UICorner")
	corner.Name = "butcorner"
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = parent
end

local function makeSavedButton(scrollingFrame, preset, order)
	local presetName = tostring(preset.name)
	local versionName = tostring(preset.version or "V4")

	local button = Instance.new("TextButton")
	button.Name = "★ " .. presetName
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(385, 39)
	button.BackgroundColor3 = Color3.fromRGB(194, 73, 115)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.Roboto
	button.Text = "★ " .. presetName
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 17
	button:SetAttribute("CaelusRecoverySavedNeko", true)
	button.Parent = scrollingFrame
	makeCorner(button)

	local infoButton = Instance.new("ImageButton")
	infoButton.Name = "infobutton"
	infoButton.BackgroundTransparency = 1
	infoButton.Position = UDim2.new(0, 11, 0.5, -10)
	infoButton.Size = UDim2.fromOffset(20, 20)
	infoButton.Image = "http://www.roblox.com/asset/?id=6294110112"
	infoButton.Parent = button

	local showingInfo = false

	infoButton.MouseButton1Click:Connect(function()
		showingInfo = not showingInfo

		if showingInfo then
			button.Text = "Saved Custom Neko • " .. versionName
			button.TextSize = 13
		else
			button.Text = "★ " .. presetName
			button.TextSize = 17
		end
	end)

	button.MouseButton1Click:Connect(function()
		if showingInfo then
			return
		end

		local selectedPreset =
			state.savedPresets and state.savedPresets[presetName]

		if type(selectedPreset) ~= "table" then
			warn(
				"[Pendalar Hub] Saved Custom Neko not found: "
					.. presetName
			)
			return
		end

		state.customNeko = deepCopy(selectedPreset)
		state.selectedMorph = "Custom Neko"
		state.selectedVersion =
			selectedPreset.version
			or state.selectedVersion
			or "V4"

		if ui.VersionLabel then
			ui.VersionLabel.Text =
				"Selected Neko Version : "
				.. tostring(state.selectedVersion)
		end

		local applied, problem = api:ApplySelectedCustom()
		if not applied then
			warn("[Pendalar Hub] " .. tostring(problem))
		end
	end)
end

local function refreshSavedNekos(force)
	local scrollingFrame = tabScroll("Nekos")
	if not scrollingFrame then
		return
	end

	local signature = signatureForSavedPresets()

	if not force and signature == runtime.savedSignature then
		return
	end

	runtime.savedSignature = signature
	clearSavedButtons(scrollingFrame)

	for index, preset in ipairs(sortedSavedPresets()) do
		makeSavedButton(scrollingFrame, preset, 10000 + index)
	end

	bindScroll(scrollingFrame)
end

local originalSaveCustom = api.SaveCustom

if type(originalSaveCustom) == "function" then
	api.SaveCustom = function(self, ...)
		local results = table.pack(originalSaveCustom(self, ...))

		task.defer(function()
			if not runtime.destroyed then
				refreshSavedNekos(true)
				bindAllScrolls()
			end
		end)

		return table.unpack(results, 1, results.n)
	end
end

function runtime:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true

	if api
		and type(originalSaveCustom) == "function"
		and api.SaveCustom ~= originalSaveCustom
	then
		api.SaveCustom = originalSaveCustom
	end

	for _, connection in ipairs(self.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(self.connections)

	for scrollingFrame in pairs(self.scrollConnections) do
		disconnectScroll(scrollingFrame)
	end

	local nekoScroll = tabScroll("Nekos")
	if nekoScroll then
		clearSavedButtons(nekoScroll)
	end
end

bindAllScrolls()
refreshSavedNekos(true)

remember(RunService.Heartbeat:Connect(function()
	if runtime.destroyed then
		return
	end

	if state.destroyed
		or environment.CaelusNekoAPI ~= api
		or environment.CaelusPendalarNekoUI ~= ui
		or not ui.GuiRoot
		or not ui.GuiRoot.Parent
	then
		runtime:Destroy()
	end
end))

task.spawn(function()
	while not runtime.destroyed do
		refreshSavedNekos(false)

		for _, tabName in ipairs({
			"Nekos",
			"Settings",
			"Neko Editor",
			"Scripts",
			"Credits",
		}) do
			local scrollingFrame = tabScroll(tabName)
			local layout =
				scrollingFrame
				and scrollingFrame:FindFirstChildOfClass("UIListLayout")

			if scrollingFrame and layout then
				local wanted =
					math.max(
						math.ceil(layout.AbsoluteContentSize.Y) + 64,
						math.ceil(scrollingFrame.AbsoluteSize.Y) + 1
					)

				if scrollingFrame.CanvasSize.Y.Scale ~= 0
					or math.abs(scrollingFrame.CanvasSize.Y.Offset - wanted) > 2
				then
					scrollingFrame.CanvasSize = UDim2.fromOffset(0, wanted)
				end
			end
		end

		task.wait(0.8)
	end
end)

print(
	"[Caelus Neko Recovery] Base hub launched; "
		.. "saved Custom Neko and Pendalar scrolling fixes are active."
)
