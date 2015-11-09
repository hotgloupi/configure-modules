--- Zlib library
-- @module configure.modules.zlib

local M = {}

--- Build Zlib library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'zlib')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local kind = args.kind or 'static'
	local project = require('configure.external').CMakeProject:new(
		table.update({name = 'zlib', kind = kind}, args)
	):download{
		url = 'http://zlib.net/zlib-' .. args.version .. '.tar.gz',
	}:configure{}:build{}:install{}

	local runtime_files = {}
	local filename
	if args.build:target():os() == Platform.OS.windows then
		if kind == 'static' then
			filename = 'zlibstatic.lib'
		else
			filename = 'zlib.lib'
			table.append(runtime_files, project:node{path = 'bin/zlib.dll'})
		end
	else
		if kind == 'static' then
			filename = 'libz.a'
		else
			filename = 'libz.so'
		end
	end
	local lib = project:node{path = 'lib/' .. filename}
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include'}
		},
		files = {lib},
		runtime_files = runtime_files,
		kind = kind,
		install_node = project:stamp_node('install'),
	}
end

return M
