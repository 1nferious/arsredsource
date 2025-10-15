local Hooks = {}

-- // Constants
hookRegistry = {}

-- // Methods
function Hooks:upvalueBypassHook(oldFunction: () -> any, hookFunction: () -> any)
    if #debug.getupvalues(oldFunction) == 0 then
        local selfIndex = (#hookRegistry + 1)

        local grabFunction = loadstring(string.format([[return function(...)
            local constant = %s
            return hookRegistry[constant](...)
        end]], selfIndex), "Upvalue Bypass Hook")

        getfenv(grabFunction).hookRegistry = hookRegistry
        
        grabFunction = grabFunction() -- 🤯

        hookRegistry[selfIndex] = hookFunction

        return hookfunction(oldFunction, grabFunction)
    end

    return hookfunction(oldFunction, LPH_NO_VIRTUALIZE(function(...)
        return hookFunction(...)
    end))
end

function Hooks:findUpvalues(func, upvalueNames)
    local foundUpvalues = {}

    for _, v in next, debug.getupvalues(func) do
        if (typeof(v) ~= 'function') or (not islclosure(v)) or (isexecutorclosure(v)) then
            continue
        end

        if (table.find(upvalueNames, getinfo(v).name)) then
            foundUpvalues[getinfo(v).name] = v 
        end
    end

    return foundUpvalues
end

function Hooks:findUpvalue(func, condition)
    local isCustomCondition = (typeof(condition) == 'function')

    for _, v in next, debug.getupvalues(func) do
        -- // CUSTOM CONDITION
        if (isCustomCondition) then
            if (condition(v)) then
                return v
            end

            continue
        end

        -- // NORMAL CONDITION
        if (typeof(v) ~= 'function') or (not islclosure(v)) or (isexecutorclosure(v)) then
            continue
        end

        if (getinfo(v).name == condition) then
            return v
        end
    end
end

return Hooks
