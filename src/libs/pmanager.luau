local libs = script.Parent
local packager = require(libs:FindFirstChild("packager"))
local helper = require(libs:FindFirstChild("helper"))

local HttpService = game:GetService("HttpService")

local plugin: Plugin
local pmanager = {}
pmanager.pendingOperations = {}

function pmanager:constructor(_plugin: Plugin)
    plugin = _plugin
end

-- Check if a package is installed
function pmanager:check(share: boolean, name: string): boolean
    local f = helper:ensureCealshellPath(share)
    local ix = require(f[".index"])
    return ix:read()[name] ~= nil
end

-- Syncing
function pmanager:sync(freshBuild: boolean?): boolean
    local start = tick()
    local function getPassed(s: number): string return tostring(math.floor((tick() - s)*10^3))  end
    print("[Cealshell] Starting sync.")

    print("Checking keyring...")
    local keyring = plugin:GetSetting("cealshell:packages/keyring")
    if typeof(keyring) ~= "table" then
        print("Keyring is invalid. Trying refetch...")
        keyring = plugin:GetSetting("cealshell:packages/keyring")
    end
    if typeof(keyring) ~= "table" then
        print("Keyring is invalid. Resetting keyring.")
        keyring = {}
        plugin:SetSetting("cealshell:packages/keyring", {})
    end
    
    local function getRemotesSafe(): any
        local remotes = plugin:GetSetting("cealshell:remotes")
        if typeof(remotes) ~= "table" then
            print("Remotes invalid. Trying refetch...")
            remotes = plugin:GetSetting("cealshell:remotes")
        end
        if typeof(remotes) ~= "table" then
            print("Remotes invalid - bailing out. You're on your own now, good luck.")
            print(("[Cealshell] Failed to sync in %sms."):format(getPassed(start)))
            return false
        end
        return remotes
    end

    local function check()
        for remote, data in keyring do
            local remotes = getRemotesSafe()
            if not remotes then return end
            local exists = false
            for _, x in remotes do
                exists = (x == remote)
                if exists then break end
            end
            if not exists then
                keyring[remote] = nil
                print(("Removed deprecated remote %s."):format(remote))
            end
        end
    end

    local function syncRemote(remote: string): boolean
        local startR = tick()
        local trailingSlash = (remote:sub(#remote, #remote) == "/")
        local finalUrl = ("%s%sapi/packages"):format(remote, trailingSlash and "" or "/")
        print(("Syncing remote %s..."):format(finalUrl))
        local data = HttpService:GetAsync(finalUrl)
        local decoded = HttpService:JSONDecode(data)
        if typeof(decoded) ~= "table" or not decoded.data then
            print(("Returned data of %s is invalid. Skipping."):format(finalUrl))
            return false
        end
        keyring[remote] = decoded.data
        print(("Sync of remote %s successful in %s."):format(finalUrl, getPassed(startR)))
        return true
    end

    local function sync()
        print("Fetching remotes...")
        local remotes = getRemotesSafe()
        if not remotes then return false end
        print("Starting sync...")
        for _, remote in remotes do
           syncRemote(remote)
        end
        return true
    end

    if #keyring ~= 0 and not freshBuild then
        check()
        sync()
    else
        print("Building keyring due to request/being empty.")
        sync()
        print("Fresh Build successful.")
    end

    -- save keyring
    plugin:SetSetting("cealshell:packages/keyring", keyring)
    
    print(("[Cealshell] Synced successfully in %sms."):format(getPassed(start)))
    return true
end

-- Resolve package dependencies
local function resolveDependencies(ix, toInstall, visited)
    visited = visited or {}
    local resolved = {}
    
    for _, pkg in pairs(toInstall) do
        if not visited[pkg.name] then
            visited[pkg.name] = true
            
            if pkg.data and pkg.data.dependencies and typeof(pkg.data.dependencies) == "table" then
                for _, dep in pairs(pkg.data.dependencies) do
                    if not (ix:read()[dep] ~= nil) then
                        warn("[Cealshell] Dependency '" .. dep .. "' for '" .. pkg.name .. "' is not installed. Proceeding anyway.")
                    end
                end
            end
            
            table.insert(resolved, pkg)
        end
    end
    
    return resolved
end

-- Internal: Perform the actual installation
local function executeInstall(toInstall: {{any}}, cealshellFolder: Instance, isInstanceSpecific: boolean)
    local ix
    if not isInstanceSpecific then
        ix = require(cealshellFolder:FindFirstChild(".index"))
    end
    
    for _, pkg in pairs(toInstall) do
        local source = packager:build(pkg.data, ix and cealshellFolder:FindFirstChild("src") or cealshellFolder)
        if ix ~= nil then
            ix:register(pkg.name, source)
        end
        print("[Cealshell] Successfully installed '" .. pkg.name .. "'")
    end
end

-- Internal: Perform the actual uninstall
local function executeUninstall(toRemove: {string}, cealshellFolder: Instance)
    local ix = require(cealshellFolder:FindFirstChild(".index"))
    local packages = ix:read()
    
    for _, pkgName in pairs(toRemove) do
        if packages[pkgName] then
            local pkgConfig = packages[pkgName]
            if pkgConfig:FindFirstChild("source") then
                pkgConfig.source.Value:Destroy()
            end
            ix:deregister(pkgName)
            print("[Cealshell] Successfully uninstalled '" .. pkgName .. "'")
        end
    end
end

-- Install packages with optional confirmation
function pmanager:install(data: {[string]: boolean}, autoConfirm: boolean, remotes: {string}, packages: {string})
    local share = data.s
    local selectedInstance = data.i -- Instance to install into (optional)
    
    -- Use selected instance if provided, otherwise use cealshell folder
    local targetFolder
    local ix
    if selectedInstance and typeof(selectedInstance) == "Instance" then
        -- Create a .cealshell structure in the selected instance
        targetFolder = selectedInstance
    else
        -- Use standard cealshell folder
        targetFolder = helper:ensureCealshellPath(share)
        ix = require(targetFolder[".index"])
    end

    if not remotes or #remotes == 0 then
        warn("[Cealshell] No remotes configured. Check plugin settings.")
        return
    end

    -- Get package data from remotes
    local toInstall: {{any}} = {}
    for _, pkg in pairs(packages) do
        if type(pkg) ~= "string" or pkg == "" then continue end
        
        local retrievedPackage = nil
        local hasUrl = pkg:find("/") ~= nil
        local hasAuthor = pkg:find(":") ~= nil

        if hasUrl then
            local packageUrl = packager:parse(pkg)
            local packageData = packager:retrieve(packageUrl)
            if packageData then
                local success, parsed = pcall(HttpService.JSONDecode, HttpService, packageData)
                if success and parsed then
                    retrievedPackage = parsed.data or parsed
                end
            end
        elseif hasAuthor then
            local defaultRemote = remotes[1]
            if not defaultRemote then
                local setting = plugin:GetSetting("cealshell:remotes/default")
                if setting then defaultRemote = setting end
            end
            
            if defaultRemote then
                local packageUrl = packager:parse(pkg, defaultRemote)
                local packageData = packager:retrieve(packageUrl)
                if packageData then
                    local success, parsed = pcall(HttpService.JSONDecode, HttpService, packageData)
                    if success and parsed then
                        retrievedPackage = parsed.data or parsed
                    end
                end
            end
        else
            for _, remote in pairs(remotes) do
                local packageUrl = remote .. pkg
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
            table.insert(toInstall, {name = pkg, data = retrievedPackage})
        else
            warn("[Cealshell] Could not find package '" .. pkg .. "' in any remote")
        end
    end

    if ix then
        toInstall = resolveDependencies(ix, toInstall)
    end

    -- Display packages to install
    print()
    if #toInstall > 0 then
        print("Packages to install:")
        for _, pkg in pairs(toInstall) do
            print("  - " .. pkg.name)
            if pkg.data and pkg.data.instances then
                print("    └─ " .. #pkg.data.instances .. " instances")
            end
        end
        print()
        
        if autoConfirm then
            executeInstall(toInstall, targetFolder, selectedInstance ~= nil)
        else
            -- Store for later confirmation
            pmanager.pendingOperations.install = {
                packages = toInstall,
                folder = targetFolder,
                isInstanceSpecific = selectedInstance ~= nil
            }
            print("[Cealshell] Pending confirmation. Type 'confirm' to proceed or 'cancel' to abort.")
        end
    else
        print("[Cealshell] No packages to install.")
    end
end

-- Uninstall packages with optional confirmation
function pmanager:uninstall(share: boolean, autoConfirm: boolean, packages: {string})
    local f = helper:ensureCealshellPath(share)
    local ix = require(f[".index"])
    local installed = ix:read()

    -- Filter packages that exist
    local packagesToRemove = {}
    print()
    print("Packages to uninstall:")
    for _, pkg in pairs(packages) do
        if type(pkg) == "string" and installed[pkg] then
            table.insert(packagesToRemove, pkg)
            print("  - " .. pkg)
        elseif type(pkg) == "string" then
            warn("[Cealshell] Package '" .. pkg .. "' not found")
        end
    end
    print()
    
    if #packagesToRemove == 0 then
        print("[Cealshell] No packages to uninstall.")
        return
    end
    
    if autoConfirm then
        executeUninstall(packagesToRemove, f)
    else
        -- Store for later confirmation
        pmanager.pendingOperations.uninstall = {
            packages = packagesToRemove,
            folder = f
        }
        print("[Cealshell] Pending confirmation. Type 'confirm' to proceed or 'cancel' to abort.")
    end
end

-- Confirm the pending operation
function pmanager:confirm()
    if pmanager.pendingOperations.install then
        local op = pmanager.pendingOperations.install
        executeInstall(op.packages, op.folder, op.isInstanceSpecific or false)
        pmanager.pendingOperations.install = nil
        return true
    elseif pmanager.pendingOperations.uninstall then
        local op = pmanager.pendingOperations.uninstall
        executeUninstall(op.packages, op.folder)
        pmanager.pendingOperations.uninstall = nil
        return true
    end
    print("[Cealshell] No pending operation to confirm.")
    return false
end

-- Cancel the pending operation
function pmanager:cancel()
    if pmanager.pendingOperations.install or pmanager.pendingOperations.uninstall then
        print("[Cealshell] Operation cancelled.")
        pmanager.pendingOperations = {}
        return true
    end
    print("[Cealshell] No pending operation to cancel.")
    return false
end

return pmanager