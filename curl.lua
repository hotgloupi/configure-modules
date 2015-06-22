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
	local curl = require("configure.external").Project:new{
		name = 'cURL',
		build = args.build,
	}:download_tarball{
		url = 'http://curl.haxx.se/download/curl-'.. args.version .. '.tar.gz',
	}
	local kind = args.kind or 'static'

	curl:configure{
		command = {
			curl:step_directory('source') / 'configure',
			'--prefix', tostring(curl:step_directory('install'))
		},
		working_directory = curl:step_directory('build'),
		env = {CC = compiler.binary_path}
	}:build{
		command = {
			args.build:fs():which("make"), "-C", curl:step_directory('build'),
		}
	}:install{
		command = {
			args.build:fs():which("make"), "-C", curl:step_directory('build'), 'install'
		}
	}
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
