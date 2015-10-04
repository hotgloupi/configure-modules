--- GLM library
-- @module configure.modules.glm

local M = {}

--- Build GLM library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'GLM')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
function M.build(args)
	local project = require('configure.external').CMakeProject:new(
		table.update(
			{
				name = 'GLM',
			},
			args
		)
	):download{
		url = 'https://github.com/g-truc/glm/archive/' .. args.version .. '.tar.gz'
	}:configure{}:build{}:install{}
	return args.compiler.Library:new{
		name = project.name,
		files = {},
		include_directories = {
			project:directory_node{path = 'include'},
		},
		install_node = project:stamp_node('install'),
		kind = 'static',
	}
end

return M
