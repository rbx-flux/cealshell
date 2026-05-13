--[[
 ______     ______     ______     __         ______     __  __     ______     __         __        
/\  ___\   /\  ___\   /\  __ \   /\ \       /\  ___\   /\ \_\ \   /\  ___\   /\ \       /\ \       
\ \ \____  \ \  __\   \ \  __ \  \ \ \____  \ \___  \  \ \  __ \  \ \  __\   \ \ \____  \ \ \____  
 \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_____/ 
                                                                                                   
Simple and easy CLI tool with integrated package manager.
Designed for Roblox Studio.
Licensed with MIT under (c) janisfox 2026.
Contact: https://github.com/janisfox
GitHub: https://github.com/rbx-flux/cealshell-cli
Website: https://cealshell.dev/
]]--

local start = tick()
--

--// Services
local LogService = game:GetService("LogService")

--// Folders
local libs = script:FindFirstChild("libs")
local cmds = script:FindFirstChild("commands")

--// Modules
local reg = require(libs:FindFirstChild("registry"))
local pmanager = require(libs:FindFirstChild("pmanager"))
pmanager:constructor(plugin)

--// Binds
LogService.MessageOut:Connect(function(str: string, messageType: Enum.MessageType) 
	if messageType ~= Enum.MessageType.MessageOutput then return end

	local target = "> --c "
	if str:sub(1, target:len()) == target then
		str = str:sub(target:len()+1)
	else
		return
	end
	
	local split = str:split(" ")
	local cmd = split[1]
	split[1] = nil
	reg:call(cmd, split)
end)

--// Script

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

-- Register
local function iterate(folder: Instance)
	for _, item in folder:GetChildren() do
		if not item:IsA("ModuleScript") then
			iterate(item)
			continue
		end
		local cmd = require(item)
		if cmd.constructor then
			cmd.constructor(plugin)
		end
		local r = reg:register(cmd.name, cmd.args, cmd.callback, cmd.description, cmd.manual, cmd.signer)
		if cmd.alias and typeof(cmd.alias) == "table" then
			r:alias(cmd.alias)
		end
	end
end
iterate(cmds)

-- Misc
plugin.Unloading:Connect(function()
	saveRemotes()
end)


--
print("[Cealshell] Loaded in", math.floor((tick() - start)*10^3) .."ms")