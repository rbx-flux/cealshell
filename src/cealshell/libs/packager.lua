--// Services
local HttpService = game:GetService("HttpService")

--// Globals
local packager = {}

function packager:parse(package: string)
    local s1 = package:split("/")
    assert(#s1 >= 2, "Invalid address")

    local s2 = s1[2]:split(":")
    assert(#s2 >= 2, "Missing ':'")

    local s3 = s2[2]:split("@")
    assert(#s3 >= 2, "Missing '@'")

    local url = s1[1]
    local author = s2[1]
    local package = s3[1]
    local version = s3[2]

    local final = ("http://%s/%s/%s/%s"):format(url, author, package, version)
    print(final)

    return final
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

function packager:build(package: {any}, parent: Instance)
    if not package or not package.instances then
        warn("Invalid package data")
        return
    end
    
    local function buildInstance(data, parentInstance)
        local instance = Instance.new(data.ClassName)
        instance.Name = data.Name

        if data.Properties then
            for propertyName, propertyData in pairs(data.Properties) do
                if propertyName ~= "ClassName" and propertyName ~= "Name" and propertyName ~= "Parent" then
                    if type(propertyData) == "table" and propertyData.type and propertyData.value then
                        pcall(function()
                            instance[propertyName] = propertyData.value
                        end)
                    elseif type(propertyData) ~= "table" or (propertyData.type ~= "Instance" and propertyData.type ~= "Object") then
                        pcall(function()
                            instance[propertyName] = propertyData
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
            buildInstance(instanceData, parent)
        end
    end
end

return packager