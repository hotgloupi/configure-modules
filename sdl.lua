--- SDL library
-- @module configure.modules.sdl

local M = {}

--- Build SDL library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'zlib')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
-- @tparam bool args.dynapi Use dynamic api magic (defaults to true)
-- @tparam table args.with Configuration options
-- @tparam bool args.with.atomic enable atomic support (defaults to true)
-- @tparam bool args.with.audio enable audio support (defaults to true)
-- @tparam bool args.with.cpuinfo enable cpuinfo support (defaults to true)
-- @tparam bool args.with.dlopen enable dlopen support (defaults to true)
-- @tparam bool args.with.events enable events support (defaults to true)
-- @tparam bool args.with.file enable file support (defaults to true)
-- @tparam bool args.with.filesystem enable filesystem support (defaults to true)
-- @tparam bool args.with.haptic enable haptic support (defaults to true)
-- @tparam bool args.with.joystick enable joystick support (defaults to true)
-- @tparam bool args.with.loadso enable loadso support (defaults to true)
-- @tparam bool args.with.power enable power support (defaults to true)
-- @tparam bool args.with.render enable render support (defaults to true)
-- @tparam bool args.with.threads enable threads support (defaults to true)
-- @tparam bool args.with.timers enable timers support (defaults to true)
-- @tparam bool args.with.video enable video support (defaults to true)

function M.build(args)
	local kind = args.kind or 'static'
	local project = require('configure.external').CMakeProject:new(
		table.update({name = 'SDL', kind = kind}, args)
	):download{
		url = 'https://www.libsdl.org/release/SDL2-' .. args.version ..'.tar.gz'
	}

	local with = table.update({
		atomic = true,
		audio = true,
		cpuinfo = true,
		dlopen = true,
		events = true,
		file = true,
		filesystem = true,
		haptic = true,
		joystick = true,
		loadso = true,
		power = true,
		render = true,
		threads = true,
		timers = true,
		video = true,
	}, args.with or {})

	local vars = {}
	for k, v in pairs(with) do
		vars['SDL_' .. k:upper()] = v
	end

	vars['SDL_SHARED'] = kind == 'shared'
	vars['SDL_STATIC'] = kind == 'static'

	if args.dynapi == false then

		local script = args.build:file_node(
			Filesystem.current_script():parent_path() / 'sdl-disable-dynapi.lua'
		)
		project:add_step{
			name = 'disable-dynapi',
			targets = {
				[0] = {
					{
						args.build:configure_program(), '-E', 'lua-function',
						script,
						'main',
						project:step_directory('source') / 'src' / 'dynapi' / 'SDL_dynapi.h'
					},
				}
			},
			sources = {script}
		}
	end
	project:configure{variables = vars}:build{}:install{}

	local files = {}
	if args.compiler.build:target():is_osx() then
		for _, file in ipairs({'IOKit', 'Carbon'}) do
			table.append(files, args.compiler:find_system_library_filename(file))
		end
	end

	local filename = args.compiler:canonical_library_filename('SDL2', kind)
	local lib = project:node{path = 'lib/' .. filename}
	table.append(files, lib)
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include/SDL2'}
		},
		files = files,
		kind = kind,
		install_node = project:stamp_node('install'),
	}
end

return M
