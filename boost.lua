--- C++ Boost libraries
-- @module configure.modules.boost

local M = {}

local function default_component_defines(component, kind, threading)
	if component == 'unit_test_framework' and kind == 'shared' then
		return {'BOOST_TEST_DYN_LINK'}
	end
	return {}
end

local components = {
	'atomic',
	'chrono',
	'container',
	'context',
	'coroutine',
	'date_time',
	'exception',
	'filesystem',
	'graph',
	'graph_parallel',
	'iostreams',
	'locale',
	'log',
	'math',
	'mpi',
	'program_options',
	'python',
	'random',
	'regex',
	'serialization',
	'signals',
	'system',
	'test',
	'thread',
	'timer',
	'wave',
}


--- Deduce compilation info from filename
--
-- @arg f Filename to be parsed
-- @returns a table containing the following fields:
--  - threading: `true` when threading is enabled
--  - toolset: Boost toolset
--  - version: {Major, minor, sub-minor}
--  - static_runtime: `true` when the standard library is linked statically
--  - debug_runtime: `true` if the debug standard library is used
--  - stlport: `true` if stlport is used
--  - native_iostreams: `true` when native iostreams are used
local function extract_flags_from_filename(f)
	-- Boost library files are as follow:
	-- (lib)?boost_<COMPONENT>(-<FLAGS>)?.(lib|a|so)(.<VERSION>)?
	local flags = tostring(f:filename()):match("-[^.]*")
	local parts = {}
	if flags ~= nil then
		parts = flags:strip('-'):split('-')
	end
	local res = {}
	for i, part in ipairs(parts) do
		if part == "mt" then
			res['threading'] = true
		elseif part:starts_with('vc') then
			res['toolset'] = part
		elseif part:match("%d+_%d+") then
			res['version'] = part:gsub('_', '.')
		elseif part:match("^s?g?d?p?n?$") then
			table.update(res, {
				static_runtime = part:find('s') ~= nil,
				debug_runtime = part:find('g') ~= nil,
				debug = part:find('d') ~= nil,
				stlport = part:find('p') ~= nil,
				native_iostreams = part:find('n') ~= nil,
			})
		else
			error("Unknown boost library name part '" .. part .. "'")
		end
	end
	return res
end

local function find_config_include(boost_root, compiler)
	local fs = compiler.build:fs()
	local dirs = {}
	if boost_root ~= nil then
		table.append(dirs, boost_root)
		table.append(dirs, boost_root / 'include')
	end
	table.extend(dirs, compiler:system_include_directories())
	return fs:find_file(
		dirs,
		'boost/version.hpp'
	):path():parent_path():parent_path()
end

local function find_library_dir(boost_root, compiler)
	local build = compiler.build
	local fs = build:fs()
	local dirs = {}
	if boost_root then
		table.append(dirs, boost_root / 'lib')
		table.append(dirs, boost_root / 'stage/lib')
	end
	table.extend(dirs, compiler:system_library_directories())
	for _, dir in ipairs(dirs) do
		build:debug("Examining library directory", dir)
		for _, lib in ipairs(fs:glob(dir, "libboost_*")) do
			-- return when some file is found
			return dir
		end
	end
	build:error("Couldn't find Boost library directory (checked " .. table.tostring(dirs) .. ")")
end

--
local function find_library_files(config_header, library_dir, components, compiler)
	local build = compiler.build
	local fs = build:fs()
	local component_files = {}
	local lib_files = config_header:set_cached_property(
		'library-files',
		function ()
			local res = {}
			for _, node in ipairs(fs:glob(library_dir, "*boost_*")) do
				table.append(res, node:path())
			end
			return res
		end
	)
	for _, component in ipairs(components) do
		component_files[component] = config_header:set_cached_property(
			component .. '-all-library-files',
			function ()
				local res = {}
				for _, lib in ipairs(lib_files) do
					local filename = tostring(lib:filename())
					if filename:starts_with("libboost_" .. component) or
						(build:target():os() == Platform.OS.windows and
						 filename:starts_with("boost_" .. component)) then
						table.append(res, lib)
						build:debug("Found Boost library", lib, "for component", component)
					end
				end
				return res
			end
		)
	end
	return component_files
end

