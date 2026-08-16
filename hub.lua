-- File: LOAD_NEKO_SHADOW_CUSTOM_3_27_PERSISTENT_PRESETS.lua
-- Caelus Neko Hub Runtime 3.32.2 Single Pendalar Window
-- Prevents overlapping loader runs from creating duplicate Pendalar windows.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local environment = (type(getgenv) == "function" and getgenv()) or _G
local RUNTIME_VERSION = "3.32.5-neko-v5-original-legs"

local function startupLog(message)
	pcall(function()
		print("[Caelus Neko " .. RUNTIME_VERSION .. "] " .. tostring(message))
	end)
end

-- startupLog is a unique function object for this execution, so it also acts
-- as a generation token without consuming another top-level local slot.
environment.CaelusNekoHubLaunchToken = startupLog

local function waitForLocalPlayer(timeoutSeconds)
	local deadline = os.clock() + timeoutSeconds
	repeat
		local current = Players.LocalPlayer
		if current then
			return current
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return nil
end

local player = waitForLocalPlayer(20)
if not player then
	error("[Caelus Neko] LocalPlayer did not become available within 20 seconds.", 0)
end

local playerGui = player:FindFirstChildOfClass("PlayerGui")
if not playerGui then
	local candidate = player:WaitForChild("PlayerGui", 20)
	if candidate and candidate:IsA("PlayerGui") then
		playerGui = candidate
	end
end
if not playerGui then
	error("[Caelus Neko] PlayerGui did not become available within 20 seconds.", 0)
end

startupLog("Player and PlayerGui ready")
do
	local oldBoot = playerGui:FindFirstChild("CaelusNekoBootStatus")
	if oldBoot then oldBoot:Destroy() end

	local bootGui = Instance.new("ScreenGui")
	bootGui.Name = "CaelusNekoBootStatus"
	bootGui.ResetOnSpawn = false
	bootGui.IgnoreGuiInset = true
	bootGui.DisplayOrder = 1000000

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 8)
	label.Size = UDim2.fromOffset(360, 32)
	label.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamSemibold
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextSize = 13
	label.Text = "Caelus Neko 3.32.2: starting..."
	label.Parent = bootGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = label

	bootGui.Parent = playerGui
	environment.CaelusNekoBootGui = bootGui
end

environment.CaelusNekoBootStatus = function(message, failed)
	local bootGui = environment.CaelusNekoBootGui
	local label = bootGui and bootGui:FindFirstChild("Status")
	if label and label:IsA("TextLabel") then
		label.Text = tostring(message)
		if failed then
			label.TextColor3 = Color3.fromRGB(255, 145, 145)
		end
	end
	startupLog(message)
end

environment.CaelusNekoBootStatus("Caelus Neko 3.32.2: player ready")
local ARMOR_OFF_TEMPLATE = "rbxassetid://0"
local LOWER_BELT_NAMES = {"BeltBase", "BeltLayer", "BeltBack", "BeltCover"}
local LOWER_REAR_ACCESSORY_NAMES = {"RearAccessoryRight", "RearAccessoryLeft"}
local LOWER_V5_BELT_NAMES = {
	"BeltShell", "BeltPanel1", "BeltPanel2", "BeltPanel3", "BeltPanel4",
}
local SCARF_TEMPLATE_NAMES_BY_VERSION = {
	["V3"] = {
		Default = "CaelusOriginalScarf_V3",
		Psycho = "CaelusOriginalScarf_V3_Psycho",
	},
	["V3 with V4 aspect"] = {
		Default = "CaelusOriginalScarf_V3V4",
		Psycho = "CaelusOriginalScarf_V3V4_Psycho",
	},
	["V4"] = {
		Default = "CaelusOriginalScarf_V4",
		Psycho = "CaelusOriginalScarf_V4_Psycho",
	},
	["V5"] = {
		Default = "CaelusOriginalScarf_V5",
		Psycho = "CaelusOriginalScarf_V5_Psycho",
	},
}
local SCARF_COUNT_BY_VERSION = {
	["V3"] = 8,
	["V3 with V4 aspect"] = 8,
	["V4"] = 8,
	["V5"] = 10,
}
local CUSTOM_MORPH_NAME = "Custom Neko"
local WHITE_NEKO_SOURCE_MORPH = "White neko"
local DEFAULT_WHITE_NEKO_SKIN = Color3.fromRGB(255, 204, 153)
local MAX_CUSTOM_ASSETS = 20
local CUSTOM_SKIN_PRESETS = {
	{Name = "Porcelain", Color = Color3.fromRGB(255, 224, 189)},
	{Name = "Light", Color = Color3.fromRGB(241, 194, 125)},
	{Name = "Warm", Color = Color3.fromRGB(224, 172, 105)},
	{Name = "Tan", Color = Color3.fromRGB(198, 134, 66)},
	{Name = "Brown", Color = Color3.fromRGB(141, 85, 36)},
	{Name = "Deep", Color = Color3.fromRGB(92, 51, 23)},
	{Name = "Neko", Color = DEFAULT_WHITE_NEKO_SKIN},
	{Name = "Pale", Color = Color3.fromRGB(248, 248, 248)},
}

local function fail(message)
	if type(environment.CaelusNekoBootStatus) == "function" then
		environment.CaelusNekoBootStatus("Caelus Neko failed: " .. tostring(message), true)
	end
	error("[Caelus Neko] " .. tostring(message), 0)
end

-- Stop an earlier session, including the two superseded loaders.
for _, key in ipairs({"CaelusNekoOriginalRuntimeSession", "CaelusNekoOriginalSession", "CaelusNekoShadowSession"}) do
	local previous = environment[key]
	if type(previous) == "table" and type(previous.Destroy) == "function" then
		pcall(function() previous:Destroy() end)
	end
end
for _, guiName in ipairs({"CaelusNekoOriginalMenu", "CaelusOriginalNekoMenu", "CaelusSigmaMenu", "CaelusNekoShadowHub"}) do
	local old = playerGui:FindFirstChild(guiName)
	if old then old:Destroy() end
end
for _, child in ipairs(workspace:GetChildren()) do
	if child:GetAttribute("CaelusNekoVisualRig") == true or child.Name:match("^CaelusNekoShadow_") then
		child:Destroy()
	end
end

local function getObjectsWithRetry(uri, attempts)
	local lastProblem = "no objects returned"
	for attempt = 1, attempts do
		local ok, objects = pcall(function()
			return game:GetObjects(uri)
		end)
		if ok and type(objects) == "table" and #objects > 0 then
			return objects, nil
		end

		lastProblem = ok and "no objects returned" or tostring(objects)
		startupLog(
			"Asset attempt "
				.. tostring(attempt)
				.. "/"
				.. tostring(attempts)
				.. " failed for "
				.. uri
				.. ": "
				.. lastProblem
		)
		if attempt < attempts then
			task.wait(math.min(0.2 * attempt, 1))
		end
	end
	return nil, lastProblem
end

environment.CaelusNekoBootStatus("Caelus Neko 3.32.2: loading assets...")

local catalog = nil
local catalogUri = nil
local catalogProblem = nil
for _, uri in ipairs({
	(function()
		local runtime = environment.CaelusRemoteAssetRuntime
		if type(runtime) ~= "table" or type(runtime.getAssetUri) ~= "function" then
			return nil
		end
		local ok, resolved = pcall(runtime.getAssetUri, runtime, "NekoShadowAssets.rbxmx")
		if ok and type(resolved) == "string" and resolved ~= "" then
			return resolved
		end
		return nil
	end)(),
	"rbxasset://avatar/CaelusNekoShadow/NekoShadowAssets.rbxmx",
	"rbxasset://content/avatar/CaelusNekoShadow/NekoShadowAssets.rbxmx",
}) do
	local objects, problem = getObjectsWithRetry(uri, 6)
	catalogProblem = problem or catalogProblem
	local candidate = objects and objects[1] or nil
	if candidate then
		local root = candidate.Name == "CaelusNekoOriginalRuntime"
			and candidate or candidate:FindFirstChild("CaelusNekoOriginalRuntime", true)
		if root then
			catalog = root
			catalogUri = uri
			for index = 2, #objects do
				pcall(function()
					objects[index]:Destroy()
				end)
			end
			break
		end

		for _, object in ipairs(objects) do
			pcall(function()
				object:Destroy()
			end)
		end
	end
end

if not catalog then
	fail(
		"NekoShadowAssets.rbxmx could not be opened after retries. "
			.. "The remote cache and installed-asset fallbacks both failed. "
			.. "Last error: "
			.. tostring(catalogProblem or "unknown")
	)
end

environment.CaelusNekoBootStatus("Caelus Neko 3.32.2: assets ready")
startupLog("Asset catalog ready: " .. tostring(catalogUri))

local menuTemplate = catalog:FindFirstChild("CaelusNekoOriginalMenu")
local rigTemplate = catalog:FindFirstChild("CaelusNekoVisualR6")
local lowerV5BeltTemplates = {
	Default = catalog:FindFirstChild("CaelusOriginalBeltV5"),
	Bunny = catalog:FindFirstChild("CaelusOriginalBeltV5_Bunny"),
}
local scarfTemplates = {}
for versionName, templateNames in pairs(SCARF_TEMPLATE_NAMES_BY_VERSION) do
	scarfTemplates[versionName] = {}
	for variant, templateName in pairs(templateNames) do
		local template = catalog:FindFirstChild(templateName)
		if template and template:IsA("Model") then
			scarfTemplates[versionName][variant] = template
		end
	end
end
if not (menuTemplate and menuTemplate:IsA("ScreenGui")
and rigTemplate and rigTemplate:IsA("Model")
and lowerV5BeltTemplates.Default and lowerV5BeltTemplates.Default:IsA("Model")
and lowerV5BeltTemplates.Bunny and lowerV5BeltTemplates.Bunny:IsA("Model")
and scarfTemplates["V3"].Default and scarfTemplates["V3"].Psycho
and scarfTemplates["V3 with V4 aspect"].Default
and scarfTemplates["V3 with V4 aspect"].Psycho
and scarfTemplates["V4"].Default and scarfTemplates["V4"].Psycho
and scarfTemplates["V5"].Default and scarfTemplates["V5"].Psycho) then
	catalog:Destroy()
	fail("The local catalog opened, but its menu, R6 rig, belt or scarf is missing.")
end

local VERSIONS = {"V3", "V3 with V4 aspect", "V4", "V5"}
local MORPHS = {
	"White neko",
	"Neko Veil",
	"Psycho Neko",
	"Bunny neko",
	"Bunny neko (alt that remove accessories)",
}
local DISPLAY_NAMES = {
	["White neko"] = "White neko",
	["Neko Veil"] = "Neko Veil",
	["Psycho Neko"] = "Psycho Neko",
	["Bunny neko"] = 'Bunny "neko"',
	["Bunny neko (alt that remove accessories)"] = 'Bunny "neko" [alt]',
	[CUSTOM_MORPH_NAME] = "Custom Neko",
}
environment.CaelusLegacyNekoConfig = {
	order = {
		"Cafe Neko",
		"Cowboy Neko",
		"Dino Neko",
		"McDonalds Neko",
		"Midnight Neko",
		"Miku Neko",
		"Brazil Miku",
		"Neko V5",
		"Noob Neko",
		"Pink Cow Girl",
		"Snow Fox Neko",
		"SWAT Neko",
		"Tiny Neko",
	},
	variants = {
		["Cafe Neko"] = {file = "CafeNeko.rbxm", display = "Cafe Neko"},
		["Cowboy Neko"] = {file = "CowboyNeko.rbxm", display = "Cowboy Neko"},
		["Dino Neko"] = {file = "DinoNeko.rbxm", display = "Dino Neko"},
		["McDonalds Neko"] = {file = "McDonaldsNeko.rbxm", display = "McDonald's Neko"},
		["Midnight Neko"] = {file = "MidnightNeko.rbxm", display = "Midnight Neko"},
		["Miku Neko"] = {file = "MikuNeko.rbxm", display = "Miku Neko"},
		["Brazil Miku"] = {
			file = "BrazilMikuNeko.rbxm",
			display = "Brazil Miku",
			accentColor = Color3.fromRGB(255, 102, 204),
			normalizeSkinDetails = true,
		},
		["Neko V5"] = {
			file = "MelanieNeko.rbxm",
			display = "Neko V5",
			customController = true,
			preserveEverything = true,
			keys = {"F", "R", "Z", "X", "C", "V", "Y", "T", "P", "0", "M", "N"},
		},
		["Noob Neko"] = {file = "NoobNeko.rbxm", display = "Noob Neko", skinColor = Color3.fromRGB(245, 205, 48), accentColor = Color3.fromRGB(13, 105, 172)},
		["Pink Cow Girl"] = {file = "PinkCowGirl.rbxm", display = "Pink Cow Girl"},
		["Snow Fox Neko"] = {file = "SnowFoxNeko.rbxm", display = "Snow Fox Neko"},
		["SWAT Neko"] = {file = "SwatNeko.rbxm", display = "SWAT Neko"},
		["Tiny Neko"] = {file = "TinyNeko.rbxm", display = "Tiny Neko"},
	},
	buttons = {},
	baseY = 0.405,
	stepY = 0.075,
}
for _, legacyName in ipairs(environment.CaelusLegacyNekoConfig.order) do
	local config = environment.CaelusLegacyNekoConfig.variants[legacyName]
	DISPLAY_NAMES[legacyName] = config and config.display or legacyName
end
local KEYS_BY_VERSION = {
	["V3"] = {"F", "R", "Z", "X", "C", "V", "Y", "T", "G", "P", "0", "M", "N"},
	["V3 with V4 aspect"] = {"F", "U", "B", "R", "K", "Z", "X", "C", "V", "Y", "T", "G", "J", "Q", "E", "P", "M", "N"},
	["V4"] = {"F", "U", "B", "R", "K", "Z", "X", "C", "V", "Y", "T", "G", "J", "Q", "E", "P", "M", "N"},
	["V5"] = {"F", "R", "E", "Y", "L", "U", "H", "J", "K", "C", "B", "V", "N", "M"},
}

for _, versionName in ipairs(VERSIONS) do
	local version = catalog:FindFirstChild(versionName)
	if not version then
		catalog:Destroy()
		fail("Missing original version: " .. versionName)
	end
	for _, morphName in ipairs(MORPHS) do
		local controller = version:FindFirstChild(morphName)
		if not (controller and controller:IsA("LocalScript")) then
			catalog:Destroy()
			fail("Missing original controller: " .. versionName .. " / " .. morphName)
		end
	end
end

local compiler = loadstring
if type(compiler) ~= "function" then
	catalog:Destroy()
	fail("This executor has no loadstring support for the embedded original controllers.")
end

local gui = menuTemplate
gui.Parent = playerGui
environment.CaelusNekoBootStatus("Caelus Neko 3.32.2: building menu...")
local main = gui:FindFirstChild("Frame")
local selectionTabs = main and main:FindFirstChild("selection tabs")
local morphList = selectionTabs and selectionTabs:FindFirstChild("ScrollingFrame")
local tabs = main and main:FindFirstChild("Tabs")
local versionFolder = tabs and tabs:FindFirstChild("version container")
local selectedText = main and main:FindFirstChild("actual selected")
local selectedCaption = main and main:FindFirstChild("Selected")
local selectedValue = main and main:FindFirstChild("StringType")
local r6Button = tabs and tabs:FindFirstChild("R6")
local respawnButton = tabs and tabs:FindFirstChild("Respawn")
local keysButton = tabs and tabs:FindFirstChild("soon")
if not (main and morphList and versionFolder and selectedText and selectedValue and r6Button and respawnButton and keysButton) then
	gui:Destroy()
	catalog:Destroy()
	fail("The original Neko hub V1 controls are incomplete.")
end

for _, descendant in ipairs(gui:GetDescendants()) do
	if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
		local normalizedText = string.lower(
			(descendant.Text or ""):gsub("%s+", " ")
		)

		if normalizedText == "neko hub"
			or normalizedText == "neko hub v1"
			or normalizedText == "caelus neko hub"
		then
			descendant.Text = "Neko Morphs"
		end
	end
end

main.Active = true
main.Draggable = true
if selectedCaption and selectedCaption:IsA("TextLabel") then selectedCaption.Text = "Neko Selected:" end
keysButton.Text = "Keys"

if environment.CaelusNekoHubLaunchToken ~= startupLog then
	gui:Destroy()
	catalog:Destroy()
	return
end

local state = {
	catalog = catalog,
	gui = gui,
	connections = {},
	followConnections = {},
	hidden = {},
	hiddenSurfaceVisuals = {},
	visibilityBinding = nil,
	shadow = nil,
	controller = nil,
	command = nil,
	armorEvent = nil,
	selectedMorph = nil,
	selectedVersion = "V4",
	customNeko = nil,
	activeCustomNeko = nil,
	activeLegacyNeko = nil,
	activeLegacySkinColor = nil,
	activeMorph = nil,
	activeVersion = nil,
	sessionSerial = 0,
	destroyed = false,
	keyPanelOpen = UserInputService.TouchEnabled,
	lowerArmorOn = true,
	upperArmorOn = true,
	armorReady = false,
	lowerArmorParts = {},
	upperArmorParts = {},
	lowerArmorLookup = {},
	upperArmorLookup = {},
	lowerBaseWearParts = {},
	lowerBaseWearBindings = {},
	upperScarfParts = {},
	upperScarfBindings = {},
	armorPartTransparency = {},
	visualParts = {},
	visualPartLookup = {},
	morphPantsTemplate = nil,
	morphShirtTemplate = nil,
	morphShirtGraphicTemplate = nil,
	activeTouches = {},
	realCharacter = nil,
	realHumanoid = nil,
	realRoot = nil,
	wearRoot = nil,
	appearanceStorage = nil,
	originalAccessoryTransparency = {},
	originalHeadVisualTransparency = {},
	bodyColorSnapshots = {},
	directWearInstances = {},
	motorSnapshots = {},
	posePairs = {},
	driverCoreParts = {},
	animateScript = nil,
	animateWasDisabled = nil,
	savedPresets = {},
	presetButtons = {},
	editingPresetName = nil,
	editingPresetPath = nil,
	customDraftUse3DPants = true,
	originalClawRunSpeedEnabled = false,
	clawsActive = false,
	clawRunSpeed = 35.2,
	clawBaseWalkSpeed = nil,
	clothingGuard = {
		props = {
			Shirt = "ShirtTemplate",
			Pants = "PantsTemplate",
			ShirtGraphic = "Graphic",
		},
		priority = {},
		objects = {},
		expected = {},
		watched = {},
		connections = {},
	},
}
environment.CaelusNekoOriginalRuntimeSession = state
environment.CaelusNekoOriginalSession = state
environment.CaelusNekoShadowSession = state
startupLog("Hub session ready")

local function remember(connection)
	table.insert(state.connections, connection)
	return connection
end

local function rememberFollow(connection)
	table.insert(state.followConnections, connection)
	return connection
end

local function disconnectArray(array)
	for _, connection in ipairs(array) do
		pcall(function() connection:Disconnect() end)
	end
	table.clear(array)
end

local function playNamedSound(root, soundName)
	local sound = root and root:FindFirstChild(soundName, true)
	if sound and sound:IsA("Sound") then pcall(function() sound:Play() end) end
end

local function flashButton(button, message)
	if not (button and button:IsA("TextButton")) then return end
	local old = button.Text
	button.Text = tostring(message)
	task.delay(0.8, function()
		if button and button.Parent then button.Text = old end
	end)
end

local function realCharacter(timeoutSeconds)
	local deadline = os.clock() + (timeoutSeconds or 20)
	repeat
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and humanoid and root and root:IsA("BasePart") then
			return character, humanoid, root
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return nil, nil, nil
end

local function zeroVelocity(part)
	pcall(function() part.AssemblyLinearVelocity = Vector3.zero end)
	pcall(function() part.AssemblyAngularVelocity = Vector3.zero end)
	pcall(function() part.Velocity = Vector3.zero end)
	pcall(function() part.RotVelocity = Vector3.zero end)
end

local function makePartNonPhysical(part, stopMotion)
	if not (part and part:IsA("BasePart")) then return end
	part.CanCollide = false
	pcall(function() part.CanTouch = false end)
	pcall(function() part.CanQuery = false end)
	part.Massless = true
	if stopMotion then zeroVelocity(part) end
end

local function colorsClose(left, right)
	return math.abs(left.R - right.R) <= 0.01
		and math.abs(left.G - right.G) <= 0.01
		and math.abs(left.B - right.B) <= 0.01
end

local function recolorMatchingParts(root, sourceColor, targetColor)
	if not root then return end
	if root:IsA("BasePart") and colorsClose(root.Color, sourceColor) then
		root.Color = targetColor
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and colorsClose(descendant.Color, sourceColor) then
			descendant.Color = targetColor
		end
	end
end

local function setRigSkinColor(shadow, skinColor)
	for _, name in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
		local part = shadow:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = skinColor
		end
	end
end

local function setBodyColors(bodyColors, skinColor)
	if not (bodyColors and bodyColors:IsA("BodyColors")) then return end
	for _, propertyName in ipairs({
		"HeadColor3",
		"LeftArmColor3",
		"LeftLegColor3",
		"RightArmColor3",
		"RightLegColor3",
		"TorsoColor3",
	}) do
		pcall(function() bodyColors[propertyName] = skinColor end)
	end
end

environment.CaelusNormalizeLegacySkinDetails = function(controller, skinColor)
	if not controller or typeof(skinColor) ~= "Color3" then return end
	for _, containerName in ipairs({
		"TorsoYes",
		"LArmYes",
		"RArmYes",
		"LLegYes",
		"RLegYes",
	}) do
		local container = controller:FindFirstChild(containerName)
		if container then
			recolorMatchingParts(container, DEFAULT_WHITE_NEKO_SKIN, skinColor)
			recolorMatchingParts(
				container,
				Color3.fromRGB(234, 184, 146),
				skinColor
			)
		end
	end
	controller:SetAttribute("CaelusLegacySkinDetailsNormalized", true)
end

local function trackVisualPart(part, stopMotion)
	if not (part and part:IsA("BasePart")) then return end
	if not state.visualPartLookup[part] then
		state.visualPartLookup[part] = true
		table.insert(state.visualParts, part)
	end
	makePartNonPhysical(part, stopMotion)
end

local function trackVisualModel(model, stopMotion)
	if model:IsA("BasePart") then trackVisualPart(model, stopMotion) end
	for _, descendant in ipairs(model:GetDescendants()) do
		trackVisualPart(descendant, stopMotion)
	end
end

local function enforceVisualPhysics()
	for index = #state.visualParts, 1, -1 do
		local part = state.visualParts[index]
		if part and part.Parent then
			makePartNonPhysical(part, false)
		else
			state.visualPartLookup[part] = nil
			table.remove(state.visualParts, index)
		end
	end
end

