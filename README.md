## Web crawler and parsers detection NGINX/lua

#### Module on the LUA for detecting robots search engines. Can detect parsing the site and block IP. Protection of web resources from parsing


access - defines and logs the crawler

freq - defines parsers and blocks them


#### For freq.lua

REQUEST_LIMIT_ANALYZE - The time period for which the analysis will take place

ABNORMAL_COEF - Coefficient of deviation from normal. If the requests are received through the same time periods

REQUEST_LIMIT - The limit of requests after which the client be blocked

TIME_USER_LOCK - Blocking time for the IP address 

TIME_EXPIRE_REQUEST - Time expire data of request in redis storage	
