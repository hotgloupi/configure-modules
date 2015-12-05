--- Alsa library
-- @module configure.modules.alsa

local M = {}

--- Find Alsa library
--
-- @param args
-- @param args.build
-- @param args.compiler A compiler instance
-- @param[opt] args.version The required version (defaults to the latest found)
-- @param[opt] args.env_prefix A prefix for all environment variables (default to ALSA)
-- @param[opt] args.kind 'shared' or 'static' (default to 'shared')
function M.find(args)
	args = table.update({env_prefix = 'ALSA', kind = 'shared'}, args)
	local include_dir = args.build:lazy_path_option(
		args.env_prefix .. '-include-dir',
		'Alsa include directory',
		function()
			return args.build:fs():find_file(
				args.compiler:system_include_directories(),
				'alsa/asoundlib.h'
			):path():parent_path():parent_path()
		end
	)

	local library = args.build:lazy_path_option(
		args.env_prefix .. '-' .. args.kind .. '-library',
		'Alsa ' .. args.kind ..  ' library',
		function()
			return args.build:fs():find_file(
				args.compiler:system_library_directories(),
				args.compiler:canonical_library_filename('asound', args.kind)
			):path()
		end
	)

	return args.compiler.Library:new{
		name = 'alsa',
		include_directories = {include_dir},
		files = {args.build:file_node(library)},
		kind = args.kind,
	}
end


--- Build Alsa library
--
-- @param args
-- @param args.build The build instance
-- @param args.version The version to use (for example "1.31")
-- @param args.compiler The compiler to use
-- @param[opt] args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	args = table.update({name = 'alsa', kind = 'static'}, args)
	local project = require('configure.external').AutotoolsProject:new(args)
	project:download{url = 'ftp://ftp.alsa-project.org/pub/lib/alsa-lib-' .. args.version .. '.tar.bz2'}
	local configure_args = {
		'--disable-symbolic-functions',
		'--disable-python',
	}

	if args.kind == 'static' then
		table.extend(configure_args, {'--enable-static', '--disable-shared'})
	else
		table.extend(configure_args, {'--disable-static', '--enable-shared'})
	end

	project:configure{args = configure_args}
	project:build{}
	project:install{}
	return args.compiler.Library:new{
		name = args.name,
		include_directories = { project:directory_node{path = 'include'} },
		files = { project:node{path = 'lib/' .. args.compiler:canonical_library_filename('asound', args.kind)} },
		kind = args.kind,
		install_node = project:stamp_node('install'),
	}
end


return M
