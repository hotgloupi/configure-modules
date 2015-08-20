--- FreeType library
-- @module configure.modules.librocket

local M = {}

--- Build FreeType2 library
--
-- @param args
-- @param args.build Build instance
-- @param args.name Name of the project (defaults to 'FreeType')
-- @param args.version Version to use
-- @param args.compiler
-- @param args.c_compiler
-- @param args.install_directory
-- @param args.kind 'shared' or 'static' (defaults to 'static')
function M.build(args)
	local kind = args.kind or 'static'
	if args.version == nil then
		args.build:error("You must specify a version")
	end
	local url = 'http://download.savannah.gnu.org/releases/freetype/freetype-'
		.. args.version .. '.tar.gz'
	local project = require('configure.external').CMakeProject:new(
		table.update({
			name = 'FreeType',
			kind = kind,
		}, args)
	):download{
		url = url,
	}
	local filenames = {
		"src/base/ftsystem.c",
		"src/base/ftinit.c",
		"src/base/ftdebug.c",
		"src/base/ftbase.c",
		"src/base/ftbbox.c",         -- recommended, see <freetype/ftbbox.h>
		"src/base/ftglyph.c",        -- recommended, see <freetype/ftglyph.h>
		"src/base/ftbdf.c",          -- optional, see <freetype/ftbdf.h>
		"src/base/ftbitmap.c",       -- optional, see <freetype/ftbitmap.h>
		"src/base/ftcid.c",          -- optional, see <freetype/ftcid.h>
		"src/base/ftfstype.c",       -- optional
		"src/base/ftgasp.c",         -- optional, see <freetype/ftgasp.h>
		"src/base/ftgxval.c",        -- optional, see <freetype/ftgxval.h>
		"src/base/ftlcdfil.c",       -- optional, see <freetype/ftlcdfil.h>
		"src/base/ftmm.c",           -- optional, see <freetype/ftmm.h>
		"src/base/ftotval.c",        -- optional, see <freetype/ftotval.h>
		"src/base/ftpatent.c",       -- optional
		"src/base/ftpfr.c",          -- optional, see <freetype/ftpfr.h>
		"src/base/ftstroke.c",       -- optional, see <freetype/ftstroke.h>
		"src/base/ftsynth.c",        -- optional, see <freetype/ftsynth.h>
		"src/base/fttype1.c",        -- optional, see <freetype/t1tables.h>
		"src/base/ftwinfnt.c",       -- optional, see <freetype/ftwinfnt.h>
		"src/base/ftxf86.c",         -- optional, see <freetype/ftxf86.h>

		"src/bdf/bdf.c",             -- BDF font driver
		"src/cff/cff.c",             -- CFF/OpenType font driver
		"src/cid/type1cid.c",        -- Type 1 CID-keyed font driver
		"src/pcf/pcf.c",             -- PCF font driver
		"src/pfr/pfr.c",             -- PFR/TrueDoc font driver
		"src/sfnt/sfnt.c",           -- SFNT files support (TrueType & OpenType)
		"src/truetype/truetype.c",   -- TrueType font driver
		"src/type1/type1.c",         -- Type 1 font driver
		"src/type42/type42.c",       -- Type 42 font driver
		"src/winfonts/winfnt.c",     -- Windows FONT / FNT font driver

		"src/raster/raster.c",       -- monochrome rasterizer
		"src/smooth/smooth.c",       -- anti-aliasing rasterizer

		"src/autofit/autofit.c",     -- auto hinting module
		"src/cache/ftcache.c",       -- cache sub-system (in beta)
		"src/gzip/ftgzip.c",         -- support for compressed fonts (.gz)
		"src/lzw/ftlzw.c",           -- support for compressed fonts (.Z)
		"src/bzip2/ftbzip2.c",       -- support for compressed fonts (.bz2)
		"src/gxvalid/gxvalid.c",     -- TrueTypeGX/AAT table validation
		"src/otvalid/otvalid.c",     -- OpenType table validation
		"src/psaux/psaux.c",         -- PostScript Type 1 parsing
		"src/pshinter/pshinter.c",   -- PS hinting module
		"src/psnames/psnames.c",     -- PostScript glyph names support
	}

	if args.build:target():is_osx() then
		table.append(
			filenames,
			"src/base/ftmac.c"          -- only on the Macintosh
		)
	end

	local sources = {}
	for _, filename in ipairs(filenames) do
		local node = args.build:file_node(
			project:step_directory('source') / filename
		)
		args.build:add_rule(
			Rule:new():add_source(project:last_step()):add_target(node)
		)
		table.append(sources, node)
	end

	return args.compiler:link_library{
		name = project.name,
		sources = sources,
		kind = args.kind or 'static',
		object_directory = project:step_directory('build'),
		directory = project:step_directory('install') / 'lib',
		defines = {'FT2_BUILD_LIBRARY'},
		include_directories = {
			project:step_directory('source') / 'include',
		}
	}
end

return M
