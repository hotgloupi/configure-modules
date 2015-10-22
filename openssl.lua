--- OpenSSL library
-- @module configure.modules.openssl

local M = {}

--- Build OpenSSL library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'OpenSSL')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'shared')
function M.build(args)
	local project = require('configure.external').Project:new(
		table.update({name = 'OpenSSL'}, args)
	):download{
		url = 'https://www.openssl.org/source/openssl-' .. args.version .. '.tar.gz',
	}
end

return M

