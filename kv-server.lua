----------------------------------------
-- Test task for tarantool team vacancy.
----------------------------------------

-- Import modules
local httpd = require('http.server')
local router = require('http.router').new()
local json=require('json')
local log = require('log')

box.cfg{log_format = 'plain', log = 'kv-app.log'}

-- Create space for the first time
box.once('schema', function()
	box.schema.create_space('massive')
	box.space.massive:format({
        	{ name = 'key', type = 'string' },
        	{ name = 'value', type = 'string' }})
	box.space.massive:create_index('primary', {type = 'hash', parts = {1, 'str'}})
end)

-- Request_checker
local function req_check_post(req)
	print('reqQQQ', req['key'], req['value'])
	if ((req['key'] == nil) or (type(req['key']) ~= 'string')) then
        	log.info("Error: incorrect key!")
        	return true
    	elseif ((req['value'] == nil) or (type(req['value']) ~= 'string')) then
        	log.info("Error: incorrect value!")
		return true
	end
	return false
end

local function req_check_put(req)
	print('reqQQQ', req['key'], req['value'])
	if ((req['value'] == nil) or (type(req['value']) ~= 'string')) then
        	log.info("Error: incorrect value!")
		return true
	end
	return false
end
-- POST handler
local function poster(self)
	local jkv = json.decode(self:read())
	if req_check_post(jkv) then
		log.info('Wrong key-value!')
		return {status = 400,headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Wrong key-value!</body>
		    			</html>]]
		    	};
	end

	for v, t in box.space.massive:pairs() do
		-- Check for value existing
		if (jkv['key'] == t[1]) then
			log.info("Key {" .. jkv['key'] .. "} already exists.")
	    		return {status = 409,headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Key already exists!</body>
		    			</html>]]
		    	};
		end
	end
	-- Add new key-value 
	box.space.massive:insert{jkv['key'], jkv['value']}
	log.info("Record {" .. jkv['key'] .."/"..jkv['value'].."} added succesfully")
	return {status = 200,headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    	body = [[<html>
		    		<body>Record added succesfully.</body>
		    	</html>]]
		};
end

-- GET handler
local function getter(self)
	local key = self:stash('key')
	local kv = box.space.massive:get(key)
	if (kv == nil) then
	log.info("Key {"..key.."} not found!")
	return { status = 404, headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Key not found!</body>
		    			</html>]]
		};
	end
	
	log.info("Success, return value: {"..kv[2].."}.")
	return { status = 200, body = kv[2] }
end

-- DELETE handler
local function deletter(self)
	local key = self:stash('key')
	local kv = box.space.massive:get(key)
	if (kv == nil) then
		log.info("Key {"..key.."} not found!")
		return { status = 404, headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    		body = [[<html>
		    			<body>Key not found!</body>
		    		</html>]]
		};
	end
	
	box.space.massive:delete(key)
	log.info("Record {" .. kv[1] .."/"..kv[2].."} was deleted successfully.")
	return { status = 200, headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Record was deleted!</body>
		    			</html>]]
		}
end

-- PUT handler
local function putter(self)
	local key = self:stash('key')
	local jkv = json.decode(self:read())
	local kv = box.space.massive:get(key)
	if req_check_put(jkv) then
		log.info('Wrong key-value!')
		return {status = 400,headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Wrong key-value!</body>
		    			</html>]]
		    	};
	end
	
	if (kv == nil) then
	log.info("Key {"..key.."} not found!")
	return { status = 404, headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    		body = [[<html>
		    			<body>Key not found!</body>
		    		</html>]]
		};
	end
	
	box.space.massive:update(key, {{'=', 2, jkv['value']}})
	log.info("Record {" .. kv[1] .."/"..kv[2].."} was updated successfully.")
	return { status = 200, headers = { ['content-type'] = 'text/html; charset=utf8' }, 
	    			body = [[<html>
		    				<body>Record was updated!</body>
		    			</html>]]
		}
end

-- Server and routes initialisation
local server = httpd.new('127.0.0.1', 8080, {log_requests = true, log_errors = true})  
router:route({ path = '/kv', method = 'POST' }, poster)
router:route({ path = '/kv/:key', method = 'GET' }, getter)
router:route({ path = '/kv/:key', method = 'DELETE' }, deletter)
router:route({ path = '/kv/:key', method = 'PUT' }, putter)

server:set_router(router)
server:start()
