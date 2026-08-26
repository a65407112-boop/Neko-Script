-- File: make_full_hub.lua
-- Generates a full standalone hub.lua from the known-good 6,204-line base.
-- Run this ONCE in your executor, then upload the generated hub.lua to GitHub.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local environment = (type(getgenv) == "function" and getgenv()) or _G

local BASE_URL =
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/3791149/hub.lua"

local OUTPUT_FOLDER = "CaelusNekoHub_Full"
local OUTPUT_PATH = OUTPUT_FOLDER .. "/hub.lua"

local function executorFunction(name)
	local value = rawget(environment, name)
	if type(value) == "function" then
		return value
	end

	value = rawget(_G, name)
	if type(value) == "function" then
		return value
	end

	if type(getfenv) == "function" then
		local ok, currentEnvironment = pcall(getfenv, 0)
		if ok and type(currentEnvironment) == "table" then
			value = rawget(currentEnvironment, name)
			if type(value) == "function" then
				return value
			end
		end
	end

	return nil
end

local request = executorFunction("request")
	or executorFunction("http_request")
	or executorFunction("httprequest")

local syn = rawget(environment, "syn")
if not request and type(syn) == "table" and type(syn.request) == "function" then
	request = syn.request
end

local http = rawget(environment, "http")
if not request and type(http) == "table" and type(http.request) == "function" then
	request = http.request
end

local writefile = executorFunction("writefile")
local makefolder = executorFunction("makefolder")
local isfolder = executorFunction("isfolder")
local setclipboard = executorFunction("setclipboard")
	or executorFunction("toclipboard")

if type(writefile) ~= "function" then
	error(
		"[Full Hub Builder] Your executor has no writefile(). "
			.. "The full file cannot be saved.",
		0
	)
end

local function fetch(url)
	local lastProblem = "download failed"

	for attempt = 1, 4 do
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
					and #body > 100000
					and (not status or status < 400)
				then
					return body
				end

				lastProblem =
					"HTTP "
					.. tostring(status or "?")
					.. " / response was too small"
			else
				lastProblem = tostring(response)
			end
		end

		local ok, body = pcall(function()
			return game:HttpGet(
				url
					.. "?fullHubBuilder="
					.. tostring(os.time())
					.. "-"
					.. tostring(attempt)
			)
		end)

		if ok and type(body) == "string" and #body > 100000 then
			return body
		end

		lastProblem = tostring(body or lastProblem)

		if attempt < 4 then
			task.wait(0.5 * attempt)
		end
	end

	error(
		"[Full Hub Builder] Could not download the known-good hub: "
			.. tostring(lastProblem),
		0
	)
end

