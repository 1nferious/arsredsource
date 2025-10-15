local Cleaner = {}
Cleaner.__index = Cleaner

-- // Constructor Methods
function Cleaner.new()
	local self = setmetatable({}, Cleaner)
	
	self.Connections = {}
	self.Destroyable = {}
	self.Tasks = {}
	
	return self
end

function Cleaner:Destroy()
	self:Clean()

	table.clear(self)
end

-- // Methods
function Cleaner:AddDestroyable(destoryableInstance: any)
	table.insert(self.Destroyable, destoryableInstance)
	
	return destoryableInstance
end

function Cleaner:AddConnection(signalConnection: any)
	table.insert(self.Connections, signalConnection)
	
	return signalConnection
end

function Cleaner:AddTask(task: thread)
	table.insert(self.Tasks, task)
end

function Cleaner:Clean()
	for i,v in next, self.Tasks do
		if (coroutine.status(v) ~= 'dead') then
			task.cancel(v)
		end

		self.Tasks[i] = nil
	end

	for i,v in next, self.Connections do
		v:Disconnect()
		
		self.Connections[i] = nil
	end
	
	for i,v in next, self.Destroyable do
		if (not v.Destroy) then -- // no destroy method? skill issue
			continue
		end
		
		v:Destroy()
		
		self.Destroyable[i] = nil
	end
end

-- // Alias
Cleaner.AddSignal = Cleaner.AddDestroyable

return Cleaner