--- GLEW library
-- @module configure.modules.glm

local M = {}

--- Build GLEW library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'GLEW')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind
function M.build(args)
	local kind = args.kind or 'static'
	local project = require('configure.external').CMakeProject:new(
		table.update(
			{
				name = 'GLEW',
				extract_directory = 'source',
				source_directory = 'source/build/cmake',
			},
			args
		)
	):download{
		url = 'https://github.com/nigels-com/glew/archive/glew-' .. args.version .. '.tar.gz'
	}
	project:add_step{
		name = 'gen-sources',
		targets = {
			[0] = {
				{'make', 'extensions'}
			}
		},
		working_directory = project:step_directory('extract'),
	}
	local configure_variables = {
		BUILD_SHARED_LIBS = kind ~= 'static',
	}
	project:configure{variables = configure_variables}:build{}:install{}
	local filename = args.compiler:canonical_library_filename('GLEW', kind)
	local lib = project:node{path = 'lib/' .. filename}
	return args.compiler.Library:new{
		name = project.name,
		files = {lib},
		include_directories = {
			project:directory_node{path = 'include'},
		},
		defines = kind == 'static' and {'GLEW_NO_GLU', 'GLEW_STATIC'} or {},
		install_node = project:stamp_node('install'),
		kind = kind,
	}
end

return M

