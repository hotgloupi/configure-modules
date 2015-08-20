--- Bullet library
-- @module configure.modules.assimp

local M = {}

--- Build Bullet library
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
	local major, minor, sub = table.unpack(args.version:split('.'))
	local project = require('configure.external').CMakeProject:new(
		table.update(
			{
				name = 'Bullet',
				kind = kind,
			},
			args
		)
	):download{
		url = 'https://github.com/bulletphysics/bullet3/archive/' .. args.version ..'.tar.gz',
	}
    local configure_variables = {
		CMAKE_C_COMPILER = args.c_compiler.binary,
		Boost_DEBUG = true,
		Boost_DETAILED_FAILURE_MSG = true,
		Boost_NO_SYSTEM_PATHS = true,
		Boost_NO_CMAKE = true,
		Boost_ADDITIONAL_VERSIONS = args.boost.version,
		ASSIMP_BUILD_ASSIMP_TOOLS = false,
		ASSIMP_BUILD_STATIC_LIB = kind == 'static',
		ASSIMP_BUILD_SAMPLES = false,
		ASSIMP_BUILD_TESTS = false,
		ASSIMP_NO_EXPORT = true,
		ASSIMP_DEBUG_POSTFIX = '',
	}
	project:configure{variables = configure_variables}:build{}:install{}

	local filename
	if args.build:target():os() == Platform.OS.windows then
		if kind == 'static' then
			filename = 'assimp.lib'
		else
			filename = 'assimp.lib'
		end
	else
		if kind == 'static' then
			filename = 'libassimp.a'
		else
			filename = 'libassimp.so'
		end
	end
	local lib = project:node{path = 'lib/' .. filename}
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include'}
		},
		files = {lib},
		kind = kind,
	}
end

return M




