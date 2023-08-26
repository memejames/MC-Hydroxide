local ClosureSpy = {}

local requiredMethods = {
    ["hookFunction"] = true,
    ["newCClosure"] = true,
    ["isLClosure"] = true,
    ["getProtos"] = true,
    ["getUpvalues"] = true,
    ["getUpvalue"] = true,
    ["getContext"] = true,
    ["setContext"] = true,
    ["setUpvalue"] = true,
    ["getConstants"] = true,
    ["getConstant"] = true,
    ["setConstant"] = true
}

-- Define as global function in order to reduce upvalue count in hooks

local eventCallback
		
function setEvent(callback)
    if not eventCallback then
        eventCallback = function(hook,...)
        	local vargs = {...}
        	if not hook.Ignored and not hook:AreArgsIgnored(vargs) then
			    if not hook:AreArgsIgnored(vargs) then
					task.spawn(function()
			        	callback(hook,unpack(vargs))
	        		end)
			    end
	        end
        end
    end
end

local Hook = {}
local hookMap = {}
hookCache = {}

function Hook.new(closure)
    local hook = {}
    if getInfo(closure.Data).nups < 1 then
        return
    elseif hookCache[closure.Data] then
        return false
    end
	
    --hookCache[closure.Data]
    local old; old = hookFunction(closure.Data, function(...)
        local vargs = {...}
        local call = {
			script = getfenv(0).script,
			args = vargs
		}
		
	    if eventCallback then
			task.spawn(function()
				eventCallback(hook, call)
			end)
		end
	    
	    
        if not hook.Blocked and not hook:AreArgsBlocked(vargs) then
            return old(...)
    	else
			return
        end
		
		return old(...)
    end)
    
	hookCache[closure.Data] = old
    closure.Data = hookCache[closure.Data]
	
    hook.Closure = closure
    hook.Calls = 0
    hook.Logs = {}
    hook.Ignored = false
    hook.Blocked = false
    hook.Ignore = Hook.ignore
    hook.Block = Hook.block
    hook.IgnoreArg = Hook.ignoreArg
    hook.BlockArg = Hook.blockArg
    hook.Remove = Hook.remove
    hook.Clear = Hook.clear
    hook.BlockedArgs = {}
    hook.IgnoredArgs = {}
    hook.AreArgsBlocked = Hook.areArgsBlocked
    hook.AreArgsIgnored = Hook.areArgsIgnored
    hook.IncrementCalls = Hook.incrementCalls
    hook.DecrementCalls = Hook.decrementCalls

    hookMap[closure.Data] = hook

    return hook
end

function Hook.remove(hook)
    hookMap[hook.Closure.Data] = nil
end

function Hook.clear(hook)
    hook.Calls = 0
end

function Hook.block(hook)
    hook.Blocked = not hook.Blocked
end

function Hook.ignore(hook)  
    hook.Ignored = not hook.Ignored
end

function Hook.blockArg(hook, index, value, byType)
    local blockedArgs = hook.BlockedArgs
    local blockedIndex = blockedArgs[index]

    if not blockedIndex then
        blockedIndex = {
            types = {},
            values = {}
        }
        blockedArgs[index] = blockedIndex
    end

    if byType then
        blockedIndex.types[value] = true
    else
        blockedIndex.values[value] = true
    end
end

function Hook.ignoreArg(hook, index, value, byType)
    local ignoredArgs = hook.IgnoredArgs
    local indexIgnore = ignoredArgs[index]

    if not indexIgnore then
        indexIgnore = {
            types = {},
            values = {}
        }

        ignoredArgs[index] = indexIgnore
    end

    if byType then
        indexIgnore.types[value] = true
    else
        indexIgnore.values[value] = true
    end
end

function Hook.areArgsBlocked(hook, args)
    local blockedArgs = hook.BlockedArgs

    for index, value in pairs(args) do
        local indexBlock = blockedArgs[index]
        
        if indexBlock and ( indexBlock.types[typeof(value)] or indexBlock.values[value] ~= nil ) then
            return true
        end
    end

    return false
end

function Hook.areArgsIgnored(hook, args)
    local ignoredArgs = hook.IgnoredArgs

    for index, value in pairs(args) do
        local indexIgnore = ignoredArgs[index]

        if indexIgnore and ( indexIgnore.types[typeof(value)] or indexIgnore.values[value] ~= nil ) then
            return true
        end
    end

    return false
end

function Hook.incrementCalls(hook, vargs)
    hook.Calls = hook.Calls + 1
    table.insert(hook.Logs, vargs)
end

function Hook.decrementCalls(hook, vargs)
    local logs = hook.Logs

    hook.Calls = hook.Calls - 1
    table.remove(logs, table.find(logs, vargs))
end

ClosureSpy.Hook = Hook
ClosureSpy.SetEvent = setEvent
ClosureSpy.RequiredMethods = requiredMethods
return ClosureSpy