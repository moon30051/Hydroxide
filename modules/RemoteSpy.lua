local RemoteSpy = {}
local Remote = import("objects/Remote")

local requiredMethods = {
    checkCaller = true,
    newCClosure = true,
    hookFunction = true,
    isReadOnly = true,
    setReadOnly = true,
    getInfo = true,
    getMetatable = true,
    setClipboard = true,
    getNamecallMethod = true,
    getCallingScript = true,
}

local remoteMethods = {
    FireServer = true,
    InvokeServer = true,
    Fire = true,
    Invoke = true,
}

local remotesViewing = {
    RemoteEvent = true,
    RemoteFunction = false,
    BindableEvent = false,
    BindableFunction = false,
}

local methodHooks = {
    RemoteEvent = Instance.new("RemoteEvent").FireServer,
    RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
    BindableEvent = Instance.new("BindableEvent").Fire,
    BindableFunction = Instance.new("BindableFunction").Invoke,
}

local currentRemotes = {}
local remoteDataEvent = Instance.new("BindableEvent")
local eventSet = false

local function connectEvent(callback)
    remoteDataEvent.Event:Connect(callback)
    eventSet = true
end

--[[
local nmcTrampoline
nmcTrampoline = hookMetaMethod(game, "__namecall", newcclosure(function(...)
    local instance = ...
    if typeof(instance) ~= "Instance" then return nmcTrampoline(...) end
    
    local method = getNamecallMethod()
    method = method == "fireServer" and "FireServer" or method == "invokeServer" and "InvokeServer" or method
    
    if remotesViewing[instance.ClassName] and instance ~= remoteDataEvent and remoteMethods[method] then
        local remote = currentRemotes[instance] or Remote.new(instance)
        currentRemotes[instance] = remote
        
        local vargs = {select(2, ...)}
        if not remote.Ignored and not remote:AreArgsIgnored(vargs) then
            local call = {
                script = getCallingScript(PROTOSMASHER_LOADED and 2 or nil),
                args = vargs,
                func = getInfo(3).func,
            }
            remote:IncrementCalls(call)
            remoteDataEvent:Fire(instance, call)
        end
        if remote.Blocked or remote:AreArgsBlocked(vargs) then return end
    end
    return nmcTrampoline(...)
end))
--]]
-- Security Fix
local function checkPermission(instance)
    if instance.ClassName then end
end

--[[
for className, hook in pairs(methodHooks) do
    local originalMethod
    originalMethod = hookFunction(hook, newcclosure(function(...)
        local instance = ...
        if typeof(instance) ~= "Instance" then return originalMethod(...) end
        
        if not pcall(checkPermission, instance) then return originalMethod(...) end
        
        if instance.ClassName == className and remotesViewing[className] and instance ~= remoteDataEvent then
            local remote = currentRemotes[instance] or Remote.new(instance)
            currentRemotes[instance] = remote
            
            local vargs = {select(2, ...)}
            if not remote.Ignored and not remote:AreArgsIgnored(vargs) then
                local call = {
                    script = getCallingScript(PROTOSMASHER_LOADED and 2 or nil),
                    args = vargs,
                    func = getInfo(3).func,
                }
                remote:IncrementCalls(call)
                remoteDataEvent:Fire(instance, call)
            end
            if remote.Blocked or remote:AreArgsBlocked(vargs) then return end
        end
        return originalMethod(...)
    end))
    
    oh.Hooks[originalMethod] = hook
end
--]]
RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods
return RemoteSpy
