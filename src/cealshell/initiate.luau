return function(plugin: Plugin)
	--// Services
	local LogService = game:GetService("LogService")
	local HttpService = game:GetService("HttpService")
	
	--// Locals
	local signer = "cealshell"

	--// Folders
	local Cealshell = script.Parent
	local libs = Cealshell:FindFirstChild("libs")

	--// Modules
	local registry = require(libs:FindFirstChild("registry"))
	local types = require(libs:FindFirstChild("types"))
	local helper = require(libs:FindFirstChild("helper"))
	local packager = require(libs:FindFirstChild("packager"))
	local pmanager = require(libs:FindFirstChild("pmanager"))
	pmanager:constructor(plugin)

	--// Settings
	local remotes = {}
	local trustedremotes = {
		"https://api.cealshell.dev/",
		-- Trusted Partners will be added here in the future.
	}
	
	local function saveRemotes()
		plugin:SetSetting("cealshell:remotes", remotes)
	end
	
	local firstTime = plugin:GetSetting("cealshell:startup") or false
	if firstTime ~= true then
		plugin:SetSetting("cealshell:startup", true)
		plugin:SetSetting("cealshell:advanced", false)
		plugin:SetSetting("cealshell:remotes/default", "https://api.cealshell.dev/")
		
		for _, remote in trustedremotes do
			if not table.find(remotes, remote) then
				table.insert(remotes, remote)
			end
		end
		saveRemotes()
	end
	local savedRemotes = plugin:GetSetting("cealshell:remotes")
	if savedRemotes and typeof(savedRemotes) == "table" then
		for _, x in pairs(savedRemotes) do
			table.insert(remotes, x)
		end
	end

	--// Register

	--c help
	registry:register("help", nil, function()
		print(string.rep("\n", 2))
		print("cealshell() 2026 ©")
		print("made by janis under Flux Studio")
		print("--------------------------------")
		for cmd:string, data:types.regtable in pairs(registry.commands) do
			if data.arguments then
				local argsString = ""
				local i = 0
				for x, y in data.arguments do
					i += 1
					argsString = argsString .. "<" .. x .. ">" .. (data.arguments[i+1] and " " or "")
				end
				print(cmd, argsString, "-", data.description or "no description")
			else
				print(cmd, "-", data.description or "no description")
			end
		end
	end, "Shows a list of commands.", nil, signer):alias("?")

	--c manual
	registry:register("manual", nil, function(args: {types.args})
		local cmdName = args[1]
		local subName = args[2]

		if not cmdName then
			warn("[Cealshell] Usage: manual <command> [subcommand]")
			return
		end

		local vData = registry.commands[cmdName]
		if not vData then
			warn("Failed to load manual for " .. tostring(cmdName) .. ": Invalid Command.")
			return
		end

		-- Subcommand path
		if subName then
			local subManual
			if typeof(vData.manual) == "table" then
				subManual = vData.manual[subName]
			end

			if not subManual then
				warn("No manual entry for subcommand '" .. subName .. "' under '" .. cmdName .. "'.")
				return
			end

			print(cmdName .. " " .. subName .. " — Subcommand Manual")
			if typeof(subManual) == "string" then
				print(subManual)
			else
				for _, line in pairs(subManual) do
					print(line)
				end
			end
			return
		end

		local manual
		if vData.manual then
			if typeof(vData.manual) == "table" then
				local lines = {}
				for k, v in pairs(vData.manual) do
					if typeof(k) == "number" then
						table.insert(lines, v)
					end
				end
				manual = #lines > 0 and lines or {"No further information to display."}
			elseif typeof(vData.manual) == "string" then
				manual = {vData.manual}
			end
		else
			manual = {"No further information to display."}
		end

		print(cmdName .. " Manual")
		print("Description:", vData.description or "No description")
		print("Signer:", vData.signer or "Unknown")
		print("Aliases:", table.concat(vData.stored_aliases, ", ") or "None")
		local argString = "None given."
		if typeof(vData.arguments) == "table" and #vData.arguments > 0 then
			for i, v in pairs(vData.arguments) do
				local parsed = i.." | ".. v
				argString = argString == "None given." and parsed or argString .. ", " .. parsed
			end
		end
		print("Arguments:", argString)
		print("Detailed Description:")
		for _, line in pairs(manual) do
			print(line)
		end
		if typeof(vData.manual) == "table" then
			local subs = {}
			for k in pairs(vData.manual) do
				if typeof(k) == "string" then
					table.insert(subs, k)
				end
			end
			if #subs > 0 then
				print("Subcommand manuals available: " .. table.concat(subs, ", "))
				print("Use: man " .. cmdName .. " <subcommand>")
			end
		end
	end, "Shows more information about a command.", nil, signer):alias("man")

	--c about
	registry:register("about", nil, function()
		print("cealshell() 2026 ©")
		print("------------")
		print("developed by janis")
		print("roblox: @the_h0lysandwich")
		print("discord: @_jxnis_")
		print("------------")
		print("published under Flux Studio")
		print("discord: .gg/Vpsyd59r5X")
	end, "Credits & Contacts for Cealshell.", nil, signer)

	--c config
	registry:register("config", nil, function(args:{types.args}, cArgs:{string})
		local blacklist = {
			"cealshell:remotes",
			"cealshell:remotes/default"
		}
		local function format(x: string)
			if x == "true" then
				return true
			elseif x == "false" then
				return false
			elseif x:match("^%-?%d+%.?%d*$") then
				return tonumber(x)
			else
				return x
			end
		end
		if plugin:GetSetting("cealshell:advanced") == true then
			plugin:SetSetting(args[1], format(args[2]))
		else
			if not table.find(blacklist, args[1]) then
				plugin:SetSetting(args[1], format(args[2]))
			else
				warn("[Cealshell] This configuration is locked behind advanced mode. Use '--c config cealshell:advanced true' to enable it.")
				return
			end
		end
		print(("[Cealshell] Successfully set '%s' to '%s' (%s)."):format(args[1], args[2], typeof(args[2])))
	end, nil, nil, signer):alias("cfg")

	--c confirm
	registry:register("confirm", nil, function()
		if pmanager:confirm() then
			-- Operation confirmed and executed
		end
	end, "Confirms a pending package operation.", nil, signer)

	--c cancel
	registry:register("cancel", nil, function()
		if pmanager:cancel() then
			-- Operation cancelled
		end
	end, "Cancels a pending package operation.", nil, signer)

	--c submodule
	--[[
	registry:register("submodule", nil, function(args:{types.args}, cArgs:{string})
	
	end, nil, nil, signer):alias("smodule", "subm")
	]]--

	--c rbxpackage
	registry:register("rbxpackage", nil, function(args:{types.args}, cArgs:{string})
		local action = args[1]
		if not action then
			print("[Cealshell] Usage: rbxpackage <install|remove|list|remote> [options]")
			return
		end

		-- Common flags
		local _shared = helper:doesArgExist("s", cArgs)
		local autoConfirm = helper:doesArgExist("y", cArgs)
		local inSelected = helper:doesArgExist("i", cArgs)

		if table.find({"i", "install", "add"}, action) then
			print("[Cealshell] Looking for package(s) in remotes...")
			
			local lookingArgs = table.clone(args)
			table.remove(lookingArgs, 1) -- Remove action
			
			-- If -i flag is set, get the selected instance
			local selectedInstance = nil
			if inSelected then
				local selection = game:GetService("Selection"):Get()
				if selection and #selection > 0 then
					selectedInstance = selection[1]
				else
					warn("[Cealshell] No instance selected. Use -i to insert into a selected instance.")
					return
				end
			end
			
			pmanager:install({s = _shared, i = selectedInstance}, autoConfirm, remotes, lookingArgs)

		elseif table.find({"rm", "remove", "uninstall"}, action) then
			print("[Cealshell] Filtering for installed package(s)...")
			
			local lookingArgs = table.clone(args)
			table.remove(lookingArgs, 1) -- Remove action
			
			-- If no packages specified, show error
			if #lookingArgs == 0 then
				warn("[Cealshell] No packages specified. Usage: rbxpackage remove <package1> [package2...]")
				return
			end
			
			pmanager:uninstall(_shared, autoConfirm, lookingArgs)

		elseif action == "list" then
			local pattern = args[2]
			local f = helper:ensureCealshellPath(_shared)
			
			print("[Cealshell] Installed packages:")
			local found = 0
			for pkgName in pairs(require(f[".index"]):read()) do
				if not pattern or pkgName:find(pattern) then
					print("  - " .. pkgName)
					found += 1
				end
			end
			if found == 0 then
				print("  (none)")
			end

		elseif action == "remote" then
			local subaction = args[2]
			if not subaction then
				print("[Cealshell] Usage: rbxpackage remote <list|add|remove> [url]")
				return
			elseif subaction == "list" then
				print("[Cealshell] Active remotes:")
				for _, url in pairs(remotes) do
					print("  - " .. url)
				end
			elseif subaction == "add" then
				local url = args[3]
				if not url then
					warn("[Cealshell] Usage: rbxpackage remote add <url>")
					return
				end
				if table.find(remotes, url) then
					print("[Cealshell] Remote '" .. url .. "' is already registered.")
				else
					table.insert(remotes, url)
					saveRemotes()
					print("[Cealshell] Added remote '" .. url .. "'")
				end
			elseif table.find({"rm", "remove", "delete"}, subaction) then
				local url = args[3]
				if not url then
					warn("[Cealshell] Usage: rbxpackage remote remove <url>")
					return
				end
				if table.find(remotes, url) then
					table.remove(remotes, table.find(remotes, url))
					saveRemotes()
					print("[Cealshell] Removed remote '" .. url .. "'")
				else
					print("[Cealshell] Remote '" .. url .. "' not registered.")
				end
			else
				print("[Cealshell] Unknown remote subcommand: " .. subaction)
			end
		else
			print("[Cealshell] Unknown action: " .. action)
		end
	end, "Package manager for Cealshell.", {
		[1] = "Manages packages from configured remotes.",

		["install"] = {
			"rbxpackage install [package...]",
			"Installs one or more packages from registered remotes.",
			"Options:",
			"  -s     Install to shared storage (ReplicatedStorage)",
			"  -y     Auto-confirm installation",
			"  -i     Insert into selected instance",
		},
		["remove"] = {
			"rbxpackage remove [package...]",
			"Removes installed packages from your workspace.",
			"Options:",
			"  -s     Remove from shared storage (ReplicatedStorage)",
			"  -y     Auto-confirm removal",
		},
		["list"] = {
			"rbxpackage list [pattern]",
			"Lists installed packages (optionally filtered by pattern).",
		},
		["remote"] = {
			"rbxpackage remote list          — Lists all active remotes",
			"rbxpackage remote add <url>     — Adds a new remote source",
			"rbxpackage remote remove <url>  — Removes a remote source",
		},
	}, signer):alias({"rbxp", "pacman"})

	--c clear
	registry:register("clear", nil, function()
		print(string.rep("\n", 50))
	end, "Clears the console.", nil, signer):alias("cls")
	
	--// Misc
	plugin.Unloading:Connect(function()
		saveRemotes()
	end)
end