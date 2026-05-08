local libs = script.Parent.Parent.libs
local types = require(libs.types)
local registry = require(libs.registry)

return {
    name = "help",
    args = nil,
    callback = function()
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
    end,
    description = "Shows a list of available commands.",
    manual = nil,
    signer = "cealshell",
    alias = {"?"},
}