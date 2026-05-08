local libs = script.Parent.Parent.libs
local helper = require(libs.helper)
local types = require(libs.types)
local pmanager = require(libs.pmanager)

local plugin
return {
    name = "rbxpackage",
    args = nil,
    constructor = function(pl: Plugin) plugin = pl end,
    callback = function(args:{types.args}, cArgs:{string})
		local action = args[1]
		if not action then
			print("[Cealshell] Usage: rbxpackage <install|remove|list|remote> [options]")
			return
		end

        local remotes = plugin:GetSetting("cealshell:remotes")

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
		elseif action == "sync" then
			pmanager:sync(helper:doesArgExist("f", args))

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
					plugin:SetSetting("cealshell:remotes", remotes)
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
					plugin:SetSetting("cealshell:remotes", remotes)
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
	end,
    description = "Package manager for Cealshell.",
    manual = {
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
		["sync"] = {
			"rbxpackage sync",
			"Manually sync all packages from all remotes.",
			"Options:",
			"  -f	  Fresh Build the keyring.",
		}
	},
    signer = "cealshell",
    alias = {"pacman", "rbxp"},
}