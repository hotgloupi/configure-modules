--- Python library
-- @module configure.modules.python

local M = {}

--- Build Python library and executable
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'Python')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'shared')
function M.build(args)
	local project = require('configure.external').AutotoolsProject:new(
		table.update({name = 'Python'}, args)
	):download_tarball{
		url = 'http://www.python.org/ftp/python/' .. args.version .. '/Python-' .. args.version ..'.tgz',
	}:configure{

	}:build{

	}:install{

	}
	local short_version = args.version:sub(1,1) .. '.' .. args.version:sub(3,3)
	local kind = args.kind or 'static'
	local lib
	if kind == 'static' then
		lib = project:node{path = 'lib/libpython.a'}
	else
		lib = project:node{path = 'lib/libpython.so'}
	end
	return args.compiler.Library:new{
		name = 'Python',
		include_directories = {project:directory_node{path = 'include'}},
		files = {lib},
		kind = kind,
		bundle = {
			executable = project:node{path = 'bin/python' .. short_version},
			version = args.version,
			short_version = short_version,
		}
	}
end

return M
