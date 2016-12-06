--- cURL Library
-- @module configure.modules.curl

local M = {}


--- Build cURL library and executable
--
-- @param args
-- @param args.build The build instance
-- @param args.version The version to use (for example "7.35.0")
-- @param args.compiler The compiler to use
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	args = table.update({name = 'cURL', kind = 'static'}, args)
	local project
	local configure_args = {}
	local build = args.build
	local kind = args.kind
	local compiler = args.compiler
	if build:host():is_windows() then
		project = require("configure.external").CMakeProject:new(args)
		configure_args = {
			variables = {
				CURL_STATICLIB = (kind == 'static'),
			},
		}
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
	local files = {}
	local runtime_files = {}
	if build:host():is_windows()  then
		if kind == 'shared' then
			table.append(
				files,
				project:node{path = 'lib/libcurl_imp.lib'}
			)
			table.append(
				runtime_files,
				project:node{path = 'bin/libcurl.dll'}
			)
		else
			table.append(
				files,
				project:node{path = 'lib/libcurl.lib'}
			)
		end
		for _, file in ipairs({'Advapi32.lib'}) do
			table.append(
				files,
				args.compiler:find_system_library_file_from_filename(file)
			)
		end
	else
		table.append(
			files,
			project:node{
				path = 'lib/' .. args.compiler:canonical_library_filename('curl', kind)
			}
		)
	end
	return args.compiler.Library:new{
		name = 'cURL',
		include_directories = {project:directory_node{path = 'include'}},
		files = files,
		runtime_files = runtime_files,
		kind = kind,
		install_node = project:stamp_node('install'),
		defines = kind == 'static' and {{'CURL_STATICLIB',1}} or {},
	}
end

return M
