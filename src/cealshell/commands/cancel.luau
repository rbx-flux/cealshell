local libs = script.Parent.Parent.libs
local pmanager = require(libs.pmanager)

return {
    name = "cancel",
    args = nil,
    callback = function()
        if pmanager:cancel() then
			-- Operation cancelled
		end
    end,
    description = "Cancels a pending package operation.",
    manual = nil,
    signer = "cealshell",
    alias = nil,
}