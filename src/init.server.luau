--[[
 ______     ______     ______     __         ______     __  __     ______     __         __        
/\  ___\   /\  ___\   /\  __ \   /\ \       /\  ___\   /\ \_\ \   /\  ___\   /\ \       /\ \       
\ \ \____  \ \  __\   \ \  __ \  \ \ \____  \ \___  \  \ \  __ \  \ \  __\   \ \ \____  \ \ \____  
 \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_____/ 
                                                                                                   
Simple and easy CLI tool with integrated package manager.
Designed for Roblox Studio.
Licensed with MIT under (c) Flux Studio 2026.
GitHub: https://github.com/rbx-flux/cealshell-cli
Website: https://cealshell.dev/
]]--

local start = tick()
--

--// Services
local LogService = game:GetService("LogService")

--// Folders
local libs = script:FindFirstChild("libs")

--// Modules
local reg = require(libs:FindFirstChild("registry"))
require(script.initiate)(plugin)

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


--
print("[Cealshell] Loaded in", math.floor((tick() - start)*10^3) .."ms")