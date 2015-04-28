print(package.path)

-- local objc = require("objc.init")
local objc = require("objc.BridgeSupport")
objc.loadFramework("AppKit")
objc.loadFramework("SpriteKit")

pool = objc.NSAutoreleasePool:new()

local myStr = objc.NSStr("test")

-- objc.NSSpeechSynthesizer:new():startSpeakingString(myStr)
-- os.execute("sleep "..2)

local bit = require("bit")

function hello(s)
  print("hello " .. s)
end

function test(scene)
  local myStr = objc.NSStr("Spaceship")
  local node = objc.SKSpriteNode:new()
  print(scene)
end