local function moveWholeRigToRoot(model, visualRoot, target)
	local delta = target * visualRoot.CFrame:Inverse()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CFrame = delta * descendant.CFrame
			zeroVelocity(descendant)
		end
	end
	visualRoot.CFrame = target
	zeroVelocity(visualRoot)
end

local function unbindVisibility()
	if state.visibilityBinding then
		pcall(function() RunService:UnbindFromRenderStep(state.visibilityBinding) end)
		state.visibilityBinding = nil
	end
end

local function restoreRealVisibility()
	unbindVisibility()
	for part, value in pairs(state.hidden) do
		if part and part.Parent then
			pcall(function() part.LocalTransparencyModifier = value end)
		end
	end
	table.clear(state.hidden)
	for visual, value in pairs(state.hiddenSurfaceVisuals) do
		if visual and visual.Parent then
			pcall(function() visual.Transparency = value end)
		end
	end
	table.clear(state.hiddenSurfaceVisuals)
end

local function hideRealPart(part)
	if not (part and part:IsA("BasePart")) then return end
	if state.hidden[part] == nil then
		state.hidden[part] = part.LocalTransparencyModifier
	end
	part.LocalTransparencyModifier = 1
end

local function hideRealSurfaceVisual(visual)
	if not (visual and (visual:IsA("Decal") or visual:IsA("Texture"))) then return end
	if state.hiddenSurfaceVisuals[visual] == nil then
		state.hiddenSurfaceVisuals[visual] = visual.Transparency
	end
	visual.Transparency = 1
end

local function hideRealDescendant(descendant)
	hideRealPart(descendant)
	hideRealSurfaceVisual(descendant)
end

local function enforceRealVisibility()
	for part in pairs(state.hidden) do
		if part and part.Parent then
			part.LocalTransparencyModifier = 1
		else
			state.hidden[part] = nil
		end
	end
	for visual in pairs(state.hiddenSurfaceVisuals) do
		if visual and visual.Parent then
			visual.Transparency = 1
		else
			state.hiddenSurfaceVisuals[visual] = nil
		end
	end
end

local function hideRealVisibility(character)
	restoreRealVisibility()
	for _, descendant in ipairs(character:GetDescendants()) do
		hideRealDescendant(descendant)
	end
	rememberFollow(character.DescendantAdded:Connect(hideRealDescendant))
end


local PRESET_ROOT = "CaelusNekoShadow"
local PRESET_FOLDER = PRESET_ROOT .. "/CustomNekos"
local DIRECT_BODY_NAMES = {
	"Head",
	"Torso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
	"HumanoidRootPart",
}

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

local FILE_API = {
	isfolder = executorFunction("isfolder"),
	isfile = executorFunction("isfile"),
	makefolder = executorFunction("makefolder"),
	listfiles = executorFunction("listfiles"),
	readfile = executorFunction("readfile"),
	writefile = executorFunction("writefile"),
	delfile = executorFunction("delfile"),
}

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function validVersion(versionName)
	for _, candidate in ipairs(VERSIONS) do
		if candidate == versionName then return true end
	end
	return false
end

local function normalizePresetName(value)
	local name = trim(value)
	if name == "" then return nil, "Give your Neko a name." end
	if #name > 32 then return nil, "Name must be 32 characters or less." end
	if name:find("[^%w%s_%-]") then
		return nil, "Name can use letters, numbers, spaces, _ and -."
	end
	return name, nil
end

local function presetFileName(name)
	return (name:gsub("%s+", "_"):gsub("[^%w_%-]", "")) .. ".json"
end

local function ensurePresetFolder()
	if not (FILE_API.makefolder and FILE_API.writefile) then
		return false, "This executor does not support makefolder/writefile."
	end

	local function ensure(path)
		if FILE_API.isfolder then
			local ok, exists = pcall(FILE_API.isfolder, path)
			if ok and exists then return true end
		end
		local ok = pcall(FILE_API.makefolder, path)
		if ok then return true end
		if FILE_API.isfolder then
			local verifyOk, exists = pcall(FILE_API.isfolder, path)
			return verifyOk and exists
		end
		return false
	end

	if not ensure(PRESET_ROOT) then
		return false, "Could not create " .. PRESET_ROOT .. "."
	end
	if not ensure(PRESET_FOLDER) then
		return false, "Could not create " .. PRESET_FOLDER .. "."
	end
	return true, nil
end

local function serializePreset(config)
	return {
		format = 1,
		name = config.name,
		version = validVersion(config.version) and config.version or "V4",
		skin = {
			math.floor(config.skinColor.R * 255 + 0.5),
			math.floor(config.skinColor.G * 255 + 0.5),
			math.floor(config.skinColor.B * 255 + 0.5),
		},
		assetIds = config.assetIds,
		use3DPants = config.use3DPants ~= false,
	}
end

local function deserializePreset(data)
	if type(data) ~= "table" then return nil end
	local name = type(data.name) == "string" and normalizePresetName(data.name) or nil
	if not name then return nil end
	local skin = data.skin
	if type(skin) ~= "table" then return nil end
	local red = tonumber(skin[1])
	local green = tonumber(skin[2])
	local blue = tonumber(skin[3])
	if not (red and green and blue) then return nil end
	red = math.clamp(math.floor(red + 0.5), 0, 255)
	green = math.clamp(math.floor(green + 0.5), 0, 255)
	blue = math.clamp(math.floor(blue + 0.5), 0, 255)

	local assetIds = {}
	local seen = {}
	if type(data.assetIds) == "table" then
		for _, value in ipairs(data.assetIds) do
			local assetId = tonumber(value)
			if assetId and assetId > 0 and not seen[assetId] then
				seen[assetId] = true
				table.insert(assetIds, assetId)
				if #assetIds >= MAX_CUSTOM_ASSETS then break end
			end
		end
	end

	return {
		name = name,
		version = validVersion(data.version) and data.version or "V4",
		skinColor = Color3.fromRGB(red, green, blue),
		assetIds = assetIds,
		use3DPants = data.use3DPants ~= false,
	}
end

function FILE_API.presetIndexPath()
	return PRESET_FOLDER .. "/_index.json"
end

function FILE_API.readPresetIndex()
	local names = {}
	if not FILE_API.readfile then
		return names
	end

	local ok, contents = pcall(FILE_API.readfile, FILE_API.presetIndexPath())
	if not ok or type(contents) ~= "string" then
		return names
	end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(contents)
	end)
	if not decodeOk or type(decoded) ~= "table" then
		return names
	end

	local source = type(decoded.files) == "table" and decoded.files or decoded
	local seen = {}
	for _, fileName in ipairs(source) do
		if type(fileName) == "string" then
			local normalized = fileName:gsub("\\", "/"):match("([^/]+)$")
			if normalized
			and normalized ~= "_index.json"
			and string.lower(normalized):sub(-5) == ".json"
			and not seen[normalized] then
				seen[normalized] = true
				table.insert(names, normalized)
			end
		end
	end

	return names
end

function FILE_API.writePresetIndex()
	if not FILE_API.writefile then
		return false
	end

	local files = {}
	local seen = {}
	for _, preset in pairs(state.savedPresets) do
		local path = preset.filePath
		local fileName = type(path) == "string"
			and path:gsub("\\", "/"):match("([^/]+)$")
			or presetFileName(preset.name)

		if fileName
		and fileName ~= "_index.json"
		and not seen[fileName] then
			seen[fileName] = true
			table.insert(files, fileName)
		end
	end
	table.sort(files, function(left, right)
		return string.lower(left) < string.lower(right)
	end)

	local encodeOk, encoded = pcall(function()
		return HttpService:JSONEncode({
			format = 1,
			files = files,
		})
	end)
	if not encodeOk then
		return false
	end

	local writeOk = pcall(FILE_API.writefile, FILE_API.presetIndexPath(), encoded)
	return writeOk
end

local function loadSavedPresets()
	table.clear(state.savedPresets)

	if not (FILE_API.readfile and FILE_API.writefile) then
		startupLog("Preset persistence unavailable: readfile/writefile missing.")
		return
	end

	local folderReady, folderProblem = ensurePresetFolder()
	if not folderReady then
		startupLog("Preset folder unavailable: " .. tostring(folderProblem))
		return
	end

	local paths = {}
	local seenPaths = {}

	local function rememberPath(path)
		if type(path) ~= "string" then
			return
		end

		local normalized = path:gsub("\\", "/")
		local fileName = normalized:match("([^/]+)$")
		if not fileName
		or fileName == "_index.json"
		or string.lower(fileName):sub(-5) ~= ".json" then
			return
		end

		local canonical = PRESET_FOLDER .. "/" .. fileName

		if not seenPaths[canonical] then
			seenPaths[canonical] = true
			table.insert(paths, canonical)
		end
	end

	if FILE_API.listfiles then
		local listOk, files = pcall(FILE_API.listfiles, PRESET_FOLDER)
		if listOk and type(files) == "table" then
			for _, path in ipairs(files) do
				rememberPath(path)
			end
		end
	end

	for _, fileName in ipairs(FILE_API.readPresetIndex()) do
		rememberPath(PRESET_FOLDER .. "/" .. fileName)
	end

	for _, path in ipairs(paths) do
		local readOk, contents = pcall(FILE_API.readfile, path)
		if readOk and type(contents) == "string" then
			local decodeOk, data = pcall(function()
				return HttpService:JSONDecode(contents)
			end)

			if decodeOk then
				local preset = deserializePreset(data)
				if preset then
					preset.filePath = path
					state.savedPresets[preset.name] = preset
				end
			end
		end
	end

	FILE_API.writePresetIndex()
	startupLog(
		"Loaded "
			.. tostring(#FILE_API.readPresetIndex())
			.. " persistent Custom Neko preset file(s)."
	)
end

local function savePresetToDisk(config, previousPath)
	local ready, problem = ensurePresetFolder()
	if not ready then
		return false, problem
	end

	local encodedOk, encoded = pcall(function()
		return HttpService:JSONEncode(serializePreset(config))
	end)
	if not encodedOk then
		return false, "Could not encode preset: " .. tostring(encoded)
	end

	local preferredPath = PRESET_FOLDER .. "/" .. presetFileName(config.name)
	local path = preferredPath

	if previousPath
	and previousPath ~= preferredPath
	and not FILE_API.delfile then
		path = previousPath
	end

	local writeOk, writeProblem = pcall(FILE_API.writefile, path, encoded)
	if not writeOk then
		return false, "Could not save preset: " .. tostring(writeProblem)
	end

	if previousPath
	and previousPath ~= path
	and FILE_API.delfile then
		local deleteOk, deleteProblem = pcall(FILE_API.delfile, previousPath)
		if not deleteOk then
			startupLog(
				"Preset renamed, but old file could not be removed: "
					.. tostring(deleteProblem)
			)
		end
	end

	return true, path
end

local function copyCustomConfig(config)
	if not config then return nil end
	local assetIds = {}
	for _, assetId in ipairs(config.assetIds or {}) do
		table.insert(assetIds, assetId)
	end
	return {
		name = config.name,
		version = config.version,
		skinColor = config.skinColor,
		assetIds = assetIds,
		use3DPants = config.use3DPants ~= false,
	}
end

local function restoreDirectWear()
	local character = state.realCharacter

	if state.clothingGuard and type(state.clothingGuard.disconnect) == "function" then
		state.clothingGuard:disconnect()
	end

	for _, pair in ipairs(state.posePairs) do
		local motor = pair.motor
		if motor and motor.Parent then
			pcall(function() motor.Transform = pair.originalTransform or CFrame.new() end)
		end
	end
	table.clear(state.posePairs)
	table.clear(state.motorSnapshots)

	if state.animateScript and state.animateScript.Parent and state.animateWasDisabled ~= nil then
		pcall(function() state.animateScript.Disabled = state.animateWasDisabled end)
	end
	state.animateScript = nil
	state.animateWasDisabled = nil

	for part, value in pairs(state.originalAccessoryTransparency) do
		if part and part.Parent then
			pcall(function() part.LocalTransparencyModifier = value end)
		end
	end
	table.clear(state.originalAccessoryTransparency)

	for visual, value in pairs(state.originalHeadVisualTransparency) do
		if visual and visual.Parent then
			pcall(function() visual.Transparency = value end)
		end
	end
	table.clear(state.originalHeadVisualTransparency)

	for part, color in pairs(state.bodyColorSnapshots) do
		if part and part.Parent then
			pcall(function() part.Color = color end)
		end
	end
	table.clear(state.bodyColorSnapshots)

	for _, instance in ipairs(state.directWearInstances) do
		if instance and instance.Parent then
			pcall(function() instance:Destroy() end)
		end
	end
	table.clear(state.directWearInstances)

	if state.wearRoot and state.wearRoot.Parent then
		pcall(function() state.wearRoot:Destroy() end)
	end
	state.wearRoot = nil

	if state.appearanceStorage and state.appearanceStorage.Parent and character and character.Parent then
		for _, child in ipairs(state.appearanceStorage:GetChildren()) do
			child.Parent = character
		end
		state.appearanceStorage:Destroy()
	elseif state.appearanceStorage and state.appearanceStorage.Parent then
		state.appearanceStorage:Destroy()
	end
	state.appearanceStorage = nil

	table.clear(state.driverCoreParts)
	state.realCharacter = nil
	state.realHumanoid = nil
	state.realRoot = nil
end

local function connectedDriverWeld(parent, part0, part1, preferredName)
	if preferredName then
		local candidate = parent and parent:FindFirstChild(preferredName)
		if candidate and candidate:IsA("JointInstance")
		and candidate.Part0 == part0 and candidate.Part1 == part1 then
			return candidate
		end
	end
	if not parent then return nil end
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("JointInstance")
		and child.Part0 == part0 and child.Part1 == part1 then
			return child
		end
	end
	return nil
end

local function connectClientAnimationStep(callback)
	local ok, signal = pcall(function()
		return RunService.PreSimulation
	end)
	if ok and signal then
		local connectOk, connection = pcall(function()
			return signal:Connect(callback)
		end)
		if connectOk and connection then
			return connection, "PreSimulation"
		end
	end

	return RunService.Stepped:Connect(function()
		callback()
	end), "Stepped fallback"
end

local function setupDirectPose(driver, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		return false, "Direct Wear requires an R6 character."
	end

	local driverRoot = driver:FindFirstChild("HumanoidRootPart")
	local driverTorso = driver:FindFirstChild("Torso")
	local realRoot = character:FindFirstChild("HumanoidRootPart")
	local realTorso = character:FindFirstChild("Torso")
	if not (driverRoot and driverTorso and realRoot and realTorso) then
		return false, "R6 root/torso is missing."
	end

	local definitions = {
		{
			driver = connectedDriverWeld(driverRoot, driverRoot, driverTorso, "RootJoint"),
			motor = realRoot:FindFirstChild("RootJoint"),
		},
		{
			driver = connectedDriverWeld(driverTorso, driverTorso, driver:FindFirstChild("Head"), "Neck"),
			motor = realTorso:FindFirstChild("Neck"),
		},
		{
			driver = connectedDriverWeld(driverTorso, driverTorso, driver:FindFirstChild("Right Arm")),
			motor = realTorso:FindFirstChild("Right Shoulder"),
		},
		{
			driver = connectedDriverWeld(driverTorso, driverTorso, driver:FindFirstChild("Left Arm")),
			motor = realTorso:FindFirstChild("Left Shoulder"),
		},
		{
			driver = connectedDriverWeld(driverTorso, driverTorso, driver:FindFirstChild("Right Leg")),
			motor = realTorso:FindFirstChild("Right Hip"),
		},
		{
			driver = connectedDriverWeld(driverTorso, driverTorso, driver:FindFirstChild("Left Leg")),
			motor = realTorso:FindFirstChild("Left Hip"),
		},
	}

	table.clear(state.posePairs)
	for _, definition in ipairs(definitions) do
		local driverJoint = definition.driver
		local motor = definition.motor
		if not (driverJoint and motor and motor:IsA("Motor6D")) then
			table.clear(state.posePairs)
			return false, "Could not map the White Neko R6 animation joints."
		end
		table.insert(state.posePairs, {
			driverJoint = driverJoint,
			motor = motor,
			baseC0 = motor.C0,
			baseC1 = motor.C1,
			originalTransform = motor.Transform,
		})
	end

	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		state.animateScript = animate
		state.animateWasDisabled = animate.Disabled
		animate.Disabled = true
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function() track:Stop(0) end)
		end

		local animationPlayedOk, animationPlayedConnection = pcall(function()
			return animator.AnimationPlayed:Connect(function(track)
				if state.realHumanoid ~= humanoid then return end
				pcall(function() track:Stop(0) end)
			end)
		end)
		if animationPlayedOk and animationPlayedConnection then
			rememberFollow(animationPlayedConnection)
		end
	end

	return true, nil
end

local function syncDirectPose()
	for _, pair in ipairs(state.posePairs) do
		local driverJoint = pair.driverJoint
		local motor = pair.motor
		if driverJoint and driverJoint.Parent and motor and motor.Parent then
			local driverTransform = CFrame.new()

			if driverJoint:IsA("Motor6D") then
				driverTransform = driverJoint.Transform
			end

			local desiredRelative =
				driverJoint.C0
				* driverTransform
				* driverJoint.C1:Inverse()

			pcall(function()
				motor.Transform =
					pair.baseC0:Inverse()
					* desiredRelative
					* pair.baseC1
			end)
		end
	end
end

local function enforceDirectWear()
	for part in pairs(state.originalAccessoryTransparency) do
		if part and part.Parent then
			part.LocalTransparencyModifier = 1
		end
	end
	for visual in pairs(state.originalHeadVisualTransparency) do
		if visual and visual.Parent then
			visual.Transparency = 1
		end
	end
	for _, part in ipairs(state.driverCoreParts) do
		if part and part.Parent then
			part.LocalTransparencyModifier = 1
		end
	end

	if state.realCharacter
	and state.activeLegacyNeko
	and typeof(state.activeLegacySkinColor) == "Color3" then
		setRigSkinColor(state.realCharacter, state.activeLegacySkinColor)
		local bodyColors = state.realCharacter:FindFirstChildOfClass("BodyColors")
		if bodyColors and bodyColors:GetAttribute("CaelusDirectWear") == true then
			setBodyColors(bodyColors, state.activeLegacySkinColor)
		end
	end
end

local function moveOriginalAppearanceToStorage(character)
	local storage = Instance.new("Folder")
	storage.Name = "CaelusOriginalAppearanceStorage"
	storage.Parent = character
	state.appearanceStorage = storage

	for _, child in ipairs(character:GetChildren()) do
		if child ~= storage and (
			child:IsA("Shirt")
			or child:IsA("Pants")
			or child:IsA("ShirtGraphic")
			or child:IsA("BodyColors")
			or child:IsA("CharacterMesh")
		) then
			child.Parent = storage
		end
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Hat") then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") then
					state.originalAccessoryTransparency[descendant] = descendant.LocalTransparencyModifier
					descendant.LocalTransparencyModifier = 1
				end
			end
		end
	end

	local head = character:FindFirstChild("Head")
	if head then
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then
				state.originalHeadVisualTransparency[child] = child.Transparency
				child.Transparency = 1
			end
		end
	end
end

local function copyDriverAppearance(driver, character, driverToReal)
	for driverPart, realPart in pairs(driverToReal) do
		if driverPart.Name ~= "HumanoidRootPart" then
			state.bodyColorSnapshots[realPart] = realPart.Color
			realPart.Color = driverPart.Color
		end
	end

	for _, className in ipairs({"Shirt", "Pants", "ShirtGraphic", "BodyColors", "CharacterMesh"}) do
		for _, child in ipairs(driver:GetChildren()) do
			if child:IsA(className) then
				local clone = child:Clone()
				clone:SetAttribute("CaelusDirectWear", true)
				clone.Parent = character
				table.insert(state.directWearInstances, clone)
			end
		end
	end
end

local function retargetJoint(joint, driverToReal)
	local ok0, part0 = pcall(function() return joint.Part0 end)
	local ok1, part1 = pcall(function() return joint.Part1 end)
	if ok0 and driverToReal[part0] then
		pcall(function() joint.Part0 = driverToReal[part0] end)
	end
	if ok1 and driverToReal[part1] then
		pcall(function() joint.Part1 = driverToReal[part1] end)
	end
end

function state:mountNekoV5OriginalLegShells(
	driver,
	character,
	wearRoot
)
	if self.activeLegacyNeko ~= "Neko V5" then
		return
	end

	for _, legName in ipairs({"Left Leg", "Right Leg"}) do
		local sourceLeg = driver:FindFirstChild(legName)
		local realLeg = character:FindFirstChild(legName)

		if sourceLeg
			and sourceLeg:IsA("BasePart")
			and realLeg
			and realLeg:IsA("BasePart")
		then
			local shell = sourceLeg:Clone()
			shell.Name =
				"CaelusNekoV5Original"
				.. legName:gsub("%s+", "")
			shell:SetAttribute("CaelusDirectWear", true)

			for _, descendant in ipairs(shell:GetDescendants()) do
				if descendant:IsA("JointInstance")
					or descendant:IsA("WeldConstraint")
					or descendant:IsA("Script")
					or descendant:IsA("LocalScript")
				then
					descendant:Destroy()
				end
			end

			shell.Anchored = false
			shell.CFrame = realLeg.CFrame
			makePartNonPhysical(shell, true)

			pcall(function()
				shell.LocalTransparencyModifier = 0
			end)

			shell.Parent = wearRoot

			local weld = Instance.new("WeldConstraint")
			weld.Name = "CaelusNekoV5LegWeld"
			weld.Part0 = realLeg
			weld.Part1 = shell
			weld.Parent = shell

			table.insert(self.directWearInstances, shell)
		end
	end
end