--- Find Boost libraries
--
-- @param args
-- @param args.compiler A compiler instance
-- @param args.components A list of components
-- @param[opt] args.version The required version (defaults to the latest found)
-- @param[opt] args.env_prefix A prefix for all environment variables (default to BOOST)
-- @param[opt] args.kind 'shared' or 'static' (default to 'static')
-- @param[opt] args.defines A list of preprocessor definitions
-- @param[opt] args.threading Search for threading enable libraries (default to the compiler default)
-- @param[opt] args.<COMPONENT>_kind Select the 'static' or 'shared' version of a component.
-- @param[opt] args.<COMPONENT>_defines A list of preprocessor definitions
function M.find(args)
	local components = args.components
	if args.components == nil then
		build:error("You must provide a list of Boost libraries to search for")
	end
	local env_prefix = args.env_prefix or 'BOOST'
	local build = args.compiler.build
	local fs = build:fs()
	local boost_root = build:path_option(
		env_prefix .. '-root',
		"Boost root directory"
	)
	local boost_include_dir = build:lazy_path_option(
		env_prefix .. '-include-dir',
		"Boost include directory",
		function() return find_config_include(boost_root, args.compiler) end
	)
	local boost_version_header = build:file_node(boost_include_dir / 'boost/version.hpp')
	if not boost_version_header:path():exists() then
		build:error("Couldn't find 'boost/version.hpp' in", boost_include_dir)
	end
	build:debug("Found boost version header at", boost_version_header)
	local boost_library_dir = build:lazy_path_option(
		env_prefix .. '-library-dir',
		"Boost library dir",
		function() return find_library_dir(boost_root, args.compiler) end
	)

	local component_files = find_library_files(
		boost_version_header,
		boost_library_dir,
		components,
		args.compiler
	)

	local Library = require('configure.lang.cxx.Library')
	local res = {}
	for _, component in ipairs(components) do
		if component_files[component] == nil then
			build:error("Couldn't find library files for boost component '" .. component .. "'")
		end
		local files = component_files[component]
		local runtime_files = {}
		local kind = args[component .. '_kind'] or args.kind or 'static'
		-- Filter files based on the kind selected ('static' or 'shared')
		local ext = args.compiler:_library_extension(kind)
		local filtered = boost_version_header:set_cached_property(
			component .. '-' .. kind .. '-library-files',
			function ()
				local res = {}
				for i, f in ipairs(files) do
					local filename = tostring(f:filename())
					if build:target():os() == Platform.OS.windows then
						if filename:ends_with('.lib') then
							if kind == 'shared' and filename:starts_with('boost_') then
								table.append(res, f)
							elseif kind == 'static' and filename:starts_with('libboost_') then
								table.append(res, f)
							else
								build:debug("Ignore non boost lib", f)
							end
						elseif kind == 'shared' and filename:ends_with('.dll') then
							table.append(runtime_files, f)
						end
					elseif tostring(f):ends_with(ext) then
						build:debug("Select", f, "(ends with '" .. ext .."')")
						table.append(res, f)
					else
						build:debug("Ignore", f)
					end
				end
				return res
			end
		)

		local function arg(name, default)
			local res = args[component .. '_' .. name]
			if res == nil then return default end
			return res
		end

		local wanted_flags = {
			threading = arg('threading', args.compiler.threading),
			static_runtime = arg('static_runtime', args.compiler.runtime == 'static'),
			debug_runtime = arg('debug_runtime', args.compiler.debug_runtime),
			debug = arg('debug', args.compiler.debug),
		}
		local files, selected, unknown = filtered, {}, {}
		build:debug("Try to filter", table.tostring(files))
		for _, f in ipairs(files) do
			build:debug("Checking file", f)
			local file_flags = extract_flags_from_filename(f)

			-- TODO: Check against toolset
			-- TODO: Check the version
			local check = nil
			for k, v in pairs(file_flags) do
				if wanted_flags[k] ~= nil then
					check = wanted_flags[k] == v
				end
				if check == false then
					build:debug("Ignore", f, "(The", k, "flag",
					            (v and "is not" or "is"), " present)")
					break
				end
			end
			if check == true then
				build:debug('select', f, '(seems to match required flags)')
				table.append(selected, f)
			elseif check == nil then
				build:debug('select', f, '(but no flag has been checked)')
				table.append(unknown, f)
			end
		end
		build:debug("selected=" .. table.tostring(selected), "unknown=" .. table.tostring(unknown))

		if #selected > 0 then
			files = selected
		elseif #unknown > 0 then
			files = unknown
		else
			build:error("Couldn't find any library file for Boost component '"
			            .. component .. "' in:", table.tostring(files))
		end

		if #files > 1 then
			build:error("Too many file selected for Boost component '"
			            .. component .. "':", table.tostring(files))
		end

		local selected_runtime_files = {}
		for _, f in ipairs(runtime_files) do
			if f:stem() == files[0]:stem() then
				table.append(selected_runtime_files, f)
			end
		end
		local defines = default_component_defines(component, kind, threading)
		table.extend(defines, args[component .. '_defines'] or args.defines or {})

		build:debug("Boost component '" .. component .. "' defines:", table.tostring(defines))
		table.append(res, Library:new{
			name = "Boost." .. component,
			include_directories = { boost_include_dir },
			files = files,
			defines = defines,
			runtime_files = selected_runtime_files,
			kind = kind,
		})
	end
	return res
