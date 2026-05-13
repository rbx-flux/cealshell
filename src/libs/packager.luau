--// Services
local HttpService = game:GetService("HttpService")

--// Local Functions
local ENUM_PROPERTY_MAP = {
    RunContext = "RunContext",
    SafeAreaCompatibility = "SafeAreaCompatibility",
    ScreenInsets = "ScreenInsets",
    ZIndexBehavior = "ZIndexBehavior",
    SizeConstraint = "SizeConstraint",
    ScrollingDirection = "ScrollingDirection",
    ElasticBehavior = "ElasticBehavior",
    FillDirection = "FillDirection",
    HorizontalAlignment = "HorizontalAlignment",
    VerticalAlignment = "VerticalAlignment",
    SortOrder = "SortOrder",
    BorderMode = "BorderMode",
    ApplyStrokeMode = "ApplyStrokeMode",
    LineJoinMode = "LineJoinMode",
    ResampleMode = "ResampleMode",
    ScaleType = "ScaleType",
    TextDirection = "TextDirection",
    TextTruncate = "TextTruncate",
    TextXAlignment = "TextXAlignment",
    TextYAlignment = "TextYAlignment",
    AutomaticSize = "AutomaticSize",
    AspectType = "AspectType",
    DominantAxis = "DominantAxis",
    InputSink = "InputSink",
    StrokeSizingMode = "StrokeSizingMode",
}

local function deserializeValue(propertyName, propertyData)
    if type(propertyData) ~= "table" or not propertyData.type then
        return propertyData
    end

    local t = propertyData.type
    local v = propertyData.value

    if t == "UDim2" then
        return UDim2.new(v[1][1], v[1][2], v[2][1], v[2][2])
    elseif t == "UDim" then
        return UDim.new(v[1], v[2])
    elseif t == "Color3" then
        return Color3.fromRGB(v[1] * 255, v[2] * 255, v[3] * 255)
    elseif t == "Vector2" then
        return Vector2.new(v[1], v[2])
    elseif t == "Vector3" then
        return Vector3.new(v[1], v[2], v[3])
    elseif t == "Enum" then
        local enumType = ENUM_PROPERTY_MAP[propertyName]
        if enumType then
            local ok, result = pcall(function()
                return Enum[enumType]:FromValue(v)
            end)
            if ok then return result end
        end
        return nil
    elseif t == "int" or t == "int64" or t == "float" or t == "bool" or t == "string" then
        return v
    elseif t == "Instance" or t == "Unknown" then
        return nil
    end

    return nil
end

--// Globals
local packager = {}

function packager:parse(package: string, remote_Url: string?)
    local remoteUrl: string = remote_Url or "https://api.cealshell.dev"

    -- Normalize remote URL: remove trailing slash if present
    if remoteUrl:sub(-1) == "/" then
        remoteUrl = remoteUrl:sub(1, -2)
    end

    -- Check if package address contains "/" (full URL format)
    if package:find("/") then
        local s1 = package:split("/")
        assert(#s1 >= 2, "Invalid address")

        local s2 = s1[2]:split(":")
        assert(#s2 >= 2, "Missing ':'")

        local s3 = s2[2]:split("@")
        assert(#s3 >= 2, "Missing '@'")

        local url = s1[1]
        local author = s2[1]
        local packageName = s3[1]
        local version = s3[2]

        -- Preserve scheme from URL or default to https
        local scheme = "https"
        if url:match("^https?://") then
            scheme = url:match("^(https?)://")
            url = url:match("^https?://(.*)$")
        end
        
        local final = ("%s://%s/%s/%s/%s"):format(scheme, url, author, packageName, version)
        return final
    else
        -- Simplified format: author:package[@version]
        local parts = package:split(":")
        assert(#parts >= 2, "Invalid format. Use author:package or author:package@version")

        local author = parts[1]
        local restParts = table.concat(parts, ":", 2):split("@")
        local packageName = restParts[1]
        local version = restParts[2] or "latest"

        -- Build URL from remote, appending /api/packages if not already present
        local apiPath = "/api/packages"
        if not remoteUrl:match(apiPath .. "/?$") then
            remoteUrl = remoteUrl .. apiPath
        end
        
        local final = remoteUrl .. "/" .. author .. "/" .. packageName .. "/" .. version
        return final
    end
end

function packager:retrieve(address: string)
    local success, data = pcall(function() 
        return HttpService:GetAsync(address)
    end)
    if not success then 
        warn("[Packager] Failed to retrieve: " .. tostring(data))
        return nil 
    end
    return data
end

function packager:build(package: {instances: {}}, parent: Instance)
    if not package or not package.instances or #package.instances == 0 then
        warn("Invalid package data - no instances found")
        return
    end
    
    local function buildInstance(data, parentInstance)
        local instance = Instance.new(data.ClassName)
        instance.Name = data.Name

        if data.Properties then
            for propertyName, propertyData in pairs(data.Properties) do
                if propertyName ~= "ClassName" and propertyName ~= "Name" and propertyName ~= "Parent" then
                    local value = deserializeValue(propertyName, propertyData)
                    if value ~= nil then
                        pcall(function()
                            instance[propertyName] = value
                        end)
                    end
                end
            end
        end

        if data.Children and #data.Children > 0 then
            for _, childData in ipairs(data.Children) do
                buildInstance(childData, instance)
            end
        end
        
        instance.Parent = parentInstance
        
        return instance
    end
    
    if type(package.instances) == "table" then
        for _, instanceData in ipairs(package.instances) do
            return buildInstance(instanceData, parent)
        end
    end

    return nil
end

return packager