local function mountDirectWear(driver, character, humanoid, realRoot)
	if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		return false, "Direct Wear only supports R6. Switch the game character to R6 first."
	end

	local driverToReal = {}
	for _, name in ipairs(DIRECT_BODY_NAMES) do
		local driverPart = driver:FindFirstChild(name)
		local realPart = character:FindFirstChild(name)
		if not (driverPart and driverPart:IsA("BasePart") and realPart and realPart:IsA("BasePart")) then
			return false, "Direct Wear is missing R6 part: " .. name
		end
		driverToReal[driverPart] = realPart
		table.insert(state.driverCoreParts, driverPart)
	end

	state.realCharacter = character
	state.realHumanoid = humanoid
	state.realRoot = realRoot

	moveOriginalAppearanceToStorage(character)
	copyDriverAppearance(driver, character, driverToReal)
	state.clothingGuard:start(character)

	local wearRoot = Instance.new("Model")
	wearRoot.Name = "CaelusNekoWear"
	wearRoot:SetAttribute("CaelusDirectWear", true)
	wearRoot.Parent = character
	state.wearRoot = wearRoot

	state:mountNekoV5OriginalLegShells(
		driver,
		character,
		wearRoot
	)

	local realTorso = character:FindFirstChild("Torso")
	for _, modelName in ipairs({"CaelusLowerBelt", "CaelusUpperScarf"}) do
		local model = driver:FindFirstChild(modelName)
		if model and model:IsA("Model") then
			model.Parent = wearRoot
		end
	end
	for _, binding in ipairs(state.lowerBaseWearBindings) do
		binding.anchor = realTorso
	end
	for _, binding in ipairs(state.upperScarfBindings) do
		binding.anchor = realTorso
	end

	local effects = driver:FindFirstChild("Effects")
	local visualParts = {}
	local visualLookup = {}
	for _, descendant in ipairs(driver:GetDescendants()) do
		if descendant:IsA("BasePart")
		and not driverToReal[descendant]
		and descendant:GetAttribute("CaelusHiddenControllerAnchor") ~= true
		and not (effects and descendant:IsDescendantOf(effects)) then
			visualLookup[descendant] = true
			table.insert(visualParts, descendant)
		end
	end

	local joints = {}
	for _, descendant in ipairs(driver:GetDescendants()) do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			local ok0, part0 = pcall(function() return descendant.Part0 end)
			local ok1, part1 = pcall(function() return descendant.Part1 end)
			if (ok0 and visualLookup[part0]) or (ok1 and visualLookup[part1]) then
				table.insert(joints, descendant)
			end
		end
	end

	for _, joint in ipairs(joints) do
		retargetJoint(joint, driverToReal)
		joint.Parent = wearRoot
	end

	for _, part in ipairs(visualParts) do
		if part.Parent and part:IsDescendantOf(driver) then
			part.Anchored = false
			makePartNonPhysical(part, true)
			pcall(function() part.LocalTransparencyModifier = 0 end)
			part.Parent = wearRoot
		end
	end

	local driverHead = driver:FindFirstChild("Head")
	local realHead = character:FindFirstChild("Head")
	if driverHead and realHead then
		for _, child in ipairs(driverHead:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:SetAttribute("CaelusDirectWear", true)
				child.Parent = realHead
				table.insert(state.directWearInstances, child)
			end
		end
	end

	for _, part in ipairs(state.driverCoreParts) do
		part.LocalTransparencyModifier = 1
		makePartNonPhysical(part, true)
	end

	local poseReady, poseProblem = setupDirectPose(driver, character)
	if not poseReady then
		restoreDirectWear()
		return false, poseProblem
	end

	local animationConnection, animationMode = connectClientAnimationStep(function()
		if state.realCharacter ~= character or state.shadow ~= driver then return end
		syncDirectPose()
	end)
	rememberFollow(animationConnection)
	startupLog("Client animation mirror active via " .. animationMode)

	syncDirectPose()
	enforceDirectWear()
	return true, nil
end

loadSavedPresets()

local whiteNekoButton = morphList:FindFirstChild("White neko")
if not (whiteNekoButton and whiteNekoButton:IsA("TextButton")) then
	gui:Destroy()
	catalog:Destroy()
	fail("White Neko menu button is missing.")
end

local customAddButton = whiteNekoButton:Clone()
customAddButton.Name = "Add Neko"
customAddButton.Text = "+ Add Neko"
customAddButton.Position = UDim2.new(0.049261082, 0, 0.405, 0)
customAddButton.Parent = morphList

local customEditButton = whiteNekoButton:Clone()
customEditButton.Name = "Modify Neko"
customEditButton.Text = "✎ Modify Selected"
customEditButton.Position = UDim2.new(0.049261082, 0, 0.48, 0)
customEditButton.Parent = morphList

environment.CaelusLegacyNekoConfig.savedStartY = 0.555
environment.CaelusLegacyNekoConfig.baseY =
	environment.CaelusLegacyNekoConfig.savedStartY

for index, legacyName in ipairs(environment.CaelusLegacyNekoConfig.order) do
	local button = whiteNekoButton:Clone()
	button.Name = "Legacy_" .. legacyName
	button.Text = DISPLAY_NAMES[legacyName] or legacyName
	button.Position = UDim2.new(
		0.049261082,
		0,
		environment.CaelusLegacyNekoConfig.baseY
			+ ((index - 1) * environment.CaelusLegacyNekoConfig.stepY),
		0
	)
	button.Parent = morphList
	environment.CaelusLegacyNekoConfig.buttons[legacyName] = button
end

morphList.Active = true
morphList.ScrollingEnabled = true
morphList.ScrollingDirection = Enum.ScrollingDirection.Y
morphList.AutomaticCanvasSize = Enum.AutomaticSize.None

environment.CaelusLegacyNekoConfig.layoutMorphButtons = function()
	if not (morphList and morphList.Parent) then
		return
	end

	local orderedButtons = {}

	for _, morphName in ipairs(MORPHS) do
		local button = morphList:FindFirstChild(morphName)
		if button and button:IsA("GuiButton") then
			table.insert(orderedButtons, button)
		end
	end

	if customAddButton and customAddButton.Parent == morphList then
		table.insert(orderedButtons, customAddButton)
	end

	if customEditButton and customEditButton.Parent == morphList then
		table.insert(orderedButtons, customEditButton)
	end

	for _, button in ipairs(state.presetButtons) do
		if button and button.Parent == morphList then
			table.insert(orderedButtons, button)
		end
	end

	for _, legacyName in ipairs(environment.CaelusLegacyNekoConfig.order) do
		local button = environment.CaelusLegacyNekoConfig.buttons[legacyName]
		if button and button.Parent == morphList then
			table.insert(orderedButtons, button)
		end
	end

	local y = 8
	local gap = 6
	local fallbackHeight = math.max(
		24,
		math.floor((morphList.AbsoluteSize.Y * 0.07) + 0.5)
	)

	for _, button in ipairs(orderedButtons) do
		local height = math.floor(button.AbsoluteSize.Y + 0.5)

		if height < 8 then
			height = math.floor(
				(button.Size.Y.Scale * morphList.AbsoluteSize.Y)
				+ button.Size.Y.Offset
				+ 0.5
			)
		end

		height = math.max(fallbackHeight, height)

		button.Size = UDim2.new(
			button.Size.X.Scale,
			button.Size.X.Offset,
			0,
			height
		)

		button.Position = UDim2.new(
			button.Position.X.Scale,
			button.Position.X.Offset,
			0,
			y
		)

		y = y + height + gap
	end

	local canvasHeight = math.max(
		morphList.AbsoluteSize.Y,
		y + 16
	)

	morphList.CanvasSize = UDim2.fromOffset(0, canvasHeight)

	local maxScroll = math.max(
		0,
		canvasHeight - morphList.AbsoluteSize.Y
	)

	if morphList.CanvasPosition.Y > maxScroll then
		morphList.CanvasPosition = Vector2.new(
			0,
			maxScroll
		)
	end
end

task.defer(environment.CaelusLegacyNekoConfig.layoutMorphButtons)

remember(
	morphList:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(
			environment.CaelusLegacyNekoConfig.layoutMorphButtons
		)
	end)
)


local customPanel = Instance.new("Frame")
customPanel.Name = "CustomNekoPanel"
customPanel.AnchorPoint = Vector2.new(0.5, 0.5)
customPanel.Position = UDim2.fromScale(0.5, 0.5)
customPanel.Size = UDim2.fromOffset(400, 524)
customPanel.BackgroundColor3 = main.BackgroundColor3
customPanel.BackgroundTransparency = math.min(main.BackgroundTransparency, 0.08)
customPanel.BorderSizePixel = 0
customPanel.Visible = false
customPanel.Active = true
customPanel.ZIndex = 50
customPanel.Parent = gui

local customPanelScale = Instance.new("UIScale")
customPanelScale.Parent = customPanel

local function fitCustomPanel()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	customPanelScale.Scale = math.min(1, (viewport.X - 24) / 400, (viewport.Y - 24) / 524)
end
fitCustomPanel()
if workspace.CurrentCamera then
	remember(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCustomPanel))
end

local customCorner = Instance.new("UICorner")
customCorner.CornerRadius = UDim.new(0, 10)
customCorner.Parent = customPanel

