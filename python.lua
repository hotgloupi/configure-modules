--- Python library
-- @module configure.modules.python

local M = {}

--- Build Python library and executable
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'Python')
-- @param args.version Version to use
-- @param args.zlib build zlib module with this library
-- @param args.bzip2 build bzip2 module with this library
-- @param args.openssl build openssl module with this library
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'shared')
function M.build(args)
	args = table.update({
		name = 'Python',
		kind = 'shared',
	}, args)
	args.major_version = args.version:sub(1,1)
	args.minor_version = args.version:sub(3,3)
	args.short_version = args.major_version .. '.' .. args.minor_version
	args.no_dot_short_version = args.major_version .. args.minor_version
	args.tag = 'm'
	if args.build:host():is_windows() then
		return M.build_with_msvc(args)
	else
		return M.build_with_autotools(args)
	end
end

function M.build_with_msvc(args)
	local kind = args.kind
	local build = args.build
	local project = require('configure.external').Project:new(args)
	project:download{
		url = 'http://www.python.org/ftp/python/' .. args.version .. '/Python-' .. args.version ..'.tgz',
	}
	local sources = {}
	table.extend(sources, args.zlib and args.zlib.files or {})
	table.extend(sources, args.bzip2 and args.bzip2.files or {})
	table.extend(sources, args.openssl and args.openssl.files or {})


	local targets = {
		"clean",
		"python",
		"pythoncore",
		"pythonw",
		"winsound",
		"_decimal",
		"_ctypes",
		"_ctypes_test",
		"_elementtree",
		"_msi",
		"_socket",
	--	"_sqlite3",
	--	"_ssl",
		"_testcapi",
		"_testimportmultiple",
	--	"_tkinter",
	--	"_bz2",
		"select",
	--	"_lzma",
		"unicodedata",
		"pyexpat",
	--	"bdist_wininst",
		--"_hashlib",
	--	"sqlite3",
		"_multiprocessing",
		"python3dll",
		"xxlimited",
		"_testbuffer",
	--	"pylauncher",
	--	"pywlauncher",
		"_freeze_importlib",
		"_overlapped",
		"_testembed",
		"_testmultiphase",
	--	"tcl",
	--	"tix",
	--	"tk",
	--	"libeay",
	--	"ssleay",
	}

	local commands = {}
	for _, target in ipairs(targets) do
		table.append(commands, {
			'MSBuild.exe', 'PCbuild\\pcbuild.sln',
			'/p:Configuration=Release',
			'/p:Platform=x64',
			'/p:PlatformToolset=v140',
			'/p:PlatformTarget=x64',
			'/t:' .. target,
		})
	end



	project:add_step{
		name = 'build',
		working_directory = project:step_directory('source'),
		targets = {
			[0] = commands,
		}
	}

	local install_dir = project:step_directory('install')
	local lib_dir = install_dir / 'lib'
	local bin_dir = install_dir / 'bin'
	local include_dir = install_dir / 'include'
	local python_lib_dir = lib_dir / ('python' .. args.short_version)
	local python_include_dir = include_dir / ('python' .. args.short_version)

	local build_dir = project:step_directory('source') / 'PCBuild' / 'amd64'

	local module_files = {
		"_ctypes.pyd",
		"_ctypes_test.pyd",
		"_decimal.pyd",
		"_elementtree.pyd",
		"_msi.pyd",
		"_multiprocessing.pyd",
		"_overlapped.pyd",
		"_socket.pyd",
		"_testbuffer.pyd",
		"_testcapi.pyd",
		"_testimportmultiple.pyd",
		"_testmultiphase.pyd",
		"pyexpat.pyd",
		"select.pyd",
		"unicodedata.pyd",
		"winsound.pyd",
		"xxlimited.pyd",
	}

	local bin_files = {
		'python.exe',
		'python' .. args.no_dot_short_version ..'.dll',
		'python' .. args.major_version ..'.dll',
	}

	local lib_files = {
		'python' .. args.no_dot_short_version .. '.lib',
		'python' .. args.major_version .. '.lib',
	}

	local targets = {}

	for _, module in ipairs(module_files) do
		targets[python_lib_dir / module] = {
			{'cp', build_dir / module, python_lib_dir}
		}
	end

	for _, bin in ipairs(bin_files) do
		targets[bin_dir /  bin] = {
			{'cp', build_dir / bin, bin_dir}
		}
	end

	for _, lib in ipairs(lib_files) do
		targets[lib_dir / lib] = {
			{'cp', build_dir / lib, lib_dir}
		}
	end

	targets[0] = {
		{'cp', '-r', project:step_directory('source') / 'Lib' / '.', python_lib_dir },
		{'cp', '-r', project:step_directory('source') / 'Include' / '.', python_include_dir },
		{'cp', '-r', project:step_directory('source') / 'PC' / 'pyconfig.h', python_include_dir },
		{
			args.compiler.build:configure_program(), '-E', 'lua-function',
			Filesystem.current_script():parent_path() / 'python-gen-sitecustomize.lua',
			'main',
			python_lib_dir
		}
	}

	project:add_step{
		name = 'install',
		targets = targets,
	}

	local lib = build:file_node(lib_dir / lib_files[2])
	return args.compiler.Library:new{
		name = 'Python',
		include_directories = {build:directory_node(python_include_dir)},
		files = {lib},
		kind = kind,
		bundle = {
			executable = build:file_node(project:step_directory('install') / 'bin' / 'python.exe'),
			version = args.version,
			short_version = args.short_version,
			library_directory = project:directory_node{path = 'lib/python' .. args.short_version},
		},
		install_node = project:stamp_node('install'),
	}
