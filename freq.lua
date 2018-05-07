local _L = {}

function _L.log(host, remote_addr)
	local time_pick = nil
	local REQUEST_LIMIT_ANALYZE = 10
	local req_counter = 0
	local arr_range_tpicks = {}
	local ABNORMAL_COEF = 4 
	
	local REQUEST_LIMIT = 5000
	local TIME_USER_LOCK = 5
	local TIME_EXPIRE_REQUEST = 60

	local tmp_tick_value = nil
	local detect_heigth_freq = nil

        local h = os.date('%H')
        local second = os.time()

	--- Connect to Redis DB
        local redis = require "resty.redis"
        local red = redis:new()

        red:set_timeout(1000) -- 1 sec

        local ok, err = red:connect('127.0.0.1', 6379)
        if err then
          writeLog('Error of redis connection:' .. err)
        end

        local client_key = 'freq_requests:' .. host .. ':' .. remote_addr
	local request_short_live = 'short_freq_log:' .. remote_addr .. ':' .. host .. ':' .. tostring(second)	
	     
        data, err = red:get(client_key)

        if data == ngx.null then
        	red:set(client_key, 0)
        else
		data = tonumber(data)
		
		-- Check limit request and banned attribute
		if data > REQUEST_LIMIT or data == -1 then
			red:set(client_key, '-1')
			-- Freeze the key for a lock period
			red:expire(client_key, TIME_USER_LOCK)
			
			-- Clear history request after unlock client
        		data, err = red:keys('short_freq_log:' .. remote_addr .. ':' .. host .. ':*')
        		if data ~= ngx.null then
				for i in ipairs(data) do
					red:del(data[i])
				end
			end

			return	false
		end

        	red:set(client_key, data + 1)
        end

	-- Log request and timestamp
	red:set(request_short_live, second)
	red:expire(request_short_live, TIME_EXPIRE_REQUEST)

	data, err = red:keys('short_freq_log:' .. remote_addr .. ':' .. host .. ':*')
	
	-- Check behavor of client
	if data ~= ngx.null then
		local counter = 0
		for i in ipairs(data) do
    			for k in string.gmatch(data[i], ":(%d+)$") do
        			k = tonumber(k)
        			if time_pick ~= nil then
            				arr_range_tpicks[req_counter] = (k - time_pick)
            				req_counter = req_counter + 1 
        			end

        			time_pick = k
    			end
			counter = counter + 1
		end

		if req_counter > REQUEST_LIMIT_ANALYZE then
			detect_height_freq = true	
		
			time_pick = nil
			for i in ipairs(arr_range_tpicks) do
    				local tmp_time_label = arr_range_tpicks[i] 
	    			local trange = 0
    
		    		for k in ipairs(arr_range_tpicks) do
       				if k ~= i then
            					local tmp_tlabel = arr_range_tpicks[k] 
           	
            					if tmp_time_label > tmp_tlabel then
                					trange = tmp_time_label - tmp_tlabel
	            				else
        	        				trange = tmp_tlabel - tmp_time_label
            					end
            					
						-- If detect normal behavor for client to toggle flag
	            				if trange > ABNORMAL_COEF then
        	        				detect_heigth_freq = false
							break
            					end
					            
 		       			end
	    			end
			end
		else 
			detect_height_freq = nil
		end
	end

	if detect_height_freq == true then 
        	red:set(client_key, '-1')
        	red:expire(client_key, TIME_USER_LOCK)
	else 
        	red:expire(client_key, TIME_EXPIRE_REQUEST)
	end
	
	-- If current addr don't send requests
        if detect_height_freq == nil then
                detect_height_freq = false
        end

	if detect_heigth_freq then 
		return false
	else
		return true
	end
end

return _L
