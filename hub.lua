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

local environment = (type(getgenv) == "function" and getgenv()) or _G
local patchProblems = {}
local originalBase

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

local function fetchBase()
    local request = requestFunction()
    local lastProblem = "download failed"

    for attempt = 1, 3 do
        if request then
            local ok, response = pcall(request, {
                Url = BASE_URL,
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
                    "HTTP " .. tostring(status or "?")
                    .. " / empty response"
            else
                lastProblem = tostring(response)
            end
        end

        local ok, body = pcall(function()
            return game:HttpGet(
                BASE_URL .. "?caelus=" .. tostring(os.time()) .. tostring(attempt)
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
        "[Caelus Neko 3.32.8] Could not download the base hub: "
            .. tostring(lastProblem),
        0
    )
end

local function replaceOnce(source, needle, replacement, label)
    local first, last = string.find(source, needle, 1, true)

    if not first then
        table.insert(patchProblems, tostring(label))
        return source
    end

    return string.sub(source, 1, first - 1)
        .. replacement
        .. string.sub(source, last + 1)
end

originalBase = fetchBase()
local source = originalBase

source = replaceOnce(
    source,
    'local RUNTIME_VERSION = "3.32.7-fe-toggle-hard-ui"',
    'local RUNTIME_VERSION = "3.32.8-custom-controls"',
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
    'window:SetFooter("Current Version : 3.32.8")',
    "Pendalar footer version"
)

source = replaceOnce(
    source,
    'environment.CaelusNekoBootStatus("Caelus Neko 3.32.5: ready")',
    'environment.CaelusNekoBootStatus("Caelus Neko 3.32.8: ready")',
    "ready version"
)

local function runSource(sourceText, chunkName)
    local chunk, compileProblem = loadstring(sourceText, chunkName)

    if not chunk then
        return false, "compile failed: " .. tostring(compileProblem)
    end

    local ok, result = pcall(chunk)
    if not ok then
        return false, "runtime failed: " .. tostring(result)
    end

    return true, result
end

if #patchProblems > 0 then
    warn(
        "[Caelus Neko 3.32.8] Optional patch anchors changed: "
            .. table.concat(patchProblems, ", ")
            .. ". Launching the known-good base hub instead."
    )

    local ok, result = runSource(originalBase, "=CaelusNekoHub_BaseFallback")
    if not ok then
        error("[Caelus Neko] Base fallback " .. tostring(result), 0)
    end
    return result
end

local ok, result = runSource(source, "=CaelusNekoHub_3_32_8")
if ok then
    return result
end

warn(
    "[Caelus Neko 3.32.8] Patched hub "
        .. tostring(result)
        .. ". Falling back to the known-good base hub."
)

local fallbackOk, fallbackResult =
    runSource(originalBase, "=CaelusNekoHub_BaseFallback")

if not fallbackOk then
    error(
        "[Caelus Neko] Patch failed and base fallback also failed: "
            .. tostring(fallbackResult),
        0
    )
end

return fallbackResult
