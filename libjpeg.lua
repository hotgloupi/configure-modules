--- Libjpeg library
-- @module configure.modules.sdlimage

local M = {}

--- Build SDLImage library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'libjpeg')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local build = args.build
	local kind = args.kind or 'static'
	local project = require('configure.external').Project:new(
		table.update({name = 'libjpeg'}, args)
	)

	local url
	if false and build:host():is_windows() then
		url = 'http://www.ijg.org/files/jpegsr' .. args.version .. '.zip'
	else
		url = 'http://www.ijg.org/files/jpegsrc.v' .. args.version .. '.tar.gz'
	end

	project:download{url = url}

	project:add_step{
		name = 'configure',
		working_directory = project:step_directory('source'),
		targets = {
			[0] = { {'cp', 'jconfig.txt', 'jconfig.h'} },
		}
	}

	local public_headers = {'jerror.h', 'jmorecfg.h', 'jpegint.h', 'jpeglib.h',
	'jconfig.h'}

	local lib_sources = {
		'jaricom.c', 'jcapimin.c', 'jcapistd.c', 'jcarith.c', 'jccoefct.c',
		'jccolor.c', 'jcdctmgr.c', 'jchuff.c', 'jcinit.c', 'jcmainct.c',
		'jcmarker.c', 'jcmaster.c', 'jcomapi.c', 'jcparam.c', 'jcprepct.c',
		'jcsample.c', 'jctrans.c', 'jdapimin.c', 'jdapistd.c', 'jdarith.c',
		'jdatadst.c', 'jdatasrc.c', 'jdcoefct.c', 'jdcolor.c', 'jddctmgr.c',
		'jdhuff.c', 'jdinput.c', 'jdmainct.c', 'jdmarker.c', 'jdmaster.c',
		'jdmerge.c', 'jdpostct.c', 'jdsample.c', 'jdtrans.c', 'jerror.c',
		'jfdctflt.c', 'jfdctfst.c', 'jfdctint.c', 'jidctflt.c', 'jidctfst.c',
		'jidctint.c', 'jquant1.c', 'jquant2.c', 'jutils.c', 'jmemmgr.c',
	}

	-- Memory managers (use only one)
	-- jmemansi.c jmemname.c jmemnobs.c jmemdos.c jmemmac.c
	table.append(lib_sources, 'jmemnobs.c')

	local source_dir = project:step_directory('source')
	local source_nodes = {}
	local source_rule = Rule:new():add_source(project:last_step())
	for _, filename in ipairs(lib_sources) do
		table.append(source_nodes, build:file_node(source_dir / filename))
		source_rule:add_target(build:file_node(source_dir / filename))
	end

	-- Each file is dependent on the download/extract step
	build:add_rule(source_rule)

	return args.compiler:link_library{
		name = 'jpeg',
		sources = source_nodes,
		kind = kind,
		object_directory = project:step_directory('build'),
		directory = project:step_directory('install') / 'lib',
		include_directories = { source_dir },
		install_node = project:last_step(),
	}

end

return M