end

function M.build_with_autotools(args)
	local kind = args.kind or 'shared'
	local project = require('configure.external').AutotoolsProject:new(
		table.update({name = 'Python'}, args)
	):download{
		url = 'http://www.python.org/ftp/python/' .. args.version .. '/Python-' .. args.version ..'.tgz',
	}
	local sources = {}
	table.extend(sources, args.zlib and args.zlib.files or {})
	table.extend(sources, args.bzip2 and args.bzip2.files or {})
	table.extend(sources, args.openssl and args.openssl.files or {})
	local configure_args = {
		'--without-suffix',
	}
	local configure_env = {}

	if args.build:target():is_osx() then
		table.extend(configure_args, {
			'--disable-framework',
			'--disable-universalsdk',
			'--enable-ipv6',
			--'--with-system-expat',
			'--without-threads',
			--'--with-system-ffi',
			'--without-ensurepip',
		})
	end

	if args.compiler.name == 'clang' then
		table.append(configure_args, '--without-gcc')
	end

	local short_version = args.version:sub(1,1) .. '.' .. args.version:sub(3,3)
	local kind = args.kind or 'static'
	local tag = 'm'

	local build_args = {}
	if kind == 'shared' then
		table.append(configure_args, '--enable-shared')
		if args.build:target():is_osx() then
			configure_env['LDFLAGS'] = '-Wl,-search_paths_first' -- http://bugs.python.org/issue11445
			-- We replace the default flags for linking python.exe
			-- By default it's "-lpythonX.X.a -L.", which link with shared library first
			-- on OSX. However, python.exe is used to create python extensions,
			-- and symbols are looked up in the python.exe binary (with -bundle_loader)
			-- This is why we need to include all symbols in the python.exe.
			table.append(build_args, 'BLDLIBRARY=libpython' .. short_version .. tag .. '.a')
		end
	end

	project:configure{
		args = configure_args,
		sources = sources,
		env = configure_env,
	}
	project:build{args = build_args}

	project:install{}

	local install_lib_dir = project:directory_node{path = 'lib/python' .. short_version}
	local install_include_dir = project:directory_node{path = 'include/python' .. short_version .. tag}
	local lib = args.compiler:canonical_library_filename('python' .. short_version .. tag, kind)
	lib = project:node{path = 'lib/' .. lib}
	return args.compiler.Library:new{
		name = 'Python',
		include_directories = {install_include_dir},
		files = {lib},
		kind = kind,
		bundle = {
			executable = project:node{path = 'bin/python' .. short_version},
			version = args.version,
			short_version = short_version,
			library_directory = install_lib_dir,
		},
		install_node = project:stamp_node('install'),
	}
end

return M
