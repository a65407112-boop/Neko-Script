-- File: hub.lua
-- Caelus Neko Hub 3.32.8 patch layer.
-- Base: Neko-Script commit 3791149.
-- Fixes:
--   * Saved Custom Nekos appear in Pendalar -> Nekos immediately.
--   * Custom walking and idle animations can be disabled independently.
--   * Primary punches can use fist or claw combos independently of the F stance.
--   * Pendalar scrolling follows actual content size, including Settings and Editor.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE_URL =
    "https://raw.githubusercontent.com/a65407112-boop/Neko-Script/3791149/hub.lua"

local function fetchBase()
    local ok, result = pcall(function()
        return game:HttpGet(BASE_URL)
    end)

    if not ok or type(result) ~= "string" or result == "" then
        error(
            "[Caelus Neko 3.32.8] Could not download the pinned base hub: "
                .. tostring(result),
            0
        )
    end

    return result
end

local function replaceOnce(source, needle, replacement, label)
    local first, last = string.find(source, needle, 1, true)

    if not first then
        error(
            "[Caelus Neko 3.32.8] Patch anchor missing: "
                .. tostring(label),
            0
        )
    end

    return string.sub(source, 1, first - 1)
        .. replacement
        .. string.sub(source, last + 1)
end

local source = fetchBase()

source = replaceOnce(
    source,
    'local RUNTIME_VERSION = "3.32.7-fe-toggle-hard-ui"',
    'local RUNTIME_VERSION = "3.32.9-pendalar-saved-scroll"',
    "runtime version"
)

source = replaceOnce(
    source,
    [[	customDraftUse3DPants = true,
	originalClawRunSpeedEnabled = false,
	feAnimationsEnabled = false,]],
    [[	customDraftUse3DPants = true,
	originalClawRunSpeedEnabled = false,
	customWalkAnimationEnabled = true,
	customIdleAnimationEnabled = true,
	punchWithClawsEnabled = false,
	useDefaultLocomotionPose = false,
	specialPoseUntil = 0,
	primaryAttackHeld = false,
	feAnimationsEnabled = false,]],
    "state animation settings"
)

source = replaceOnce(
    source,
    "local function setupDirectPose(driver, character)",
    [[function state:restorePosePairBases()
	for _, pair in ipairs(self.posePairs) do
		local motor = pair.motor
		if motor and motor.Parent then
			pcall(function()
				motor.C0 = pair.baseC0
				motor.C1 = pair.baseC1
				motor.Transform = CFrame.new()
			end)
		end
	end
end

function state:shouldUseDefaultLocomotion()
	local humanoid = self.realHumanoid
	if not humanoid or not humanoid.Parent then
		return false
	end

	if self.primaryAttackHeld
		or os.clock() < (self.specialPoseUntil or 0)
	then
		return false
	end

	local controller = self.controller
	if controller
		and controller.Parent
		and controller:GetAttribute("CaelusAttacking") == true
	then
		return false
	end

	if humanoid.Sit then
		return false
	end

	local humanoidState = humanoid:GetState()
	if humanoidState == Enum.HumanoidStateType.Jumping
		or humanoidState == Enum.HumanoidStateType.Freefall
		or humanoidState == Enum.HumanoidStateType.FallingDown
		or humanoidState == Enum.HumanoidStateType.Climbing
		or humanoidState == Enum.HumanoidStateType.Swimming
	then
		return false
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end

	if humanoid.MoveDirection.Magnitude > 0.05 then
		return self.customWalkAnimationEnabled ~= true
	end

	return self.customIdleAnimationEnabled ~= true
end

function state:updateLocomotionAnimationPolicy(force)
	local useDefault = self:shouldUseDefaultLocomotion()
	local changed = self.useDefaultLocomotionPose ~= useDefault

	if not changed and not force then
		return useDefault
	end

	self.useDefaultLocomotionPose = useDefault

	if useDefault then
		self:restorePosePairBases()
	end

	local animate = self.animateScript
	if animate
		and animate.Parent
		and self.animateWasDisabled == false
	then
		pcall(function()
			animate.Disabled = not useDefault
		end)
	end

	if not useDefault then
		local humanoid = self.realHumanoid
		local animator =
			humanoid and humanoid:FindFirstChildOfClass("Animator")

		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track:GetAttribute("CaelusFEAnimationMirror") ~= true then
					pcall(function()
						track:Stop(0.05)
					end)
				end
			end
		end
	end

	if changed and self.feAnimationsEnabled then
		if useDefault and type(self.stopFEAnimationMirrors) == "function" then
			self:stopFEAnimationMirrors()
		elseif not useDefault
			and type(self.refreshFEAnimationMirroring) == "function"
		then
			task.defer(function()
				if not self.destroyed
					and self.feAnimationsEnabled
					and not self.useDefaultLocomotionPose
				then
					self:refreshFEAnimationMirroring()
				end
			end)
		end
	end

	return useDefault
end

function state:setCustomWalkAnimation(enabled)
	self.customWalkAnimationEnabled = enabled == true
	self:updateLocomotionAnimationPolicy(true)
end

function state:setCustomIdleAnimation(enabled)
	self.customIdleAnimationEnabled = enabled == true
	self:updateLocomotionAnimationPolicy(true)
end

function state:setPunchWithClaws(enabled)
	self.punchWithClawsEnabled = enabled == true

	local controller = self.controller
	if controller and controller.Parent then
		controller:SetAttribute(
			"CaelusPunchWithClaws",
			self.punchWithClawsEnabled
		)
	end
end

local function setupDirectPose(driver, character)]],
    "locomotion controls"
)

