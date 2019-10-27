local REDIS_CLIENT = FindMetaTable "redis_client"

local color_prefix, color_text = Color(225,0,0), Color(250,250,250)

local clients =	setmetatable({}, {__mode = "v"})
local clientcount = 0

function redis.GetClients()
	for i = 1, clientcount do
		if (clients[i] == nil) then
			table.remove(clients, i)
			i = i - 1
			clientcount = clientcount - 1
		end
	end

	return clients
end

function redis.ConnectClient(hostname, port, password, database, autopoll, autocommit)
	for k, v in ipairs(redis.GetSubscribers()) do
		if (v.Hostname == hostname) and (v.Port == port) and (v.Password == password) and (v.Database == database) and (v.AutoPoll == autopoll) and (v.AutoCommit == autocommit) then
			v:Log("Recycled connection.")
			return v
		end
	end

	local client, err = redis.CreateClient()

	if (not client) then
		error(err)
	end

	client.Hostname = hostname
	client.Port = port
	client.Password = password
	client.AutoPoll = autopoll
	client.AutoCommit = autocommit
	client.Database = database or 0
	client.PendingCommands = 0

	if (not client:TryConnect(hostname, port, password, database)) then
		return client
	end

	if (autopoll ~= false) or (autocommit ~= false) then
		hook.Add("Think", client, function()
			if (autocommit ~= false) and (client.PendingCommands > 0) then
				client:Commit()
			end
			if (autopoll ~= false) then
				client:Poll()
			end
		end)
	end

	table.insert(clients, client)
	clientcount = clientcount + 1

	return client
end


-- Internal
function REDIS_CLIENT:OnDisconnected()
	if (not hook.Call("RedisClientDisconnected", nil, self)) then
		timer.Create("RedisClientRetryConnect", 1, 0, function()
			if (not IsValid(self)) or self:TryConnect(self.Hostname, self.Port, self.Password, self.Database) then
				timer.Remove("RedisClientRetryConnect")
			end
		end)
	end
end

function REDIS_CLIENT:Wait(func, ...)
	local dat
	func(self, ..., function(...)
		dat = {...}
	end)

	self:Commit()

	self.IsWaiting = true
	local endwait = SysTime() + 1

	while self.IsWaiting and (endwait >= SysTime()) and (dat == nil) do
		self:Poll()
	end

	self:StopWait()

	return unpack(dat)
end

function REDIS_CLIENT:StopWait()
	self.IsWaiting = false
end

function REDIS_CLIENT:TryConnect(ip, port, password, database)
	local succ, err = self:Connect(ip, port)

	if (not succ) then
		self:Log(err)
		return false
	end

	if (password ~= nil) then
		local resp = self:Wait(self.Auth, password)
		if (resp ~= "OK") then
			self:Log(resp)
			return false
		end
	end

	if (database ~= nil) then
		local resp = self:Wait(self.Select, database)
		if (resp ~= "OK") then
			self:Log(resp)
			return false
		end
	end

	self:Log("Connected successfully.")

	hook.Call("RedisClientConnected", nil, self)

	return true
end

function REDIS_CLIENT:Log(message)
	MsgC(color_prefix, "[Redis-Client] ", color_text, "db" .. self.Database .. "@" .. self.Hostname .. ":" .. self.Port .. " => ", tostring(message) .. "\n")
end

local send = REDIS_CLIENT.Send
function REDIS_CLIENT:Send(tab, callback)
	self.PendingCommands = self.PendingCommands + 1
	return send(self, tab, callback and function(_, dat)
		callback(dat)
	end)
end

local publish = REDIS_CLIENT.Publish
function REDIS_CLIENT:Publish(channel, value, callback)
	self.PendingCommands = self.PendingCommands + 1
	return publish(self, channel, value, callback)
end

local commit = REDIS_CLIENT.Commit
function REDIS_CLIENT:Commit()
	self.PendingCommands = 0
	return commit(self)
end


function REDIS_CLIENT:Auth(password, callback)
	return self:Send({"AUTH", password}, callback)
end

function REDIS_CLIENT:Select(database, callback)
	return self:Send({"SELECT", database}, callback)
end

function REDIS_CLIENT:State(callback)
	return self:Send({"CLUSTER", "INFO"}, callback)
end

function REDIS_CLIENT:Save(callback)
	return self:Send("BGSAVE", callback)
end

function REDIS_CLIENT:LastSave(callback)
	return self:Send("LASTSAVE", callback)
end

-- Strings: https://redis.io/commands#string
function REDIS_CLIENT:APPEND(key, value, callback)
	return self:Send({"APPEND", key, value}, callback)
