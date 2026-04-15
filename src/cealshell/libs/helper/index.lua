local ix = {}

function ix:read()
    local t = {}
    for _, x: ObjectValue in script:GetChildren() do
        t[x.Name] = x.Value
    end
    return t
end

function ix:register(name: string, source: Instance) :: ObjectValue
    if type(name) ~= "string" then return end
    if type(source) ~= "Instance" then return end

    local x = Instance.new("ObjectValue", script)
    x.Name = name
    x.Value = source

    return x
end

function ix:deregister(name: string)
    if type(name) ~= "string" then return end
    if not script:FindFirstChild(name) then return end
    script[name]:Destroy()
end

return ix