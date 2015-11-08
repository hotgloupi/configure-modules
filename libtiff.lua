--- libtiff library
-- @module configure.modules.libtiff

local M = {}

local tools = require('configure.tools')

--- Build libtiff library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'libtiff')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
-- @param args.x Use the X Window System (defaults to false)
-- @param args.zlib zlib library to use
-- @param args.jpeg jpeg library to use
-- @param args.lzma lzma library to use
-- @param args.jbig jbig library to use
function M.build(args)
	local build = args.build
	local kind = args.kind or 'static'

	local Project = nil
	local project_kind = nil
	if args.compiler.name == 'msvc' then
		Project = require('configure.external').CMakeProject
		project_kind = 'cmake'
	else
		Project = require('configure.external').AutotoolsProject
		project_kind = 'autotools'
	end

	local project = Project:new(table.update({name = 'libtiff'}, args))

	project:download{
		url = 'ftp://ftp.remotesensing.org/pub/libtiff/tiff-' .. args.version .. '.tar.gz'
	}

	local configure_args = {}
	if project_kind == 'autotools' then
		local cmd_args = {
			'--enable-shared=' .. (kind == 'shared' and 'yes' or 'no'),
			'--enable-static=' .. (kind == 'static' and 'yes' or 'no'),
			'--without-x',
		}

		for _, name in ipairs({'zlib', 'lzma', 'jpeg', 'jbig'}) do
			local lib = args[name]
			if lib ~= nil then
				table.extend(cmd_args, {
					'--with-' .. name .. '-include-dir=' .. tostring(tools.path(lib.include_directories[1])),
					'--with-' .. name .. '-lib-dir=' .. tostring(tools.path(lib.directories[1])),
				})
			else
				table.append(cmd_args, '--disable-' .. name)
			end
		end
		configure_args.args = cmd_args
	elseif project_kind == 'cmake' then
		local vars = {}
		local lib_dirs = {}
		local inc_dirs = {}
		for _, name in ipairs({'zlib', 'lzma', 'jpeg', 'jbig'}) do
			local lib = args[name]
			if lib ~= nil then
				table.append(lib_dirs, tostring(tools.path(lib.directories[1])))
				table.append(inc_dirs, tostring(tools.path(lib.include_directories[1])))
				vars[name] = true
			else
				vars[name] = false
			end
		end
		vars.CMAKE_LIBRARY_PATH = table.concat(tools.unique(lib_dirs), ';')
		vars.CMAKE_INCLUDE_PATH = table.concat(tools.unique(inc_dirs), ';')

		configure_args.variables = vars
	else
		error("Unknown project kind")
	end

	local sources = {}
	for _, name in ipairs({'zlib', 'lzma', 'jpeg', 'jbig'}) do
		local lib = args[name]
		if lib ~= nil and lib.install_node ~= nil then
			table.append(sources, lib.install_node)
			table.extend(sources, lib.files)
		end
	end
	configure_args.sources = tools.unique(sources)

	project:configure(configure_args)
	project:build{}
	project:install{}

	local filenames = {args.compiler:canonical_library_filename('tiff', kind)}
	if build:host():is_windows() then
		if kind == 'static' then
			filenames = {'tiff.lib', 'port.lib'}
		else
			error("Not implemented")
		end
	end

	local files = {}
	for _, filename in ipairs(filenames) do
		table.append(files, project:node{path = 'lib/' .. filename})
	end

	local runtime_files = {}

	return args.compiler.Library:new{
		name = 'libtiff',
		include_directories = {project:directory_node{path = 'include'}},
		files = files,
		runtime_files = runtime_files,
		kind = kind,
		install_node = project:stamp_node('install'),
	}

end

return M
