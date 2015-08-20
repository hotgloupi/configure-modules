--- SDL library
-- @module configure.modules.sdl

local M = {}

--- Build SDL library
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
		table.update({name = 'SDL', kind = kind}, args)
	):download{
		url = 'https://www.libsdl.org/release/SDL2-' .. args.version ..'.tar.gz'
	}:configure{}:build{}:install{}

	local filename
	if args.build:target():os() == Platform.OS.windows then
		if kind == 'static' then
			filename = 'SDL.lib'
		else
			filename = 'SDL.lib'
		end
	else
		if kind == 'static' then
			filename = 'libSDL.a'
		else
			filename = 'libSDL.so'
		end
	end
	local lib = project:node{path = 'lib/' .. filename}
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include/SDL2'}
		},
		files = {lib},
		kind = kind,
	}
end

return M



