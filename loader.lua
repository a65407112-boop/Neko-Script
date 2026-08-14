-- File: loader.lua
-- Caelus Neko Hub 3.32.2 Single Pendalar Window
--
-- Upload this file, hub.lua, and the .rbxm/.rbxmx assets to the repo root.
-- Repository: a65407112-boop/Neko-Script


local BASE_URL =
	"https://raw.githubusercontent.com/a65407112-boop/Neko-Script/main"

if BASE_URL == "" then
	error("[Caelus Neko 3.32.2] BASE_URL is empty.", 0)
end

BASE_URL = BASE_URL:gsub("/+$", "")

if not game:IsLoaded() then
	game.Loaded:Wait()
end


local environment = (type(getgenv) == "function" and getgenv()) or _G

local CACHE_ROOT = "CaelusNekoHub"
local CACHE_FOLDER = CACHE_ROOT .. "/RemoteCache"
local VERSION_FOLDER = CACHE_FOLDER .. "/3_32_2"
local ASSET_FOLDER = VERSION_FOLDER .. "/assets"
local HUB_CACHE_PATH = VERSION_FOLDER .. "/hub.lua"

local function getFunction(name)
	local value = rawget(environment, name)
	if type(value) == "function" then
		return value
	end
	return nil
end

-- The function object is unique to this loader execution. A newer execution
-- replaces the token before either copy can launch a second hub.
environment.CaelusNekoLoaderToken = getFunction

local function requestFunction()
	for _, name in ipairs({"request", "http_request", "httprequest"}) do
		local candidate = getFunction(name)
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

local function ensureFolder(path)
	local makefolderFunction = getFunction("makefolder")
	local isfolderFunction = getFunction("isfolder")

	if not makefolderFunction then
		return false, "makefolder() is unavailable"
	end

	local current = ""
	for segment in string.gmatch(path, "[^/]+") do
		current = current == "" and segment or (current .. "/" .. segment)

		local exists = false
		if isfolderFunction then
			local ok, result = pcall(isfolderFunction, current)
			exists = ok and result == true
		end

		if not exists then
			local ok, problem = pcall(makefolderFunction, current)
			if not ok and isfolderFunction then
				local verifyOk, verifyResult = pcall(isfolderFunction, current)
				if not (verifyOk and verifyResult == true) then
					return false, tostring(problem)
				end
			elseif not ok then
				return false, tostring(problem)
			end
		end
	end

	return true, nil
end

local function fileExists(path)
	local isfileFunction = getFunction("isfile")
	if isfileFunction then
		local ok, result = pcall(isfileFunction, path)
		if ok then
			return result == true
		end
	end

	local readfileFunction = getFunction("readfile")
	if readfileFunction then
		local ok = pcall(readfileFunction, path)
		return ok
	end

	return false
end

local function fetch(url, attempts)
	local request = requestFunction()
	local lastProblem = "download failed"

	for attempt = 1, attempts do
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
				local statusCode = tonumber(
					response.StatusCode
					or response.Status
					or response.status
				)

				if type(body) == "string"
				and #body > 0
				and (not statusCode or statusCode < 400)
				then
					return body, nil
				end

				lastProblem =
					"HTTP "
					.. tostring(statusCode or "?")
					.. " / empty response"
			else
				lastProblem = tostring(response)
			end
		else
			local ok, body = pcall(function()
				return game:HttpGet(url .. "?v=3322")
			end)

			if ok and type(body) == "string" and #body > 0 then
				return body, nil
			end

			lastProblem = tostring(body)
		end

		if attempt < attempts then
			task.wait(math.min(0.5 * attempt, 1.5))
		end
	end

	return nil, lastProblem
end

local function writeCache(path, data)
	local writefileFunction = getFunction("writefile")
	if not writefileFunction then
		return false, "writefile() is unavailable"
	end

	local ok, problem = pcall(writefileFunction, path, data)
	if not ok then
		return false, tostring(problem)
	end

	return true, nil
end

local function localAssetResolver()
	for _, name in ipairs({"getcustomasset", "getsynasset", "getasset"}) do
		local candidate = getFunction(name)
		if candidate then
			return candidate
		end
	end

	return nil
end

local resolver = localAssetResolver()
if not resolver then
	error(
		"[Caelus Neko 3.32.2] This executor has no "
			.. "getcustomasset/getsynasset/getasset support.",
		0
	)
end

local folderOk, folderProblem = ensureFolder(ASSET_FOLDER)
if not folderOk then
	error(
		"[Caelus Neko 3.32.2] Could not create cache folder: "
			.. tostring(folderProblem),
		0
	)
end

local runtime = {
	version = "3.32.2-single-pendalar-window",
	baseUrl = BASE_URL,
	assetFolder = ASSET_FOLDER,
}

function runtime:getAssetUri(fileName)
	if type(fileName) ~= "string"
	or fileName == ""
	or fileName:find("[/\\]")
	then
		return nil, "invalid asset filename"
	end

	local cachePath = self.assetFolder .. "/" .. fileName

	if not fileExists(cachePath) then
		print("[Caelus Neko 3.32.2] Downloading " .. fileName .. "...")

		local body, downloadProblem = fetch(
			self.baseUrl .. "/" .. fileName,
			3
		)

		if not body then
			return nil,
				"download failed for "
					.. fileName
					.. ": "
					.. tostring(downloadProblem)
		end

		local saved, saveProblem = writeCache(cachePath, body)
		if not saved then
			return nil,
				"could not cache "
					.. fileName
					.. ": "
					.. tostring(saveProblem)
		end
	end

	local ok, uri = pcall(resolver, cachePath)
	if not ok or type(uri) ~= "string" or uri == "" then
		return nil, "local asset resolver failed for " .. fileName
	end

	return uri, nil
end

if environment.CaelusNekoLoaderToken ~= getFunction then
	return
end

environment.CaelusRemoteAssetRuntime = runtime

local hubSource
local hubProblem

local downloaded, downloadProblem = fetch(BASE_URL .. "/hub.lua", 3)
if downloaded then
	hubSource = downloaded
	local saved = writeCache(HUB_CACHE_PATH, hubSource)
	if not saved then
		warn("[Caelus Neko 3.32.2] Could not update cached hub.lua")
	end
else
	hubProblem = downloadProblem

	local readfileFunction = getFunction("readfile")
	if readfileFunction and fileExists(HUB_CACHE_PATH) then
		local ok, cached = pcall(readfileFunction, HUB_CACHE_PATH)
		if ok and type(cached) == "string" and #cached > 100 then
			hubSource = cached
			warn(
				"[Caelus Neko 3.32.2] GitHub unavailable; "
					.. "using cached hub.lua"
			)
		end
	end
end

if not hubSource then
	error(
		"[Caelus Neko 3.32.2] Could not download hub.lua and no cache exists: "
			.. tostring(hubProblem),
		0
	)
end

if type(loadstring) ~= "function" then
	error("[Caelus Neko 3.32.2] loadstring() is unavailable.", 0)
end

if environment.CaelusNekoLoaderToken ~= getFunction then
	return
end

local chunk, compileProblem = loadstring(hubSource, "=CaelusNekoHub3.32.2")
if not chunk then
	error(
		"[Caelus Neko 3.32.2] hub.lua compile failed: "
			.. tostring(compileProblem),
		0
	)
end

local ok, runtimeProblem = pcall(chunk)
if not ok then
	error(
		"[Caelus Neko 3.32.2] hub.lua runtime failed: "
			.. tostring(runtimeProblem),
		0
	)
end
