
local pluto = require 'pluto'

local coro = coroutine.create(function()
	for i = 1, 20 do
		coroutine.yield(i * i)
	end
end)

for i = 1, 5 do
	print(coroutine.resume(coro))
end
local perms = {
	[coroutine.yield] = 1,
}
local s = pluto.persist(perms, {co = coro})
perms = { [1] = coroutine.yield }
coro = pluto.unpersist(perms, s).co
for i = 1, 5 do
	print(coroutine.resume(coro))
end