end

function REDIS_CLIENT:BITCOUNT(key, value, starti, endi, callback)
	return self:Send({"BITCOUNT", key, starti, endi}, callback)
end

function REDIS_CLIENT:SET(key, value, callback)
	return self:Send({"SET", key, value}, callback)
end

function REDIS_CLIENT:SETEX(key, value, secs, callback)
	return self:Send({"SETEX", key, secs, value}, callback)
end

function REDIS_CLIENT:GET(key, callback)
	return self:Send({"GET", key}, callback)
end

function REDIS_CLIENT:EXISTS(key, callback)
	return self:Send({"EXISTS", key}, callback)
end

function REDIS_CLIENT:EXPIRE(key, secs, callback)
	return self:Send({"EXPIRE", key, secs}, callback)
end

function REDIS_CLIENT:TTL(key, callback)
	return self:Send({"TTL", key}, callback)
end

function REDIS_CLIENT:DEL(key, callback)
	return self:Send({"DEL", key}, callback)
end



-- Config
function REDIS_CLIENT:GetConfig(param, callback)
	return self:Send({"CONFIG", "GET", param}, callback)
end

function REDIS_CLIENT:SetConfig(param, value, callback)
	return self:Send({"CONFIG", "SET", param, value}, callback)
end


-- Lists: https://redis.io/commands#list
function REDIS_CLIENT:BLPOP(key, keys, timeout, callback)
	return self:Send({"BLPOP", key, unpack(keys), timeout}, callback)
end

function REDIS_CLIENT:BRPOP(key, keys, timeout, callback)
	return self:Send({"BRPOP", key, unpack(keys), timeout}, callback)
end

function REDIS_CLIENT:BRPOPLPUSH(source, destination, callback)
	return self:Send({"BRPOPLPUSH", source, destination}, callback)
end

function REDIS_CLIENT:LINDEX(key, callback)
	return self:Send({"LINDEX", key}, callback)
end

function REDIS_CLIENT:LINSERT(key, value, callback)
	return self:Send({"LINSERT", key, value}, callback)
end

function REDIS_CLIENT:LLEN(key, callback)
	return self:Send({"LLEN", key}, callback)
end

function REDIS_CLIENT:LPOP(key, callback)
	return self:Send({"LPOP", key}, callback)
end

function REDIS_CLIENT:LPUSH(key, values, callback)
	return self:Send({"LPUSH", key, isstring(values) and values or unpack(values)}, callback)
end

function REDIS_CLIENT:LPUSHX(key, value, callback)
	return self:Send({"LPUSHX", key, value}, callback)
end

function REDIS_CLIENT:LRANGE(key, start, stop, callback)
	return self:Send({"LRANGE", key, start, stop}, callback)
end

function REDIS_CLIENT:LREM(key, count, value, callback)
	return self:Send({"LREM", key, count, value}, callback)
end

function REDIS_CLIENT:LSET(key, index, value, callback)
	return self:Send({"LSET", key, index, value}, callback)
end

function REDIS_CLIENT:LTRIM(key, start, stop, callback)
	return self:Send({"LTRIM", key, start, stop}, callback)
end

function REDIS_CLIENT:RPOPLPUSH(source, destination, callback)
	return self:Send({"RPOPLPUSH", source, destination}, callback)
end

function REDIS_CLIENT:RPUSH(key, values, callback)
	return self:Send({"RPUSH", key, isstring(values) and values or unpack(values)}, callback)
end

function REDIS_CLIENT:PRUSHX(key, value, callback)
	return self:Send({"PRUSHX", key, value}, callback)
end

--https://redis.io/commands#hash
function REDIS_CLIENT:HMGET(key, values, callback)
	return self:Send({"HMGET", key, isstring(values) and values or unpack(values)}, callback)
end

function REDIS_CLIENT:HSET(group, key, value, callback)
	return self:Send({"HSET", group, key, value}, callback)
end

function REDIS_CLIENT:HKEYS(group, callback)
	return self:Send({"HKEYS", group}, callback)
end

function REDIS_CLIENT:HDEL(group, key, callback)
	return self:Send({"HDEL", group, key}, callback)
end

function REDIS_CLIENT:HGETALL(group, callback)
	return self:Send({"HGETALL", group}, function(dat)
		if not dat[0] then
			callback(nil)
			return
		end

		local new_dat = {}
		for i = 0,#dat,2 do -- bulk
			new_dat[dat[i]] = dat[i + 1]
		end

		callback(new_dat)
	end)
end
