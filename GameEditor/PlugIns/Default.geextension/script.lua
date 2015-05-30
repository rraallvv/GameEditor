-- Color Sprite
function createColorSprite()
	local color = NSColor.redColor()
	local size = {width=100, height=100}
	return SKSpriteNode.spriteNodeWithColorSize(color, size)
end

-- Empty Node
function createEmptyNode()
	return SKNode.node()
end

-- Light
function createLight()
	return SKLightNode.node()
end

-- Emitter
function createEmitter()
	return SKEmitterNode.node()
end

-- Label
function createLabel()
	return SKLabelNode.labelNodeWithText('Label')
end

-- Shape Node
function createShapeNode()
	local rect = {x=-50, y=-50, width=100, height=100}
	return SKShapeNode.shapeNodeWithRect(rect)
end

-- Call back function
function createNodeAtPosition(position, toolName)
	local tools = {
		ColorSprite = createColorSprite,
		EmptyNode = createEmptyNode,
		Light = createLight,
		Emitter = createEmitter,
		Label = createLabel,
		ShapeNode = createShapeNode
	}
	print(toolName)
	local createNode = tools[toolName]
    local node = createNode()
	node.position = position
	return node
end