local ADDON = [====[

-- ================================================================
-- Caelus Neko standalone additions
-- Saved Custom Nekos + Pendalar scrolling + animation toggles
-- ================================================================

do
	local ui = environment.CaelusPendalarNekoUI
	local api = environment.CaelusNekoAPI

	if type(ui) ~= "table"
		or type(api) ~= "table"
		or api.Session ~= state
		or not ui.GuiRoot
	then
		warn(
			"[Caelus Neko] Optional Pendalar additions were skipped "
				.. "because the Pendalar UI was unavailable."
		)
	else
		local pendalarMain =
			ui.GuiRoot:FindFirstChild("Main")
			or ui.GuiRoot:FindFirstChild("Main", true)

		if not pendalarMain then
			warn(
				"[Caelus Neko] Optional Pendalar additions could not "
					.. "find the Main frame."
			)
		else
			local addon = {
				destroyed = false,
				scrollConnections = {},
				savedSignature = nil,
				savedButtons = {},
				animationButtons = {},
				attackHeld = false,
				punchUntil = 0,
				specialUntil = 0,
				heldActionKeys = {},
			}

			state.pendalarStandaloneAddon = addon

			local preferences =
				environment.CaelusNekoAnimationPreferences

			if type(preferences) ~= "table" then
				preferences = {
					idle = true,
					walking = true,
					punching = true,
				}
				environment.CaelusNekoAnimationPreferences =
					preferences
			end

			addon.settings = {
				idle = preferences.idle ~= false,
				walking = preferences.walking ~= false,
				punching = preferences.punching ~= false,
			}

			local function getTabScroll(tabName)
				local tab = pendalarMain:FindFirstChild(tabName)
				if not tab then
					return nil
				end

				return tab:FindFirstChildOfClass("ScrollingFrame")
			end

			local function disconnectScroll(scrollingFrame)
				local connections =
					addon.scrollConnections[scrollingFrame]

				if not connections then
					return
				end

				for _, connection in ipairs(connections) do
					pcall(function()
						connection:Disconnect()
					end)
				end

				addon.scrollConnections[scrollingFrame] = nil
			end

			local function bindScroll(scrollingFrame)
				if not scrollingFrame
					or not scrollingFrame:IsA("ScrollingFrame")
				then
					return
				end

				disconnectScroll(scrollingFrame)

				local layout =
					scrollingFrame:FindFirstChildOfClass("UIListLayout")

				if not layout then
					return
				end

				scrollingFrame.Active = true
				scrollingFrame.ScrollingEnabled = true
				scrollingFrame.ScrollingDirection =
					Enum.ScrollingDirection.Y
				scrollingFrame.AutomaticCanvasSize =
					Enum.AutomaticSize.None
				scrollingFrame.ScrollBarThickness =
					math.max(scrollingFrame.ScrollBarThickness, 5)

				local queued = false

				local function update()
					if queued or addon.destroyed then
						return
					end

					queued = true

					task.defer(function()
						queued = false

						if addon.destroyed
							or not scrollingFrame.Parent
							or not layout.Parent
						then
							return
						end

						local viewport =
							math.ceil(scrollingFrame.AbsoluteSize.Y)

						local content =
							math.ceil(layout.AbsoluteContentSize.Y) + 72

						local height =
							math.max(content, viewport + 1)

						scrollingFrame.CanvasSize =
							UDim2.fromOffset(0, height)

						local maxY =
							math.max(0, height - viewport)

						if scrollingFrame.CanvasPosition.Y > maxY then
							scrollingFrame.CanvasPosition =
								Vector2.new(
									scrollingFrame.CanvasPosition.X,
									maxY
								)
						end
					end)
				end

				addon.scrollConnections[scrollingFrame] = {
					layout:GetPropertyChangedSignal(
						"AbsoluteContentSize"
					):Connect(update),
					scrollingFrame.ChildAdded:Connect(update),
					scrollingFrame.ChildRemoved:Connect(update),
					scrollingFrame:GetPropertyChangedSignal(
						"AbsoluteSize"
					):Connect(update),
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
					bindScroll(getTabScroll(tabName))
				end
			end

			local function clearSavedButtons()
				for _, button in ipairs(addon.savedButtons) do
					if button and button.Parent then
						button:Destroy()
					end
				end

				table.clear(addon.savedButtons)
			end

			local function savedSignature()
				local parts = {}

				for _, preset in ipairs(orderedSavedPresets()) do
					table.insert(
						parts,
						table.concat({
							tostring(preset.name),
							tostring(preset.version or ""),
							tostring(#(preset.assetIds or {})),
							tostring(preset.use3DPants ~= false),
						}, "|")
					)
				end

				return table.concat(parts, "\n")
			end

			local function addCorner(parent, radius)
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, radius or 5)
				corner.Parent = parent
				return corner
			end

			local function createSavedNekoButton(
				scrollingFrame,
				preset,
				layoutOrder
			)
				local presetName = tostring(preset.name)
				local versionName = tostring(preset.version or "V4")

				local button = Instance.new("TextButton")
				button.Name = "★ " .. presetName
				button.LayoutOrder = layoutOrder
				button.Size = UDim2.fromOffset(385, 39)
				button.BackgroundColor3 =
					Color3.fromRGB(194, 73, 115)
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.Font = Enum.Font.Roboto
				button.Text = "★ " .. presetName
				button.TextColor3 = Color3.new(1, 1, 1)
				button.TextSize = 17
				button:SetAttribute(
					"CaelusPendalarSavedCustomNeko",
					true
				)
				button.Parent = scrollingFrame
				addCorner(button, 5)

				local infoButton = Instance.new("ImageButton")
				infoButton.Name = "infobutton"
				infoButton.BackgroundTransparency = 1
				infoButton.Position =
					UDim2.new(0, 11, 0.5, -10)
				infoButton.Size = UDim2.fromOffset(20, 20)
				infoButton.Image =
					"http://www.roblox.com/asset/?id=6294110112"
				infoButton.Parent = button

				local showingInfo = false

				infoButton.MouseButton1Click:Connect(function()
					showingInfo = not showingInfo

					if showingInfo then
						button.Text =
							"Saved Custom Neko • " .. versionName
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
						state.savedPresets
						and state.savedPresets[presetName]

					if type(selectedPreset) ~= "table" then
						warn(
							"[Pendalar Hub] Saved Custom Neko "
								.. "no longer exists: "
								.. presetName
						)
						return
					end

					state.customNeko =
						copyCustomConfig(selectedPreset)
					state.selectedMorph = CUSTOM_MORPH_NAME
					state.selectedVersion =
						selectedPreset.version
						or state.selectedVersion
						or "V4"

					selectedText.Text = presetName
					selectedValue.Value = CUSTOM_MORPH_NAME

					if ui.VersionLabel then
						ui.VersionLabel.Text =
							"Selected Neko Version : "
								.. tostring(state.selectedVersion)
					end

					local applied, problem =
						api:ApplySelectedCustom()

					if not applied then
						warn(
							"[Pendalar Hub] "
								.. tostring(problem)
						)
					end
				end)

				table.insert(addon.savedButtons, button)
			end

			local function refreshSavedNekos(force)
				local scrollingFrame = getTabScroll("Nekos")

				if not scrollingFrame then
					return
				end

				local signature = savedSignature()

				if not force
					and signature == addon.savedSignature
				then
					return
				end

				addon.savedSignature = signature
				clearSavedButtons()

				for index, preset in ipairs(orderedSavedPresets()) do
					createSavedNekoButton(
						scrollingFrame,
						preset,
						10000 + index
					)
				end

				bindScroll(scrollingFrame)
			end

			local function settingEnabled(key)
				return addon.settings[key] ~= false
			end

			local function updateToggleVisual(button, enabled)
				if not button or not button.Parent then
					return
				end

				local slider = button:FindFirstChild("slider")
				local knob =
					slider and slider:FindFirstChild("knob")
				local status = button:FindFirstChild("status")

				if slider then
					slider.BackgroundColor3 =
						enabled
							and Color3.fromRGB(0, 210, 75)
							or Color3.fromRGB(200, 0, 0)
				end

				if knob then
					knob.Position =
						enabled
							and UDim2.new(0, 15, 0, -3)
							or UDim2.new(0, -5, 0, -3)
				end

				if status then
					status.Text = enabled and "ON" or "OFF"
				end
			end

			local function setSetting(key, enabled)
				addon.settings[key] = enabled == true
				preferences[key] = enabled == true

				updateToggleVisual(
					addon.animationButtons[key],
					enabled == true
				)
			end

			local function createAnimationToggle(
				scrollingFrame,
				key,
				title,
				description,
				layoutOrder
			)
				local existing =
					scrollingFrame:FindFirstChild(
						"CaelusAnimation_" .. key
					)

				if existing then
					existing:Destroy()
				end

				local button = Instance.new("TextButton")
				button.Name = "CaelusAnimation_" .. key
				button.LayoutOrder = layoutOrder
				button.Size = UDim2.fromOffset(385, 48)
				button.BackgroundColor3 =
					Color3.fromRGB(194, 73, 115)
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.Font = Enum.Font.Roboto
				button.Text = ""
				button:SetAttribute(
					"CaelusAnimationSetting",
					true
				)
				button.Parent = scrollingFrame
				addCorner(button, 5)

				local titleLabel = Instance.new("TextLabel")
				titleLabel.Name = "title"
				titleLabel.BackgroundTransparency = 1
				titleLabel.Position = UDim2.fromOffset(12, 4)
				titleLabel.Size = UDim2.new(1, -105, 0, 21)
				titleLabel.Font = Enum.Font.Roboto
				titleLabel.Text = title
				titleLabel.TextColor3 = Color3.new(1, 1, 1)
				titleLabel.TextSize = 16
				titleLabel.TextXAlignment =
					Enum.TextXAlignment.Left
				titleLabel.Parent = button

				local descriptionLabel =
					Instance.new("TextLabel")
				descriptionLabel.Name = "description"
				descriptionLabel.BackgroundTransparency = 1
				descriptionLabel.Position =
					UDim2.fromOffset(12, 25)
				descriptionLabel.Size =
					UDim2.new(1, -110, 0, 17)
				descriptionLabel.Font = Enum.Font.Roboto
				descriptionLabel.Text = description
				descriptionLabel.TextColor3 =
					Color3.fromRGB(235, 220, 225)
				descriptionLabel.TextSize = 10
				descriptionLabel.TextXAlignment =
					Enum.TextXAlignment.Left
				descriptionLabel.TextTruncate =
					Enum.TextTruncate.AtEnd
				descriptionLabel.Parent = button

				local status = Instance.new("TextLabel")
				status.Name = "status"
				status.BackgroundTransparency = 1
				status.Position =
					UDim2.new(1, -78, 0.5, -8)
				status.Size = UDim2.fromOffset(30, 16)
				status.Font = Enum.Font.RobotoBold
				status.TextColor3 = Color3.new(1, 1, 1)
				status.TextSize = 10
				status.Parent = button

				local slider = Instance.new("Frame")
				slider.Name = "slider"
				slider.Size = UDim2.fromOffset(25, 10)
				slider.Position =
					UDim2.new(1, -40, 0.5, -5)
				slider.BorderSizePixel = 0
				slider.Parent = button
				addCorner(slider, 5)

				local knob = Instance.new("Frame")
				knob.Name = "knob"
				knob.Size = UDim2.fromOffset(15, 15)
				knob.BorderSizePixel = 0
				knob.BackgroundColor3 =
					Color3.fromRGB(245, 245, 245)
				knob.Parent = slider
				addCorner(knob, 8)

				addon.animationButtons[key] = button

				updateToggleVisual(
					button,
					settingEnabled(key)
				)

				button.MouseButton1Click:Connect(function()
					setSetting(
						key,
						not settingEnabled(key)
					)
				end)
			end

			local function installAnimationToggles()
				local scrollingFrame = getTabScroll("Settings")

				if not scrollingFrame then
					return
				end

				createAnimationToggle(
					scrollingFrame,
					"idle",
					"Custom Idle Animation",
					"OFF removes the custom Neko idle pose",
					20001
				)

				createAnimationToggle(
					scrollingFrame,
					"walking",
					"Custom Walking Animation",
					"OFF removes the custom Neko walking pose",
					20002
				)

				createAnimationToggle(
					scrollingFrame,
					"punching",
					"Custom Punch Animation",
					"OFF keeps punching but removes its custom pose",
					20003
				)

				bindScroll(scrollingFrame)
			end

			local function currentActionKeys()
				local legacyConfig =
					state.activeLegacyNeko
					and environment.CaelusLegacyNekoConfig
						.variants[state.activeLegacyNeko]

				if legacyConfig
					and type(legacyConfig.keys) == "table"
				then
					return legacyConfig.keys
				end

				return KEYS_BY_VERSION[
					state.activeVersion
						or state.selectedVersion
						or "V4"
				] or {}
			end

			local function normalizedKeyName(keyCode)
				local name = string.upper(keyCode.Name)

				if name == "ZERO" then
					return "0"
				end

				return name
			end

			local function isActionKey(keyCode)
				local name = normalizedKeyName(keyCode)

				for _, key in ipairs(currentActionKeys()) do
					if string.upper(tostring(key)) == name then
						return true, name
					end
				end

				return false, name
			end

			local function hasHeldActionKey()
				return next(addon.heldActionKeys) ~= nil
			end

			local function shouldNeutralizePose()
				local humanoid = state.realHumanoid

				if not humanoid or not humanoid.Parent then
					return false
				end

				local now = os.clock()

				if addon.attackHeld or now < addon.punchUntil then
					return not settingEnabled("punching")
				end

				if hasHeldActionKey()
					or now < addon.specialUntil
				then
					return false
				end

				local humanoidState = humanoid:GetState()

				if humanoid.Sit
					or humanoidState
						== Enum.HumanoidStateType.Jumping
					or humanoidState
						== Enum.HumanoidStateType.Freefall
					or humanoidState
						== Enum.HumanoidStateType.FallingDown
					or humanoidState
						== Enum.HumanoidStateType.Climbing
					or humanoidState
						== Enum.HumanoidStateType.Swimming
					or humanoid.FloorMaterial
						== Enum.Material.Air
				then
					return false
				end

				if humanoid.MoveDirection.Magnitude > 0.05 then
					return not settingEnabled("walking")
				end

				return not settingEnabled("idle")
			end

			local function restoreNeutralPose()
				for _, pair in ipairs(state.posePairs or {}) do
					local motor = pair.motor

					if motor
						and motor.Parent
						and motor:IsA("Motor6D")
					then
						pcall(function()
							motor.C0 = pair.baseC0
							motor.C1 = pair.baseC1
							motor.Transform = CFrame.new()
						end)
					end
				end
			end

			local renderSignal = nil

			local renderOk, preRender = pcall(function()
				return RunService.PreRender
			end)

			if renderOk and preRender then
				renderSignal = preRender
			else
				renderSignal = RunService.RenderStepped
			end

			remember(renderSignal:Connect(function()
				if addon.destroyed or state.destroyed then
					return
				end

				if shouldNeutralizePose() then
					restoreNeutralPose()
				end
			end))

			remember(UserInputService.InputBegan:Connect(
				function(input, gameProcessed)
					if addon.destroyed
						or state.destroyed
						or gameProcessed
					then
						return
					end

					if input.UserInputType
							== Enum.UserInputType.MouseButton1
						or input.UserInputType
							== Enum.UserInputType.Touch
					then
						if not overInteractiveGui(input.Position) then
							addon.attackHeld = true
							addon.punchUntil = os.clock() + 1.8
						end

						return
					end

					if input.UserInputType
						== Enum.UserInputType.Keyboard
					then
						local action, keyName =
							isActionKey(input.KeyCode)

						if action then
							addon.heldActionKeys[keyName] = true
							addon.specialUntil =
								os.clock() + 1.25
						end
					end
				end
			))

			remember(UserInputService.InputEnded:Connect(
				function(input)
					if addon.destroyed then
						return
					end

					if input.UserInputType
							== Enum.UserInputType.MouseButton1
						or input.UserInputType
							== Enum.UserInputType.Touch
					then
						addon.attackHeld = false
						addon.punchUntil =
							math.max(
								addon.punchUntil,
								os.clock() + 0.55
							)
						return
					end

					if input.UserInputType
						== Enum.UserInputType.Keyboard
					then
						local action, keyName =
							isActionKey(input.KeyCode)

						if action then
							addon.heldActionKeys[keyName] = nil
							addon.specialUntil =
								math.max(
									addon.specialUntil,
									os.clock() + 0.35
								)
						end
					end
				end
			))

			local originalSaveCustom = api.SaveCustom

			if type(originalSaveCustom) == "function" then
				api.SaveCustom = function(self, ...)
					local results =
						table.pack(
							originalSaveCustom(self, ...)
						)

					task.defer(function()
						if not addon.destroyed
							and not state.destroyed
						then
							refreshSavedNekos(true)
							bindAllScrolls()
						end
					end)

					return table.unpack(
						results,
						1,
						results.n
					)
				end
			end

			function addon:Destroy()
				if self.destroyed then
					return
				end

				self.destroyed = true

				if type(originalSaveCustom) == "function"
					and api.SaveCustom ~= originalSaveCustom
				then
					api.SaveCustom = originalSaveCustom
				end

				clearSavedButtons()

				for _, button in pairs(self.animationButtons) do
					if button and button.Parent then
						button:Destroy()
					end
				end

				table.clear(self.animationButtons)

				for scrollingFrame in pairs(
					self.scrollConnections
				) do
					disconnectScroll(scrollingFrame)
				end
			end

			bindAllScrolls()
			refreshSavedNekos(true)
			installAnimationToggles()

			task.spawn(function()
				while not addon.destroyed
					and not state.destroyed
					and environment.CaelusPendalarNekoUI == ui
					and ui.GuiRoot
					and ui.GuiRoot.Parent
				do
					refreshSavedNekos(false)

					for _, tabName in ipairs({
						"Nekos",
						"Settings",
						"Neko Editor",
						"Scripts",
						"Credits",
					}) do
						local scrollingFrame =
							getTabScroll(tabName)

						local layout =
							scrollingFrame
							and scrollingFrame
								:FindFirstChildOfClass(
									"UIListLayout"
								)

						if scrollingFrame and layout then
							local wanted =
								math.max(
									math.ceil(
										layout.AbsoluteContentSize.Y
									) + 72,
									math.ceil(
										scrollingFrame.AbsoluteSize.Y
									) + 1
								)

							if scrollingFrame.CanvasSize.Y.Scale ~= 0
								or math.abs(
									scrollingFrame.CanvasSize.Y.Offset
										- wanted
								) > 2
							then
								scrollingFrame.CanvasSize =
									UDim2.fromOffset(0, wanted)
							end
						end
					end

					task.wait(0.8)
				end

				addon:Destroy()
			end)

			print(
				"[Caelus Neko] Standalone additions active: "
					.. "saved Custom Nekos, fixed Pendalar scrolling, "
					.. "and idle/walk/punch animation toggles."
			)
		end
	end
end

]====]

local source = fetch(BASE_URL)

local marker = "\nreturn gui"
local markerStart = source:match(".*()\nreturn gui")

if not markerStart then
	error(
		"[Full Hub Builder] The known-good hub ending changed; "
			.. "the full file was not generated.",
		0
	)
end

local before = source:sub(1, markerStart - 1)
local after = source:sub(markerStart)

local merged =
	before
	.. ADDON
	.. after

merged = merged:gsub(
	'local RUNTIME_VERSION = "3%.32%.7%-fe%-toggle%-hard%-ui"',
	'local RUNTIME_VERSION = "3.32.9-standalone-custom-controls"',
	1
)

merged = merged:gsub(
	'window:SetFooter%("Current Version : 3%.32%.7"%)',
	'window:SetFooter("Current Version : 3.32.9")',
	1
)

if makefolder then
	local folderExists = false

	if isfolder then
		local ok, exists = pcall(isfolder, OUTPUT_FOLDER)
		folderExists = ok and exists == true
	end

	if not folderExists then
		pcall(makefolder, OUTPUT_FOLDER)
	end
end

local writeOk, writeProblem =
	pcall(writefile, OUTPUT_PATH, merged)

if not writeOk then
	writeOk, writeProblem =
		pcall(writefile, "hub_full.lua", merged)

	if writeOk then
		print(
			"[Full Hub Builder] Wrote full standalone file to hub_full.lua"
		)

		if setclipboard then
			pcall(
				setclipboard,
				"hub_full.lua"
			)
		end

		return
	end

	error(
		"[Full Hub Builder] Could not write the full hub: "
			.. tostring(writeProblem),
		0
	)
end

print(
	"[Full Hub Builder] SUCCESS. Full standalone hub written to: "
		.. OUTPUT_PATH
)

print(
	"[Full Hub Builder] Size: "
		.. tostring(#merged)
		.. " bytes. Upload THAT generated hub.lua to GitHub."
)

if setclipboard then
	pcall(setclipboard, OUTPUT_PATH)
end
