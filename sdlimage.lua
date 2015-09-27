--- SDLImage library
-- @module configure.modules.sdlimage

local M = {}

--- Build SDLImage library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'zlib')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local kind = args.kind or 'static'
	local project = require('configure.external').CMakeProject:new(
		table.update({name = 'SDLImage', kind = kind}, args)
	):download{
		url = 'https://www.libsdl.org/projects/SDL_image/release/SDL2_image-'
			.. args.version .. '.tar.gz'
	}
	local source_dir = project:step_directory('source')
	local fs = args.compiler.build:fs()

	local sources = {
		'IMG_bmp.c',
		'IMG.c',
		'IMG_gif.c',
		'IMG_jpg.c',
		'IMG_lbm.c',
		'IMG_pcx.c',
		'IMG_png.c',
		'IMG_pnm.c',
		'IMG_tga.c',
		'IMG_tif.c',
		'IMG_webp.c',
		'IMG_xcf.c',
		'IMG_xpm.c',
		'IMG_xv.c',
		'IMG_xxx.c',
	}
	project:add_step {
		name = 'build',
		sources = args.sdl.files,
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
	local defines = {
		'LOAD_BMP',
		'LOAD_GIF',
		-- 'LOAD_JPG',
		-- 'LOAD_JPG_DYNAMIC',
		'LOAD_LBM',
		'LOAD_PCX',
		-- 'LOAD_PNG',
		-- 'LOAD_PNG_DYNAMIC',
		'LOAD_PNM',
		'LOAD_TGA',
		-- 'LOAD_TIF',
		-- 'LOAD_TIF_DYNAMIC',
		-- 'LOAD_WEBP',
		-- 'LOAD_WEBP_DYNAMIC',
		'LOAD_XCF',
		'LOAD_XPM',
		'LOAD_XV',
		'LOAD_XXX',
		'SDL_IMAGE_USE_COMMON_BACKEND' -- XXX should use IMG_ImageIO.m on OS X
	}
	return args.compiler:link_library{
		name = project.name,
		sources = source_nodes,
		defines = defines,
		kind = args.kind or 'static',
		object_directory = project:step_directory('build'),
		directory = project:step_directory('install') / 'lib',
		include_directories = table.extend(
			{
				project:step_directory('source'),
			},
			args.sdl.include_directories
		)
	}
end

return M




