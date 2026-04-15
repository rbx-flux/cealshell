local libs = script.Parent
local packager = require(libs:FindFirstChild("packager"))
local helper = require(libs:FindFirstChild("helper"))

local UIS = game:GetService("UserInputService")

local plugin: Plugin
local pmanager = {}
pmanager.queue = {}

local function install(toInstall: {{any}})
    for _, pkg in pairs(toInstall) do
        packager:build(pkg.data, i)
        print("Successfully installed " .. pkg.name)
    end
end

UIS.InputBegan:Connect(function(input)
    if #pmanager.queue > 0 then
        if input.KeyCode == Enum.KeyCode.Y then
            install(pmanager.queue[1])
        elseif input.KeyCode == Enum.KeyCode.N then
            print("[Cealshell] Cancelling installation.")
        else
            return
        end
        table.remove(pmanager.queue, 1)
    end
end)

function pmanager:constructor(_plugin: Plugin)
    plugin = _plugin
end

function pmanager:check(share: boolean, name: string)
    local f = helper.ensureCealshellPath(share)
    local ix = require(f[".index"])
    return ix:read()[name] ~= nil
end

function pmanager:install(share: boolean, autoConfirm: boolean, packages: {string})
    local f = helper.ensureCealshellPath(share);
    local nf = helper.ensureCealshellPath(not share);
    local ix = require(f[".index"])
    local nix = require(nf[".index"])

    -- Get package data
    local toInstall = {}
    for _, pkg in pairs(packages) do
        if type(pkg) ~= "string" then continue end
        
        local retrievedPackage = nil
        local hasUrl = packageName:find("/") ~= nil
        local hasAuthor = packageName:find(":") ~= nil

        if hasUrl then
            local packageUrl = packager:parse(packageName)
            local packageData = packager:retrieve(packageUrl)
            if packageData then
                local success, parsed = pcall(HttpService.JSONDecode, HttpService, packageData)
                if success and parsed then
                    retrievedPackage = parsed.data or parsed
                end
            end
        elseif hasAuthor then
            local packageUrl = packager:parse(packageName, remotes[1] or plugin:GetSetting("cealshell:remotes/default"))
            local packageData = packager:retrieve(packageUrl)
            if packageData then
                local success, parsed = pcall(HttpService.JSONDecode, HttpService, packageData)
                if success and parsed then
                    retrievedPackage = parsed.data or parsed
                end
            end
        else
            for _, remote in pairs(remotes) do
                local packageUrl = remote .. packageName
                local packageData = packager:retrieve(packageUrl)
                if packageData then
                    local success, parsed = pcall(HttpService.JSONDecode, HttpService, packageData)
                    if success and parsed then
                        retrievedPackage = parsed.data or parsed
                        break
                    end
                end
            end
        end
        
        if retrievedPackage then
            table.insert(toInstall, {name = packageName, data = retrievedPackage})
        else
            warn("[Cealshell] Could not find package " .. packageName .. " in any remote")
        end
    end

    -- Installment
    print()
    if #toInstall > 0 then
        print("Packages to install:")
        for _, pkg in pairs(toInstall) do
            print("  - " .. (pkg.name or "UNKNOWN"))
            if pkg.data and pkg.data.instances then
                print("    └─ " .. #pkg.data.instances .. " instances")
            end
            if pkg.data and pkg.data.dependencies and typeof(pkg.data.dependencies) == "table" then
                for _, dep in pairs(pkg.data.dependencies) do
                    print("    └─ " .. dep)
                end
            end
        end
        print()
        
        if autoConfirm then
            install(toInstall)
        else
            table.insert(pamanager.queue, toInstall)
        end
    end
end

function pmanager:uninstall(share: boolean, autoConfirm: boolean, packages: {string})
    local f = helper.ensureCealshellPath(share);
    local ix = require(f[".index"])
end

return pmanager