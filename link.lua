#!/usr/bin/env lua

-- This is a system/hard link farming script
-- Declare folders/files to be linked at the root path

package.path = package.path .. ";./?.lua"
local Format = string.format
require('sh')


---@alias LinkType "hard" | "sys"
---@alias BackupEntry { [1]: string, [2]: LinkType }

---@type string
local root_path = "~/"

---@type BackupEntry[]
local backup_paths = {
    {".bashrc",                         "hard"},
    {".config/fish/config.fish",        "hard"},
    {".zshrc",                          "hard"},
    {".tmux.conf",                      "hard"},
    {".vimrc",                          "hard"},
    {".ssh/",                           "sys"},
    {".config/nvim/",                   "sys"},
    {".config/alacritty/",              "sys"},
    {".local/share/fonts/",             "sys"},
    {".local/share/nvim/site/spell",    "sys"},
    {".config/autostart/",    			"sys"},
    --{".local/share/nvim/",    "sys"},
}

---@class FinalLog
---@field messages string[]
---@field print fun(self: FinalLog)
local final_log = {
    messages = {},
    print = function(self)
        if #self.messages == 0 then return end
        for _, data in ipairs(self.messages) do
            print(data)
        end
    end,
}

---Validates and resolves the mandatory source/backup directory path.
---Terminates execution if the path is omitted or cannot be found.
---@param dir_arg string? The path passed via command-line argument
---@return string The validated, absolute directory path without trailing slashes
local function require_source_dir(dir_arg)
    if dir_arg == nil or dir_arg == "" then
        io.stderr:write("Error: A backup/source folder must be specified as an argument.\n")
        os.exit(1)
    end

    local expanded_path = string.gsub(dir_arg, "^~", os.getenv("HOME") or "~")
    local dir_exists = sh(Format('if [ -d "%s" ]; then echo "t"; fi', expanded_path)).out == "t"

    if not dir_exists then
        io.stderr:write(Format("Error: Specified folder '%s' does not exist or is not a directory.\n", dir_arg))
        os.exit(1)
    end

    -- Get absolute path to prevent symlinks from breaking when using relative directories
    local absolute_path = sh(Format('cd "%s" && pwd', expanded_path)).out

    return string.gsub(absolute_path, "[/]+$", "")
end

---Verifies if all files and directories declared in backup_paths exist in the target folder.
---Prompts the user for confirmation if missing entries are detected.
---@param paths BackupEntry[] List of target paths
---@param source_dir string Resolved directory containing source files
local function verify_backup_paths(paths, source_dir)
    local missing_paths = {}

    for _, entry in ipairs(paths) do
        local full_path = Format("%s/%s", source_dir, entry[1])
        local exists = sh(Format('if [ -e "%s" ]; then echo "t"; fi', full_path)).out == "t"

        if not exists then
            table.insert(missing_paths, entry[1])
        end
    end

    if #missing_paths > 0 then
        print("\n[!] Warning: The following declared paths were not found in the specified directory:")
        for _, missing in ipairs(missing_paths) do
            print(Format("  - %s", missing))
        end

        local choice = sh_input("\nDo you want to proceed anyway? (y/n)", {'^[ynYN]$'})
        if string.lower(choice) ~= "y" then
            print("Operation aborted by user.")
            os.exit(1)
        end
    end
end

---Generates an isolated backup of active configurations.
---Prompts the user for a custom directory name; falls back to automatic generation if declined.
---@param paths BackupEntry[] Target paths to back up
---@param base_path string Root folder containing active configurations
local function generate_backup(paths, base_path)
    log('\n>>\n>>generate_backup START\n>>\n')
    if paths == nil or base_path == nil then
        error('generate_backup:\nParameters cannot be nil')
    end

    ---Creates a unique backup directory name recursively if duplicates exist.
    ---@param name string Base directory prefix
    ---@param index integer? Collision differentiator
    ---@return string
    local function define_dir_name(name, index)
        index = index or 0
        local new_name = Format("%s-%d", name, index)
        if sh(Format('ls | grep -Po "^%s$"', new_name)).status ~= 0 then
            return new_name
        end

        return define_dir_name(name, index + 1)
    end

    local backup_dir_name
    local custom_choice = sh_input("\nDo you want to specify a custom name for the backup folder? (y/n)", {'^[ynYN]$'})

    if string.lower(custom_choice) == "y" then
        print("\nEnter backup folder name:")
        local custom_name = io.read()
        while custom_name == nil or custom_name:match("^%s*$") do
            print("Folder name cannot be empty. Please enter a valid backup folder name:")
            custom_name = io.read()
        end
        backup_dir_name = custom_name:match("^%s*(.-)%s*$")
    else
        local backup_dir_prefix = Format("backup.%s", sh('echo "$HOSTNAME@$USER"').out)
        backup_dir_name = define_dir_name(backup_dir_prefix)
    end

    sh(Format("mkdir -p %s", backup_dir_name))

    for _, path in ipairs(paths) do
        local path_source_full = Format("%s%s", base_path, path[1])

        sh(Format("mkdir -p $(dirname %s/%s)", backup_dir_name, path[1]))
        local check_syslink = sh(Format('if [ -L "$(echo %s)%s" ]; then echo "t"; fi', base_path, path[1])).out

        log(Format("check_syslink value: [%s]  type:[%s]", check_syslink, type(check_syslink)))

        local not_a_system_link = (check_syslink ~= "t")
        if not_a_system_link then
            sh(Format("cp -r %s %s/%s", path_source_full, backup_dir_name, path[1]))
        else
            log('>> target path is a system link\n>> link path will be followed and copied')
            local syslink_path = sh(Format("readlink %s", path_source_full)).out
            sh(Format("cp -r %s %s/%s", syslink_path, backup_dir_name, path[1]))
        end
    end

    log('\n>>\n>> generate_backup END\n>>\n')