local function makeCustomLabel(name, text, position, size, textSize, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 51
	label.Parent = customPanel
	return label
end

local function makeCustomButton(name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(54, 54, 64)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.TextSize = 13
	button.ZIndex = 51
	button.Parent = customPanel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local function makeCustomTextBox(name, position, size, placeholder, font)
	local box = Instance.new("TextBox")
	box.Name = name
	box.Position = position
	box.Size = size
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = font or Enum.Font.Code
	box.PlaceholderText = placeholder
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(245, 245, 245)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
	box.TextSize = 13
	box.ZIndex = 51
	box.Parent = customPanel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = box
	return box
end

local customTitle = makeCustomLabel(
	"Title",
	"Custom Neko",
	UDim2.fromOffset(16, 12),
	UDim2.new(1, -32, 0, 28),
	20,
	true
)

makeCustomLabel(
	"NameCaption",
	"Character name",
	UDim2.fromOffset(16, 45),
	UDim2.new(1, -146, 0, 18),
	13,
	true
)

makeCustomLabel(
	"VersionCaption",
	"Version",
	UDim2.new(1, -130, 0, 45),
	UDim2.fromOffset(114, 18),
	13,
	true
)

local customNameBox = makeCustomTextBox(
	"CharacterName",
	UDim2.fromOffset(16, 66),
	UDim2.new(1, -146, 0, 30),
	"My Neko",
	Enum.Font.Gotham
)

local customVersionButton = makeCustomButton(
	"Version",
	"V4",
	UDim2.new(1, -130, 0, 66),
	UDim2.fromOffset(114, 30)
)

makeCustomLabel(
	"SkinCaption",
	"Skin tone",
	UDim2.fromOffset(16, 105),
	UDim2.new(1, -32, 0, 20),
	14,
	true
)

local skinGrid = Instance.new("Frame")
skinGrid.Name = "SkinGrid"
skinGrid.BackgroundTransparency = 1
skinGrid.Position = UDim2.fromOffset(16, 129)
skinGrid.Size = UDim2.new(1, -32, 0, 76)
skinGrid.ZIndex = 51
skinGrid.Parent = customPanel

local skinGridLayout = Instance.new("UIGridLayout")
skinGridLayout.CellSize = UDim2.fromOffset(86, 32)
skinGridLayout.CellPadding = UDim2.fromOffset(8, 8)
skinGridLayout.FillDirectionMaxCells = 4
skinGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
skinGridLayout.Parent = skinGrid

local selectedSkinLabel = makeCustomLabel(
	"SelectedSkin",
	"",
	UDim2.fromOffset(16, 209),
	UDim2.new(1, -32, 0, 18),
	12,
	false
)

local customColorBox = makeCustomTextBox(
	"CustomColor",
	UDim2.fromOffset(16, 232),
	UDim2.new(1, -111, 0, 32),
	"#RRGGBB or 255,204,153",
	Enum.Font.Code
)

local applyColorButton = makeCustomButton(
	"ApplyColor",
	"Apply",
	UDim2.new(1, -87, 0, 232),
	UDim2.fromOffset(71, 32)
)

makeCustomLabel(
	"AppearanceCaption",
	"Clothing / accessory asset IDs",
	UDim2.fromOffset(16, 274),
	UDim2.new(1, -32, 0, 20),
	14,
	true
)

makeCustomLabel(
	"AppearanceHint",
	"Shirt / Pants / T-Shirt / accessory IDs. Comma / space / newline separated.",
	UDim2.fromOffset(16, 295),
	UDim2.new(1, -32, 0, 30),
	11,
	false
)

local assetBox = makeCustomTextBox(
	"AppearanceIds",
	UDim2.fromOffset(16, 328),
	UDim2.new(1, -32, 0, 72),
	"shirtId, pantsId, hairId, ...",
	Enum.Font.Code
)
assetBox.MultiLine = true
assetBox.TextWrapped = true
assetBox.TextXAlignment = Enum.TextXAlignment.Left
assetBox.TextYAlignment = Enum.TextYAlignment.Top

makeCustomLabel(
	"ThreeDPantsCaption",
	"3D pants geometry",
	UDim2.fromOffset(16, 405),
	UDim2.new(1, -150, 0, 22),
	13,
	true
)

state.custom3DPantsButton = makeCustomButton(
	"Use3DPants",
	"On",
	UDim2.new(1, -126, 0, 402),
	UDim2.fromOffset(110, 28)
)

makeCustomLabel(
	"ThreeDPantsHint",
	"Off keeps 2D pants; belt, pockets, V5 lower pieces and scarf still toggle normally.",
	UDim2.fromOffset(16, 431),
	UDim2.new(1, -32, 0, 24),
	10,
	false
)

local customStatus = makeCustomLabel(
	"Status",
	"",
	UDim2.fromOffset(16, 455),
	UDim2.new(1, -32, 0, 24),
	11,
	false
)

local saveCustomButton = makeCustomButton(
	"Save",
	"Save & Select",
	UDim2.fromOffset(16, 486),
	UDim2.new(0.63, -20, 0, 30)
)
local cancelCustomButton = makeCustomButton(
	"Cancel",
	"Cancel",
	UDim2.new(0.63, 4, 0, 486),
	UDim2.new(0.37, -20, 0, 30)
)

local customDraftSkinColor = DEFAULT_WHITE_NEKO_SKIN
local customDraftVersion = state.selectedVersion or "V4"

local function updateCustomVersionButton()
	customVersionButton.Text = customDraftVersion
end

remember(customVersionButton.Activated:Connect(function()
	local currentIndex = table.find(VERSIONS, customDraftVersion) or 1
	local nextIndex = (currentIndex % #VERSIONS) + 1
	customDraftVersion = VERSIONS[nextIndex]
	customStatus.Text = ""
	updateCustomVersionButton()
	playNamedSound(customPanel, "Clicksound")
end))

state.UpdateCustom3DPantsButton = function()
	if state.custom3DPantsButton and state.custom3DPantsButton.Parent then
		state.custom3DPantsButton.Text = state.customDraftUse3DPants and "On" or "Off"
	end
end

remember(state.custom3DPantsButton.Activated:Connect(function()
	state.customDraftUse3DPants = not state.customDraftUse3DPants
	customStatus.Text = ""
	state.UpdateCustom3DPantsButton()
	playNamedSound(customPanel, "Clicksound")
end))

local function colorToText(color)
	return string.format(
		"RGB %d, %d, %d",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function updateSelectedSkinLabel(name)
	selectedSkinLabel.Text = (name and (name .. "  •  ") or "") .. colorToText(customDraftSkinColor)
end

local function parseColorText(value)
	local hex = string.match(value, "^%s*#?(%x%x%x%x%x%x)%s*$")
	if hex then
		return Color3.fromRGB(
			tonumber(string.sub(hex, 1, 2), 16),
			tonumber(string.sub(hex, 3, 4), 16),
			tonumber(string.sub(hex, 5, 6), 16)
		)
	end
	local red, green, blue = string.match(
		value,
		"^%s*(%d+)%s*[, ]+%s*(%d+)%s*[, ]+%s*(%d+)%s*$"
	)
	red, green, blue = tonumber(red), tonumber(green), tonumber(blue)
	if red and green and blue
	and red >= 0 and red <= 255
	and green >= 0 and green <= 255
	and blue >= 0 and blue <= 255 then
		return Color3.fromRGB(red, green, blue)
	end
	return nil
end

local function parseCustomAssetIds(value)
	local ids = {}
	local seen = {}
	for digits in string.gmatch(value, "%d+") do
		local numeric = tonumber(digits)
		if numeric and numeric > 0 and not seen[numeric] then
			seen[numeric] = true
			table.insert(ids, numeric)
			if #ids > MAX_CUSTOM_ASSETS then
				return nil, "Maximum " .. tostring(MAX_CUSTOM_ASSETS) .. " clothing/accessory assets."
			end
		end
	end
	return ids, nil
end


local function orderedSavedPresets()
	local presets = {}
	for _, preset in pairs(state.savedPresets) do
		table.insert(presets, preset)
	end
	table.sort(presets, function(left, right)
		return string.lower(left.name) < string.lower(right.name)
	end)
	return presets
end

local function refreshPresetButtons()
	for _, button in ipairs(state.presetButtons) do
		if button and button.Parent then
			button:Destroy()
		end
	end
	table.clear(state.presetButtons)

	local presets = orderedSavedPresets()
	local stepY = environment.CaelusLegacyNekoConfig.stepY
	local savedStartY = environment.CaelusLegacyNekoConfig.savedStartY

	for index, preset in ipairs(presets) do
		local button = whiteNekoButton:Clone()
		button.Name = "SavedNeko_" .. preset.name
		button.Text = "★ " .. preset.name
		button.Position = UDim2.new(
			0.049261082,
			0,
			savedStartY + ((index - 1) * stepY),
			0
		)
		button.Parent = morphList
		table.insert(state.presetButtons, button)

		remember(button.MouseEnter:Connect(function()
			playNamedSound(morphList, "Hoversound")
		end))
		remember(button.Activated:Connect(function()
			state.editingPresetName = nil
			state.editingPresetPath = nil
			state.customNeko = copyCustomConfig(preset)
			state.selectedMorph = CUSTOM_MORPH_NAME
			state.selectedVersion = preset.version or state.selectedVersion or "V4"
			selectedText.Text = preset.name
			selectedValue.Value = CUSTOM_MORPH_NAME
			playNamedSound(morphList, "Clicksound")
		end))
	end

	environment.CaelusLegacyNekoConfig.baseY =
		savedStartY + (#presets * stepY)

	task.defer(
		environment.CaelusLegacyNekoConfig.layoutMorphButtons
	)
end

refreshPresetButtons()

for index, preset in ipairs(CUSTOM_SKIN_PRESETS) do
	local button = makeCustomButton(
		"Skin_" .. tostring(index),
		preset.Name,
		UDim2.new(),
		UDim2.fromOffset(86, 32)
	)
	button.LayoutOrder = index
	button.BackgroundColor3 = preset.Color
	local luminance = preset.Color.R * 0.299 + preset.Color.G * 0.587 + preset.Color.B * 0.114
	button.TextColor3 = luminance > 0.62 and Color3.fromRGB(25, 25, 25) or Color3.fromRGB(245, 245, 245)
	button.Parent = skinGrid
	remember(button.Activated:Connect(function()
		customDraftSkinColor = preset.Color
		customColorBox.Text = ""
		customStatus.Text = ""
		updateSelectedSkinLabel(preset.Name)
	end))
end

remember(applyColorButton.Activated:Connect(function()
	local parsed = parseColorText(customColorBox.Text)
	if not parsed then
		customStatus.Text = "Invalid color. Use #RRGGBB or R,G,B."
		return
	end
	customDraftSkinColor = parsed
	customStatus.Text = ""
	updateSelectedSkinLabel("Custom")
end))


local function openCustomPanel(config, editingPreset)
	local saved = config and copyCustomConfig(config) or nil
	customDraftSkinColor = saved and saved.skinColor or DEFAULT_WHITE_NEKO_SKIN
	customDraftVersion = saved and saved.version or state.selectedVersion or "V4"
	state.customDraftUse3DPants = not saved or saved.use3DPants ~= false
	customNameBox.Text = saved and saved.name or ""

	if saved then
		local values = {}
		for _, assetId in ipairs(saved.assetIds or {}) do
			table.insert(values, tostring(assetId))
		end
		assetBox.Text = table.concat(values, ", ")
	else
		assetBox.Text = ""
	end

	state.editingPresetName = editingPreset and editingPreset.name or nil
	state.editingPresetPath = editingPreset and editingPreset.filePath or nil

	customTitle.Text = editingPreset
		and ("Modify " .. editingPreset.name)
		or "Add Custom Neko"
	saveCustomButton.Text = editingPreset and "Save Changes" or "Save & Select"
	customColorBox.Text = ""
	customStatus.Text = ""
	updateCustomVersionButton()
	state.UpdateCustom3DPantsButton()
	updateSelectedSkinLabel(saved and "Saved" or "Neko")
	customPanel.Visible = true
end

local function selectedSavedPreset()
	local current = state.customNeko
	if state.selectedMorph ~= CUSTOM_MORPH_NAME or not current then
		return nil
	end
	return state.savedPresets[current.name]
end

remember(customAddButton.MouseEnter:Connect(function()
	playNamedSound(morphList, "Hoversound")
end))
remember(customAddButton.Activated:Connect(function()
	playNamedSound(morphList, "Clicksound")
	openCustomPanel(nil, nil)
end))

remember(customEditButton.MouseEnter:Connect(function()
	playNamedSound(morphList, "Hoversound")
end))
remember(customEditButton.Activated:Connect(function()
	playNamedSound(morphList, "Clicksound")
	local preset = selectedSavedPreset()
	if not preset then
		flashButton(customEditButton, "Select saved Neko")
		return
	end
	openCustomPanel(preset, preset)
end))

remember(cancelCustomButton.Activated:Connect(function()
	state.editingPresetName = nil
	state.editingPresetPath = nil
	customPanel.Visible = false
end))
remember(saveCustomButton.Activated:Connect(function()
	local name, nameProblem = normalizePresetName(customNameBox.Text)
	if not name then
		customStatus.Text = nameProblem
		return
	end

	local existingWithName = state.savedPresets[name]
	if existingWithName and name ~= state.editingPresetName then
		customStatus.Text = "A saved Neko already uses that name."
		return
	end

	if customColorBox.Text ~= "" then
		local parsed = parseColorText(customColorBox.Text)
		if not parsed then
			customStatus.Text = "Invalid color. Use #RRGGBB or R,G,B."
			return
		end
		customDraftSkinColor = parsed
	end

	local assetIds, problem = parseCustomAssetIds(assetBox.Text)
	if not assetIds then
		customStatus.Text = problem
		return
	end

	local config = {
		name = name,
		version = validVersion(customDraftVersion) and customDraftVersion or "V4",
		skinColor = customDraftSkinColor,
		assetIds = assetIds,
		use3DPants = state.customDraftUse3DPants,
	}

	local previousName = state.editingPresetName
	local previousPath = state.editingPresetPath
	local exported, exportResult = savePresetToDisk(config, previousPath)

	if previousName and previousName ~= name then
		state.savedPresets[previousName] = nil
	end

	state.savedPresets[name] = copyCustomConfig(config)
	if exported then
		state.savedPresets[name].filePath = exportResult
		FILE_API.writePresetIndex()
		startupLog("Saved Custom Neko to executor workspace: " .. tostring(exportResult))
	else
		startupLog("Preset is session-only: " .. tostring(exportResult))
	end
	refreshPresetButtons()

	state.customNeko = copyCustomConfig(config)
	state.selectedMorph = CUSTOM_MORPH_NAME
	state.selectedVersion = config.version
	state.editingPresetName = nil
	state.editingPresetPath = nil
	selectedText.Text = name
	selectedValue.Value = CUSTOM_MORPH_NAME
	customPanel.Visible = false
	playNamedSound(morphList, "Clicksound")
end))


local keyPanel = Instance.new("Frame")
keyPanel.Name = "Keys"
keyPanel.AnchorPoint = Vector2.new(1, 0.5)
keyPanel.Position = UDim2.new(1, -12, 0.5, 0)
keyPanel.Size = UDim2.fromOffset(242, 190)
keyPanel.BackgroundColor3 = main.BackgroundColor3
keyPanel.BackgroundTransparency = main.BackgroundTransparency
keyPanel.BorderSizePixel = 0
keyPanel.Visible = false
keyPanel.Active = true
keyPanel.Parent = gui

local keyPanelCorner = Instance.new("UICorner")
keyPanelCorner.CornerRadius = UDim.new(0, 8)
keyPanelCorner.Parent = keyPanel

local keyTitle = Instance.new("TextLabel")
keyTitle.Name = "Title"
keyTitle.BackgroundTransparency = 1
keyTitle.Position = UDim2.fromOffset(9, 4)
keyTitle.Size = UDim2.new(1, -18, 0, 24)
keyTitle.Font = Enum.Font.GothamBold
keyTitle.Text = "Keys"
keyTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
keyTitle.TextSize = 14
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Parent = keyPanel

local keyScroll = Instance.new("ScrollingFrame")
keyScroll.Name = "Buttons"
keyScroll.Position = UDim2.fromOffset(8, 31)
keyScroll.Size = UDim2.new(1, -16, 1, -39)
keyScroll.BackgroundTransparency = 1
keyScroll.BorderSizePixel = 0
keyScroll.ScrollBarThickness = 3
keyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
keyScroll.CanvasSize = UDim2.fromOffset(0, 0)
keyScroll.Parent = keyPanel

local keyGrid = Instance.new("UIGridLayout")
keyGrid.CellSize = UDim2.fromOffset(39, 35)
keyGrid.CellPadding = UDim2.fromOffset(5, 5)
keyGrid.FillDirectionMaxCells = 5
keyGrid.SortOrder = Enum.SortOrder.LayoutOrder
keyGrid.Parent = keyScroll

function state:activeRealHumanoid()
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function state:restoreClawRunSpeed()
	local humanoid = self:activeRealHumanoid()

	if humanoid and self.clawBaseWalkSpeed ~= nil then
		pcall(function()
			humanoid.WalkSpeed = self.clawBaseWalkSpeed
		end)
	end

	self.clawBaseWalkSpeed = nil
end

function state:refreshClawRunSpeed()
	local humanoid = self:activeRealHumanoid()

	if not humanoid then
		return
	end

	if self.originalClawRunSpeedEnabled
		and self.clawsActive
		and self.activeMorph
	then
		if self.clawBaseWalkSpeed == nil then
			self.clawBaseWalkSpeed = humanoid.WalkSpeed
		end

		pcall(function()
			humanoid.WalkSpeed = self.clawRunSpeed
		end)
	else
		self:restoreClawRunSpeed()
	end
end

function state:syncClawRunStateFromController()
	local controller = self.controller

	if not controller or not controller.Parent then
		self.clawsActive = false
		self:refreshClawRunSpeed()
		return
	end

	self.clawsActive =
		controller:GetAttribute("CaelusAggressive") == true

	self:refreshClawRunSpeed()
end

local function fireCommand(kind, value)
	local command = state.command

	if command
		and command.Parent
		and command:IsA("BindableEvent")
	then
		command:Fire(kind, value)
	end
end

local function clearKeyButtons()
	for _, child in ipairs(keyScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
end

local function createKeyButton(key, order)
	local button = keysButton:Clone()
	button.Name = "Key_" .. key
	button.LayoutOrder = order
	button.Text = key
	button.Size = UDim2.fromOffset(39, 35)
	button.Position = UDim2.new()
	button.AnchorPoint = Vector2.zero
	button.Parent = keyScroll
	local pressed = false
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if pressed then return end
			pressed = true
			fireCommand("key_down", string.lower(key))
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not pressed then return end
			pressed = false
			fireCommand("key_up", string.lower(key))
		end
	end)
end

local function rebuildKeyPanel(versionName)
	clearKeyButtons()
	local legacyConfig = state.activeLegacyNeko
		and environment.CaelusLegacyNekoConfig.variants[state.activeLegacyNeko]
	local keys = (legacyConfig and legacyConfig.keys)
		or KEYS_BY_VERSION[versionName]
		or {}
	for index, key in ipairs(keys) do createKeyButton(key, index) end
	keyTitle.Text = (state.activeLegacyNeko or versionName) .. "  Keys"
	keyPanel.Visible = state.keyPanelOpen and state.command ~= nil and #keys > 0
end

local function cleanupShadow()
	state.sessionSerial = state.sessionSerial + 1
	state:restoreClawRunSpeed()
	state.clawsActive = false

	if state.externalCustomRuntime
		and state.externalCustomRuntime.Parent
		and state.externalCustomRuntime ~= player.Character
	then
		pcall(function()
			state.externalCustomRuntime:Destroy()
		end)
	end

	state.externalCustomRuntime = nil
	unbindVisibility()
	disconnectArray(state.followConnections)
	if state.controller and state.controller.Parent then
		pcall(function() state.controller:SetAttribute("CaelusSessionActive", false) end)
	end
	restoreDirectWear()
	if state.shadow and state.shadow.Parent then state.shadow:Destroy() end
	restoreRealVisibility()
	state.shadow = nil
	state.controller = nil
	state.command = nil
	state.armorEvent = nil
	state.activeMorph = nil
	state.activeVersion = nil
	state.activeCustomNeko = nil
	state.activeLegacyNeko = nil
	state.activeLegacySkinColor = nil
	state.lowerArmorOn = true
	state.upperArmorOn = true
	state.armorReady = false
	table.clear(state.lowerArmorParts)
	table.clear(state.upperArmorParts)
	table.clear(state.lowerArmorLookup)
	table.clear(state.upperArmorLookup)
	table.clear(state.lowerBaseWearParts)
	table.clear(state.lowerBaseWearBindings)
	table.clear(state.upperScarfParts)
	table.clear(state.upperScarfBindings)
	table.clear(state.armorPartTransparency)
	table.clear(state.visualParts)
	table.clear(state.visualPartLookup)
	state.morphPantsTemplate = nil
	state.morphShirtTemplate = nil
	state.morphShirtGraphicTemplate = nil
	table.clear(state.activeTouches)
	keyPanel.Visible = false
end

environment.CaelusMelanieSourceAdapter = function(source)
	local function replacePlainOnce(text, needle, replacement)
		local first, last = text:find(needle, 1, true)
		if not first then
			return nil, "missing source marker: " .. tostring(needle)
		end
		return text:sub(1, first - 1) .. replacement .. text:sub(last + 1), nil
	end

	local function replacePlainAll(text, needle, replacement)
		local cursor = 1
		local pieces = {}
		local replaced = 0
		while true do
			local first, last = text:find(needle, cursor, true)
			if not first then
				table.insert(pieces, text:sub(cursor))
				break
			end
			table.insert(pieces, text:sub(cursor, first - 1))
			table.insert(pieces, replacement)
			cursor = last + 1
			replaced = replaced + 1
		end
		return table.concat(pieces), replaced
	end

	local function spliceBetween(text, firstMarker, lastMarker, replacement)
		local first = text:find(firstMarker, 1, true)
		if not first then
			return nil, "missing source marker: " .. tostring(firstMarker)
		end
		local last = text:find(lastMarker, first, true)
		if not last then
			return nil, "missing source marker: " .. tostring(lastMarker)
		end
		return text:sub(1, first - 1) .. replacement .. text:sub(last), nil
	end

	local problem

	-- The supplied anims3 is a legacy server Script.  Keep its original
	-- animation/effect code, but replace only the server input transport and
	-- player-character lookup so it can drive the isolated Direct Wear rig.
	source, problem = spliceBetween(
		source,
		"local Player = game.Players:GetPlayerFromCharacter(script.Parent)",
		"--replace all player into = Player = game.Players:GetPlayerFromCharacter(script.Parent)",
		[=[local Player = game:GetService("Players").LocalPlayer
if not Player then
	error("Melanie client bridge could not resolve LocalPlayer")
end
local Mouse = Player:GetMouse()
local mouse = Mouse
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

]=]
	)
	if not source then return nil, problem end

	source, problem = spliceBetween(
		source,
		"local Player = nil",
		"ZTfade=false",
		[=[local DriverCharacter = script.Parent
local RealCharacter = Player.Character
local MotionHumanoid = RealCharacter and RealCharacter:FindFirstChildOfClass("Humanoid")
local MotionRootPart = RealCharacter and RealCharacter:FindFirstChild("HumanoidRootPart")
if not (DriverCharacter and MotionHumanoid and MotionRootPart) then
	error("Melanie Direct Wear character bridge is incomplete")
end

]=]
	)
	if not source then return nil, problem end

	source, problem = replacePlainOnce(
		source,
		"Character= Player.Character",
		"Character = DriverCharacter"
	)
	if not source then return nil, problem end

	local createStart = "local RbxUtility = require("
	local createEnd = "local Create = RbxUtility.Create"
	source, problem = spliceBetween(
		source,
		createStart,
		createEnd,
		[=[local CaelusPropertyAliases = {
	Pitch = "PlaybackSpeed",
	maxForce = "MaxForce",
	velocity = "Velocity",
	angularvelocity = "AngularVelocity",
	cframe = "CFrame",
	position = "Position",
}
local function Create(className)
	return function(properties)
		local object = Instance.new(className)
		local parent = nil
		for key, value in pairs(properties or {}) do
			if key == "Parent" then
				parent = value
			elseif type(key) == "number" and typeof(value) == "Instance" then
				value.Parent = object
			else
				local propertyName = CaelusPropertyAliases[key] or key
				local assigned = pcall(function()
					object[propertyName] = value
				end)
				if not assigned and propertyName ~= key then
					pcall(function() object[key] = value end)
				end
			end
		end
		if parent then object.Parent = parent end
		return object
	end
end
local RbxUtility = {Create = Create}
]=]
	)
	if not source then return nil, problem end
	source, problem = replacePlainOnce(source, createEnd, "local Create = RbxUtility.Create")
	if not source then return nil, problem end

	source = replacePlainAll(
		source,
		"Humanoid.MoveDirection",
		"MotionHumanoid.MoveDirection"
	)
	source = replacePlainAll(
		source,
		"Humanoid.Sit",
		"MotionHumanoid.Sit"
	)
	source = replacePlainAll(
		source,
		"RootPart.Velocity",
		"MotionRootPart.AssemblyLinearVelocity"
	)

	source, problem = replacePlainOnce(
		source,
		'game:GetService("RunService").Heartbeat:connect(function(s, p)',
		[=[local CaelusHeartbeatConnection
CaelusHeartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function(s, p)
	if script:GetAttribute("CaelusSessionActive") ~= true or not script.Parent then
		pcall(function() script.ArtificialHB:Fire() end)
		CaelusHeartbeatConnection:Disconnect()
		return
	end]=]
	)
	if not source then return nil, problem end

	source, problem = replacePlainOnce(
		source,
		"while Humanoid.Health>0.001 do ",
		'while script:GetAttribute("CaelusSessionActive") == true and Humanoid.Health > 0.001 do '
	)
	if not source then return nil, problem end
	source = replacePlainAll(
		source,
		"while Hold == true do",
		'while Hold == true and script:GetAttribute("CaelusSessionActive") == true do'
	)
	source = replacePlainAll(
		source,
		"while laying == true do",
		'while laying == true and script:GetAttribute("CaelusSessionActive") == true do'
	)
	source = replacePlainAll(
		source,
		"while true do Swait()",
		'while script:GetAttribute("CaelusSessionActive") == true do Swait()'
	)
	source = replacePlainAll(
		source,
		'while ReturningValue == "" do wait() end',
		'while ReturningValue == "" and script:GetAttribute("CaelusSessionActive") == true do wait() end'
	)

	local bridgeMarker = "coroutine.resume(coroutine.create(function()"
	local bridgeStart = nil
	local cursor = 1
	while true do
		local found = source:find(bridgeMarker, cursor, true)
		if not found then break end
		bridgeStart = found
		cursor = found + #bridgeMarker
	end
	if not bridgeStart
		or not source:find("RemoteFunction", bridgeStart, true)
	then
		return nil, "missing Melanie server remote bridge"
	end

	source = source:sub(1, bridgeStart - 1) .. [=[
local CaelusCommand = Character:FindFirstChild("CaelusNekoCommand")
if not (CaelusCommand and CaelusCommand:IsA("BindableEvent")) then
	CaelusCommand = Instance.new("BindableEvent")
	CaelusCommand.Name = "CaelusNekoCommand"
	CaelusCommand.Parent = Character
end

local function CaelusActive()
	return script.Parent ~= nil
		and script:GetAttribute("CaelusSessionActive") == true
end

local function CaelusKeyDown(key)
	if not CaelusActive() or type(key) ~= "string" then return end
	task.spawn(function()
		local ok, message = pcall(KeyDownF, string.lower(key))
		if not ok and script.Parent then
			script:SetAttribute("CaelusCommandError", tostring(message))
		end
	end)
end

local function CaelusKeyUp(key)
	if not CaelusActive() or type(key) ~= "string" then return end
	task.spawn(function()
		local ok, message = pcall(KeyUpF, string.lower(key))
		if not ok and script.Parent then
			script:SetAttribute("CaelusCommandError", tostring(message))
		end
	end)
end

local function CaelusMouseDown()
	if not CaelusActive() then return end
	task.spawn(function()
		local ok, message = pcall(Button1DownF)
		if not ok and script.Parent then
			script:SetAttribute("CaelusCommandError", tostring(message))
		end
	end)
end

local function CaelusMouseUp()
	if not CaelusActive() then return end
	local ok, message = pcall(Button1UpF)
	if not ok and script.Parent then
		script:SetAttribute("CaelusCommandError", tostring(message))
	end
end

Mouse.Move:Connect(function()
	if CaelusActive() then Target = Mouse.Hit.Position end
end)
Mouse.Button1Down:Connect(CaelusMouseDown)
Mouse.Button1Up:Connect(CaelusMouseUp)
Mouse.KeyDown:Connect(CaelusKeyDown)
Mouse.KeyUp:Connect(CaelusKeyUp)
CaelusCommand.Event:Connect(function(kind, value)
	if kind == "key_down" then
		CaelusKeyDown(value)
	elseif kind == "key_up" then
		CaelusKeyUp(value)
	elseif kind == "mouse_down" then
		CaelusMouseDown()
	elseif kind == "mouse_up" then
		CaelusMouseUp()
	end
end)

script:SetAttribute("CaelusReady", true)
]=]

	return source, nil
end

local function isolatedChunk(targetScript)
	local source = nil
	local lastProblem = "empty source"

	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return targetScript.Source
		end)
		if ok and type(result) == "string" and result ~= "" then
			source = result
			break
		end

		lastProblem = ok and "empty source" or tostring(result)
		if attempt < 4 then
			task.wait(0.05 * attempt)
		end
	end

	if not source then
		return nil, "Could not read embedded source after retries: " .. tostring(lastProblem)
	end

	if targetScript.Name == "CaelusNekoOriginalController" then
		source = source:gsub(
			'if h ~= nil and hit%.Parent ~= Character and hit%.Parent:FindFirstChild%("Torso"%) or hit%.Parent:FindFirstChild%("UpperTorso"%) ~= nil then',
			'if h ~= nil and hit.Parent ~= Character and hit.Parent ~= DriverCharacter and (hit.Parent:FindFirstChild("Torso") or hit.Parent:FindFirstChild("UpperTorso")) then'
		)

		source = source:gsub(
			"agresive%s*=%s*true",
			'agresive = true; pcall(function() script:SetAttribute("CaelusAggressive", true) end)'
		)

		source = source:gsub(
			"agresive%s*=%s*false",
			'agresive = false; pcall(function() script:SetAttribute("CaelusAggressive", false) end)'
		)
	end

	if targetScript:GetAttribute("CaelusMelanieClientController") == true then
		source, lastProblem = environment.CaelusMelanieSourceAdapter(source)
		if not source then
			return nil, "Melanie client adapter failed: " .. tostring(lastProblem)
		end
	end

	local chunk, problem = compiler("local script = ...\n" .. source)
	if not chunk then
		return nil, "Compile error: " .. tostring(problem)
	end
	return chunk, nil
end

local function runEmbedded(targetScript, asynchronous)
	local chunk, problem = isolatedChunk(targetScript)
	if not chunk then return false, problem end
	local function execute()
		local ok, result = pcall(chunk, targetScript)
		if not ok and targetScript.Parent then
			local stage = targetScript:GetAttribute("CaelusStage") or "unknown"
			local message = tostring(result) .. " (stage: " .. tostring(stage) .. ")"
			targetScript:SetAttribute("CaelusStartError", message)
		end
		return ok, result
	end
	if asynchronous then
		task.spawn(execute)
		return true
	end
	return execute()
end

local function findMatchingRigAttachment(shadow, attachmentName)
	for _, descendant in ipairs(shadow:GetDescendants()) do
		if descendant:IsA("Attachment")
		and descendant.Name == attachmentName
		and descendant.Parent
		and descendant.Parent.Parent == shadow then
			return descendant
		end
	end
	return nil
end

local function destroyLoadedObjects(objects)
	for _, object in ipairs(objects) do
		if object and object.Parent then
			object:Destroy()
		elseif object then
			pcall(function() object:Destroy() end)
		end
	end
end

function environment.CaelusLegacyNekoConfig:isVariant(name)
	return self.variants[name] ~= nil
end

function environment.CaelusLegacyNekoConfig:loadRoot(name)
	local config = self.variants[name]
	if not config then
		return nil, "Unknown legacy Neko: " .. tostring(name)
	end

	local lastProblem = "asset not found"
	local variantUris = {
		"rbxasset://avatar/CaelusNekoShadow/LegacyNekos/" .. config.file,
		"rbxasset://content/avatar/CaelusNekoShadow/LegacyNekos/" .. config.file,
	}

	do
		local runtime = environment.CaelusRemoteAssetRuntime
		if type(runtime) == "table" and type(runtime.getAssetUri) == "function" then
			local ok, resolved, remoteProblem = pcall(
				runtime.getAssetUri,
				runtime,
				config.file
			)
			if ok and type(resolved) == "string" and resolved ~= "" then
				table.insert(variantUris, 1, resolved)
			elseif ok and remoteProblem then
				lastProblem = tostring(remoteProblem)
			end
		end
	end

	for _, uri in ipairs(variantUris) do
		local objects, problem = getObjectsWithRetry(uri, 4)
		lastProblem = problem or lastProblem
		if objects then
			local root = objects[1]
			if root then
				for index = 2, #objects do
					pcall(function() objects[index]:Destroy() end)
				end
				return root, nil
			end
			destroyLoadedObjects(objects)
		end
	end

	return nil,
		"Could not load "
			.. tostring(config.display or name)
			.. " from LegacyNekos. Last error: "
			.. tostring(lastProblem)
end

function environment.CaelusLegacyNekoConfig:createCustomShadow(name, realRoot)
	local root, problem = self:loadRoot(name)
	if not root then return nil, nil, nil, problem end

	local mainModule =
		root:IsA("ModuleScript")
			and root
			or root:FindFirstChild("MainModule", true)
	local template = mainModule
		and mainModule:FindFirstChild("DefaultCharacter6")
	local sourceController = mainModule
		and mainModule:FindFirstChild("anims3")

	if not (mainModule and mainModule:IsA("ModuleScript")) then
		root:Destroy()
		return nil, nil, nil, "Melanie MainModule is missing."
	end
	if not (template and template:IsA("Model")) then
		root:Destroy()
		return nil, nil, nil, "Melanie DefaultCharacter6 is missing."
	end
	if not (
		sourceController
		and (
			sourceController:IsA("Script")
			or sourceController:IsA("LocalScript")
			or sourceController:IsA("ModuleScript")
		)
	) then
		root:Destroy()
		return nil, nil, nil, "Melanie anims3 controller is missing."
	end

	local shadow = template:Clone()
	shadow.Name = "CaelusNekoVisual_" .. player.UserId
	shadow:SetAttribute("CaelusNekoVisualRig", true)
	shadow:SetAttribute("CaelusLowerArmorOn", true)
	shadow:SetAttribute("CaelusUpperArmorOn", true)
	shadow:SetAttribute("CaelusCustomControllerMode", "MelanieClientDirectWear")

	local visualRoot = shadow:FindFirstChild("HumanoidRootPart")
	local visualHumanoid =
		shadow:FindFirstChild("NekoHumanoid")
			or shadow:FindFirstChildOfClass("Humanoid")
	if not (visualRoot and visualRoot:IsA("BasePart") and visualHumanoid) then
		shadow:Destroy()
		root:Destroy()
		return nil, nil, nil, "Melanie R6 template is incomplete."
	end

	for _, bodyName in ipairs(DIRECT_BODY_NAMES) do
		local bodyPart = shadow:FindFirstChild(bodyName)
		if not (bodyPart and bodyPart:IsA("BasePart")) then
			shadow:Destroy()
			root:Destroy()
			return nil, nil, nil, "Melanie R6 part is missing: " .. bodyName
		end
	end

	local animate = shadow:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then animate.Disabled = true end
	local healthScript = shadow:FindFirstChild("Health")
	if healthScript and healthScript:IsA("Script") then healthScript.Disabled = true end
	pcall(function() visualHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
	pcall(function() visualHumanoid.BreakJointsOnDeath = false end)
	pcall(function() visualHumanoid.RequiresNeck = false end)
	pcall(function() visualHumanoid.AutoRotate = false end)
	pcall(function() visualHumanoid.PlatformStand = true end)
	pcall(function() visualHumanoid.EvaluateStateMachine = false end)

	visualRoot.Anchored = true
	moveWholeRigToRoot(shadow, visualRoot, realRoot.CFrame)
	shadow.Parent = workspace
	moveWholeRigToRoot(shadow, visualRoot, realRoot.CFrame)

	local command = Instance.new("BindableEvent")
	command.Name = "CaelusNekoCommand"
	command.Parent = shadow
	local armorEvent = Instance.new("BindableEvent")
	armorEvent.Name = "CaelusArmorToggle"
	armorEvent.Parent = shadow

	local controller = sourceController:Clone()
	controller.Name = "CaelusMelanieClientController"
	controller:SetAttribute("CaelusSessionActive", true)
	controller:SetAttribute("CaelusStartError", nil)
	controller:SetAttribute("CaelusCustomController", true)
	controller:SetAttribute("CaelusMelanieClientController", true)
	controller.Parent = shadow

	trackVisualModel(shadow, true)
	root:Destroy()
	return shadow, visualRoot, controller, nil
end

function environment.CaelusLegacyNekoConfig:replaceChild(targetParent, sourceParent, childName)
	if not (targetParent and sourceParent) then
		return false, "Missing parent for " .. tostring(childName)
	end

	local sourceChild = sourceParent:FindFirstChild(childName)
	if not sourceChild then
		return false, "Variant is missing " .. tostring(childName)
	end

	local old = targetParent:FindFirstChild(childName)
	if old then
		old:Destroy()
	end

	sourceChild:Clone().Parent = targetParent
	return true, nil
end

function environment.CaelusLegacyNekoConfig:patchController(controller, name)
	local root, problem = self:loadRoot(name)
	if not root then
		return false, problem
	end

	local config = self.variants[name]

	if config and config.preserveEverything then
		local ok, patchProblem = pcall(function()
			for _, sourceChild in ipairs(root:GetChildren()) do
				local oldChild = controller:FindFirstChild(sourceChild.Name)

				if oldChild then
					oldChild:Destroy()
				end

				sourceChild:Clone().Parent = controller
			end

			controller:SetAttribute("CaelusLegacyVariant", name)
			controller:SetAttribute(
				"CaelusPreserveLegacyEverything",
				true
			)

			local bodyColors =
				controller:FindFirstChildWhichIsA("BodyColors", true)
				or root:FindFirstChildWhichIsA("BodyColors", true)

			if bodyColors then
				local colorOk, headColor = pcall(function()
					return bodyColors.HeadColor3
				end)

				if colorOk and typeof(headColor) == "Color3" then
					controller:SetAttribute(
						"CaelusLegacySkinColor",
						headColor
					)
				end
			end
		end)

		pcall(function()
			root:Destroy()
		end)

		if not ok then
			return false, tostring(patchProblem)
		end

		return true, nil
	end

	local ok, patchProblem = pcall(function()
		local sourceExtras = root:FindFirstChild("Extras")
		local targetExtras = controller:FindFirstChild("Extras")
		if not (sourceExtras and targetExtras) then
			error("Variant or controller is missing Extras")
		end

		local replaced, replaceProblem = self:replaceChild(
			targetExtras,
			sourceExtras,
			"Outfit"
		)
		if not replaced then
			error(replaceProblem)
		end

		replaced, replaceProblem = self:replaceChild(
			controller,
			root,
			"Armor"
		)
		if not replaced then
			error(replaceProblem)
		end

		for _, spec in ipairs({
			{"RLegYes", "RightLeg"},
			{"LLegYes", "LeftLeg"},
			{"RArmYes", "RightArm"},
			{"LArmYes", "LeftArm"},
			{"TorsoYes", "Torso"},
		}) do
			local containerName = spec[1]
			local modelName = spec[2]
			local sourceContainer = root:FindFirstChild(containerName)
			local targetContainer = controller:FindFirstChild(containerName)
			if not (sourceContainer and targetContainer) then
				error("Variant is missing " .. containerName)
			end

			replaced, replaceProblem = self:replaceChild(
				targetContainer,
				sourceContainer,
				modelName
			)
			if not replaced then
				error(replaceProblem)
			end
		end

		controller:SetAttribute("CaelusLegacyVariant", name)

		local configuredSkinColor = self.variants[name]
			and self.variants[name].skinColor
		if typeof(configuredSkinColor) == "Color3" then
			controller:SetAttribute("CaelusLegacySkinColor", configuredSkinColor)
		else
			local legacyBodyColors =
				targetExtras:FindFirstChildWhichIsA("BodyColors", true)
				or root:FindFirstChildWhichIsA("BodyColors", true)
			if legacyBodyColors then
				local okColor, headColor = pcall(function()
					return legacyBodyColors.HeadColor3
				end)
				if okColor and typeof(headColor) == "Color3" then
					controller:SetAttribute("CaelusLegacySkinColor", headColor)
				end
			end
		end
	end)

	pcall(function() root:Destroy() end)

	if not ok then
		return false, tostring(patchProblem)
	end
	return true, nil
end

local CUSTOM_CLOTHING_CLASSES = {"Shirt", "Pants", "ShirtGraphic"}

local function collectInstancesOfClass(objects, className)
	local found = {}
	for _, object in ipairs(objects) do
		if object:IsA(className) then table.insert(found, object) end
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA(className) then table.insert(found, descendant) end
		end
	end
	return found
end

local function cloneCustomHandle(source, assetId, shadow)
	local handle = source:IsA("BasePart") and source or source:FindFirstChild("Handle", true)
	if not (handle and handle:IsA("BasePart")) then
		return nil, "Accessory " .. tostring(assetId) .. " has no Handle"
	end

	local cloned = handle:Clone()
	local attachment = cloned:FindFirstChildOfClass("Attachment")
	if not attachment then
		cloned:Destroy()
		return nil, "Accessory " .. tostring(assetId) .. " has no attachment"
	end
	if not findMatchingRigAttachment(shadow, attachment.Name) then
		local attachmentName = attachment.Name
		cloned:Destroy()
		return nil, "Accessory " .. tostring(assetId) .. " uses unsupported " .. attachmentName
	end

	for _, descendant in ipairs(cloned:GetDescendants()) do
		if descendant:IsA("Weld")
		or descendant:IsA("WeldConstraint")
		or descendant:IsA("Motor6D") then
			descendant:Destroy()
		end
	end
	cloned.Name = "CustomAccessory_" .. tostring(assetId)
	makePartNonPhysical(cloned, true)
	return cloned, nil
end

local function destroyAppearanceResult(result)
	if not result then return end
	for _, instance in pairs(result.clothing or {}) do
		pcall(function() instance:Destroy() end)
	end
	for _, handle in ipairs(result.handles or {}) do
		pcall(function() handle:Destroy() end)
	end
end

local function loadCustomAppearanceAsset(assetId, shadow)
	local objects, problem = getObjectsWithRetry(
		"rbxassetid://" .. tostring(assetId),
		4
	)
	if not objects then
		return nil,
			"Could not load clothing/accessory "
				.. tostring(assetId)
				.. ": "
				.. tostring(problem or "unknown")
	end

	local result = {
		clothing = {},
		handles = {},
	}
	for _, className in ipairs(CUSTOM_CLOTHING_CLASSES) do
		local matches = collectInstancesOfClass(objects, className)
		if matches[1] then result.clothing[className] = matches[1]:Clone() end
	end

	local accessorySources = collectInstancesOfClass(objects, "Accessory")
	for _, source in ipairs(collectInstancesOfClass(objects, "Hat")) do
		table.insert(accessorySources, source)
	end

	if #accessorySources == 0 and next(result.clothing) == nil then
		for _, object in ipairs(objects) do
			local candidate = object:IsA("BasePart") and object or object:FindFirstChild("Handle", true)
			if candidate and candidate:IsA("BasePart")
			and candidate:FindFirstChildOfClass("Attachment") then
				table.insert(accessorySources, candidate)
				break
			end
		end
	end

	for _, source in ipairs(accessorySources) do
		local handle, problem = cloneCustomHandle(source, assetId, shadow)
		if not handle then
			destroyLoadedObjects(objects)
			destroyAppearanceResult(result)
			return nil, problem
		end
		table.insert(result.handles, handle)
	end
	destroyLoadedObjects(objects)

	if next(result.clothing) == nil and #result.handles == 0 then
		return nil, "Asset " .. tostring(assetId) .. " is not classic clothing or an attachable accessory"
	end
	return result, nil
end

local function replaceClass(container, className, replacement)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA(className) then child:Destroy() end
	end
	replacement.Parent = container
end

local function stripWhiteTailVisual(tail)
	if not (tail and tail:IsA("BasePart")) then
		return false, "White Neko Tail controller anchor is missing"
	end
	if not tail:FindFirstChildOfClass("Attachment") then
		return false, "White Neko Tail attachment anchor is missing"
	end

	tail.Transparency = 1
	tail.LocalTransparencyModifier = 1
	tail.CastShadow = false
	makePartNonPhysical(tail, true)
	tail:SetAttribute("CaelusHiddenControllerAnchor", true)

	for _, descendant in ipairs(tail:GetDescendants()) do
		if descendant:IsA("DataModelMesh")
		or descendant:IsA("Decal")
		or descendant:IsA("Texture") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.LocalTransparencyModifier = 1
			descendant.CastShadow = false
			makePartNonPhysical(descendant, true)
		elseif descendant:IsA("ParticleEmitter")
		or descendant:IsA("Trail")
		or descendant:IsA("Beam") then
			descendant.Enabled = false
		end
	end

	return true, nil
end

local function prepareCustomController(controller, shadow)
	local config = state.activeCustomNeko
	if not config then return false, "Custom Neko is not configured" end

	local extras = controller:FindFirstChild("Extras")
	local outfit = extras and extras:FindFirstChild("Outfit")
	if not outfit then return false, "White Neko Outfit is missing" end

	for _, child in ipairs(outfit:GetChildren()) do
		if child:IsA("BasePart") then
			if child.Name == "Tail" then
				local tailReady, tailProblem = stripWhiteTailVisual(child)
				if not tailReady then return false, tailProblem end
			else
				child:Destroy()
			end
		elseif child:IsA("Accessory") or child:IsA("Hat") then
			child:Destroy()
		end
	end

	recolorMatchingParts(controller, DEFAULT_WHITE_NEKO_SKIN, config.skinColor)
	setBodyColors(outfit:FindFirstChildOfClass("BodyColors"), config.skinColor)
	setRigSkinColor(shadow, config.skinColor)

	for _, assetId in ipairs(config.assetIds) do
		local appearance, problem = loadCustomAppearanceAsset(assetId, shadow)
		if not appearance then return false, problem end

		for className, clothing in pairs(appearance.clothing) do
			if className == "ShirtGraphic" then
				replaceClass(shadow, className, clothing)
			else
				replaceClass(outfit, className, clothing)
			end
		end
		for _, handle in ipairs(appearance.handles) do
			handle.Parent = outfit
		end
	end
	return true, nil
end

local function clothingTemplate(character, className, propertyName)
	local object = character and character:FindFirstChildOfClass(className)
	if object then
		local ok, value = pcall(function() return object[propertyName] end)
		if ok then return value end
	end
	return ""
end

function state.clothingGuard:disconnect()
	for _, connection in ipairs(self.connections) do
		pcall(function() connection:Disconnect() end)
	end
	table.clear(self.connections)
	table.clear(self.priority)
	table.clear(self.objects)
	table.clear(self.expected)
	table.clear(self.watched)
end

function state.clothingGuard:value(object, className)
	local propertyName = self.props[className]
	if not (object and propertyName) then return "" end
	local ok, value = pcall(function()
		return object[propertyName]
	end)
	return ok and tostring(value or "") or ""
end

function state.clothingGuard:watch(object, className)
	if not (object and object.Parent and self.props[className]) or self.watched[object] then
		return
	end
	self.watched[object] = true

	local propertyName = self.props[className]
	local connection = object:GetPropertyChangedSignal(propertyName):Connect(function()
		local character = state.realCharacter
		if not (character and object.Parent == character) then return end

		local current = self:value(object, className)
		local expected = self.expected[object]
		if expected ~= nil and current == expected then
			self.expected[object] = nil
			return
		end

		self.expected[object] = nil
		self.priority[className] = current
		self.objects[className] = object
		pcall(function() object:SetAttribute("CaelusGameClothingPriority", true) end)
		startupLog("Game clothing priority: " .. className .. " = " .. current)
	end)
	table.insert(self.connections, connection)
end

function state.clothingGuard:capture(object, className)
	local character = state.realCharacter
	if not (character and object and object.Parent == character and object:IsA(className)) then
		return
	end

	self:watch(object, className)
	self.priority[className] = self:value(object, className)
	self.objects[className] = object
	pcall(function() object:SetAttribute("CaelusGameClothingPriority", true) end)

	for _, child in ipairs(character:GetChildren()) do
		if child ~= object
		and child:IsA(className)
		and child:GetAttribute("CaelusDirectWear") == true
		and child:GetAttribute("CaelusGameClothingPriority") ~= true then
			pcall(function() child:Destroy() end)
		end
	end

	startupLog("Game supplied " .. className .. " captured as clothing priority")
end

function state.clothingGuard:start(character)
	self:disconnect()

	for className in pairs(self.props) do
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA(className) then
				self:watch(child, className)
			end
		end
	end

	table.insert(self.connections, character.ChildAdded:Connect(function(child)
		for className in pairs(self.props) do
			if child:IsA(className) then
				self:watch(child, className)
				if child:GetAttribute("CaelusDirectWear") ~= true then
					task.defer(function()
						if child.Parent == character then
							self:capture(child, className)
						end
					end)
				end
				break
			end
		end
	end))
end

function state.clothingGuard:uses3DPants()
	return not (
		state.activeMorph == CUSTOM_MORPH_NAME
		and state.activeCustomNeko
		and state.activeCustomNeko.use3DPants == false
	)
end

function state.clothingGuard:apply(character, className, nekoTemplate, armorOn, keep2D)
	if not character then return end
	local desired = self.priority[className]
	if desired == nil then
		if keep2D then
			desired = nekoTemplate or ""
		else
			desired = armorOn and (nekoTemplate or "") or ARMOR_OFF_TEMPLATE
		end
	end

	local object = self.objects[className]
	if not (object and object.Parent == character and object:IsA(className)) then
		object = character:FindFirstChildOfClass(className)
	end
	if not object then
		object = Instance.new(className)
		object:SetAttribute("CaelusDirectWear", true)
		object.Parent = character
		table.insert(state.directWearInstances, object)
		self:watch(object, className)
	end

	if self:value(object, className) ~= tostring(desired or "") then
		self.expected[object] = tostring(desired or "")
		local propertyName = self.props[className]
		local ok = pcall(function()
			object[propertyName] = tostring(desired or "")
		end)
		if not ok then
			self.expected[object] = nil
		end
	end
end

local function appearanceCharacter()
	if state.realCharacter and state.realCharacter.Parent then
		return state.realCharacter
	end
	return state.shadow
end

local function currentWearContainer(shadow)
	if state.wearRoot and state.wearRoot.Parent then
		return state.wearRoot
	end
	return shadow
end

local function currentWearTorso(shadow)
	local character = state.realCharacter
	if character and character.Parent then
		local torso = character:FindFirstChild("Torso")
		if torso and torso:IsA("BasePart") then return torso end
	end
	return shadow and shadow:FindFirstChild("Torso")
end

local function rememberArmorPart(part, target, seen)
	if not (part and part:IsA("BasePart")) or seen[part] then return end
	seen[part] = true
	if state.armorPartTransparency[part] == nil then
		state.armorPartTransparency[part] = part.Transparency
	end
	table.insert(target, part)
end

local function rememberArmorTree(container, target, seen)
	if not container then return end
	if container:IsA("BasePart") then rememberArmorPart(container, target, seen) end
	for _, descendant in ipairs(container:GetDescendants()) do
		rememberArmorPart(descendant, target, seen)
	end
end

local function refreshArmorParts(shadow, controller)
	if not (shadow and controller) then return end
	local lowerSeen = state.lowerArmorLookup
	local upperSeen = state.upperArmorLookup
	for _, name in ipairs({"LLegYes", "RLegYes"}) do
		rememberArmorTree(controller:FindFirstChild(name), state.lowerArmorParts, lowerSeen)
	end
	for _, name in ipairs({"TorsoYes", "LArmYes", "RArmYes"}) do
		rememberArmorTree(controller:FindFirstChild(name), state.upperArmorParts, upperSeen)
	end
	if state.activeLegacyNeko == "SWAT Neko" then
		for _, descendant in ipairs(shadow:GetDescendants()) do
			if descendant:IsA("BasePart")
			and descendant.Parent ~= shadow
			and descendant:FindFirstChild("BodyFrontAttachment") then
				rememberArmorPart(descendant, state.upperArmorParts, upperSeen)
			end
		end
	end
	-- These two original black leg pieces are created at runtime and are not
	-- children of LLegYes/RLegYes.  Their named welds identify them reliably.
	for _, child in ipairs(shadow:GetChildren()) do
		if child:IsA("BasePart") then
			local isLeft = child.Name == "Left" and child:FindFirstChild("Left Leg")
			local isRight = child.Name == "Right" and child:FindFirstChild("Right Leg")
			if isLeft or isRight then
				rememberArmorPart(child, state.lowerArmorParts, lowerSeen)
			end
		end
	end
end

local function collectArmorParts(shadow, controller)
	table.clear(state.lowerArmorParts)
	table.clear(state.upperArmorParts)
	table.clear(state.lowerArmorLookup)
	table.clear(state.upperArmorLookup)
	table.clear(state.armorPartTransparency)
	refreshArmorParts(shadow, controller)
end

local function setArmorPartsVisible(parts, visible)
	for _, part in ipairs(parts) do
		if part and part.Parent then
			part.Transparency = visible
				and (state.armorPartTransparency[part] or 0) or 1
		end
	end
end

local function activeLegacyPreservesEverything()
	local config = state.activeLegacyNeko
		and environment.CaelusLegacyNekoConfig.variants[
			state.activeLegacyNeko
		]

	return config and config.preserveEverything == true
end

local function lowerBeltNames()
	return state.activeVersion == "V5" and LOWER_V5_BELT_NAMES or LOWER_BELT_NAMES
end

local function hasRearPockets()
	return true
end

local function lowerWearNames()
	local names = {}
	for _, name in ipairs(lowerBeltNames()) do
		table.insert(names, name)
	end
	if hasRearPockets() then
		for _, name in ipairs(LOWER_REAR_ACCESSORY_NAMES) do
			table.insert(names, name)
		end
	end
	return names
end

local function lowerBodySkinColor()
	if state.activeMorph == CUSTOM_MORPH_NAME and state.activeCustomNeko then
		return state.activeCustomNeko.skinColor
	end
	if state.activeLegacyNeko and typeof(state.activeLegacySkinColor) == "Color3" then
		return state.activeLegacySkinColor
	end
	if state.activeMorph == "Psycho Neko" then
		return BrickColor.new("Institutional white").Color
	end
	return BrickColor.new("Pastel brown").Color
end

local function lowerBeltPieceColor(name)
	if name == "BeltBase" or name == "BeltCover" then
		return lowerBodySkinColor()
	end

	local legacyConfig = state.activeLegacyNeko
		and environment.CaelusLegacyNekoConfig.variants[state.activeLegacyNeko]
	if legacyConfig
	and typeof(legacyConfig.accentColor) == "Color3"
	and (name == "BeltLayer" or name == "BeltBack") then
		return legacyConfig.accentColor
	end

	if state.activeMorph == "Psycho Neko" then
		if name == "BeltLayer" then
			return Color3.fromRGB(48, 48, 48)
		end
		return BrickColor.new("Really black").Color
	end
	if name == "BeltLayer" then
		return BrickColor.new("Medium red").Color
	end
	if name == "BeltBack" then
		return BrickColor.new("Dusty Rose").Color
	end
	return lowerBodySkinColor()
end

local function lowerRearAccessoryColor()
	if state.activeMorph == CUSTOM_MORPH_NAME and state.activeCustomNeko then
		return state.activeCustomNeko.skinColor
	end
	if state.activeLegacyNeko and typeof(state.activeLegacySkinColor) == "Color3" then
		return state.activeLegacySkinColor
	end
	if state.activeMorph == "Psycho Neko" then
		return Color3.fromRGB(248, 248, 248)
	end
	return BrickColor.new("Pastel brown").Color
end

local function lowerV5BeltVariant()
	if state.activeMorph == "Bunny neko"
	or state.activeMorph == "Bunny neko (alt that remove accessories)" then
		return "Bunny"
	end
	return "Default"
end

local function scarfVariant()
	return state.activeMorph == "Psycho Neko" and "Psycho" or "Default"
end

local function upperScarfCount()
	return SCARF_COUNT_BY_VERSION[state.activeVersion] or 8
end

local ensureOriginalLowerBaseWear
local ensureOriginalUpperScarf

local function setWearBindingsVisible(bindings, visible)
	local applied = 0
	for _, binding in ipairs(bindings) do
		local part = binding.part
		local anchor = binding.anchor
		if part and part.Parent and anchor and anchor.Parent then
			part.Anchored = true
			part.CFrame = anchor.CFrame * binding.relative
			-- Source scarf pieces start at Transparency=1; the original V code
			-- reveals them later.  Their stored value is therefore not their
			-- visible value.  Force every replacement garment opaque when active.
			part.Transparency = visible and 0 or 1
			pcall(function() part.LocalTransparencyModifier = 0 end)
			applied = applied + 1
		end
	end
	return #bindings > 0 and applied == #bindings
end

local function setLowerBaseWearVisible(visible)
	local applied = 0
	for _, binding in ipairs(state.lowerBaseWearBindings) do
		local part = binding.part
		local anchor = binding.anchor
		if part and part.Parent and anchor and anchor.Parent then
			part.Anchored = true
			part.CFrame = anchor.CFrame * binding.relative
			local partVisible = visible
			if state.activeVersion == "V5" and part:GetAttribute("CaelusBeltPiece") == true then
				partVisible = true
			end
			part.Transparency = partVisible and 0 or 1
			pcall(function() part.LocalTransparencyModifier = 0 end)
			applied = applied + 1
		end
	end
	return #state.lowerBaseWearBindings > 0 and applied == #state.lowerBaseWearBindings
end

local function setUpperScarfVisible(visible)
	return setWearBindingsVisible(state.upperScarfBindings, visible)
end

local function enforceHiddenArmor()
	if state.armorReady and state.shadow and state.shadow.Parent then
		ensureOriginalLowerBaseWear(state.shadow)
		ensureOriginalUpperScarf(state.shadow)
	end
	local appearance = appearanceCharacter()
	local use3DPants = state.clothingGuard:uses3DPants()
	if appearance then
		if not state.lowerArmorOn or not use3DPants then
			setArmorPartsVisible(state.lowerArmorParts, false)
		end
		if not state.lowerArmorOn then
			state.clothingGuard:apply(
				appearance,
				"Pants",
				state.morphPantsTemplate,
				false,
				not use3DPants
			)
		end
		if not state.upperArmorOn then
			setArmorPartsVisible(state.upperArmorParts, false)
			state.clothingGuard:apply(
				appearance,
				"Shirt",
				state.morphShirtTemplate,
				false,
				false
			)
			state.clothingGuard:apply(
				appearance,
				"ShirtGraphic",
				state.morphShirtGraphicTemplate,
				false,
				false
			)
		end
	end
	local lowerVisible = not state.lowerArmorOn
	local upperVisible = not state.upperArmorOn
	if not setLowerBaseWearVisible(lowerVisible)
	and state.armorReady and state.shadow and state.shadow.Parent then
		ensureOriginalLowerBaseWear(state.shadow, true)
		setLowerBaseWearVisible(lowerVisible)
	end
	if not setUpperScarfVisible(upperVisible)
	and state.armorReady and state.shadow and state.shadow.Parent then
		ensureOriginalUpperScarf(state.shadow, true)
		setUpperScarfVisible(upperVisible)
	end
end

local function emitArmorBurst(kind)
	local shadow = state.shadow
	if not shadow then return end
	local anchorCharacter = appearanceCharacter() or shadow
	local names = kind == "lower"
		and {"Left Leg", "Right Leg"}
		or {"Torso", "Left Arm", "Right Arm"}
	for _, name in ipairs(names) do
		local anchor = anchorCharacter:FindFirstChild(name)
		if anchor and anchor:IsA("BasePart") then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "CaelusArmorBurst"
			emitter.Texture = "rbxassetid://244221440"
			emitter.Rate = 0
			emitter.Lifetime = NumberRange.new(0.15, 0.3)
			emitter.Speed = NumberRange.new(0.5, 1.5)
			emitter.Rotation = NumberRange.new(0, 360)
			emitter.RotSpeed = NumberRange.new(-30, 30)
			emitter.SpreadAngle = Vector2.new(360, 360)
			emitter.Acceleration = Vector3.new(0, 1, 0)
			emitter.LightEmission = 0.25
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(1, 0),
			})
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			})
			emitter.Parent = anchor
			emitter:Emit(kind == "lower" and 28 or 22)
			Debris:AddItem(emitter, 1)
		end
	end
end

local function updateArmor(kind, explicitArmorOn)
	local shadow = state.shadow
	if not (shadow and shadow.Parent) then return end
	if kind == "lower" then
		local nextArmorOn
		if type(explicitArmorOn) == "boolean" then
			nextArmorOn = explicitArmorOn
		else
			nextArmorOn = not state.lowerArmorOn
		end
		if nextArmorOn == state.lowerArmorOn then return end
		state.lowerArmorOn = nextArmorOn
		shadow:SetAttribute("CaelusLowerArmorOn", state.lowerArmorOn)
		refreshArmorParts(shadow, state.controller)
		-- Match the supplied controller: armor-off removes the 2D layer without
		-- loading a replacement texture; armor-on restores the morph's original.
		local appearance = appearanceCharacter() or shadow
		local use3DPants = state.clothingGuard:uses3DPants()
		state.clothingGuard:apply(
			appearance,
			"Pants",
			state.morphPantsTemplate,
			state.lowerArmorOn,
			not use3DPants
		)
		setArmorPartsVisible(state.lowerArmorParts, state.lowerArmorOn and use3DPants)
		ensureOriginalLowerBaseWear(shadow, not state.lowerArmorOn)
		setLowerBaseWearVisible(not state.lowerArmorOn)
		emitArmorBurst("lower")
	elseif kind == "upper" then
		local nextArmorOn
		if type(explicitArmorOn) == "boolean" then
			nextArmorOn = explicitArmorOn
		else
			nextArmorOn = not state.upperArmorOn
		end
		if nextArmorOn == state.upperArmorOn then return end
		state.upperArmorOn = nextArmorOn
		shadow:SetAttribute("CaelusUpperArmorOn", state.upperArmorOn)
		refreshArmorParts(shadow, state.controller)
		local appearance = appearanceCharacter() or shadow
		state.clothingGuard:apply(
			appearance,
			"Shirt",
			state.morphShirtTemplate,
			state.upperArmorOn,
			false
		)
		state.clothingGuard:apply(
			appearance,
			"ShirtGraphic",
			state.morphShirtGraphicTemplate,
			state.upperArmorOn,
			false
		)
		setArmorPartsVisible(state.upperArmorParts, state.upperArmorOn)
		ensureOriginalUpperScarf(shadow, not state.upperArmorOn)
		setUpperScarfVisible(not state.upperArmorOn)
		emitArmorBurst("upper")
	end
end

local function clearLowerBaseWearTracking()
	table.clear(state.lowerBaseWearParts)
	table.clear(state.lowerBaseWearBindings)
end

local function clearUpperScarfTracking()
	table.clear(state.upperScarfParts)
	table.clear(state.upperScarfBindings)
end

local function visualWearIsHealthy(shadow, modelName, names, parts, bindings)
	local torso = currentWearTorso(shadow)
	local container = currentWearContainer(shadow)
	local model = container and container:FindFirstChild(modelName)
	local anchorRoot = (state.realCharacter and state.realCharacter.Parent) and state.realCharacter or shadow
	if not (torso and torso:IsA("BasePart") and model and model:IsA("Model") and anchorRoot) then
		return false
	end
	if #parts ~= #names or #bindings ~= #names then
		return false
	end

	local basePartCount = 0
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then basePartCount = basePartCount + 1 end
	end
	if basePartCount ~= #names then return false end

	for index, name in ipairs(names) do
		local part = model:FindFirstChild(name)
		local binding = bindings[index]
		if not (part and part:IsA("BasePart")
		and binding and binding.part == part
		and binding.anchor and binding.anchor:IsDescendantOf(anchorRoot)
		and typeof(binding.relative) == "CFrame") then
			return false
		end
	end
	return true
end

local function lowerBaseWearIsHealthy(shadow)
	return visualWearIsHealthy(
		shadow,
		"CaelusLowerBelt",
		lowerWearNames(),
		state.lowerBaseWearParts,
		state.lowerBaseWearBindings
	)
end

local function registerWearPart(part, torso, relative, parts, bindings, attributeName)
	part:SetAttribute(attributeName, true)
	part.Anchored = true
	makePartNonPhysical(part, true)
	pcall(function() part.LocalTransparencyModifier = 0 end)
	table.insert(parts, part)
	table.insert(bindings, {
		part = part,
		anchor = torso,
		relative = relative,
	})
end

local function rebuildOriginalLowerBaseWear(shadow)
	local torso = currentWearTorso(shadow)
	local container = currentWearContainer(shadow)
	if not (torso and torso:IsA("BasePart") and container) then return false end

	clearLowerBaseWearTracking()
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == "CaelusLowerBelt" or child.Name == "CaelusLowerBaseWear" then
			child:Destroy()
		end
	end

	local names = lowerWearNames()
	local beltNames = lowerBeltNames()
	local model
	if state.activeVersion == "V5" then
		local variant = lowerV5BeltVariant()
		local template = lowerV5BeltTemplates[variant]
		if not template then return false end
		model = template:Clone()
		model:SetAttribute("CaelusSourceVariant", variant)
		if state.activeMorph == CUSTOM_MORPH_NAME and state.activeCustomNeko then
			local skinColor = state.activeCustomNeko.skinColor
			recolorMatchingParts(model, DEFAULT_WHITE_NEKO_SKIN, skinColor)
			local beltShell = model:FindFirstChild("BeltShell")
			if beltShell and beltShell:IsA("BasePart") then
				beltShell.Color = skinColor
			end
		end
		local reference = model:FindFirstChild("Reference")
		if not (reference and reference:IsA("BasePart")) then
			model:Destroy()
			return false
		end
		for _, name in ipairs(beltNames) do
			local part = model:FindFirstChild(name)
			if not (part and part:IsA("BasePart")) then
				model:Destroy()
				clearLowerBaseWearTracking()
				return false
			end
			registerWearPart(
				part,
				torso,
				reference.CFrame:ToObjectSpace(part.CFrame),
				state.lowerBaseWearParts,
				state.lowerBaseWearBindings,
				"CaelusBeltPiece"
			)
		end
		reference:Destroy()
	else
		-- V3/V4 build this four-piece belt in the supplied controller rather
		-- than storing it as a model.  These are its exact source dimensions,
		-- mesh scales and Torso-relative transforms, with neutral part names.
		model = Instance.new("Model")
		local function makePiece(name, size, scale, relative)
			local part = Instance.new("Part")
			part.Name = name
			part.Size = size
			part.Color = lowerBeltPieceColor(name)
			part.Material = Enum.Material.SmoothPlastic
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.CFrame = torso.CFrame * relative
			part.Parent = model
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Scale = scale
			mesh.Parent = part
			registerWearPart(
				part,
				torso,
				relative,
				state.lowerBaseWearParts,
				state.lowerBaseWearBindings,
				"CaelusBeltPiece"
			)
			return part
		end

		local baseC0 = CFrame.new(
			1.01267099, 0.00664961338, -0.0108087659,
			0.00000600004569, 0.999901056, 0.0141194789,
			-0.999941051, 0.000160070136, -0.0109077059,
			-0.0109090377, -0.0141187273, 0.999840915
		)
		local baseRelative = baseC0:Inverse()
		local base = makePiece(
			"BeltBase",
			Vector3.new(0.90731889, 1.81463778, 0.90731889),
			Vector3.new(0.899999976, 0.400000006, 0.899999976),
			baseRelative
		)
		model.PrimaryPart = base
		makePiece(
			"BeltLayer",
			Vector3.new(0.90731889, 1.81463778, 0.90731889),
			Vector3.new(0.910000026, 0.300000012, 0.910000026),
			baseRelative
		)
		makePiece(
			"BeltBack",
			Vector3.new(0.90731889, 0.90731889, 0.90731889),
			Vector3.new(0.910000026, 0.300000012, 0.910000026),
			baseRelative * CFrame.new(
				0.0176836904, 0.00030521708, -0.000466041354,
				1.00000024, 0.000000000465661287, 0.000000000123691279,
				0.000000000465661287, 1, 0.000000000931322575,
				0.000000000123691279, 0.000000000931322575, 1
			):Inverse()
		)
		makePiece(
			"BeltCover",
			Vector3.new(0.898245931, 1.50614965, 0.90731889),
			Vector3.new(0.899999976, 0.400000006, 0.899999976),
			baseRelative * CFrame.new(
				0.0445814133, -0.000175714493, -0.0795190334,
				0.81916672, 0.00343200099, -0.573545337,
				-0.00668692915, 0.99997133, -0.00356695056,
				0.573516667, 0.00675718486, 0.819166183
			):Inverse()
		)
	end

	if hasRearPockets() then
		local rearColor = lowerRearAccessoryColor()
		local function makeRearAccessory(name, size, relative)
			local part = Instance.new("Part")
			part.Name = name
			part.Size = size
			part.Color = rearColor
			part.Material = Enum.Material.SmoothPlastic
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.CFrame = torso.CFrame * relative
			part.Parent = model
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Scale = Vector3.new(1, 1, 1)
			mesh.Parent = part
			registerWearPart(
				part,
				torso,
				relative,
				state.lowerBaseWearParts,
				state.lowerBaseWearBindings,
				"CaelusRearAccessoryPiece"
			)


		end

		makeRearAccessory(
			"RearAccessoryRight",
			Vector3.new(1.19235516, 1.19235516, 1.19235516),
			CFrame.new(
				0.435791016, -1.05861664, 0.316925049,
				0.0402599983, 0.00967502035, -0.999142468,
				-0.00159899995, 0.999952495, 0.00961843506,
				0.999188006, 0.00121039059, 0.0402735509
			)
		)
		makeRearAccessory(
			"RearAccessoryLeft",
			Vector3.new(1.19235528, 1.19235528, 1.19235528),
			CFrame.new(
				-0.433959961, -1.04584504, 0.334655762,
				0.0402599983, 0.00967502035, -0.999142468,
				-0.00159899995, 0.999952495, 0.00961843506,
				0.999188006, 0.00121039059, 0.0402735509
			)
		)
	end

	model.Name = "CaelusLowerBelt"
	model:SetAttribute("CaelusExpectedPieces", #names)
	model.Parent = container
	setLowerBaseWearVisible(not state.lowerArmorOn)
	trackVisualModel(model, true)
	shadow:SetAttribute("CaelusLowerWearPieces", #state.lowerBaseWearParts)
	shadow:SetAttribute("CaelusLowerWearMode", "OriginalBeltDirectCFrame")
	return lowerBaseWearIsHealthy(shadow)
end

ensureOriginalLowerBaseWear = function(shadow, forceRebuild)
	if activeLegacyPreservesEverything() then
		clearLowerBaseWearTracking()

		for _, child in ipairs(shadow:GetChildren()) do
			if child.Name == "CaelusLowerBelt"
				or child.Name == "CaelusLowerBaseWear"
			then
				child:Destroy()
			end
		end

		shadow:SetAttribute(
			"CaelusLowerBaseWearMode",
			"PreservedByVariant"
		)

		return true
	end

	if not forceRebuild and lowerBaseWearIsHealthy(shadow) then return true end
	return rebuildOriginalLowerBaseWear(shadow)
end

local function upperScarfIsHealthy(shadow)
	local names = {}
	for index = 1, upperScarfCount() do names[index] = "Scarf" .. index end
	return visualWearIsHealthy(
		shadow,
		"CaelusUpperScarf",
		names,
		state.upperScarfParts,
		state.upperScarfBindings
	)
end

local function rebuildOriginalUpperScarf(shadow)
	local torso = currentWearTorso(shadow)
	local container = currentWearContainer(shadow)
	local variant = scarfVariant()
	local versionTemplates = scarfTemplates[state.activeVersion]
	local template = versionTemplates and versionTemplates[variant]
	if not (torso and torso:IsA("BasePart") and template and container) then return false end

	clearUpperScarfTracking()
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == "CaelusUpperScarf" then child:Destroy() end
	end

	local model = template:Clone()
	model.Name = "CaelusUpperScarf"
	model:SetAttribute("CaelusSourceVariant", variant)
	if state.activeMorph == CUSTOM_MORPH_NAME and state.activeCustomNeko then
		recolorMatchingParts(model, DEFAULT_WHITE_NEKO_SKIN, state.activeCustomNeko.skinColor)
	elseif state.activeLegacyNeko and typeof(state.activeLegacySkinColor) == "Color3" then
		recolorMatchingParts(model, DEFAULT_WHITE_NEKO_SKIN, state.activeLegacySkinColor)

		local legacyConfig =
			environment.CaelusLegacyNekoConfig.variants[state.activeLegacyNeko]
		if legacyConfig and typeof(legacyConfig.accentColor) == "Color3" then
			recolorMatchingParts(
				model,
				Color3.fromRGB(232, 186, 200),
				legacyConfig.accentColor
			)
			recolorMatchingParts(
				model,
				BrickColor.new("Medium red").Color,
				legacyConfig.accentColor
			)
		end
	end
	local count = upperScarfCount()
	model:SetAttribute("CaelusExpectedPieces", count)
	local reference = model:FindFirstChild("Reference")
	if not (reference and reference:IsA("BasePart")) then
		model:Destroy()
		return false
	end

	for index = 1, count do
		local part = model:FindFirstChild("Scarf" .. index)
		if not (part and part:IsA("BasePart")) then
			model:Destroy()
			clearUpperScarfTracking()
			return false
		end
		registerWearPart(
			part,
			torso,
			reference.CFrame:ToObjectSpace(part.CFrame),
			state.upperScarfParts,
			state.upperScarfBindings,
			"CaelusScarfPiece"
		)
	end
	reference:Destroy()
	model.Parent = container
	setUpperScarfVisible(not state.upperArmorOn)
	trackVisualModel(model, true)
	shadow:SetAttribute("CaelusUpperScarfPieces", #state.upperScarfParts)
	shadow:SetAttribute("CaelusUpperScarfMode", "OriginalScarfDirectCFrame")
	return upperScarfIsHealthy(shadow)
end

ensureOriginalUpperScarf = function(shadow, forceRebuild)
	if activeLegacyPreservesEverything() then
		clearUpperScarfTracking()

		for _, child in ipairs(shadow:GetChildren()) do
			if child.Name == "CaelusUpperScarf" then
				child:Destroy()
			end
		end

		shadow:SetAttribute(
			"CaelusUpperScarfMode",
			"PreservedByVariant"
		)

		return true
	end

	if not forceRebuild and upperScarfIsHealthy(shadow) then return true end
	return rebuildOriginalUpperScarf(shadow)
end

local function syncArmorStateFromAttributes()
	if not state.armorReady then return end
	local shadow = state.shadow
	if not (shadow and shadow.Parent) then return end
	local lowerArmorOn = shadow:GetAttribute("CaelusLowerArmorOn")
	if type(lowerArmorOn) == "boolean" and lowerArmorOn ~= state.lowerArmorOn then
		updateArmor("lower", lowerArmorOn)
	end
	local upperArmorOn = shadow:GetAttribute("CaelusUpperArmorOn")
	if type(upperArmorOn) == "boolean" and upperArmorOn ~= state.upperArmorOn then
		updateArmor("upper", upperArmorOn)
	end
end

local function removeTemplateMotors(shadow)
	-- The original controller has now created its own animated Welds.  Removing
	-- only the template Motor6Ds prevents two joint systems fighting each other.
	for _, descendant in ipairs(shadow:GetDescendants()) do
		if descendant:IsA("Motor6D") then descendant:Destroy() end
	end
end

local function makeShadow(realRoot)
	local shadow = rigTemplate:Clone()
	shadow.Name = "CaelusNekoVisual_" .. player.UserId
	shadow:SetAttribute("CaelusNekoVisualRig", true)
	shadow:SetAttribute("CaelusLowerArmorOn", true)
	shadow:SetAttribute("CaelusUpperArmorOn", true)
	local visualRoot = shadow:FindFirstChild("HumanoidRootPart")
	local visualHumanoid = shadow:FindFirstChildOfClass("Humanoid")
	if not (visualRoot and visualRoot:IsA("BasePart") and visualHumanoid) then
		shadow:Destroy()
		return nil, nil, "Visual R6 template is incomplete"
	end
	pcall(function() visualHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
	pcall(function() visualHumanoid.BreakJointsOnDeath = false end)
	pcall(function() visualHumanoid.RequiresNeck = false end)
	pcall(function() visualHumanoid.AutoRotate = false end)
	pcall(function() visualHumanoid.PlatformStand = true end)
	pcall(function() visualHumanoid.EvaluateStateMachine = false end)
	trackVisualModel(shadow, true)
	visualRoot.Anchored = true
	moveWholeRigToRoot(shadow, visualRoot, realRoot.CFrame)
	shadow.Parent = workspace
	moveWholeRigToRoot(shadow, visualRoot, realRoot.CFrame)

	local command = Instance.new("BindableEvent")
	command.Name = "CaelusNekoCommand"
	command.Parent = shadow
	local armorEvent = Instance.new("BindableEvent")
	armorEvent.Name = "CaelusArmorToggle"
	armorEvent.Parent = shadow
	return shadow, visualRoot, nil
end

local function startFollowing(shadow, visualRoot, realRoot, serial)
	local function follow()
		if state.destroyed or state.sessionSerial ~= serial or state.shadow ~= shadow
		or not shadow.Parent or not realRoot.Parent or not visualRoot.Parent then return end
		visualRoot.Anchored = true
		visualRoot.CFrame = realRoot.CFrame
		zeroVelocity(visualRoot)
		enforceVisualPhysics()
		syncArmorStateFromAttributes()
		enforceHiddenArmor()
	end
	local function renderProtection()
		follow()
		enforceDirectWear()
	end
	follow()
	rememberFollow(shadow.DescendantAdded:Connect(function(descendant)
		trackVisualPart(descendant, false)
	end))
	rememberFollow(RunService.Stepped:Connect(follow))
	local bindingName = "CaelusNekoProtect_" .. tostring(player.UserId) .. "_" .. tostring(serial)
	local bound = pcall(function()
		RunService:BindToRenderStep(
			bindingName,
			Enum.RenderPriority.Last.Value,
			renderProtection
		)
	end)
	if bound then
		state.visibilityBinding = bindingName
	else
		rememberFollow(RunService.RenderStepped:Connect(renderProtection))
	end
end

local applying = false
local function applyMorph(versionName, morphName)
	if applying or state.destroyed then return end
	applying = true
	cleanupShadow()
	local serial = state.sessionSerial
	local character, humanoid, realRoot = realCharacter(20)
	if not character then
		selectedText.Text = "Character/Humanoid/Root was not ready after 20 seconds"
		startupLog(selectedText.Text)
		applying = false
		flashButton(respawnButton, "character?")
		return
	end
	if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		selectedText.Text = "Direct Wear requires an R6 character"
		startupLog(selectedText.Text)
		applying = false
		flashButton(r6Button, "R6 required")
		return
	end
	local legacyConfig = environment.CaelusLegacyNekoConfig.variants[morphName]
	if legacyConfig then
		versionName = "V4"
	end
	local version = catalog:FindFirstChild(versionName)
	local sourceMorphName
	if legacyConfig then
		sourceMorphName = WHITE_NEKO_SOURCE_MORPH
	else
		sourceMorphName = morphName == CUSTOM_MORPH_NAME
			and WHITE_NEKO_SOURCE_MORPH or morphName
	end
	local template = version and version:FindFirstChild(sourceMorphName)
	if not (template and template:IsA("LocalScript")) then
		applying = false
		flashButton(versionFolder:FindFirstChild(versionName), "missing")
		return
	end

	local shadow
	local visualRoot
	local controller
	local shadowError
	if legacyConfig and legacyConfig.customController then
		shadow, visualRoot, controller, shadowError =
			environment.CaelusLegacyNekoConfig:createCustomShadow(
				morphName,
				realRoot
			)
	else
		shadow, visualRoot, shadowError = makeShadow(realRoot)
	end
	if not shadow then
		selectedText.Text =
			"Custom model failed: " .. tostring(shadowError or "unknown")
		startupLog(selectedText.Text)
		applying = false
		return
	end
	state.shadow = shadow
	state.command = shadow:FindFirstChild("CaelusNekoCommand")
	state.armorEvent = shadow:FindFirstChild("CaelusArmorToggle")
	state.activeMorph = morphName
	state.activeVersion = versionName
	state.activeLegacyNeko = legacyConfig and morphName or nil
	if morphName == CUSTOM_MORPH_NAME and state.customNeko then
		local assetIds = {}
		for _, assetId in ipairs(state.customNeko.assetIds) do
			table.insert(assetIds, assetId)
		end
		state.activeCustomNeko = {
			name = state.customNeko.name,
			version = state.customNeko.version or versionName,
			skinColor = state.customNeko.skinColor,
			assetIds = assetIds,
			use3DPants = state.customNeko.use3DPants ~= false,
		}
	else
		state.activeCustomNeko = nil
	end
	startFollowing(shadow, visualRoot, realRoot, serial)

	if not (legacyConfig and legacyConfig.customController) then
		controller = template:Clone()
		controller.Name = "CaelusNekoOriginalController"
		controller:SetAttribute("CaelusSessionActive", true)
		controller:SetAttribute("CaelusStartError", nil)
		controller.Parent = shadow
	end

	state.controller = controller

	if controller
		and controller.Parent
		and controller:IsA("LocalScript")
	then
		state.clawsActive =
			controller:GetAttribute("CaelusAggressive") == true

		rememberFollow(
			controller:GetAttributeChangedSignal(
				"CaelusAggressive"
			):Connect(function()
				if state.controller == controller then
					state:syncClawRunStateFromController()
				end
			end)
		)
	end

	if legacyConfig and not legacyConfig.customController then
		local legacyReady, legacyProblem =
			environment.CaelusLegacyNekoConfig:patchController(
				controller,
				morphName
			)

		if not legacyReady then
			selectedText.Text =
				"Variant failed: " .. tostring(legacyProblem)
			startupLog(selectedText.Text)
			cleanupShadow()
			applying = false
			return
		end

		local legacySkinColor =
			controller:GetAttribute("CaelusLegacySkinColor")

		if typeof(legacySkinColor) == "Color3" then
			state.activeLegacySkinColor = legacySkinColor
		else
			state.activeLegacySkinColor = DEFAULT_WHITE_NEKO_SKIN
		end
	elseif legacyConfig and legacyConfig.customController then
		state.activeLegacySkinColor = nil
	else
		state.activeLegacySkinColor = nil
	end

	if legacyConfig
	and legacyConfig.normalizeSkinDetails == true
	and typeof(state.activeLegacySkinColor) == "Color3" then
		environment.CaelusNormalizeLegacySkinDetails(
			controller,
			state.activeLegacySkinColor
		)
	end

	if morphName == CUSTOM_MORPH_NAME then
		local customReady, customProblem = prepareCustomController(controller, shadow)
		if not customReady then
			selectedText.Text = tostring(customProblem)
			cleanupShadow()
			applying = false
			flashButton(versionFolder:FindFirstChild(versionName), "custom failed")
			return
		end
	end

	-- The five original qPerfectionWeld helpers assemble the imported mesh
	-- groups exactly as in the supplied place.  They touch only this visual rig.
	for _, descendant in ipairs(controller:GetDescendants()) do
		if descendant:IsA("LocalScript") and descendant.Name == "qPerfectionWeld" then
			local helperReady, helperProblem = runEmbedded(descendant, false)
			if not helperReady then
				selectedText.Text = "Model setup failed: " .. tostring(helperProblem or "unknown")
				startupLog(selectedText.Text)
				cleanupShadow()
				applying = false
				flashButton(versionFolder:FindFirstChild(versionName), "setup failed")
				return
			end
		end
	end

	local started, startProblem = runEmbedded(controller, true)
	if not started then
		selectedText.Text =
			"Controller compile failed: "
				.. tostring(startProblem or "unknown")
		startupLog(selectedText.Text)
		applying = false
		cleanupShadow()
		flashButton(
			versionFolder:FindFirstChild(versionName),
			"compile failed"
		)
		return
	end

	local deadline = os.clock() + 20
	repeat
		task.wait(0.05)
	until state.sessionSerial ~= serial
		or state.controller ~= controller
		or controller:GetAttribute("CaelusReady") == true
		or controller:GetAttribute("CaelusStartError") ~= nil
		or os.clock() >= deadline

	if state.sessionSerial ~= serial
		or state.controller ~= controller
	then
		applying = false
		return
	end

	local controllerProblem = controller:GetAttribute("CaelusStartError")
	if controller:GetAttribute("CaelusReady") ~= true then
		controllerProblem = controllerProblem
			or (
				"controller timeout at "
					.. tostring(
						controller:GetAttribute("CaelusStage")
							or "unknown"
					)
			)

		selectedText.Text =
			"Controller start failed: " .. tostring(controllerProblem)
		startupLog(selectedText.Text)
		cleanupShadow()
		applying = false
		flashButton(
			versionFolder:FindFirstChild(versionName),
			"start failed"
		)
		return
	end

	-- Melanie installs its outfit in a delayed coroutine after the controller
	-- announces readiness.  Let that original assembly finish before Direct
	-- Wear transfers the completed visual pieces to the live R6 character.
	if legacyConfig and legacyConfig.customController then
		task.wait(0.75)
		if state.sessionSerial ~= serial or state.controller ~= controller then
			applying = false
			return
		end
	end

	startupLog(
		"Controller ready: "
			.. tostring(versionName)
			.. " / "
			.. tostring(morphName)
	)

	if state.activeLegacyNeko
		and not (legacyConfig and legacyConfig.customController)
	then
		if legacyConfig and typeof(legacyConfig.skinColor) == "Color3" then
			state.activeLegacySkinColor = legacyConfig.skinColor
		else
			local legacyBodyColors = controller:FindFirstChildWhichIsA("BodyColors", true)
			if legacyBodyColors then
				local okColor, headColor = pcall(function()
					return legacyBodyColors.HeadColor3
				end)
				if okColor and typeof(headColor) == "Color3" then
					state.activeLegacySkinColor = headColor
				end
			end
		end

		if typeof(state.activeLegacySkinColor) == "Color3" then
			setRigSkinColor(shadow, state.activeLegacySkinColor)

			local shadowBodyColors = shadow:FindFirstChildOfClass("BodyColors")
			if not shadowBodyColors then
				shadowBodyColors = Instance.new("BodyColors")
				shadowBodyColors.Name = "CaelusLegacyBodyColors"
				shadowBodyColors.Parent = shadow
			end
			setBodyColors(shadowBodyColors, state.activeLegacySkinColor)

			for _, descendant in ipairs(controller:GetDescendants()) do
				if descendant:IsA("BodyColors") then
					setBodyColors(descendant, state.activeLegacySkinColor)
				end
			end
		end
	end

	removeTemplateMotors(shadow)
	trackVisualModel(shadow, true)
	visualRoot.Anchored = true
	state.morphPantsTemplate = clothingTemplate(shadow, "Pants", "PantsTemplate")
	state.morphShirtTemplate = clothingTemplate(shadow, "Shirt", "ShirtTemplate")
	state.morphShirtGraphicTemplate = clothingTemplate(shadow, "ShirtGraphic", "Graphic")
	collectArmorParts(shadow, controller)
	state.armorReady = false
	if not (legacyConfig and legacyConfig.customController) then
		if not rebuildOriginalLowerBaseWear(shadow) then
			cleanupShadow()
			applying = false
			return
		end

		if not rebuildOriginalUpperScarf(shadow) then
			cleanupShadow()
			applying = false
			return
		end
	end
	state.armorReady = true
	if not state.clothingGuard:uses3DPants() then
		setArmorPartsVisible(state.lowerArmorParts, false)
	end
	if state.armorEvent then
		rememberFollow(state.armorEvent.Event:Connect(updateArmor))
	end
	syncArmorStateFromAttributes()

	local mounted, mountProblem = mountDirectWear(shadow, character, humanoid, realRoot)
	if not mounted then
		selectedText.Text = "Direct Wear failed: " .. tostring(mountProblem or "unknown")
		startupLog(selectedText.Text)
		cleanupShadow()
		applying = false
		flashButton(r6Button, "wear failed")
		return
	end

	selectedText.Text = state.activeCustomNeko and state.activeCustomNeko.name
		or DISPLAY_NAMES[morphName] or morphName
	selectedValue.Value = morphName
	rebuildKeyPanel(versionName)
	playNamedSound(versionFolder, "Clicksound")
	applying = false
end

for _, morphName in ipairs(MORPHS) do
	local button = morphList:FindFirstChild(morphName)
	if button and button:IsA("GuiButton") then
		remember(button.MouseEnter:Connect(function() playNamedSound(morphList, "Hoversound") end))
		remember(button.Activated:Connect(function()
			state.selectedMorph = morphName
			selectedText.Text = DISPLAY_NAMES[morphName] or morphName
			selectedValue.Value = morphName
			playNamedSound(morphList, "Clicksound")
		end))
	end
end

for _, morphName in ipairs(environment.CaelusLegacyNekoConfig.order) do
	local button = environment.CaelusLegacyNekoConfig.buttons[morphName]
	if button and button:IsA("GuiButton") then
		remember(button.MouseEnter:Connect(function()
			playNamedSound(morphList, "Hoversound")
		end))
		remember(button.Activated:Connect(function()
			state.selectedMorph = morphName
			state.selectedVersion = "V4"
			selectedText.Text = DISPLAY_NAMES[morphName] or morphName
			selectedValue.Value = morphName
			playNamedSound(morphList, "Clicksound")
		end))
	end
end

for _, versionName in ipairs(VERSIONS) do
	local button = versionFolder:FindFirstChild(versionName)
	if button and button:IsA("GuiButton") then
		remember(button.MouseEnter:Connect(function() playNamedSound(versionFolder, "Hoversound") end))
		remember(button.Activated:Connect(function()
			state.selectedVersion = versionName
			if not state.selectedMorph then
				flashButton(button, "select first")
				playNamedSound(versionFolder, "errorsound")
				return
			end
			task.spawn(applyMorph, versionName, state.selectedMorph)
		end))
	end
end

remember(r6Button.Activated:Connect(function()
	if not state.selectedMorph then
		flashButton(r6Button, "select first")
		return
	end
	task.spawn(applyMorph, state.selectedVersion or "V4", state.selectedMorph)
end))

-- Rebuild the client-side driver and remount the visible Neko on the real R6 character.
remember(respawnButton.Activated:Connect(function()
	local morphName = state.activeMorph or state.selectedMorph
	local versionName = state.activeVersion or state.selectedVersion or "V4"
	if not morphName then
		flashButton(respawnButton, "select first")
		return
	end
	task.spawn(applyMorph, versionName, morphName)
end))

remember(keysButton.Activated:Connect(function()
	state.keyPanelOpen = not state.keyPanelOpen
	rebuildKeyPanel(state.activeVersion or state.selectedVersion or "V4")
end))

environment.CaelusNekoAPI = {
	Morphs = {},
	Versions = {},
	Session = state,
}

for _, morphName in ipairs(MORPHS) do
	table.insert(environment.CaelusNekoAPI.Morphs, morphName)
end

for _, morphName in ipairs(environment.CaelusLegacyNekoConfig.order) do
	table.insert(environment.CaelusNekoAPI.Morphs, morphName)
end

for _, versionName in ipairs(VERSIONS) do
	table.insert(environment.CaelusNekoAPI.Versions, versionName)
end

function environment.CaelusNekoAPI:Apply(morphName, versionName)
	if type(morphName) ~= "string" or morphName == "" then
		return false, "Missing Neko morph name."
	end

	if not table.find(MORPHS, morphName)
		and environment.CaelusLegacyNekoConfig.variants[morphName] == nil
	then
		return false, "Unknown Neko morph: " .. tostring(morphName)
	end

	if environment.CaelusLegacyNekoConfig.variants[morphName] then
		versionName = "V4"
	elseif not table.find(VERSIONS, versionName) then
		versionName = "V4"
	end

	state.selectedMorph = morphName
	state.selectedVersion = versionName
	selectedText.Text = DISPLAY_NAMES[morphName] or morphName
	selectedValue.Value = morphName

	task.spawn(applyMorph, versionName, morphName)
	return true
end

function environment.CaelusNekoAPI:ShowMenu()
	if gui and gui.Parent then
		gui.Enabled = true
	end
end

function environment.CaelusNekoAPI:HideMenu()
	if gui and gui.Parent then
		gui.Enabled = false
	end
end

function environment.CaelusNekoAPI:GetActiveMorph()
	return state.activeMorph, state.activeVersion
end

function environment.CaelusNekoAPI:SetVersion(versionName)
	if not table.find(VERSIONS, versionName) then
		return false, "Unknown Neko version: " .. tostring(versionName)
	end

	state.selectedVersion = versionName

	if environment.CaelusPendalarNekoUI
		and environment.CaelusPendalarNekoUI.VersionLabel
	then
		environment.CaelusPendalarNekoUI.VersionLabel.Text =
			"Selected Neko Version : " .. versionName
	end

	return true
end

function environment.CaelusNekoAPI:GetVersion()
	return state.selectedVersion or state.activeVersion or "V4"
end

function environment.CaelusNekoAPI:GetSelectedCustom()
	if state.selectedMorph ~= CUSTOM_MORPH_NAME
		or not state.customNeko
	then
		return nil
	end

	return copyCustomConfig(state.customNeko)
end

function environment.CaelusNekoAPI:SaveCustom(
	name,
	versionName,
	skinColor,
	assetText,
	use3DPants,
	previousName
)
	local normalizedName, nameProblem = normalizePresetName(name)

	if not normalizedName then
		return false, nameProblem
	end

	if typeof(skinColor) ~= "Color3" then
		return false, "Skin color must be Color3."
	end

	if not validVersion(versionName) then
		versionName = "V4"
	end

	local assetIds, assetProblem =
		parseCustomAssetIds(assetText or "")

	if not assetIds then
		return false, assetProblem
	end

	local existingWithName = state.savedPresets[normalizedName]

	if existingWithName
		and normalizedName ~= previousName
	then
		return false, "A saved Neko already uses that name."
	end

	local previousPath

	if previousName and state.savedPresets[previousName] then
		previousPath = state.savedPresets[previousName].filePath
	end

	local config = {
		name = normalizedName,
		version = versionName,
		skinColor = skinColor,
		assetIds = assetIds,
		use3DPants = use3DPants ~= false,
	}

	local exported, exportResult =
		savePresetToDisk(config, previousPath)

	if previousName and previousName ~= normalizedName then
		state.savedPresets[previousName] = nil
	end

	state.savedPresets[normalizedName] = copyCustomConfig(config)

	if exported then
		state.savedPresets[normalizedName].filePath = exportResult
		FILE_API.writePresetIndex()
	else
		startupLog(
			"Pendalar preset is session-only: "
				.. tostring(exportResult)
		)
	end

	refreshPresetButtons()

	state.customNeko = copyCustomConfig(config)
	state.selectedMorph = CUSTOM_MORPH_NAME
	state.selectedVersion = versionName
	selectedText.Text = normalizedName
	selectedValue.Value = CUSTOM_MORPH_NAME

	return true, normalizedName
end

function environment.CaelusNekoAPI:ApplySelectedCustom()
	if not state.customNeko then
		return false, "No Custom Neko is selected."
	end

	task.spawn(
		applyMorph,
		state.customNeko.version or state.selectedVersion or "V4",
		CUSTOM_MORPH_NAME
	)

	return true
end

function environment.CaelusNekoAPI:Destroy()
	if state and type(state.Destroy) == "function" then
		state:Destroy()
	end
end

if type(environment.PendalarNekoRequest) == "table" then
	state.pendalarRequest = environment.PendalarNekoRequest
	environment.PendalarNekoRequest = nil

	if state.pendalarRequest.HideGui ~= false then
		gui.Enabled = false
	end

	state.pendalarApplyOk, state.pendalarApplyProblem =
		environment.CaelusNekoAPI:Apply(
			state.pendalarRequest.Morph
				or state.pendalarRequest.morph
				or state.pendalarRequest.Name
				or state.pendalarRequest.name,
			state.pendalarRequest.Version
				or state.pendalarRequest.version
				or "V4"
		)

	if not state.pendalarApplyOk then
		warn(
			"[Caelus Neko] Pendalar request failed: "
				.. tostring(state.pendalarApplyProblem)
		)
	end
end

if environment.CaelusNekoHubLaunchToken ~= startupLog then
	cleanupShadow()
	disconnectArray(state.connections)
	if gui and gui.Parent then gui:Destroy() end
	if catalog and catalog.Parent then catalog:Destroy() end
	if environment.CaelusNekoOriginalRuntimeSession == state then
		environment.CaelusNekoOriginalRuntimeSession = nil
	end
	if environment.CaelusNekoOriginalSession == state then
		environment.CaelusNekoOriginalSession = nil
	end
	if environment.CaelusNekoShadowSession == state then
		environment.CaelusNekoShadowSession = nil
	end
	if environment.CaelusNekoAPI
		and environment.CaelusNekoAPI.Session == state
	then
		environment.CaelusNekoAPI = nil
	end
	return
end

local PENDALAR_SCRIPTS = {
	{
		Name = "R6 Follow Animation",
		Description = "Follow a selected player with an R6 animation",
		Source = [=[
loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/MrArgy/MrArgyRobloxScripts/refs/heads/main/bangie2_secured.txt"
))()
]=],
	},
}

environment.CaelusPendalarNekoUI = {
	Session = state,
	LaunchToken = startupLog,
	Window = nil,
	GuiRoot = nil,
	BuildStarted = false,
	VersionLabel = nil,
	EditorStatus = nil,
	EditorSkinColor = DEFAULT_WHITE_NEKO_SKIN,
	EditorUse3DPants = true,
	EditorPreviousName = nil,
	AttackFlingEnabled = false,
	AttackFlingBusy = false,
	AttackFlingRange = 30,
	AttackFlingDuration = 0.42,
	AttackFlingSimulationConnection = nil,
	Scripts = PENDALAR_SCRIPTS,
	LibraryUrl =
		"https://raw.githubusercontent.com/shidemuri/scripts/main/newuilib.lua",
}
state.pendalarUI = environment.CaelusPendalarNekoUI

function environment.CaelusPendalarNekoUI:Fetch(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)

	if ok and type(body) == "string" and body ~= "" then
		return body
	end

	return nil, tostring(body or "HTTP request failed")
end

function environment.CaelusPendalarNekoUI:ReplacePlain(sourceText, from, to)
	local parts = {}
	local startIndex = 1
	local count = 0

	while true do
		local first, last = string.find(
			sourceText,
			from,
			startIndex,
			true
		)

		if not first then
			table.insert(parts, string.sub(sourceText, startIndex))
			break
		end

		table.insert(parts, string.sub(sourceText, startIndex, first - 1))
		table.insert(parts, to)

		count = count + 1
		startIndex = last + 1
	end

	return table.concat(parts), count
end

function environment.CaelusPendalarNekoUI:Recolor(sourceText)
	local replacements = {
		{
			"Color3.fromRGB(38, 45, 71)",
			"Color3.fromRGB(166, 58, 99)",
		},
		{
			"Color3.fromRGB(26, 32, 58)",
			"Color3.fromRGB(137, 43, 79)",
		},
		{
			"Color3.fromRGB(26,32,58)",
			"Color3.fromRGB(137,43,79)",
		},
		{
			"Color3.fromRGB(69, 69, 107)",
			"Color3.fromRGB(194, 73, 115)",
		},
		{
			"Color3.fromRGB(103, 103, 158)",
			"Color3.fromRGB(219, 110, 149)",
		},
		{
			"Color3.fromRGB(100, 100, 156)",
			"Color3.fromRGB(208, 97, 137)",
		},
		{
			"Color3.fromRGB(53, 53, 82)",
			"Color3.fromRGB(126, 38, 70)",
		},
		{
			"Color3.fromRGB(102, 61, 255)",
			"Color3.fromRGB(255, 110, 173)",
		},
		{
			"Color3.fromRGB(70, 70, 224)",
			"Color3.fromRGB(221, 107, 145)",
		},
	}
	local total = 0

	for _, replacement in ipairs(replacements) do
		local count

		sourceText, count = self:ReplacePlain(
			sourceText,
			replacement[1],
			replacement[2]
		)

		total = total + count
	end

	return sourceText, total
end

function environment.CaelusPendalarNekoUI:GetGuiRoots()
	local roots = {}
	local seen = {}

	local function add(root)
		if root and not seen[root] then
			seen[root] = true
			table.insert(roots, root)
		end
	end

	add(player:FindFirstChildOfClass("PlayerGui"))

	pcall(function()
		add(game:GetService("CoreGui"))
	end)

	if type(gethui) == "function" then
		pcall(function()
			add(gethui())
		end)
	end

	return roots
end

function environment.CaelusPendalarNekoUI:SetAttackFling(enabled)
	self.AttackFlingEnabled = enabled == true

	if self.AttackFlingEnabled
		and not self.AttackFlingSimulationConnection
	then
		self.AttackFlingSimulationConnection =
			RunService.Heartbeat:Connect(function()
				pcall(function()
					if type(sethiddenproperty) == "function" then
						sethiddenproperty(
							player,
							"MaximumSimulationRadius",
							math.huge
						)
						sethiddenproperty(
							player,
							"SimulationRadius",
							math.huge
						)
					end

					player.ReplicationFocus = workspace
				end)
			end)
	elseif not self.AttackFlingEnabled
		and self.AttackFlingSimulationConnection
	then
		self.AttackFlingSimulationConnection:Disconnect()
		self.AttackFlingSimulationConnection = nil
	end

	return true
end

function environment.CaelusPendalarNekoUI:TargetFromScreenPoint(
	screenX,
	screenY
)
	local character = player.Character
	local camera = workspace.CurrentCamera

	if not character or not camera then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character,
		state.shadow,
	}

	local ray = camera:ViewportPointToRay(screenX, screenY)
	local result = workspace:Raycast(
		ray.Origin,
		ray.Direction * 5000,
		params
	)

	if not result then
		return nil
	end

	local targetModel =
		result.Instance:FindFirstAncestorOfClass("Model")

	if not targetModel then
		return nil
	end

	local targetPlayer =
		Players:GetPlayerFromCharacter(targetModel)

	if not targetPlayer or targetPlayer == player then
		return nil
	end

	local targetHumanoid =
		targetModel:FindFirstChildOfClass("Humanoid")
	local targetRoot =
		targetModel:FindFirstChild("HumanoidRootPart")
		or targetModel:FindFirstChild("Torso")
		or targetModel:FindFirstChild("UpperTorso")

	if not targetHumanoid
		or targetHumanoid.Health <= 0
		or not targetRoot
		or not targetRoot:IsA("BasePart")
	then
		return nil
	end

	if (targetRoot.Position - root.Position).Magnitude
		> self.AttackFlingRange
	then
		return nil
	end

	return targetModel, targetRoot
end

function environment.CaelusPendalarNekoUI:FlingAtScreenPoint(
	screenX,
	screenY
)
	if not self.AttackFlingEnabled
		or self.AttackFlingBusy
	then
		return false
	end

	local targetModel, targetRoot =
		self:TargetFromScreenPoint(screenX, screenY)

	if not targetModel or not targetRoot then
		return false
	end

	local character = player.Character
	local humanoid =
		character and character:FindFirstChildOfClass("Humanoid")
	local root =
		character and character:FindFirstChild("HumanoidRootPart")

	if not character
		or not humanoid
		or humanoid.Health <= 0
		or not root
	then
		return false
	end

	self.AttackFlingBusy = true

	task.spawn(function()
		local savedCFrame = root.CFrame
		local savedLinear = root.AssemblyLinearVelocity
		local savedAngular = root.AssemblyAngularVelocity
		local savedAutoRotate = humanoid.AutoRotate
		local collisionState = {}

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				collisionState[descendant] = descendant.CanCollide

				if descendant ~= root then
					descendant.CanCollide = false
				end
			end
		end

		root.CanCollide = true
		humanoid.AutoRotate = false

		local stabilizer = Instance.new("BodyVelocity")
		stabilizer.Name = "CaelusAttackFlingStabilizer"
		stabilizer.Velocity = Vector3.zero
		stabilizer.MaxForce =
			Vector3.new(1e9, 1e9, 1e9)
		stabilizer.P = 1e5
		stabilizer.Parent = root

		local spin = Instance.new("BodyAngularVelocity")
		spin.Name = "CaelusAttackFlingSpin"
		spin.AngularVelocity = Vector3.new(0, 65000, 0)
		spin.MaxTorque =
			Vector3.new(math.huge, math.huge, math.huge)
		spin.P = math.huge
		spin.Parent = root

		local started = os.clock()
		local phase = 0

		while self.AttackFlingEnabled
			and targetModel.Parent
			and targetRoot.Parent
			and character.Parent
			and humanoid.Health > 0
			and os.clock() - started < self.AttackFlingDuration
		do
			phase = phase + 1

			local offset

			if phase % 4 == 0 then
				offset = CFrame.new(0.45, 0, 0)
			elseif phase % 4 == 1 then
				offset = CFrame.new(-0.45, 0, 0)
			elseif phase % 4 == 2 then
				offset = CFrame.new(0, 0, 0.45)
			else
				offset = CFrame.new(0, 0, -0.45)
			end

			root.CFrame = targetRoot.CFrame * offset
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity =
				Vector3.new(0, 65000, 0)

			RunService.Heartbeat:Wait()
		end

		pcall(function()
			spin:Destroy()
		end)

		pcall(function()
			stabilizer:Destroy()
		end)

		if root and root.Parent then
			local away =
				savedCFrame.Position - targetRoot.Position

			if away.Magnitude < 0.1 then
				away = -targetRoot.CFrame.LookVector
			else
				away = away.Unit
			end

			local safePosition =
				savedCFrame.Position + away * 2.5

			root.CFrame =
				CFrame.new(safePosition)
				* savedCFrame.Rotation

			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero

			local stableUntil = os.clock() + 0.2

			while root.Parent
				and os.clock() < stableUntil
			do
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				RunService.Heartbeat:Wait()
			end

			root.AssemblyLinearVelocity = savedLinear
			root.AssemblyAngularVelocity = savedAngular
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = savedAutoRotate
		end

		for part, canCollide in pairs(collisionState) do
			if part and part.Parent then
				part.CanCollide = canCollide
			end
		end

		self.AttackFlingBusy = false
	end)

	return true
end

function environment.CaelusPendalarNekoUI:RunScript(scriptEntry)
	local sourceText = scriptEntry.Source or scriptEntry.source

	if type(sourceText) ~= "string" or sourceText == "" then
		local url = scriptEntry.Url or scriptEntry[2]

		if type(url) ~= "string" or url == "" then
			return false, "Script Source/URL is missing."
		end

		local fetchProblem
		sourceText, fetchProblem = self:Fetch(url)

		if not sourceText then
			return false, fetchProblem
		end
	end

	if type(loadstring) ~= "function" then
		return false, "loadstring() is unavailable."
	end

	local chunk, compileProblem = loadstring(
		sourceText,
		"=PendalarScript"
	)

	if not chunk then
		return false, compileProblem
	end

	task.spawn(function()
		local ok, runtimeProblem = pcall(chunk)

		if not ok then
			warn(
				"[Pendalar Scripts] "
					.. tostring(runtimeProblem)
			)
		end
	end)

	return true
end

function environment.CaelusPendalarNekoUI:CreateColorPicker(tab)
	local scrollingFrame =
		tab.Tab:FindFirstChildOfClass("ScrollingFrame")

	if not scrollingFrame then
		return
	end

	local holder = Instance.new("Frame")
	holder.Name = "SkinColorPicker"
	holder.Size = UDim2.fromOffset(385, 205)
	holder.BackgroundColor3 = Color3.fromRGB(194, 73, 115)
	holder.BorderSizePixel = 0
	holder.Parent = scrollingFrame
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 5)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 7)
	title.Size = UDim2.new(1, -24, 0, 24)
	title.Font = Enum.Font.Roboto
	title.Text = "Skin Color"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = holder

	local sv = Instance.new("ImageButton")
	sv.Name = "SaturationValue"
	sv.AutoButtonColor = false
	sv.Position = UDim2.fromOffset(12, 38)
	sv.Size = UDim2.fromOffset(300, 120)
	sv.BorderSizePixel = 0
	sv.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
	sv.Image = "rbxassetid://4155801252"
	sv.Parent = holder
	Instance.new("UICorner", sv).CornerRadius = UDim.new(0, 4)

	local hue = Instance.new("ImageButton")
	hue.Name = "Hue"
	hue.AutoButtonColor = false
	hue.Position = UDim2.fromOffset(324, 38)
	hue.Size = UDim2.fromOffset(48, 120)
	hue.BorderSizePixel = 0
	hue.Parent = holder
	Instance.new("UICorner", hue).CornerRadius = UDim.new(0, 4)

	local hueGradient = Instance.new("UIGradient")
	hueGradient.Rotation = 90
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
		ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
		ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
		ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
		ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
		ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
		ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
	})
	hueGradient.Parent = hue

	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Position = UDim2.fromOffset(12, 168)
	preview.Size = UDim2.fromOffset(34, 25)
	preview.BorderSizePixel = 0
	preview.Parent = holder
	Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

	local colorText = Instance.new("TextLabel")
	colorText.BackgroundTransparency = 1
	colorText.Position = UDim2.fromOffset(55, 165)
	colorText.Size = UDim2.new(1, -67, 0, 30)
	colorText.Font = Enum.Font.Roboto
	colorText.TextColor3 = Color3.new(1, 1, 1)
	colorText.TextSize = 14
	colorText.TextXAlignment = Enum.TextXAlignment.Left
	colorText.Parent = holder

	self.ColorPicker = {
		Holder = holder,
		SV = sv,
		Hue = hue,
		Preview = preview,
		Text = colorText,
		H = 0.08,
		S = 0.35,
		V = 1,
	}

	function self.ColorPicker:SetColor(color)
		local h, s, v = color:ToHSV()
		self.H = h
		self.S = s
		self.V = v
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		preview.BackgroundColor3 = color

		colorText.Text = string.format(
			"#%02X%02X%02X   RGB %d, %d, %d",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5),
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5)
		)

		environment.CaelusPendalarNekoUI.EditorSkinColor =
			color
	end

	function self.ColorPicker:UpdateSV(position)
		local x = math.clamp(
			(position.X - sv.AbsolutePosition.X)
				/ math.max(sv.AbsoluteSize.X, 1),
			0,
			1
		)
		local y = math.clamp(
			(position.Y - sv.AbsolutePosition.Y)
				/ math.max(sv.AbsoluteSize.Y, 1),
			0,
			1
		)

		self.S = x
		self.V = 1 - y

		self:SetColor(
			Color3.fromHSV(self.H, self.S, self.V)
		)
	end

	function self.ColorPicker:UpdateHue(position)
		local y = math.clamp(
			(position.Y - hue.AbsolutePosition.Y)
				/ math.max(hue.AbsoluteSize.Y, 1),
			0,
			1
		)

		self.H = y
		sv.BackgroundColor3 =
			Color3.fromHSV(self.H, 1, 1)

		self:SetColor(
			Color3.fromHSV(self.H, self.S, self.V)
		)
	end

	local svDragging = false
	local hueDragging = false

	sv.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			svDragging = true
			self.ColorPicker:UpdateSV(input.Position)
		end
	end)

	hue.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			hueDragging = true
			self.ColorPicker:UpdateHue(input.Position)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if svDragging then
				self.ColorPicker:UpdateSV(input.Position)
			elseif hueDragging then
				self.ColorPicker:UpdateHue(input.Position)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			svDragging = false
			hueDragging = false
		end
	end)

	self.ColorPicker:SetColor(self.EditorSkinColor)
	scrollingFrame.CanvasSize =
		UDim2.fromOffset(
			scrollingFrame.CanvasSize.X.Offset,
			scrollingFrame.CanvasSize.Y.Offset + 215
		)
