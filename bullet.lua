--- Bullet library
-- @module configure.modules.assimp

local M = {}

--- Build Bullet library
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
	local major, minor, sub = table.unpack(args.version:split('.'))
	local project = require('configure.external').CMakeProject:new(
		table.update(
			{
				name = 'Bullet',
				kind = kind,
			},
			args
		)
	):download{
		url = 'https://github.com/bulletphysics/bullet3/archive/' .. args.version ..'.tar.gz',
	}
	local configure_variables = {
		BUILD_AMD_OPENCL_DEMOS = false,
		BUILD_BULLET2_DEMOS = false,
		BUILD_CPU_DEMOS = false,
		BUILD_DEMOS = false,
		BUILD_EXTRAS = false,
		BUILD_INTEL_OPENCL_DEMOS = false,
		BUILD_MINICL_OPENCL_DEMOS = false,
		BUILD_MULTITHREADING = true,
		BUILD_NVIDIA_OPENCL_DEMOS = false,
		BUILD_OPENGL3_DEMOS = false,
		BUILD_SHARED_LIBS = kind == 'shared',
		BUILD_UNIT_TESTS = false,
		CMAKE_BUILD_TYPE = 'Release',
		INSTALL_EXTRA_LIBS = false,
		INSTALL_LIBS = true,
		USE_DX11 = false,
		USE_GLUT = false,
		USE_GRAPHICAL_BENCHMARK = false,
		USE_MSVC_RUNTIME_LIBRARY_DLL = true,
	}
	project:configure{variables = configure_variables}:build{}:install{}

	local libraries = {}
	for _, lib in ipairs({'BulletDynamics', 'BulletCollision', 'BulletSoftBody', 'LinearMath'}) do
		local prefix = ''
		local ext = nil
		if args.build:target():os() == Platform.OS.windows then
			ext = '.lib'
		else
			prefix = 'lib'
			if kind == 'static' then
				ext = '.a'
			else
				ext = '.so'
			end
		end
		table.append(libraries, project:node{path = 'lib/' .. prefix .. lib .. ext})
	end
	return args.compiler.Library:new{
		name = project.name,
		include_directories = {
			project:directory_node{path = 'include/bullet'}
		},
		files = libraries,
		kind = kind,
	}
end

return M




