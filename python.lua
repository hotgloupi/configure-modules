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
end

return M
