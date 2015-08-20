--- libRocket library
-- @module configure.modules.librocket

local M = {}

--- Build libRocket library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'libRocket')
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
	local url = nil
	if args.version == 'HEAD' then
		url = 'https://github.com/libRocket/libRocket/archive/master.tar.gz'
	end
	local project = require('configure.external').CMakeProject:new(
		table.update({
			name = 'libRocket',
			kind = kind,
			source_directory = 'source/Build'
		}, args)
	):download{
		url = url,
	}

    local configure_variables = {}
    if args.c_compiler ~= nil then
	    configure_variables['CMAKE_C_COMPILER'] = args.c_compiler.binary
	end
	if args.freetype2 ~= nil then
		configure_variables['FREETYPE_INCLUDE_DIRS'] = args.freetype2.include_directories[1]
		configure_variables['FREETYPE_LIBRARY'] = args.freetype2.files[1]
	end
	configure_variables['BUILD_SHARED_LIBS'] = kind == 'shared'
	configure_variables['CMAKE_INSTALL_LIBDIR'] = 'lib' -- Prevent arch subdirectory
	project:configure{variables = configure_variables}
	project:build{}:install{}
end

return M
