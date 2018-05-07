local _O = {}

function ipInt(ip)
  local ip_int = 0
  local iter = string.gmatch(ip, "(%d+)")
  local count_octet = 4

  for k in iter do
    local octet = tonumber(k)
    
    ip_int = ip_int + (octet * math.pow(256, count_octet - 1))

    count_octet = count_octet - 1
  end

  return ip_int
end

local white_list = {
--  {2886795264, 2886795266, 0},
  {1680556032, 1680560127, 2},
  {1680560128, 1680560383, 2},
  {1680560384, 1680560639, 2},
  {1680560640, 1680560895, 2},
  {1680560896, 1680561151, 2}
}

function isNetAccess(ip) 
  local exist_flag = false
  -- Detect crawler by header
  -- local service_id = available_header[header]
  local min = 0
  local max = 0
  local list_access_params
  local ip_as_number = ipInt(ip)

  for index in ipairs(white_list) do
    -- Get record
    list_access_params = white_list[index]
    
    -- If ID range equal to ckeck address by current range
    min = list_access_params[1]
    max = list_access_params[2]

    -- Check range
    if min <= ip_as_number and max >= ip_as_number then
      return true
    end
  end

  return exist_flag
end

--- Method detection search engines crawlers
function accessUA(user_agent)
	local available_uagents = {
        	'Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)',
        	'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B411 Safari/600.1.4 (compatible; YandexBot/3.0; +http://yandex.com/bots)',
        	'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        	'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        	'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
	}

	for i in pairs(available_uagents) do
		if available_uagents[i] == user_agent then
			return true
		end
	end
	
	return false
end


function writeLog(log_msg)
	local io = require "io"
	local file=io.open('etc/nginx/lualib/log/log.txt', 'a+')
	file:write(log_msg , '\n')
	file:close()
end


function _O.sendData(data, uri, remote_addr)
	local str = ''
	local user_agent = ''
	local host = ''
	local uri_request      

	for k, v in pairs(data) do
		if k == 'user-agent' then
			user_agent = v

			if accessUA(user_agent) == false then
				return 'false'
			end
		end

		if k == 'host' then
			host = v
			uri_request = uri	
		end		
	end
	
	local redis = require "resty.redis"
	local red = redis:new()

       	red:set_timeout(1000) -- 1 sec

	local ok, err = red:connect('127.0.0.1', 6379)
	if err then
		 writeLog('Error of redis connection:' .. err)
	end
	
	ok, err = red:set('botstat:' .. host ..':' .. uri, os.time() )
	if err then
		writeLog('Error of call method from redis:' .. err)		
	end	
 
	-- return   host .. '  ' .. user_agent .. '  host:' .. uri .. ' ' .. tostring(isNetAccess(remote_addr)) .. '  ipint:' .. tostring(ipInt(remote_addr)) .. ' '  .. remote_addr
	if isNetAccess(remote_addr) and accessUA(user_agent) then 
		return true	
	else
		return false
	end
end

return _O