end

function environment.CaelusPendalarNekoUI:LoadEditorSelection()
	local config = environment.CaelusNekoAPI:GetSelectedCustom()

	if not config then
		self.EditorStatus.Text =
			"Select a saved Custom Neko first."
		return
	end

	self.EditorPreviousName = config.name
	self.EditorName.Text = config.name or ""
	self.EditorVersion = config.version or "V4"
	self.EditorUse3DPants = config.use3DPants ~= false

	local ids = {}

	for _, assetId in ipairs(config.assetIds or {}) do
		table.insert(ids, tostring(assetId))
	end

	self.EditorAssets.Text = table.concat(ids, ", ")
	self.EditorSkinColor =
		config.skinColor or DEFAULT_WHITE_NEKO_SKIN

	if self.ColorPicker then
		self.ColorPicker:SetColor(self.EditorSkinColor)
	end

	self.EditorStatus.Text =
		"Loaded : " .. tostring(config.name)
end

function environment.CaelusPendalarNekoUI:SaveEditor()
	local ok, result = environment.CaelusNekoAPI:SaveCustom(
		self.EditorName:GetText(),
		self.EditorVersion or environment.CaelusNekoAPI:GetVersion(),
		self.EditorSkinColor,
		self.EditorAssets:GetText(),
		self.EditorUse3DPants,
		self.EditorPreviousName
	)

	if not ok then
		self.EditorStatus.Text = tostring(result)
		return
	end

	self.EditorPreviousName = result
	self.EditorStatus.Text = "Saved : " .. tostring(result)