source = replaceOnce(
    source,
    [[				if state.feAnimationsEnabled
					and track:GetAttribute("CaelusFEAnimationMirror") == true
				then
					return
				end
				pcall(function() track:Stop(0) end)]],
    [[				if state.feAnimationsEnabled
					and track:GetAttribute("CaelusFEAnimationMirror") == true
				then
					return
				end
				if state:shouldUseDefaultLocomotion() then
					return
				end
				pcall(function() track:Stop(0) end)]],
    "default animation allowance"
)

source = replaceOnce(
    source,
    [[local function syncDirectPose()
	for _, pair in ipairs(state.posePairs) do]],
    [[local function syncDirectPose()
	if state:updateLocomotionAnimationPolicy(false) then
		return
	end

	for _, pair in ipairs(state.posePairs) do]],
    "pose mirror switch"
)

source = replaceOnce(
    source,
    [[local function fireCommand(kind, value)
	local command = state.command]],
    [[local function fireCommand(kind, value)
	if kind == "mouse_down" then
		state.primaryAttackHeld = true
		state.specialPoseUntil = os.clock() + 2
	elseif kind == "mouse_up" then
		state.primaryAttackHeld = false
	elseif kind == "key_down" then
		state.specialPoseUntil = os.clock() + 5
	end

	local command = state.command]],
    "command pose protection"
)

source = replaceOnce(
    source,
    [[		source = source:gsub(
			"agresive%s*=%s*false",
			'agresive = false; pcall(function() script:SetAttribute("CaelusAggressive", false) end)'
		)
	end]],
    [[		source = source:gsub(
			"agresive%s*=%s*false",
			'agresive = false; pcall(function() script:SetAttribute("CaelusAggressive", false) end)'
		)

		source = source:gsub(
			"attack%s*=%s*true",
			'attack = true; pcall(function() script:SetAttribute("CaelusAttacking", true) end)'
		)
		source = source:gsub(
			"attack%s*=%s*false",
			'attack = false; pcall(function() script:SetAttribute("CaelusAttacking", false) end)'
		)

		local comboStart = source:find("function ClickCombo()", 1, true)
		if comboStart then
			local conditionStart, conditionEnd =
				source:find("if agresive == false then", comboStart, true)

			if conditionStart then
				source =
					source:sub(1, conditionStart - 1)
					.. 'if script:GetAttribute("CaelusPunchWithClaws") ~= true then'
					.. source:sub(conditionEnd + 1)
			end
		end
	end]],
    "controller punch selection"
)

source = replaceOnce(
    source,
    [[		controller.Name = "CaelusNekoOriginalController"
		controller:SetAttribute("CaelusSessionActive", true)]],
    [[		controller.Name = "CaelusNekoOriginalController"
		controller:SetAttribute(
			"CaelusPunchWithClaws",
			state.punchWithClawsEnabled
		)
		controller:SetAttribute("CaelusSessionActive", true)]],
    "controller punch setting"
)

