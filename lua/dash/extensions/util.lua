--[[---------------------------------------------------------
   Name: Tracer(vecStart, vecEnd, pEntity, iAttachment, flVelocity, bWhiz, pCustomTracerName, iParticleID)
   Desc: Create a tracer effect
-----------------------------------------------------------]]
-- Tracer flags
TRACER_FLAG_WHIZ = 0x0001
TRACER_FLAG_USEATTACHMENT = 0x0002

TRACER_DONT_USE_ATTACHMENT = -1

function util.Tracer(vecStart, vecEnd, pEntity, iAttachment, flVelocity, bWhiz, pCustomTracerName, iParticleID)
	local data = EffectData()
	data:SetStart(vecStart)
	data:SetOrigin(vecEnd)
	data:SetEntity(pEntity)
	data:SetScale(flVelocity)
	
	if (iParticleID ~= nil) then
		data:SetHitBox(iParticleID)
	end

	local fFlags = data:GetFlags()

	-- Flags
	if bWhiz then
		fFlags = bit.bor(fFlags, TRACER_FLAG_WHIZ)
	end

	if (iAttachment ~= TRACER_DONT_USE_ATTACHMENT) then
		fFlags = bit.bor(fFlags, TRACER_FLAG_USEATTACHMENT)
		data:SetAttachment(iAttachment)
	end

	data:SetFlags(fFlags)

	-- Fire it off
	if pCustomTracerName then
		util.Effect(pCustomTracerName, data)
	else
		util.Effect("Tracer", data)
	end
end

--[[---------------------------------------------------------
	Find an empty Vector
-----------------------------------------------------------]]
local Vector 				= Vector
local ents_FindInSphere 	= ents.FindInSphere
local util_PointContents 	= util.PointContents

local badpoints = {
	[CONTENTS_SOLID] 		= true,
	[CONTENTS_MOVEABLE] 	= true,
	[CONTENTS_LADDER]		= true,
	[CONTENTS_PLAYERCLIP] 	= true,
	[CONTENTS_MONSTERCLIP] 	= true,
}

function util.PosIsEmpty(pos, area, fAllowed)
	if badpoints[util_PointContents(pos)] then
		return false
	end

	local entities = ents_FindInSphere(pos, area)
	for i = 1, #entities do
		if fAllowed and fAllowed(entities[i]) then continue end

		if isProp(entities[i]) or (entities[i]:IsPlayer() and entities[i]:Alive()) then
			return false
		end
	end

	return true
end

local isEmpty = util.PosIsEmpty
function util.FindEmptyPos(pos, area, steps)
	pos = Vector(pos.x, pos.y, pos.z)
	area = area or 35

	if isEmpty(pos, area) then
		return pos
	end

	for i = 1, (steps or 6) do
		local step = i * math.random(20,50)
		if isEmpty(Vector(pos.x + step, pos.y, pos.z), area) then
			pos.x = pos.x + step
			return pos
		elseif isEmpty(Vector(pos.x, pos.y + step, pos.z), area) then
			pos.y = pos.y + step
			return pos
		elseif isEmpty(Vector(pos.x, pos.y, pos.z + step), area) then
			pos.z = pos.z + step
			return pos
		end
	end

	return pos
end


local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function util.Base64Decode(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

function resource.AddDir(dir, recursive)
	local files, folders = file.Find(dir .. '*', 'GAME')

	for k, v in ipairs(files) do
		resource.AddFile(dir .. v)
	end
	if (recursive == true) then
		for _,d in ipairs(folders) do
			if d == '.svn' then continue end
			resource.AddDir(dir .. d, recursive)
		end
	end
end

function IsValid(object)
	if (not object) then return false end

	local isvalid = object.IsValid
	if (not isvalid) then return false end

	return isvalid(object)
end