end

---Creates symbolic or hard links pointing from source_dir into the root path.
---@param links BackupEntry[] List of link definitions
---@param root string Target base directory (typically home)
---@param source_dir string Folder containing the source configuration files
local function create_links(links, root, source_dir)
    log('\n>>\n>> create_links START\n>>\n')

    local backup_choice = sh_input("\nDo you want to create a backup of current configurations first? (y/n)", {'^[ynYN]$'})
    if string.lower(backup_choice) == "y" then
        generate_backup(links, root)
    else
        print("\n Skipping backup.")
        log("Backup skipped by user.")
    end

    for _, path in ipairs(links) do
        local operation = (path[2] == "sys") and "-s" or ""
        local path_source = Format("%s/%s", source_dir, path[1])
        local path_target = string.gsub(Format("%s%s", root, path[1]), "[/]+$", "")

        if sh(Format('if [ -e "%s" ]; then echo "t"; fi', path_source)).out == "t" then
            local target_dir = sh(Format("dirname %s", path_target)).out
            sh(Format("mkdir -p %s", target_dir))
            sh(Format("rm -rf %s", path_target))

            if operation ~= "" then
                sh(Format("ln %s %s %s", operation, path_source, path_target))
            else
                sh(Format("ln %s %s", path_source, path_target))
            end
        else
            log(Format("Source path '%s' does not exist, skipping link creation.", path_source))
        end
    end

    log('\n>>\n>> create_links END\n>>\n')
end

---Restores files by directly copying them from the specified backup folder.
---@param links BackupEntry[] List of file definitions to restore
---@param root string Target directory where configurations are restored
---@param source_dir string Folder containing the backup files
local function restore_backup(links, root, source_dir)
    log('\n>>\n>> restore_backup START\n>>\n')

    for _, path in ipairs(links) do
        local path_source = Format("%s/%s", source_dir, path[1])
        local path_target = string.gsub(Format("%s%s", root, path[1]), "[/]+$", "")

        if sh(Format('if [ -e "%s" ]; then echo "t"; fi', path_source)).out == "t" then
            local target_dir = sh(Format("dirname %s", path_target)).out
            sh(Format("mkdir -p %s", target_dir))
            sh(Format("rm -rf %s", path_target))
            sh(Format("cp -r %s %s", path_source, path_target))
            log(Format("Restored: %s -> %s", path_source, path_target))
        else
            log(Format("Backup file '%s' not found, skipping restore.", path_source))
        end
    end

    log('\n>>\n>> restore_backup END\n>>\n')
end

---Removes all target files and links from the root directory.
---@param links BackupEntry[]
---@param root string
local function remove_links(links, root)
    root = root or root_path
    for _, file in ipairs(links) do
        local path_target = string.gsub(Format("%s%s", root, file[1]), "[/]+$", "")
        sh(Format("rm -rf %s", path_target), true)
    end

    log('\n>>\n>> remove_links END\n>>\n')
end

---@type table<string, fun()>
local actions = {
    backup = function()
        sh_q_enable_logs()
        generate_backup(backup_paths, root_path)
    end,
    link = function()
        sh_q_enable_logs()
        local source_dir = require_source_dir(arg[2])
        verify_backup_paths(backup_paths, source_dir)
        create_links(backup_paths, root_path, source_dir)
    end,
    restore = function()
        sh_q_enable_logs()
        local source_dir = require_source_dir(arg[2])
        verify_backup_paths(backup_paths, source_dir)
        restore_backup(backup_paths, root_path, source_dir)
    end,
    remove = function()
        sh_q_enable_logs()
        remove_links(backup_paths, root_path)
    end,
}

if arg[1] and actions[arg[1]] ~= nil then
    actions[arg[1]]()
    print('================')
    print('|   Finished   |')
    print('================')
    os.exit(0)
end

print('\n'..[[
All available arguments:

backup            -> Creates an isolated backup of current files in root path
link   <dir>      -> Links files from <dir> into root path (requires directory)
restore <dir>     -> Copies files back from <dir> into root path (requires directory)
remove            -> Removes all files/links declared at target root paths
]])
