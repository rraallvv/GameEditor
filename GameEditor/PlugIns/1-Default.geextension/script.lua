function createColorSprite()
	local color = NSColor.redColor()
	local size = {width=100, height=100}
	return SKSpriteNode.spriteNodeWithColorSize(color, size)
end

function createEmptyNode()
	return SKNode.node()
end

function createLight()
	return SKLightNode.node()
end

function createEmitter()
	return SKEmitterNode.node()
end

function createNodeAtPosition(position, toolName)
	local tools = {
		ColorSprite = createColorSprite,
		EmptyNode = createEmptyNode,
		Light = createLight,
		Emitter = createEmitter
	}
	print(toolName)
	local createNode = tools[toolName]
    local node = createNode()
	node.position = position
	return node
end
