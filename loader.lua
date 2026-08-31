-- File: loader.lua
-- Caelus Neko diagnostic loader.
-- Never silently uses the old hub cache and never hides diagnostics until UI appears.

local environment = (type(getgenv) == "function" and getgenv()) or _G

local HUB_URLS = {
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/main/hub.lua",
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/refs/heads/main/hub.lua",
}

local BASE_URL =
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/main"

local CACHE_ROOT =
	"CaelusNekoHub/RemoteCache/diagnostic_2026_08_31"

local ASSET_FOLDER = CACHE_ROOT .. "/assets"
local LOG_PATH = CACHE_ROOT .. "/last_loader_error.txt"

local function getFunction(name)
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

local function writeDiagnostic(message)
	local writefile = getFunction("writefile")
	local makefolder = getFunction("makefolder")
	local isfolder = getFunction("isfolder")

	if not writefile then
		return
	end

	if makefolder then
		local current = ""

		for segment in string.gmatch(CACHE_ROOT, "[^/]+") do
			current =
				current == ""
				and segment
				or (current .. "/" .. segment)

			local exists = false

			if isfolder then
				local ok, result = pcall(isfolder, current)
				exists = ok and result == true
			end

			if not exists then
				pcall(makefolder, current)
			end
		end
	end

	pcall(
		writefile,
		LOG_PATH,
		"Caelus Neko diagnostic loader\n"
			.. os.date("!%Y-%m-%dT%H:%M:%SZ")
			.. "\n\n"
			.. tostring(message)
	)
end

warn("[Caelus Diagnostic Loader] BOOT")

local statusGui = nil
local statusLabel = nil

local function parentForStatusGui()
	local gethui = getFunction("gethui")

	if gethui then
		local ok, result = pcall(gethui)

		if ok and typeof(result) == "Instance" then
			return result
		end
	end

	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)

	if okCore and coreGui then
		return coreGui
	end

	local players = game:GetService("Players")
	local player = players.LocalPlayer

	if player then
		return player:FindFirstChildOfClass("PlayerGui")
	end

	return nil
end

local function makeStatusGui()
	local parent = parentForStatusGui()

	if not parent then
		return
	end

	local old = parent:FindFirstChild("CaelusDiagnosticLoaderStatus")

	if old then
		pcall(function()
			old:Destroy()
		end)
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "CaelusDiagnosticLoaderStatus"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 2147483647
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 8)
	label.Size = UDim2.new(0, 620, 0, 92)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	label.BackgroundTransparency = 0.05
	label.BorderSizePixel = 0
	label.Font = Enum.Font.Code
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "Caelus Neko diagnostic loader: starting..."
	label.Parent = screen

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = label

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local parentOk = pcall(function()
		screen.Parent = parent
	end)

	if not parentOk then
		local players = game:GetService("Players")
		local player = players.LocalPlayer
		local playerGui =
			player
			and (
				player:FindFirstChildOfClass("PlayerGui")
				or player:FindFirstChild("PlayerGui")
			)

		if playerGui then
			parentOk = pcall(function()
				screen.Parent = playerGui
			end)
		end
	end

	if not parentOk then
		pcall(function()
			screen:Destroy()
		end)
		return
	end

	statusGui = screen
	statusLabel = label
end

makeStatusGui()

local function status(message, failed)
	message = tostring(message)

	if failed then
		warn("[Caelus Diagnostic Loader] " .. message)
		writeDiagnostic(message)
	else
		print("[Caelus Diagnostic Loader] " .. message)
	end

	if not statusGui or not statusGui.Parent then
		makeStatusGui()
	end

	if statusLabel and statusLabel.Parent then
		statusLabel.Text = message
		statusLabel.TextColor3 =
			failed
			and Color3.fromRGB(255, 145, 145)
			or Color3.fromRGB(245, 245, 245)
	end
end

status("1/7 Loader started. Waiting for Roblox to finish loading...")

if not game:IsLoaded() then
	local deadline = os.clock() + 30

	repeat
		task.wait(0.1)
	until game:IsLoaded() or os.clock() >= deadline

	if not game:IsLoaded() then
		status(
			"LOADER ERROR: game:IsLoaded() stayed false for 30 seconds.",
			true
		)
		error("[Caelus Diagnostic Loader] game load timeout", 0)
	end
end

status("2/7 Roblox loaded. Preparing fresh asset runtime...")