end

function environment.CaelusPendalarNekoUI:DestroyExistingWindow(keep)
	if self.GuiRoot
		and self.GuiRoot ~= keep
		and self.GuiRoot.Parent
	then
		pcall(function()
			self.GuiRoot:Destroy()
		end)
	end

	if not keep then
		self.GuiRoot = nil
		self.Window = nil
	end

	for _, root in ipairs(self:GetGuiRoots()) do
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("ScreenGui") and child ~= keep then
				local normalized = string.lower(
					tostring(child.Name or "")
				)

				if child:GetAttribute("CaelusPendalarHub") == true
					or normalized == "pendulum hub"
					or normalized == "pendalar hub"
				then
					pcall(function()
						child:Destroy()
					end)
				end
			end
		end
	end
end

function environment.CaelusPendalarNekoUI:FindCreatedGui(
	before,
	expectedName
)
	for _, root in ipairs(self:GetGuiRoots()) do
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("ScreenGui")
				and not before[child]
				and (
					not expectedName
					or child.Name == expectedName
				)
			then
				return child
			end
		end
	end

	return nil
end

function environment.CaelusPendalarNekoUI:Build()
	if environment.CaelusNekoHubLaunchToken ~= self.LaunchToken then
		return false, "A newer Neko Hub launch superseded this one."
	end

	if self.BuildStarted then
		return true
	end

	self.BuildStarted = true
	self:DestroyExistingWindow()

	local sourceText, fetchProblem = self:Fetch(self.LibraryUrl)

	if not sourceText then
		return false,
			"Pendalar UI download failed: " .. tostring(fetchProblem)
	end

	local recolorCount
	sourceText, recolorCount = self:Recolor(sourceText)
	if not sourceText:find(
		'local ScreenGui = Instance.new("ScreenGui")',
		1,
		true
	) then
		local screenGuiPatchCount
		sourceText, screenGuiPatchCount = self:ReplacePlain(
			sourceText,
			'ScreenGui = Instance.new("ScreenGui")',
			'local ScreenGui = Instance.new("ScreenGui")'
		)

		if screenGuiPatchCount == 0 then
			warn(
				"[Pendalar Hub] UI library ScreenGui declaration "
					.. "could not be isolated."
			)
		end
	end

	if recolorCount == 0 then
		warn(
			"[Pendalar Hub] UI library colors changed; "
				.. "continuing without pink recolor."
		)
	end

	if type(loadstring) ~= "function" then
		return false, "loadstring() is unavailable."
	end

	local chunk, compileProblem = loadstring(
		sourceText,
		"=PendalarEmbeddedUI"
	)

	if not chunk then
		return false,
			"Pendalar UI compile failed: " .. tostring(compileProblem)
	end

	local ok, library = pcall(chunk)

	if not ok then
		return false,
			"Pendalar UI runtime failed: " .. tostring(library)
	end

	if type(library) ~= "table"
		or type(library.New) ~= "function"
	then
		return false, "Pendalar UI library returned an invalid object."
	end

	if environment.CaelusNekoHubLaunchToken ~= self.LaunchToken then
		return false, "A newer Neko Hub launch superseded this one."
	end

	-- Capture immediately before New(). The hidden Fling GUI has already been
	-- created, so it cannot be mistaken for the Pendalar window.
	self:DestroyExistingWindow()
	local guiBefore = {}

	for _, root in ipairs(self:GetGuiRoots()) do
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("ScreenGui") then
				guiBefore[child] = true
			end
		end
	end

	local window = library:New("Pendalar Hub")
	self.GuiRoot = self:FindCreatedGui(guiBefore, "Pendalar Hub")

	if not self.GuiRoot then
		self:DestroyExistingWindow()
		return false, "Pendalar Hub ScreenGui was not created."
	end

	self.GuiRoot:SetAttribute("CaelusPendalarHub", true)
	self.GuiRoot:SetAttribute("CaelusNekoRuntimeVersion", RUNTIME_VERSION)
	self:DestroyExistingWindow(self.GuiRoot)
	local nekosTab = window:NewTab("Nekos")
	local settingsTab = window:NewTab("Settings")
	local editorTab = window:NewTab("Neko Editor")
	local scriptsTab = window:NewTab("Scripts")
	local creditsTab = window:NewTab("Credits")

	self.ScriptsTab = scriptsTab

	nekosTab:NewSearchBar()

	for _, morphName in ipairs(environment.CaelusNekoAPI.Morphs) do
		local buttonMorphName = morphName
		local displayName = DISPLAY_NAMES[buttonMorphName]
			or buttonMorphName

		nekosTab:NewButton(
			displayName,
			"Morph into " .. displayName,
			function()
				local applied, problem =
					environment.CaelusNekoAPI:Apply(
						buttonMorphName,
						environment.CaelusNekoAPI:GetVersion()
					)

				if not applied then
					warn(
						"[Pendalar Hub] "
							.. tostring(problem)
					)
				end
			end
		)
	end

	self.VersionLabel = settingsTab:NewLabel(
		"Selected Neko Version : "
			.. environment.CaelusNekoAPI:GetVersion()
	)

	for _, versionName in ipairs(environment.CaelusNekoAPI.Versions) do
		local selectedVersion = versionName

		settingsTab:NewButton(
			selectedVersion,
			"Use " .. selectedVersion .. " for Neko morphs",
			function()
				environment.CaelusNekoAPI:SetVersion(
					selectedVersion
				)
			end
		)
	end

	settingsTab:NewBoolButton(
		"Original Claw Run Speed",
		"Use the original 35.2 run speed while F claws are active",
		function(enabled)
			state.originalClawRunSpeedEnabled =
				enabled == true
			state:refreshClawRunSpeed()
		end,
		state.originalClawRunSpeedEnabled
	)

	settingsTab:NewBoolButton(
		"Attack Fling",
		"Fling the player under your cursor/tap during the main attack",
		function(enabled)
			self:SetAttackFling(enabled)
		end,
		self.AttackFlingEnabled
	)


	editorTab:NewLabel("Custom Neko Editor")

	self.EditorName = editorTab:NewTextBar(
		"Neko Name",
		"Name for the saved Custom Neko",
		""
	)

	self.EditorAssets = editorTab:NewTextBar(
		"Asset IDs",
		"Shirt, pants, T-shirt, accessory and hat IDs",
		""
	)

	self.EditorVersion =
		environment.CaelusNekoAPI:GetVersion()

	editorTab:NewButton(
		"Editor Version",
		"Cycle the version used by this Custom Neko",
		function()
			local currentIndex =
				table.find(
					environment.CaelusNekoAPI.Versions,
					self.EditorVersion
				)
				or 1

			local nextIndex =
				(currentIndex % #environment.CaelusNekoAPI.Versions)
				+ 1

			self.EditorVersion =
				environment.CaelusNekoAPI.Versions[nextIndex]

			self.EditorStatus.Text =
				"Editor Version : " .. self.EditorVersion
		end
	)

	editorTab:NewBoolButton(
		"3D Pants",
		"Show generated 3D lower-body geometry",
		function(enabled)
			self.EditorUse3DPants = enabled
		end,
		true
	)

	self.EditorStatus = editorTab:NewLabel(
		"Editor Version : " .. self.EditorVersion
	)

	self:CreateColorPicker(editorTab)

	editorTab:NewButton(
		"Load Selected",
		"Load the selected saved Custom Neko into the editor",
		function()
			self:LoadEditorSelection()
		end
	)

	editorTab:NewButton(
		"Save & Select",
		"Save this Custom Neko and select it",
		function()
			self:SaveEditor()
		end
	)

	editorTab:NewButton(
		"Apply Custom Neko",
		"Apply the currently selected Custom Neko",
		function()
			local applied, problem =
				environment.CaelusNekoAPI:ApplySelectedCustom()

			if not applied then
				self.EditorStatus.Text = tostring(problem)
			end
		end
	)

	scriptsTab:NewLabel("Pendalar Scripts")

	for _, scriptEntry in ipairs(self.Scripts) do
		local entry = scriptEntry
		local entryUrl =
			entry.Url or entry[2] or ""

		if not tostring(entryUrl):find(
			"Universal%-Script%-Touch%-fling%-script%-22447"
		) then
			local scriptName =
				entry.Name or entry[1] or "Script"
		local description =
			entry.Description
			or entry[3]
			or ("Run " .. scriptName)

			scriptsTab:NewButton(
				scriptName,
				description,
				function()
					local ran, problem = self:RunScript(entry)

					if not ran then
						warn(
							"[Pendalar Scripts] "
								.. tostring(problem)
						)
					end
				end
			)
		end
	end

	creditsTab:NewLabel("Alpha Sigma Male")
	creditsTab:NewLabel("Larry")
	creditsTab:NewLabel("melanie070910")

	window:SetMainTab(nekosTab)
	window:SetFooter("Current Version : 3.32.5")

	self.Window = window

	if gui and gui.Parent then
		gui.Enabled = false
	end

	return true
end

state.pendalarUiOk, state.pendalarUiProblem =
	state.pendalarUI:Build()

if not state.pendalarUiOk
	and environment.CaelusNekoHubLaunchToken
		~= state.pendalarUI.LaunchToken
then
	cleanupShadow()
	disconnectArray(state.connections)
	if gui and gui.Parent then gui:Destroy() end
	if catalog and catalog.Parent then catalog:Destroy() end
	if environment.CaelusNekoOriginalRuntimeSession == state then
		environment.CaelusNekoOriginalRuntimeSession = nil
	end
	if environment.CaelusNekoOriginalSession == state then
		environment.CaelusNekoOriginalSession = nil
	end
	if environment.CaelusNekoShadowSession == state then
		environment.CaelusNekoShadowSession = nil
	end
	if environment.CaelusNekoAPI
		and environment.CaelusNekoAPI.Session == state
	then
		environment.CaelusNekoAPI = nil
	end
	if environment.CaelusPendalarNekoUI == state.pendalarUI then
		environment.CaelusPendalarNekoUI = nil
	end
	return
end

if not state.pendalarUiOk then
	if state.pendalarUI then
		state.pendalarUI.BuildStarted = false
	end

	warn(
		"[Pendalar Hub] Embedded UI failed: "
			.. tostring(state.pendalarUiProblem)
	)

	if gui and gui.Parent then
		gui.Enabled = true
	end
end

local function overInteractiveGui(position)
	local ok, objects = pcall(function()
		return GuiService:GetGuiObjectsAtPosition(position.X, position.Y)
	end)
	if not ok then return false end
	for _, object in ipairs(objects) do
		if object:IsDescendantOf(gui) then return true end
		if object:IsA("GuiButton") or object:IsA("TextBox") or object:IsA("ScrollingFrame") then return true end
	end
	return false
end

-- A touch on open world space performs the original mouse attack.  UI taps,
-- including the phone movement controls and key buttons, are ignored.
remember(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local isTouch =
		input.UserInputType == Enum.UserInputType.Touch
	local isMouse =
		input.UserInputType == Enum.UserInputType.MouseButton1

	if not isTouch and not isMouse then
		return
	end

	if overInteractiveGui(input.Position) then
		return
	end

	local pendalarUI = state.pendalarUI

	if type(pendalarUI) == "table"
		and pendalarUI.AttackFlingEnabled
	then
		pendalarUI:FlingAtScreenPoint(
			input.Position.X,
			input.Position.Y
		)
	end

	if isTouch then
		state.activeTouches[input] = true
		fireCommand("mouse_down")
	end
end))
remember(UserInputService.InputEnded:Connect(function(input)
	if state.activeTouches[input] then
		state.activeTouches[input] = nil
		fireCommand("mouse_up")
	end
end))

