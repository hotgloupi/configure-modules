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
	args = table.update({name = 'cURL', kind = 'static'}, args)
	local project
	local configure_args = {}
	if args.build:host():is_windows() then
		project = require("configure.external").CMakeProject:new(args)
	else
		project = require("configure.external").AutotoolsProject:new(args)
		configure_args = {
			args = {
				'--without-ssl',
				'--disable-ldap',
				'--disable-ldaps',
			}
		}
	end
	project:download{
		url = 'http://curl.haxx.se/download/curl-'.. args.version .. '.tar.gz',
	}
	project:configure(configure_args)
	project:build{}
	project:install{}
	local kind = args.kind or 'static'
	local lib = project:node{
		path = 'lib/' .. args.compiler:canonical_library_filename('curl', kind)
	}
	return args.compiler.Library:new{
		name = 'cURL',
		include_directories = {project:directory_node{path = 'include'}},
		files = {lib},
		kind = kind,
		install_node = project:stamp_node('install'),
		defines = kind == 'static' and {{'CURL_STATICLIB',1}} or {},
	}
end

return M
