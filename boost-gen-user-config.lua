
function main(source_dir, python_exe)
	source_dir = Path:new(source_dir)
	if not source_dir:is_absolute() then
		source_dir = Filesystem:cwd() / source_dir
	end

	python_exe = Path:new(python_exe)
	if not python_exe:is_absolute() then
		python_exe = Filesystem:cwd() / python_exe
	end

	local prefix = Process:check_output(
		{python_exe, '-c', 'import sys; print(sys.prefix)'}
	):strip()

	local include_dir = Process:check_output(
		{python_exe, '-c', 'import distutils.sysconfig as s; print(s.get_python_inc(True))'}
	):strip()

	local version = Process:check_output(
		{python_exe, '-c', 'import sys; print(".".join(map(str, sys.version_info[:2])))'}
	):strip()

	local library_dir = Process:check_output(
		{python_exe, '-c', 'import distutils.sysconfig as s; print(s.get_config_var("LIBDIR"))'}
	):strip()

	local library = Process:check_output(
		{python_exe, '-c', 'import distutils.sysconfig as s; print(s.get_config_var("LDLIBRARY"))'}
	):strip()

	local lib_path = Path:new(library_dir) / library
	assert(lib_path:exists())
	local expected_name = "libpython" .. version .. tostring(lib_path:ext())
	local expected_path = Path:new(library_dir) / expected_name
	if not expected_path:exists() then
		Process:check_output({'cp', lib_path, expected_path})
	end

	local f = assert(io.open(tostring(source_dir / "user-config.jam") , 'w'))
	f:write("using python : " .. version .. '\n')
	f:write("             : " .. tostring(python_exe) .. '\n')
	f:write("             : " .. include_dir .. '\n')
	f:write("             : " .. library_dir .. '\n')
	f:write("             ;\n")
	f:close()
end