remember(player.CharacterAdded:Connect(function(character)
	local morphName = state.activeMorph or state.selectedMorph
	local versionName = state.activeVersion or state.selectedVersion
	cleanupShadow()
	if morphName and versionName and not state.destroyed then
		task.delay(1, function()
			if not state.destroyed and player.Character == character then
				task.spawn(applyMorph, versionName, morphName)
			end
		end)
	end
end))

function state:Destroy()
	if self.destroyed then return end
	self.destroyed = true

	local pendalarUI =
		self.pendalarUI or environment.CaelusPendalarNekoUI

	if type(pendalarUI) == "table" then
		pendalarUI:SetAttackFling(false)
		pendalarUI.AttackFlingBusy = false
	end

	self:restoreClawRunSpeed()
	self.clawsActive = false

	local followRuntime = environment.CaelusR6FollowRuntime
	if type(followRuntime) == "table"
		and type(followRuntime.Destroy) == "function"
	then
		pcall(function() followRuntime:Destroy() end)
	end

	cleanupShadow()
	disconnectArray(self.connections)
	if self.gui and self.gui.Parent then self.gui:Destroy() end
	if self.catalog then self.catalog:Destroy() end
	if environment.CaelusNekoOriginalRuntimeSession == self then environment.CaelusNekoOriginalRuntimeSession = nil end
	if environment.CaelusNekoOriginalSession == self then environment.CaelusNekoOriginalSession = nil end
	if environment.CaelusNekoShadowSession == self then environment.CaelusNekoShadowSession = nil end
	if environment.CaelusNekoAPI and environment.CaelusNekoAPI.Session == self then
		environment.CaelusNekoAPI = nil
	end
	if type(pendalarUI) == "table"
		and pendalarUI.Session == self
	then
		pendalarUI:DestroyExistingWindow()
		pendalarUI.BuildStarted = false
		if environment.CaelusPendalarNekoUI == pendalarUI then
			environment.CaelusPendalarNekoUI = nil
		end
	end
	self.pendalarUI = nil
end

selectedText.Text = "???"
selectedValue.Value = ""
rebuildKeyPanel("V4")

if type(environment.CaelusNekoBootStatus) == "function" then
	environment.CaelusNekoBootStatus("Caelus Neko 3.32.5: ready")
end
task.delay(0.35, function()
	local bootGui = environment.CaelusNekoBootGui
	if bootGui and bootGui.Parent then
		bootGui:Destroy()
	end
	environment.CaelusNekoBootGui = nil
	environment.CaelusNekoBootStatus = nil
end)

return gui
