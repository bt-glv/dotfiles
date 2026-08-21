#!/usr/bin/env lua

-- This is a system/hard link farming script
-- Declare folders/files present on the same folder
-- as this file to be linked at the root path
--
package.path = ";./?.lua"
require('sh');

local root_path = "~/"
local backup_paths = {
	{".bashrc", 						"hard"},
	{".config/fish/config.fish", 		"sys"},
	{".zshrc", 							"hard"},
	{".tmux.conf", 						"hard"},
	{".vimrc", 							"hard"},
	{".ssh/", 				            "sys"},
	{".config/nvim/",		            "sys"},
	{".config/alacritty/",	            "sys"},
	{".local/share/fonts/",	            "sys"},
	{".local/share/nvim/site/spell",	"sys"},
	--{".local/share/nvim/",	"sys"},
	--{".config/autostart/",	"sys"},
}


--- Copies every file in "backup_paths" currently present 
--- in your sistem to a backup folder.
local function generate_backup(paths, base_path)

	log('\n>>\n>>generate_backup START\n>>\n')
	if paths == nil or base_path == nil then
		error('generate_backup:\nParameters cannot be nil')
	end

	---@param name string Desired dir name
	---@param index integer? Recursive index - used to differentiate backups on the same machine
	--- Creates the backup folder's name, checks if a folder of that name exists;
	--- if not, it returns the name, if it does, the function calls itself recursively
	local function define_dir_name(name, index)
		if index == nil then index = 0 end

		local new_name = name..'-'..index
		if sh('ls | grep -Po "^'..new_name..'$"').status ~= 0 then
			return new_name
		end

		return define_dir_name(name, index+1)
	end


	local backup_dir_prefix = string.format("backup.%s", sh('echo "$HOSTNAME@$USER"').out)
	local backup_dir_name   = define_dir_name(backup_dir_prefix)

	sh('mkdir '..backup_dir_name)

	local path_source_full
	for _, path in ipairs(paths) do

		path_source_full = base_path..path[1]

		-- TODO: replace all concatenation with ".." with string.format for better readability
		sh('mkdir -p $(dirname '..backup_dir_name..'/'..path[1]..')')
		local check_syslink = sh('if [ -L "$(echo '..base_path..')'..path[1]..'" ]; then echo "t";  fi').out

		log("check_syslink value: ["..check_syslink..']  type:['..type(check_syslink)..']')

		local not_a_system_link = (check_syslink ~= "t")
		if not_a_system_link then
			sh('cp -r '..path_source_full.." "..backup_dir_name.."/"..path[1])
		else
			log('>> target path is a system link\n>> link path will be followed and copied')
			local syslink_path = sh('readlink '..path_source_full).out
			sh('cp -r '..syslink_path.." "..backup_dir_name.."/"..path[1])
		end

	end

	log('\n>>\n>> generate_backup END\n>>\n')
end

-- TODO: add a way to select a backup folder to create links from it
--
---@param links table Contains a list sets of "path" and  "link type"
---@param root string Home folder path
---Creates hard or system links to all paths defined in "links"
local function link_bakcups(links, root)

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


-- TODO: review this function
-- this needs to remove all system and hardlinks
local function remove_links(links)
	local operation = ""
	for i, file in ipairs(links) do
		sh("rm -r "..full_path.." >/dev/null 2>&1")
	end
	print('\n### Finished! ###\n')
end


actions = {
	backup = function()
		sh_q_enable_logs()
		generate_backup	(backup_paths, root_path)
	end,
	create = function()
		sh_q_enable_logs()
		link_bakcups (backup_paths, root_path)
	end,
	remove = function()
		sh_q_enable_logs()
		remove_links(backup_paths)
	end
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


