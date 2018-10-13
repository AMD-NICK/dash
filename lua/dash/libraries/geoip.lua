geoip = {}

local http_fetch    = http.Fetch
local json_to_table = util.JSONToTable

local failures      = 0
local result_cache  = {}


-- https://ipapi.com/documentation
-- https://ipapi.com/quickstart
local key = ""
function geoip.Get(ip, cback, failure)
	if result_cache[ip] then
		cback(result_cache[ip])
	else
		http_fetch("http://api.ipapi.com/api/" .. ip .. "?access_key=" .. key .. "&fields=country_code,country_name,continent_name", function(b)
			local res = json_to_table(b)
			if res.error then
				error(res.error.info)
			end

			failures = 0
			result_cache[ip] = res
			cback(res)
		end, function()
			if failures <= 5 then
				timer.Simple(5, function()
					failures = failures + 1
					geoip.Get(ip, cback, failure)
				end)
			else
				failure()
			end
		end)
	end
end

function geoip.SetKey(sKey)
	key = sKey
end

-- geoip.SetKey("")
-- geoip.Get("8.8.8.8", PrintTable)
