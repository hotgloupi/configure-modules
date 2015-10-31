--- IDN Library
-- @module configure.modules.idn

local M = {}


--- Build IDN library
--
-- @param args
-- @param args.build The build instance
-- @param args.version The version to use (for example "1.31")
-- @param args.compiler The compiler to use
-- @param[opt] args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	args = table.update({ name = 'idn', kind = 'static'}, args)
	local project = require('configure.external').AutotoolsProject:new(args)
	project:download{url = 'http://ftp.gnu.org/gnu/libidn/libidn-' .. args.version .. '.tar.gz'}
	project:configure{}
	project:build{}
	project:install{}
	return args.compiler.Library:new{
		name = args.name,
		include_directories = { project:directory_node{path = 'include'} },
		files = { project:node{path = 'lib/' .. args.compiler:canonical_library_filename('idn', args.kind)} },
		kind = args.kind,
		install_node = project:stamp_node('install'),
	}
end

return M
