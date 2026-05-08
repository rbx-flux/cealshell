return function(plugin: Plugin)
	--// Folders
	local Cealshell = script.Parent
	local libs = Cealshell:FindFirstChild("libs")
	local cmds = Cealshell.commands

	--// Modules
	local registry = require(libs:FindFirstChild("registry"))
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
		plugin:SetSetting("cealshell:packages/keyring", {})
		
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
	local function iretate(folder: Instance)
		for _, item in folder:GetChildren() do
			if not item:IsA("ModuleScript") then
				iretate(item)
				continue
			end
			local cmd = require(item)
			if cmd.constructor then
				cmd.constructor(plugin)
			end
			local r = registry:register(cmd.name, cmd.args, cmd.callback, cmd.description, cmd.manual, cmd.signer)
			if cmd.alias and typeof(cmd.alias) == "table" then
				r:alias(cmd.alias)
			end
		end
	end
	iretate(cmds)
	
	--// Misc
	plugin.Unloading:Connect(function()
		saveRemotes()
	end)
end