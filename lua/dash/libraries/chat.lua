chat = chat or {}
chat.GetTable = chat.GetTable or setmetatable({}, {
	__call = function(self)
		return self
	end
})

setmetatable(chat,{
	__call = function(self, name)
		return self.Register(name)
	end,
})



local chats = chat.GetTable

local CHAT = {}
CHAT.__index = CHAT

debug.getregistry().Chat = CHAT

local net_Start = net.Start
local net_Send  = net.Send
local ents_FindInSphere = ents.FindInSphere

function chat.Register(name)
	local OBJ = setmetatable({
		NetworkString = 'chat_' .. name,
		SendFunc = net.Broadcast,
		Name = name
	},CHAT)

	chats[name] = OBJ

	if (SERVER) then
		util.AddNetworkString(OBJ.NetworkString)
	else
		net.Receive(OBJ.NetworkString, function()
			if IsValid(LocalPlayer()) then
				local ret = {OBJ.ReadFunc()}
				if (#ret > 0) then
					chat.AddText(unpack(ret))
				end
			end
		end)
	end

	return setmetatable(OBJ, CHAT)
end

function chat.Send(name, ...)
	local chat_obj = chats[name]
	net_Start(chat_obj.NetworkString)
		chat_obj.WriteFunc(...)
	chat_obj.SendFunc(...)
end

function CHAT:Write(func)
	self.WriteFunc = func
	return self
end

function CHAT:Read(func)
	self.ReadFunc = func
	return self
end

function CHAT:Filter(fFilter)
	self.SendFunc = function(...)
		net_Send(fFilter(...))
	end

	return self
end

function CHAT:SetLocal(radius) -- first arg to chat.Send must be a player if this is used
	self.SendFunc = function(pl)
		net_Send(table.Filter(ents_FindInSphere(pl:EyePos(), radius), function(v)
			return v:IsPlayer()
		end))
	end
end
