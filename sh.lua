
log_generate = true

function log(head, body)
	if not log_generate then return end
	if body == nil then print(head) return end
	print("\n<"..head..">\n"..body.."\n")
end


function sh(command,suppress)
	if suppress then command = command.." >/dev/null 2>&1" end
	log("sh command", command)
	local command_obj = io.popen(command)
	if command_obj == nil then error("io.popen is returning nil") end

	local output = command_obj:read('*a')
	output = string.gsub(output,"\n$",'')
	local _,_,op_status = command_obj:close()

	return  {out = output, status = op_status}
end


---@param checks table
function sh_input(question, checks)
	if type(checks) == 'string' then checks = {checks} end

	while true do
		if question ~= nil then print(question) end
		local input = io.read()

		local x = false
		for _, check_pattern in ipairs(checks) do
			x = (string.match(input, check_pattern) ~= nil) or x	
		end
		
		if x then return input end

	end 
end


function sh_q_enable_logs()
	input = sh_input('\nEnable logs? (y/n)\n', {'[yn]'})
	if input == 'y' 	then log_generate = true 
	elseif input == 'n' then  log_generate = false
	end
end


local arg_opts = {}

---@param key string
---@param func function
function arg_add_opts(key, func, desc) arg_opts[key] = {func, desc} end
function arg_run()
	if actions[arg_opts[1]] ~= null then
		actions[arg_opts[1]]()
		os.exit()
	end

	for key, key_data in ipairs(arg_opts) do
		print('"'..key..'" -> '..key_data[2]..'\n')
	end
end


-- function shx(command)
	-- local command_obj = io.popen(command)
	-- if command_obj == nil then error("io.popen is returning nil") end

	-- local output = command_obj:read('*a')
	-- output = string.gsub(output,"\n$",'')
	-- local _,_,op_status = command_obj:close()

	-- return  {out = output, status = op_status}
-- end


