local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
    name = "confirm",
    args = nil,
    callback = function()
        if pmanager:confirm() then
			-- Operation cancelled
		end
    end,
    description = "Confirms a pending package operation.",
    manual = nil,
    signer = "cealshell",
    alias = nil,
}