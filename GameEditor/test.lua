-- Test the bridge
local ffi = require('ffi')
ffi.cdef[[
	int printf(const char * __restrict, ...);
	void import(const char *framework);
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

function objc:import(framework)
	ffi.C.import(framework)
end

objc:import("AVKit")
print(objc:class("AVPlayerView"):alloc():init())

-- Create a test sprite
local sprite = objc:class("SKSpriteNode"):spriteNodeWithImageNamed('Spaceship')
sprite:setName('test')
sprite:runAction(objc:class("SKAction"):repeatActionForever(objc:class("SKAction"):rotateByAngle_duration(5, 1)))
scene:addChild(sprite)
