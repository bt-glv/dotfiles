-- This is a system/hard link farming script
-- Declare folders/files present on the same folder
-- as this file to be linked at the root path

#!/usr/bin/env lua
package.path = ";./?.lua"
require('sh');


local root_path = "~/"
local links = {
	{".bashrc", 			"hard"},
	{".tmux.conf", 			"hard"},
	{".vimrc", 				"hard"},
	{".zshrc", 				"hard"},
	{".ssh/", 				"sys"},
	{".config/nvim/",		"sys"},
	{".config/alacritty/",	"sys"},
	{".local/share/nvim/",	"sys"},
	{".local/share/fonts/",	"sys"},
	--{".config/autostart/",	"sys"},
}

-- ideas
-- exclude folders from a path

-- todo
-- [ ] adapt this file to use SH for argument handling
-- [ ] adapt SH to handle argument trees


-------------
-------------

-- copies home folder path to this file's path
local function snapshot(paths, base_path)

		local operation = true
		log("\n>>\n>> snapshot START\n>>")

		for i, path in ipairs(paths) do

			local dirname = sh('dirname '..path).out
			sh('mkdir -p '..dirname)

			sh("cp -r "..base_path..path.." "..dirname)
			log("item "..i)
		end

		log("\n>>\n>> snapshot END\n>>")
end

local final_considerations = {
	messages = {},
	print = function(self)
		if #self == 0 then return end
		for _, data in ipairs(self.messages) do
			print(data)
		end
	end,
}


local function generate_backup(paths, base_path)
	log('\n>>\n>>generate_backup START\n>>\n')
	if paths == nil or base_path == nil then
		error('generate_backup:\nParameters cannot be nil')
	end


	local function check_foldername(name, index)
		if index == nil then index = 0 end

		local new_name = name..'-'..index
		if sh('ls | grep -Po "^'..new_name..'$"').status ~= 0 then
			return new_name
		end
		return check_foldername(name, index+1)
	end


	local backup_folder_name = check_foldername('backup.'..sh('echo "$HOSTNAME@$USER"').out)
	sh('mkdir '..backup_folder_name)

	local path_source_full
	for _, path in ipairs(paths) do
		path_source_full = base_path..path[1]

		sh('mkdir -p $(dirname '..backup_folder_name..'/'..path[1]..')')

		local check_syslink = sh('if [ -L "$(echo '..base_path..')'..path[1]..'" ]; then echo "t";  fi').out
		log("check_syslink value: ["..check_syslink..']  type:['..type(check_syslink)..']')

		if check_syslink  ~= "t" then
			sh('cp -r '..path_source_full.." "..backup_folder_name.."/"..path[1])
		else
			log('>> target path is a system link\n>> link path will be followed and copied')
			local syslink_path = sh('readlink '..path_source_full).out
			sh('cp -r '..syslink_path.." "..backup_folder_name.."/"..path[1])
		end

	end

	log('\n>>\n>> generate_backup END\n>>\n')
end


-- TODO:
-- [ ] test this function
--
-- get list of all files and folder
-- itarate thoough each of them
-- create a hardlink for file
-- run funciton again on folder
--
local function everything_in_folder_hardlink(base_path)
	local res = sh([[ls -la ]]..base_path..[[| grep -Po "[^ /]+$]])
	local entries = {}

	for line in res.out:gmatch("([^\n]*)\n?") do
        if line ~= "" then
            table.insert(entries, line)
        end
    end

	for _, data in ipairs(entries) do
		if sh("ln "..data.." "..base_path..data).status == 1 then
			everything_in_folder_hardlink(base_path..data.."/")
		end
	end

end


local function create_links(links, root)
	log('\n>>\n>> create_links START\n>>\n')
	generate_backup(links, root)
	for i, path in ipairs(links) do
		local operation = ""
		if path[2] == "sys" then operation = "-s" end

		local path_source = sh('pwd').out..'/'..path[1]
		local path_target = string.gsub(root..path[1], "[/]$", '')

		sh("mkdir -p "..sh('dirname '..path_target).out)
		sh("rm -rf "..path_target)
		sh("ln "..operation.." "..path_source.." "..path_target)
	end

	log('\n>>\n>> create_links END\n>>\n')
end


local function remove_links(links)
	local operation = ""
	for i, file in ipairs(links) do
		sh("rm -r "..full_path.." >/dev/null 2>&1")
	end
	print('\n### Finished! ###\n')
end


actions = {
	backup = function() sh_q_enable_logs(); generate_backup	(links, root_path) 	end,
	create = function() sh_q_enable_logs(); create_links	(links, root_path) 	end,
	remove = function() sh_q_enable_logs(); remove_links	(links) 			end
}

if actions[arg[1]] ~= null then
	actions[arg[1]]()
	print('\n### Finished! ###\n')
	os.exit()
end

print('\n'..[[
All available arguments:

backup    -> Creates a backup of existing files
create    -> Removes files at home path and replace
          them with links to files/folders in this folder
remove    -> Remove all files (including links) at root path
]])


