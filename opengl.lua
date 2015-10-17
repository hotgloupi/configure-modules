--- C++ OpenGL library
-- @module configure.modules.opengl


local M = {}

--- Find OpenGL library
--
-- @param args
-- @param args.compiler A compiler instance
function M.find(args)
	local build = args.compiler.build
	local library_filenames = {}
	if build:target():is_windows() then
		table.append(library_filenames, 'opengl32.lib')
	elseif build:target():is_osx() then
		table.extend(library_filenames, {
			'OpenGL',
			'Cocoa',
			'CoreFoundation',
		})
	else
		table.append(library_filenames, 'libGL.so')
	end

	local libraries = {}
	for _, filename in ipairs(library_filenames) do
		table.append(libraries, args.compiler:find_system_library_file_from_filename(filename))
	end
	return args.compiler.Library:new{
		name = 'OpenGL',
		include_directories = {},
		files = libraries,
		kind = 'shared',
	}
end

return M