local function requestFunction()
	for _, name in ipairs({
		"request",
		"http_request",
		"httprequest",
	}) do
		local candidate = getFunction(name)

		if candidate then
			return candidate
		end
	end

	local syn = rawget(environment, "syn")

	if type(syn) == "table"
		and type(syn.request) == "function"
	then
		return syn.request
	end

	local http = rawget(environment, "http")

	if type(http) == "table"
		and type(http.request) == "function"
	then
		return http.request
	end

	return nil
end

local function ensureFolder(path)
	local makefolder = getFunction("makefolder")
	local isfolder = getFunction("isfolder")

	if not makefolder then
		return false, "makefolder() is unavailable"
	end

	local current = ""

	for segment in string.gmatch(path, "[^/]+") do
		current =
			current == ""
			and segment
			or (current .. "/" .. segment)

		local exists = false

		if isfolder then
			local ok, result = pcall(isfolder, current)
			exists = ok and result == true
		end

		if not exists then
			local ok, problem = pcall(makefolder, current)

			if not ok then
				if isfolder then
					local verifyOk, verifyResult =
						pcall(isfolder, current)

					if verifyOk and verifyResult == true then
						continue
					end
				end

				return false, tostring(problem)
			end
		end
	end

	return true
end

local function fileExists(path)
	local isfile = getFunction("isfile")

	if isfile then
		local ok, result = pcall(isfile, path)

		if ok then
			return result == true
		end
	end

	local readfile = getFunction("readfile")

	if readfile then
		local ok = pcall(readfile, path)
		return ok
	end

	return false
end

local function freshUrl(url)
	local separator =
		string.find(url, "?", 1, true)
		and "&"
		or "?"

	return url
		.. separator
		.. "caelus="
		.. tostring(os.time())
		.. "-"
		.. tostring(math.random(100000, 999999))
end

