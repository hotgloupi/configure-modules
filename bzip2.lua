--- BZIP2 library
-- @module configure.modules.bzip2

local M = {}

--- Build Bzip2 library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'bzip2')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'shared')
function M.build(args)
	local project = require('configure.external').AutotoolsProject:new(
		table.update({name = 'bzip2'}, args)
	):download{
		url = 'http://www.bzip.org/' .. args.version .. '/bzip2-' .. args.version ..'.tar.gz',
	}
	local sources = {
		'blocksort.c',
		'huffman.c',
		'crctable.c',
		'randtable.c',
		'compress.c',
		'decompress.c',
		'bzlib.c',
	}
	local source_nodes = {}
	for _, filename in ipairs(sources) do

		local node = args.build:file_node(
			project:step_directory('source') / filename
		)
		args.build:add_rule(
			Rule:new():add_source(project:last_step()):add_target(node)
		)
		table.append(source_nodes, node)
	end
	return args.compiler:link_library{
		name = project.name,
		sources = source_nodes,
		kind = args.kind or 'static',
		object_directory = project:step_directory('build'),
		directory = project:step_directory('install') / 'lib',
		include_directories = {
			project:step_directory('source'),
		}
	}
end

return M

