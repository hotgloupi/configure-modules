--- Assimp library
-- @module configure.modules.assimp

local M = {}

local tools = require('configure.tools')

--- Build Assimp library
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
				name = 'Assimp',
				kind = kind,
				extract_directory = 'source',
				source_directory = 'source/assimp-' .. args.version,
			},
			args
		)
	):download{
		url = 'http://sourceforge.net/projects/assimp/files/assimp-'
		.. tostring(major) .. '.' .. tostring(minor)
		.. '/assimp-' .. args.version
		.. '_no_test_models.zip/download',
		filename = 'assimp.zip'
	}
    local configure_variables = {
		CMAKE_C_COMPILER = args.c_compiler.binary,
		ASSIMP_BUILD_ASSIMP_TOOLS = false,
		BUILD_SHARED_LIBS = kind ~= 'static',
		ASSIMP_BUILD_STATIC_LIB = kind == 'static',
		ASSIMP_BUILD_SAMPLES = false,
		ASSIMP_BUILD_TESTS = false,
		ASSIMP_NO_EXPORT = true,
		ASSIMP_DEBUG_POSTFIX = '',
	}
	if args.boost ~= nil then
		local include_directories = {}
		local library_directories = {}
		for _, t in ipairs(args.boost) do
			table.extend(include_directories, t.include_directories)
			table.extend(library_directories, t.directories)
		end
		include_directories = tools.unique(include_directories)
		library_directories = tools.unique(library_directories)
		if #include_directories == 0 then
			error("Cannot find any boost include directory")
		end
		if #library_directories == 0 then
			error("Cannot find any boost library directory")
		end
		if #include_directories > 1 then
			args.build:warning("Multiple include directories found for boost")
		end
		if #library_directories > 1 then
			args.build:warning("Multiple library directories found for boost")
		end

		table.update(configure_variables, {
			ASSIMP_ENABLE_BOOST_WORKAROUND = false,
			Boost_DEBUG = true,
			Boost_DETAILED_FAILURE_MSG = true,
			Boost_NO_SYSTEM_PATHS = true,
			Boost_NO_CMAKE = true,
			Boost_ADDITIONAL_VERSIONS = args.boost.version,
			BOOST_INCLUDEDIR = include_directories[1],
			BOOST_LIBRARYDIR = library_directories[1],
		})
	end
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
		KInd = kind,
	}
end

return M




