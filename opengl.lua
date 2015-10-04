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

	local search_directories = args.compiler:system_library_directories()
	local libraries = {}
	for _, filename in ipairs(library_filenames) do
		local found = false
		local file = nil
		for _, dir in ipairs(search_directories) do
			file = dir / filename
			if file:exists() then
				table.append(libraries, file)
				found = true
				build:debug("Found OpenGL library '" .. tostring(file) .. "'")
				break
			end
		end
		if not found then
			error("Couldn't find '" .. filename .. "' in " ..
			      table.tostring(search_directories))
		end
	end
	return args.compiler.Library:new{
		name = 'OpenGL',
		include_directories = {},
		files = libraries,
		kind = 'shared',
	}
end

return M