local function fetch(url, attempts, minimumBytes)
	local request = requestFunction()
	local lastProblem = "download failed"

	for attempt = 1, attempts do
		local urlToUse = freshUrl(url)

		if request then
			local ok, response = pcall(request, {
				Url = urlToUse,
				Method = "GET",
				Headers = {
					["Cache-Control"] =
						"no-cache, no-store, must-revalidate",
					["Pragma"] = "no-cache",
					["Expires"] = "0",
					["User-Agent"] = "CaelusNekoDiagnosticLoader/1.0",
				},
			})

			if ok and type(response) == "table" then
				local body = response.Body or response.body
				local code = tonumber(
					response.StatusCode
						or response.Status
						or response.status
				)

				if type(body) == "string"
					and #body >= minimumBytes
					and (not code or code < 400)
				then
					return body
				end

				lastProblem =
					"request HTTP "
					.. tostring(code or "?")
					.. ", "
					.. tostring(
						type(body) == "string"
							and #body
							or 0
					)
					.. " bytes"
			else
				lastProblem = tostring(response)
			end
		end

		local ok, body = pcall(function()
			return game:HttpGet(urlToUse)
		end)

		if ok
			and type(body) == "string"
			and #body >= minimumBytes
		then
			return body
		end

		if not ok then
			lastProblem = tostring(body)
		elseif type(body) == "string" then
			lastProblem =
				"HttpGet returned only "
				.. tostring(#body)
				.. " bytes"
		end

		if attempt < attempts then
			task.wait(math.min(0.5 * attempt, 1.5))
		end
	end

	return nil, lastProblem
end

local resolver = nil

for _, name in ipairs({
	"getcustomasset",
	"getsynasset",
	"getasset",
}) do
	local candidate = getFunction(name)

	if candidate then
		resolver = candidate
		break
	end
end

if not resolver then
	status(
		"LOADER ERROR: executor has no getcustomasset/getsynasset/getasset.",
		true
	)
	error("[Caelus Diagnostic Loader] no custom-asset resolver", 0)
end

local folderOk, folderProblem = ensureFolder(ASSET_FOLDER)

if not folderOk then
	status(
		"LOADER ERROR: could not create fresh asset folder: "
			.. tostring(folderProblem),
		true
	)
	error("[Caelus Diagnostic Loader] asset-folder failure", 0)
end

local runtime = {
	baseUrl = BASE_URL,
	assetFolder = ASSET_FOLDER,
	version = "diagnostic-2026-08-31",
}

function runtime:getAssetUri(fileName)
	if type(fileName) ~= "string"
		or fileName == ""
		or string.find(fileName, "[/\\]")
	then
		return nil, "invalid asset filename"
	end

	local cachePath =
		self.assetFolder .. "/" .. fileName

	if not fileExists(cachePath) then
		status(
			"Downloading required asset: "
				.. fileName
		)

		local body, problem =
			fetch(
				self.baseUrl .. "/" .. fileName,
				4,
				32
			)

		if not body then
			return nil,
				"asset download failed for "
					.. fileName
					.. ": "
					.. tostring(problem)
		end

		local writefile = getFunction("writefile")

		if not writefile then
			return nil, "writefile() is unavailable"
		end

		local ok, writeProblem =
			pcall(writefile, cachePath, body)

		if not ok then
			return nil,
				"could not save "
					.. fileName
					.. ": "
					.. tostring(writeProblem)
		end
	end

	local ok, uri = pcall(resolver, cachePath)

	if not ok
		or type(uri) ~= "string"
		or uri == ""
	then
		return nil,
			"custom-asset resolver failed for "
				.. fileName
	end

	return uri
end

environment.CaelusRemoteAssetRuntime = runtime

status("3/7 Fresh asset runtime ready. Downloading hub.lua...")

local hubSource = nil
local hubProblem = nil
local usedHubUrl = nil

for _, hubUrl in ipairs(HUB_URLS) do
	local body, problem = fetch(hubUrl, 3, 100000)

	if body then
		hubSource = body
		usedHubUrl = hubUrl
		break
	end

	hubProblem = problem
end

if not hubSource then
	status(
		"HUB DOWNLOAD ERROR: "
			.. tostring(hubProblem),
		true
	)
	error("[Caelus Diagnostic Loader] hub download failed", 0)
end

status(
	"4/7 Downloaded hub.lua: "
		.. tostring(#hubSource)
		.. " bytes. Compiling..."
)

local compiler =
	type(loadstring) == "function"
	and loadstring
	or nil

if not compiler then
	status(
		"HUB COMPILE ERROR: loadstring() is unavailable.",
		true
	)
	error("[Caelus Diagnostic Loader] no loadstring", 0)
end

local hubChunk, compileProblem =
	compiler(hubSource, "=CaelusNekoHub")

if not hubChunk then
	status(
		"HUB COMPILE ERROR:\n"
			.. tostring(compileProblem),
		true
	)
	error(
		"[Caelus Diagnostic Loader] "
			.. tostring(compileProblem),
		0
	)
end

status(
	"5/7 Hub compiled successfully from:\n"
		.. tostring(usedHubUrl)
)

environment.CaelusNekoLoaderDiagnostic = {
	startedAt = os.clock(),
	hubBytes = #hubSource,
	hubUrl = usedHubUrl,
	cacheRoot = CACHE_ROOT,
}

status("6/7 Starting hub runtime...")

local runtimeOk, runtimeProblem =
	xpcall(
		hubChunk,
		function(problem)
			local traceback =
				debug
				and type(debug.traceback) == "function"
				and debug.traceback(tostring(problem), 2)
				or tostring(problem)

			return traceback
		end
	)

if not runtimeOk then
	status(
		"HUB RUNTIME ERROR:\n"
			.. tostring(runtimeProblem),
		true
	)
	error(
		"[Caelus Diagnostic Loader] hub runtime failed",
		0
	)
end

status(
	"7/7 Hub returned successfully. Waiting up to 20 seconds for UI..."
)

local function findNekoUi()
	local pendalar = environment.CaelusPendalarNekoUI

	if type(pendalar) == "table"
		and pendalar.GuiRoot
		and pendalar.GuiRoot.Parent
	then
		return true, "Pendalar"
	end

	local players = game:GetService("Players")
	local player = players.LocalPlayer
	local playerGui =
		player and player:FindFirstChildOfClass("PlayerGui")

	if playerGui then
		for _, name in ipairs({
			"CaelusNekoOriginalMenu",
			"CaelusOriginalNekoMenu",
			"CaelusSigmaMenu",
			"CaelusNekoShadowHub",
		}) do
			local candidate = playerGui:FindFirstChild(name)

			if candidate then
				return true, name
			end
		end
	end

	return false, nil
end

local deadline = os.clock() + 20
local foundUi = false
local uiName = nil

repeat
	foundUi, uiName = findNekoUi()

	if foundUi then
		break
	end

	task.wait(0.2)
until os.clock() >= deadline

if not foundUi then
	status(
		"HUB UI ERROR: hub.lua compiled and returned without an error, "
			.. "but no Neko/Pendalar UI was detected after 20 seconds.\n"
			.. "Downloaded hub size: "
			.. tostring(#hubSource)
			.. " bytes.",
		true
	)

	error(
		"[Caelus Diagnostic Loader] hub produced no detectable UI",
		0
	)
end

status(
	"SUCCESS: detected "
		.. tostring(uiName)
		.. ". Loader will close in 3 seconds."
)

task.delay(3, function()
	if statusGui and statusGui.Parent then
		statusGui:Destroy()
	end
end)
