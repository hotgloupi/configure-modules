
local content = [[
def _main():
    import sys
    #build_flags = sys.abiflags
    from os.path import abspath, dirname, join, normpath
    prefix = normpath(join(dirname(abspath(__file__)), '../..'))
    sys.prefix = sys.exec_prefix = sys.base_exec_prefix = prefix
    from distutils import sysconfig
    def get_python_inc(plat_specific=0, prefix=None):
        if prefix is None:
            prefix = sys.prefix
        python_dir = 'python' + sysconfig.get_python_version() + sysconfig.build_flags
        return join(prefix, "include", python_dir)
    sysconfig.get_python_inc = get_python_inc

    def get_python_lib(plat_specific=0, standard_lib=0, prefix=None):
        if prefix is None:
            prefix = sys.prefix
        libpython = join(prefix,
                         "lib", "python" + sysconfig.get_python_version())
        if standard_lib:
            return libpython
        else:
            return join(libpython, "site-packages")
    sysconfig.get_python_lib = get_python_lib

    vars = sysconfig.get_config_vars()
    vars['LIBDIR'] = join(sys.prefix, 'lib')
    import os
    if os.name == 'nt':
        vars['LDLIBRARY'] = 'python' + vars['VERSION'] + '.lib'
    import os

_main()
del _main
]]

function main(lib_dir)
	local f = assert(io.open(tostring(Path:new(lib_dir) / "sitecustomize.py") , 'w'))
	f:write(content)
	f:close()
end
