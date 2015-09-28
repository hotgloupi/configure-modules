--- FreeType library
-- @module configure.modules.librocket

local M = {}

--- Build FreeType2 library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'FreeType')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.c_compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local kind = args.kind or 'static'
	if args.version == nil then
		args.build:error("You must specify a version")
	end
	local url = 'http://download.savannah.gnu.org/releases/freetype/freetype-'
		.. args.version .. '.tar.gz'
	local project = require('configure.external').CMakeProject:new(
		table.update({
			name = 'FreeType',
			kind = kind,
		}, args)
	):download{
		url = url,
	}
	local configure_variables = {
		BUILD_SHARED_LIBS = kind ~= 'static',
	}

	project:configure{variables = configure_variables}
	project:build{}:install{}

	local libraries = {}
	for _, lib in ipairs({'freetype'}) do
		local prefix = ''
		local ext = nil
		if args.build:target():os() == Platform.OS.windows then
			ext = '.lib'
		else
			prefix = 'lib'
			if kind == 'static' then
				ext = '.a'
			else
				ext = '.so'
			end
		end
		table.append(libraries, project:node{path = 'lib/' .. prefix .. lib .. ext})
	end
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include/freetype2'}
		},
		files = libraries,
		kind = kind,
		install_node = project:stamp_node('install'),
	}
end

return M
