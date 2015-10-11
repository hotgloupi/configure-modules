

function main(header)
	local f = assert(io.open(header , 'w'))
	f:write("#ifndef SDL_DYNAMIC_API\n")
	f:write("# define SDL_DYNAMIC_API 0\n")
	f:write("#endif\n")
	f:close()
end
