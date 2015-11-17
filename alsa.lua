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
		files = {library},
		kind = args.kind,
	}
end


return M
