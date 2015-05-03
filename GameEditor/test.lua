-- Test the bridge
local ffi = require('ffi')
local objc = {
}
ffi.cdef[[
	int printf(const char * __restrict, ...);
]]
print('>>>!!!1')
ffi.C.printf('>>>!!!2')

local function capture(table, key, rest)
	return	function(...)
				local args = {...}
				print(string.format('call to %s with key %s {', tostring(table), tostring(key)))
				for i=1, #args do
					print(tostring(args[i]))
				end
				print('}')
			end
end

mock = {}
mt = { __index = capture }
setmetatable(mock, mt)
mock.foo()
mock.foo('bar')
mock.foo('bar', 5)

-- Create a test sprite
local obj = SKSpriteNode:spriteNodeWithImageNamed('Spaceship')
obj:setName('test')
scene:addChild(obj)
