package._cache = package._cache or {}

function modinit(modname)
	local mod = package._cache[modname]
	if not (mod) then
		local org = getfenv(2)
		local mt = {
			__index = function (t, key)
				return rawget(t, key)
				 or rawget(org, key)
				 or rawget(_G, key);
			end
		}
		mod = setmetatable({}, mt)

		local errfunc = function (...)
			print("[error]", modname,  GetTime(), ...)
		end
		local safe = function (f)
			return function (...)
				local args = {...}
				local ret = {}
				xpcall(function ()
					ret = { f(unpack(args)) }
				end, errfunc)
				return unpack(ret)
			end
		end
		local import = function (filename)
			local ret = {}
			xpcall(function ()
			  ret = { mod.modimport("scripts/"..filename) }
			end, errfunc)
			return unpack(ret)
		end
		mod._f = safe
		mod._err = errfunc
		mod._M = mod
		mod.import = import

		package._cache[modname] = mod
	end

  setfenv(2, mod)
  return mod
end

function modget(modname)
  return package._cache[modname]
end
package.modinit = modinit;

return modinit;