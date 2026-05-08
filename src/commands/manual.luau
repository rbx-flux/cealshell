local libs = script.Parent.Parent.libs
local types = require(libs.types)
local registry = require(libs.registry)

return {
    name = "manual",
    args = nil,
    callback = function(args: {types.args})
        local cmdName = args[1]
		local subName = args[2]

		if not cmdName then
			warn("[Cealshell] Usage: manual <command> [subcommand]")
			return
		end

		local vData = registry.commands[cmdName]
		if not vData then
			-- Try to resolve as an alias
			for _, data in pairs(registry.commands) do
				if data.stored_aliases and table.find(data.stored_aliases:getAll(), cmdName) then
					vData = data
					break
				end
			end
		end
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
    end,
    description = "Shows more information about a command.",
    manual = "you found THE manual of the century.",
    signer = "cealshell",
    alias = {"man"},
}