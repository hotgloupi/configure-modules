--- Python library
-- @module configure.modules.python

local M = {}

--- Build Python library and executable
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'Python')
-- @param args.version Version to use
-- @param args.zlib build zlib module with this library
-- @param args.bzip2 build bzip2 module with this library
-- @param args.openssl build openssl module with this library
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'shared')
function M.build(args)
	local project = require('configure.external').AutotoolsProject:new(
		table.update({name = 'Python'}, args)
	):download{
		url = 'http://www.python.org/ftp/python/' .. args.version .. '/Python-' .. args.version ..'.tgz',
	}
	local sources = {}
	table.extend(sources, args.zlib and args.zlib.files or {})
	table.extend(sources, args.bzip2 and args.bzip2.files or {})
	table.extend(sources, args.openssl and args.openssl.files or {})
	project:configure{
		sources = sources,
	}:build{

	}:install{

	}
	local short_version = args.version:sub(1,1) .. '.' .. args.version:sub(3,3)
	local kind = args.kind or 'static'
	local tag = 'm'
	local lib
	if kind == 'static' then
		lib = project:node{path = 'lib/libpython' .. short_version .. tag .. '.a'}
	else
		lib = project:node{path = 'lib/libpython.so'}
	end
	return args.compiler.Library:new{
		name = 'Python',
		include_directories = {
			project:directory_node{path = 'include/python' .. short_version .. tag}
		},
		files = {lib},
		kind = kind,
		bundle = {
			executable = project:node{path = 'bin/python' .. short_version},
			version = args.version,
			short_version = short_version,
		},
		install_node = project:stamp_node('install'),
	}
end

return M
