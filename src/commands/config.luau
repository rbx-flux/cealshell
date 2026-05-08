local libs = script.Parent.Parent.libs
local types = require(libs.types)
local plugin

return {
    name = "config",
    args = nil,
	constructor = function(pl: Plugin) plugin = pl end,
    callback = function(args:{types.args}, cArgs:{string})
        local blacklist = {
			"cealshell:remotes",
			"cealshell:remotes/default",
			"cealshell:packages/keyring"
		}
		local function format(x: string) : types.args
			if x == "true" then
				return true
			elseif x == "false" then
				return false
			elseif x:match("^%-?%d+%.?%d*$") then
				return tonumber(x) or 0
			else
				return x
			end
		end

		local function run()
			if args[2] then
				plugin:SetSetting(tostring(args[1]), format(tostring(args[2])))
			else
				print(plugin:GetSetting(tostring(args[1])))
			end
		end

		if plugin:GetSetting("cealshell:advanced") == true then
			run()
		else
			if not table.find(blacklist, args[1]) then
				run()
			else
				warn("[Cealshell] This configuration is locked behind advanced mode. Use '--c config cealshell:advanced true' to enable it.")
				return
			end
		end
		print(("[Cealshell] Successfully set '%s' to '%s' (%s)."):format(tostring(args[1]), tostring(args[2]), typeof(args[2])))
    end,
    description = nil,
    manual = nil,
    signer = "cealshell",
    alias = {"cfg"},
}