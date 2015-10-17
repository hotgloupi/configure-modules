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

	local lib = args.compiler:canonical_library_filename('python' .. short_version .. tag, kind)
	lib = project:node{path = 'lib/' .. lib}
	return args.compiler.Library:new{
		name = 'Python',
		include_directories = {
			project:directory_node{path = 'include/python' .. short_version .. tag}
		},
		files = {lib},
		kind = kind,
		bundle = {
			executable = project:node{path = 'bin/python' .. short_version},
			version = args.version,
			short_version = short_version,
		},
		install_node = project:stamp_node('install'),
	}
end

return M