end

--- Build Boost libraries
--
-- @param args
-- @param args.build Build instance
-- @param args.components List of boost libraries to build
-- @param args.name Name of the project (defaults to 'boost')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
-- @param args.COMPONENT_kind Specify the kind for a specific component (defaults to args.kind)
-- @param args.python Python library to use
-- @param args.zlib Zlib library
-- @param args.bzip2 BZip2 library
function M.build(args)
	if args.components == nil then
		error("You must provide a list of components to build")
	end
	local tarball = 'boost_' .. args.version:gsub('%.', '_') .. '.tar.gz'
	local url = 'http://sourceforge.net/projects/boost/files/boost/' ..
	            args.version ..'/' .. tarball .. '/download'
	local project = require('configure.external').Project:new(
		table.update({name = 'boost'}, args)
	):download{
		url = url,
		filename = tarball,
	}

	local install_dir = project:step_directory('install')
	local source_dir = project:step_directory('source')

	-- We exclude python from the list of --with-libraries.
	-- the bootstrap.sh script will generate a python configuration
	-- which is incomplete (missing include dir).
	-- The problem is that a user-config will not replace or augment this
	-- generated conf, but boost.build will instead try to figure out what is
	-- the correct include dir, missing the 'm' suffix when pymalloc was
	-- enabled.
	-- Consequently, we remove python here, but generate a complete and correct
	-- user-config.jam to describe the python install we want to link against.
	local with_python = false
	local with_libraries = {}
	for _, component in ipairs(args.components) do
		if component == 'python' then
			with_python = true
		else
			table.append(with_libraries, component)
		end
	end

	local bootstrap_command = {}

	if args.build:host():is_windows() then
		table.extend(bootstrap_command, { 'cmd', '/C', 'bootstrap.bat' })
	else
		table.extend(bootstrap_command, { 'sh', 'bootstrap.sh' })
		table.extend(bootstrap_command, {
			'--prefix=' .. tostring(install_dir),
			'--with-libraries=' .. table.concat(args.components, ',')
		})
	end

	local env = {}

	if with_python then
		if args.python == nil then
			error("You must provide a python library instance in order to build Boost.Python")
		end
        env['PYTHONPATH'] = args.python.bundle.library_directory
		-- This is what we would like to do instead of generating ourself the user-config.jam
		if not args.build:host():is_windows() then
			table.extend(
				bootstrap_command,
				{
					'--with-python-root=' .. tostring(args.python.directories[1]:parent_path()),
					'--with-python=' .. tostring(args.python.bundle.executable:path()),
					'--with-python-version=' .. args.python.bundle.version:sub(1, 3),
				}
			)
		end
	end

	local bjam = source_dir / 'b2'
	project:add_step{
		name = 'bootstrap',
		directory = source_dir,
		targets = {
			[0] = {bootstrap_command},
		},
		working_directory = source_dir,
		sources = sources,
	}

	if with_python then
		project:add_step{
			name = 'gen-user-config',
			directory = source_dir,
			targets = {
				[0] = {
					{
						args.build:configure_program(), '-E', 'lua-function',
						Filesystem.current_script():parent_path() / 'boost-gen-user-config.lua',
						'main',
						source_dir,
						args.python.bundle.executable:path(),
					}
				}
			},
			sources = {args.python.bundle.executable},
			env = env,
		}
	end


	local sources = {}

	local install_command = {
		tostring(bjam), 'install',
		'toolset=' .. args.compiler.name,
		'--disable-icu',
		'--prefix=' .. tostring(install_dir),
		'--layout=system',
        '--user-config=' .. tostring(source_dir / 'user-config.jam'),
		'link=static',
		'link=shared',
		'variant=release',
		'threading=multi',
		'cxxflags=-fPIC',
	--	'define=BOOST_ERROR_CODE_HEADER_ONLY=1',
	--	'define=BOOST_SYSTEM_NO_DEPRECATED=1',
		'dll-path=' .. tostring(install_dir / 'lib'),
		'--debug-configuration',
		--'-j4',
		'-sBOOST_ROOT=' .. tostring(source_dir),
		'--reconfigure',
		'-d+2',
		'include=' .. tostring(args.python.include_directories[1]:path()),
		'address-model=' .. tostring(args.build:target():address_model()),
	}

	if args.compiler.standard then
		table.append(install_command, 'cxxflags=-std=' .. args.compiler.standard)
	end

	if args.compiler.standard_library then
		table.extend(install_command, {
			'cxxflags=-stdlib=' .. args.compiler.standard_library,
			'linkflags=-stdlib=' .. args.compiler.standard_library,
		})
	end

    if with_python then
        table.extend(install_command, {'python='..args.python.bundle.version:sub(1, 3)})
		table.extend(sources, args.python.files)
    end
	if args.zlib ~= nil then
		table.extend(install_command, {
			'-sZLIB_INCLUDE=' .. tostring(args.zlib.include_directories[1]:path()),
			'-sZLIB_LIBPATH=' .. tostring(args.zlib.files[1]:path():parent_path()),
			'-sZLIB_BINARY=z'
		})
		table.extend(sources, args.zlib.files)
	end
	if not args.build:host():is_windows() then
		if args.bzip2 ~= nil then
			table.extend(install_command, {
				'-sBZIP2_INCLUDE=' .. tostring(args.bzip2.include_directories[1]:path()),
				'-sBZIP2_LIBPATH=' .. tostring(args.bzip2.files[1]:path():parent_path()),
				'-sBZIP2_BINARY=bzip2'
			})
			table.extend(sources, args.bzip2.files)
		end
	end

	for _, component in ipairs(args.components) do
		table.append(install_command, '--with-' .. component)
	end
	local install_commands = { install_command }

	local build = args.build
	for _, component in ipairs(args.components) do
		local kind = args[component .. '_kind'] or kind
		if build:target():is_windows() and kind == 'shared' then
			local dll = 'boost_' .. component .. '.dll'
			table.append(
				install_commands,
				{
					'cp',
					project:step_directory('install') / 'lib' / dll,
					project:step_directory('install') / 'bin' / dll,
				}
			)
		end
	end

	-- dll-path is not used on OSX
	if args.build:target():is_osx() then
		for _, component in ipairs(args.components) do
			local kind = args[component .. '_kind'] or kind
			if kind == 'shared' then
				local filename = 'libboost_' .. component .. '.dylib'
				table.append(
					install_commands,
					{'install_name_tool', '-id', '@rpath/' .. filename, project:node{path = 'lib/' .. filename}}
				)
			end
		end
	end

	project:add_step{
		name = 'install',
		directory = source_dir,
		targets = {
			[0] = install_commands,
		},
		working_directory = source_dir,
		sources = sources,
		env = env,
	}
	local Library = require('configure.lang.cxx.Library')
	local res = {}
	local target_os = args.build:target():os()
	local kind = args.kind or 'static'
	for _, component in ipairs(args.components) do
		local kind = args[component .. '_kind'] or kind
		local defines = {
			{'BOOST_ERROR_CODE_HEADER_ONLY', 1},
			{'BOOST_SYSTEM_NO_DEPRECATED', 1},
			{'BOOST_ALL_NO_LIB', 1},
		}
		local runtime_files = {}
		local filename = args.compiler:canonical_library_filename('boost_' .. component, kind)
		if target_os == Platform.OS.windows then
			if kind == 'shared' then
				filename = 'boost_' .. component .. '.lib'
				table.append(
					runtime_files,
					project:node{path = 'bin/boost_' .. component .. '.dll'}
				)
			else
				filename = 'libboost_' .. component .. '.lib'
			end
		end
		local files = {
			project:node{path = 'lib/' .. filename},
		}

		table.append(res, Library:new{
			name = "Boost." .. component,
			include_directories = { project:directory_node{path = 'include'} },
			files = files,
			defines = defines,
			runtime_files = runtime_files,
			install_node = project:stamp_node('install'),
			kind = kind,
		})
	end
	return res
end

return M