source = replaceOnce(
    source,
    [[function environment.CaelusNekoAPI:GetSelectedCustom()
	if state.selectedMorph ~= CUSTOM_MORPH_NAME
		or not state.customNeko
	then
		return nil
	end
	return copyCustomConfig(state.customNeko)
end

function environment.CaelusNekoAPI:SaveCustom(]],
    [[function environment.CaelusNekoAPI:GetSelectedCustom()
	if state.selectedMorph ~= CUSTOM_MORPH_NAME
		or not state.customNeko
	then
		return nil
	end
	return copyCustomConfig(state.customNeko)
end

function environment.CaelusNekoAPI:GetSavedCustoms()
	local result = {}

	for _, preset in ipairs(orderedSavedPresets()) do
		table.insert(result, copyCustomConfig(preset))
	end

	return result
end

function environment.CaelusNekoAPI:ApplySavedCustom(name)
	local preset = state.savedPresets[tostring(name or "")]

	if not preset then
		return false, "Saved Custom Neko not found: " .. tostring(name)
	end

	local config = copyCustomConfig(preset)
	local versionName =
		validVersion(config.version) and config.version or "V4"

	state.customNeko = config
	state.selectedMorph = CUSTOM_MORPH_NAME
	state.selectedVersion = versionName
	selectedText.Text = config.name or "Custom Neko"
	selectedValue.Value = CUSTOM_MORPH_NAME

	if environment.CaelusPendalarNekoUI
		and environment.CaelusPendalarNekoUI.VersionLabel
	then
		environment.CaelusPendalarNekoUI.VersionLabel.Text =
			"Selected Neko Version : " .. versionName
	end

	task.spawn(applyMorph, versionName, CUSTOM_MORPH_NAME)
	return true
end

function environment.CaelusNekoAPI:SaveCustom(]],
    "saved Neko API"
)

source = replaceOnce(
    source,
    [[	EditorPreviousName = nil,
	AttackFlingEnabled = false,]],
    [[	EditorPreviousName = nil,
	NekosTab = nil,
	SettingsTab = nil,
	EditorTab = nil,
	CreditsTab = nil,
	SavedNekoButtonNames = {},
	ScrollCanvasConnections = {},
	AttackFlingEnabled = false,]],
    "Pendalar state fields"
)

source = replaceOnce(
    source,
    [[function environment.CaelusPendalarNekoUI:SaveEditor()]],
    [[function environment.CaelusPendalarNekoUI:FitTabScroll(tab)
	if not tab or not tab.Tab then
		return
	end

	local scrollingFrame =
		tab.Tab:FindFirstChildOfClass("ScrollingFrame")
	if not scrollingFrame then
		return
	end

	local layout =
		scrollingFrame:FindFirstChildOfClass("UIListLayout")
	if not layout then
		return
	end

	local function updateCanvas()
		if not scrollingFrame.Parent or not layout.Parent then
			return
		end

		local contentHeight = layout.AbsoluteContentSize.Y + 16
		local minimumHeight = math.max(scrollingFrame.AbsoluteSize.Y + 1, 1)

		scrollingFrame.CanvasSize =
			UDim2.fromOffset(0, math.max(contentHeight, minimumHeight))
	end

	self.ScrollCanvasConnections =
		self.ScrollCanvasConnections or {}

	if not self.ScrollCanvasConnections[scrollingFrame] then
		self.ScrollCanvasConnections[scrollingFrame] =
			layout:GetPropertyChangedSignal("AbsoluteContentSize")
				:Connect(updateCanvas)
	end

	updateCanvas()
	task.defer(updateCanvas)
end

function environment.CaelusPendalarNekoUI:RefreshSavedNekos()
	local tab = self.NekosTab
	if not tab or not tab.Tab then
		return
	end

	local scrollingFrame =
		tab.Tab:FindFirstChildOfClass("ScrollingFrame")
	if not scrollingFrame then
		return
	end

	for _, buttonName in ipairs(self.SavedNekoButtonNames or {}) do
		local button = scrollingFrame:FindFirstChild(buttonName)
		if button
			and button:GetAttribute("CaelusSavedCustomNeko") == true
		then
			button:Destroy()
		end
	end

	self.SavedNekoButtonNames = {}

	for _, preset in ipairs(environment.CaelusNekoAPI:GetSavedCustoms()) do
		local presetName = tostring(preset.name or "Custom Neko")
		local buttonName = "★ " .. presetName
		local versionName = tostring(preset.version or "V4")

		tab:NewButton(
			buttonName,
			"Saved Custom Neko • " .. versionName,
			function()
				local applied, problem =
					environment.CaelusNekoAPI:ApplySavedCustom(presetName)

				if not applied then
					warn(
						"[Pendalar Hub] "
							.. tostring(problem)
					)
				end
			end
		)

		local created = scrollingFrame:FindFirstChild(buttonName)
		if created then
			created:SetAttribute("CaelusSavedCustomNeko", true)
		end

		table.insert(self.SavedNekoButtonNames, buttonName)
	end

	self:FitTabScroll(tab)
end

function environment.CaelusPendalarNekoUI:SaveEditor()]],
    "Pendalar helpers"
)

source = replaceOnce(
    source,
    [[	self.EditorPreviousName = result
	self.EditorStatus.Text = "Saved : " .. tostring(result)
end]],
    [[	self.EditorPreviousName = result
	self.EditorStatus.Text = "Saved : " .. tostring(result)
	self:RefreshSavedNekos()
end]],
    "live saved Neko refresh"
)

source = replaceOnce(
    source,
    [[	self.ScriptsTab = scriptsTab
	-- FE Animations uses a direct Settings row]],
    [[	self.NekosTab = nekosTab
	self.SettingsTab = settingsTab
	self.EditorTab = editorTab
	self.ScriptsTab = scriptsTab
	self.CreditsTab = creditsTab
	self.SavedNekoButtonNames = {}
	self.ScrollCanvasConnections = {}
	-- FE Animations uses a direct Settings row]],
    "Pendalar tab references"
)

source = replaceOnce(
    source,
    [[	end

	self.VersionLabel = settingsTab:NewLabel(
		"Selected Neko Version : "]],
    [[	end

	self:RefreshSavedNekos()

	self.VersionLabel = settingsTab:NewLabel(
		"Selected Neko Version : "]],
    "initial saved Neko list"
)

source = replaceOnce(
    source,
    [[	settingsTab:NewBoolButton(
		"Original Claw Run Speed",]],
    [[	settingsTab:NewBoolButton(
		"Custom Walking Animation",
		"Use the Neko's custom walking animation; off uses the character's normal walk",
		function(enabled)
			state:setCustomWalkAnimation(enabled)
		end,
		state.customWalkAnimationEnabled
	)

	settingsTab:NewBoolButton(
		"Custom Idle Animation",
		"Use the Neko's custom idle animation; off uses the character's normal idle",
		function(enabled)
			state:setCustomIdleAnimation(enabled)
		end,
		state.customIdleAnimationEnabled
	)

	settingsTab:NewBoolButton(
		"Punch With Claws",
		"On uses the claw combo; off uses the normal fist combo",
		function(enabled)
			state:setPunchWithClaws(enabled)
		end,
		state.punchWithClawsEnabled
	)

	settingsTab:NewBoolButton(
		"Original Claw Run Speed",]],
    "new Settings toggles"
)

source = replaceOnce(
    source,
    [[	creditsTab:NewLabel("melanie070910")

	window:SetMainTab(nekosTab)]],
    [[	creditsTab:NewLabel("melanie070910")

	self:FitTabScroll(nekosTab)
	self:FitTabScroll(settingsTab)
	self:FitTabScroll(editorTab)
	self:FitTabScroll(scriptsTab)
	self:FitTabScroll(creditsTab)

	window:SetMainTab(nekosTab)]],
    "scroll canvas fix"
)

source = replaceOnce(
    source,
    [[remember(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local isTouch =]],
    [[remember(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local keyName = string.upper(input.KeyCode.Name)
		if keyName == "ZERO" then
			keyName = "0"
		end

		local legacyConfig = state.activeLegacyNeko
			and environment.CaelusLegacyNekoConfig.variants[
				state.activeLegacyNeko
			]
		local keys = (legacyConfig and legacyConfig.keys)
			or KEYS_BY_VERSION[state.activeVersion or state.selectedVersion]
			or {}

		if table.find(keys, keyName) then
			state.specialPoseUntil = os.clock() + 5
		end

		return
	end

	local isTouch =]],
    "keyboard action pose protection"
)

source = replaceOnce(
    source,
    [[	if overInteractiveGui(input.Position) then
		return
	end

	local pendalarUI = state.pendalarUI]],
    [[	if overInteractiveGui(input.Position) then
		return
	end

	state.primaryAttackHeld = true
	state.specialPoseUntil = os.clock() + 2

	local pendalarUI = state.pendalarUI]],
    "mouse attack pose protection"
)

source = replaceOnce(
    source,
    [[remember(UserInputService.InputEnded:Connect(function(input)
	if state.activeTouches[input] then]],
    [[remember(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		state.primaryAttackHeld = false
	end

	if state.activeTouches[input] then
		state.primaryAttackHeld = false]],
    "attack release"
)

source = replaceOnce(
    source,
    'window:SetFooter("Current Version : 3.32.7")',
    'window:SetFooter("Current Version : 3.32.9")',
    "Pendalar footer version"
)

source = replaceOnce(
    source,
    'environment.CaelusNekoBootStatus("Caelus Neko 3.32.5: ready")',
    'environment.CaelusNekoBootStatus("Caelus Neko 3.32.9: ready")',
    "ready version"
)

local chunk, compileProblem =
    loadstring(source, "=CaelusNekoHub_3_32_8")

if not chunk then
    error(
        "[Caelus Neko 3.32.8] Patched hub compile failed: "
            .. tostring(compileProblem),
        0
    )
end

local ok, result = pcall(chunk)

if not ok then
	error(
		"[Caelus Neko 3.32.9] Patched hub runtime failed: "
			.. tostring(result),
		0
	)
end

local function installPendalarRuntimeFixes()
	local ui = environment.CaelusPendalarNekoUI
	local api = environment.CaelusNekoAPI
	local session = api and api.Session

	if type(ui) ~= "table"
		or type(api) ~= "table"
		or type(session) ~= "table"
		or not ui.GuiRoot
	then
		warn("[Caelus Neko 3.32.9] Pendalar runtime fix could not find the UI/session.")
		return
	end

	local main = ui.GuiRoot:FindFirstChild("Main")
	if not main then
		warn("[Caelus Neko 3.32.9] Pendalar Main frame was not found.")
		return
	end

	local scrollConnections = {}

	local function disconnectScrollConnections(scrollingFrame)
		local existing = scrollConnections[scrollingFrame]
		if not existing then
			return
		end

		for _, connection in ipairs(existing) do
			pcall(function()
				connection:Disconnect()
			end)
		end

		scrollConnections[scrollingFrame] = nil
	end

	local function bindScrollingFrame(scrollingFrame)
		if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
			return
		end

		disconnectScrollConnections(scrollingFrame)

		local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
		if not layout then
			return
		end

		scrollingFrame.Active = true
		scrollingFrame.ScrollingEnabled = true
		scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollingFrame.ScrollBarThickness = math.max(scrollingFrame.ScrollBarThickness, 5)
		scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None

		local queued = false
		local function updateCanvas()
			if queued then
				return
			end

			queued = true
			task.defer(function()
				queued = false

				if not scrollingFrame.Parent or not layout.Parent then
					return
				end

				local contentHeight = math.ceil(layout.AbsoluteContentSize.Y) + 48
				local viewportHeight = math.ceil(scrollingFrame.AbsoluteSize.Y)
				local canvasHeight = math.max(contentHeight, viewportHeight + 1)

				scrollingFrame.CanvasSize = UDim2.fromOffset(0, canvasHeight)

				local maxScroll = math.max(0, canvasHeight - viewportHeight)
				if scrollingFrame.CanvasPosition.Y > maxScroll then
					scrollingFrame.CanvasPosition = Vector2.new(
						scrollingFrame.CanvasPosition.X,
						maxScroll
					)
				end
			end)
		end

		scrollConnections[scrollingFrame] = {
			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas),
			scrollingFrame.ChildAdded:Connect(updateCanvas),
			scrollingFrame.ChildRemoved:Connect(updateCanvas),
			scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas),
		}

		updateCanvas()
	end

	local function findTabScroll(tabName)
		local tabFrame = main:FindFirstChild(tabName)
		if not tabFrame then
			return nil
		end

		return tabFrame:FindFirstChildOfClass("ScrollingFrame")
	end

	local function copyValue(value, seen)
		if type(value) ~= "table" then
			return value
		end

		seen = seen or {}
		if seen[value] then
			return seen[value]
		end

		local resultTable = {}
		seen[value] = resultTable

		for key, item in pairs(value) do
			resultTable[copyValue(key, seen)] = copyValue(item, seen)
		end

		return resultTable
	end

	local function sortedSavedPresets()
		local presets = {}

		for _, preset in pairs(session.savedPresets or {}) do
			if type(preset) == "table" and type(preset.name) == "string" then
				table.insert(presets, preset)
			end
		end

		table.sort(presets, function(left, right)
			return string.lower(left.name) < string.lower(right.name)
		end)

		return presets
	end

	local function clearRuntimeSavedButtons(scrollingFrame)
		for _, child in ipairs(scrollingFrame:GetChildren()) do
			if child:GetAttribute("CaelusPendalarSavedNeko") == true
				or child:GetAttribute("CaelusSavedCustomNeko") == true
			then
				child:Destroy()
			end
		end
	end

	local function makeSavedButton(scrollingFrame, preset, layoutOrder)
		local presetName = tostring(preset.name)
		local versionName = tostring(preset.version or "V4")

		local button = Instance.new("TextButton")
		button.Name = "★ " .. presetName
		button.LayoutOrder = layoutOrder
		button.Size = UDim2.fromOffset(385, 39)
		button.BackgroundColor3 = Color3.fromRGB(194, 73, 115)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Font = Enum.Font.Roboto
		button.Text = "★ " .. presetName
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 17
		button:SetAttribute("CaelusPendalarSavedNeko", true)
		button.Parent = scrollingFrame

		local corner = Instance.new("UICorner")
		corner.Name = "butcorner"
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button

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

			local currentPreset = session.savedPresets
				and session.savedPresets[presetName]

			if type(currentPreset) ~= "table" then
				warn("[Pendalar Hub] Saved Neko no longer exists: " .. presetName)
				return
			end

			session.customNeko = copyValue(currentPreset)
			session.selectedMorph = "Custom Neko"
			session.selectedVersion = currentPreset.version
				or session.selectedVersion
				or "V4"

			if ui.VersionLabel then
				ui.VersionLabel.Text =
					"Selected Neko Version : " .. tostring(session.selectedVersion)
			end

			local applied, problem = api:ApplySelectedCustom()
			if not applied then
				warn("[Pendalar Hub] " .. tostring(problem))
			end
		end)

		return button
	end

	local savedSignature = nil

	local function currentSavedSignature()
		local names = {}

		for _, preset in ipairs(sortedSavedPresets()) do
			table.insert(
				names,
				tostring(preset.name)
					.. "\0"
					.. tostring(preset.version or "")
					.. "\0"
					.. tostring(#(preset.assetIds or {}))
			)
		end

		return table.concat(names, "\1")
	end

	local function refreshSavedNekos(force)
		local scrollingFrame = findTabScroll("Nekos")
		if not scrollingFrame then
			return
		end

		local signature = currentSavedSignature()
		if not force and signature == savedSignature then
			return
		end

		savedSignature = signature
		clearRuntimeSavedButtons(scrollingFrame)

		for index, preset in ipairs(sortedSavedPresets()) do
			makeSavedButton(scrollingFrame, preset, 10000 + index)
		end

		bindScrollingFrame(scrollingFrame)
	end

	ui.RefreshSavedNekos = function(_, force)
		refreshSavedNekos(force ~= false)
	end

	ui.FitTabScroll = function(_, tab)
		local scrollingFrame

		if type(tab) == "table" and tab.Tab then
			scrollingFrame = tab.Tab:FindFirstChildOfClass("ScrollingFrame")
		elseif typeof(tab) == "Instance" then
			if tab:IsA("ScrollingFrame") then
				scrollingFrame = tab
			else
				scrollingFrame = tab:FindFirstChildOfClass("ScrollingFrame")
			end
		end

		if scrollingFrame then
			bindScrollingFrame(scrollingFrame)
		end
	end

	for _, tabName in ipairs({
		"Nekos",
		"Settings",
		"Neko Editor",
		"Scripts",
		"Credits",
	}) do
		bindScrollingFrame(findTabScroll(tabName))
	end

	refreshSavedNekos(true)

	task.spawn(function()
		while not session.destroyed
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
				local scrollingFrame = findTabScroll(tabName)
				if scrollingFrame then
					local layout =
						scrollingFrame:FindFirstChildOfClass("UIListLayout")
					if layout then
						local wantedHeight =
							math.max(
								math.ceil(layout.AbsoluteContentSize.Y) + 48,
								math.ceil(scrollingFrame.AbsoluteSize.Y) + 1
							)

						if math.abs(
							scrollingFrame.CanvasSize.Y.Offset - wantedHeight
						) > 2 then
							scrollingFrame.CanvasSize =
								UDim2.fromOffset(0, wantedHeight)
						end
					end
				end
			end

			task.wait(0.75)
		end

		for scrollingFrame in pairs(scrollConnections) do
			disconnectScrollConnections(scrollingFrame)
		end
	end)

	print(
		"[Caelus Neko 3.32.9] Pendalar saved-Neko and scrolling fixes active."
	)
end

local fixOk, fixProblem = pcall(installPendalarRuntimeFixes)
if not fixOk then
	warn(
		"[Caelus Neko 3.32.9] Pendalar runtime fix failed: "
			.. tostring(fixProblem)
	)
end

return result
