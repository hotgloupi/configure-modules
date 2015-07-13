--- cURL Library
-- @module configure.modules.curl

local M = {}


--- Build cURL library and executable
--
-- @param args
-- @param args.build The build instance
-- @param args.version The version to use (for example "7.35.0")
-- @param args.compiler The compiler to use
-- @param[opt] args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local curl = require("configure.external").AutotoolsProject:new(
		table.update({name = 'cURL'}, args)
	):download_tarball{
		url = 'http://curl.haxx.se/download/curl-'.. args.version .. '.tar.gz',
	}:configure{
	}:build{
	}:install{
	}
	local kind = args.kind or 'static'
	if kind == 'static' then
		local lib = curl:node{path = 'lib/libcurl.a'}
	else
		local lib = curl:node{path = 'lib/libcurl.so'}
	end
	return args.compiler.Library:new{
		name = 'cURL',
		include_directories = {curl:directory_node{path = 'include'}},
		files = {lib},
		kind = kind,
	}
end

return M
