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

-- Linear Gravity Field
function createLinearGravityField()
	return SKFieldNode.node()
end

-- Radial Gravity Field
function createRadialGravityField()
	return SKFieldNode.node()
end

-- Spring Field
function createSpringField()
	return SKFieldNode.node()
end

-- Drag Field
function createDragField()
	return SKFieldNode.node()
end

-- Vortex Field
function createVortexField()
	return SKFieldNode.node()
end

-- Turbulence Field
function createTurbulenceField()
	return SKFieldNode.node()
end

-- Noise Field
function createNoiseField()
	return SKFieldNode.node()
end

-- Velocity Field
function createVelocityField()
	return SKFieldNode.node()
end

toolFunctions = {
	ColorSprite = createColorSprite,
	EmptyNode = createEmptyNode,
	Light = createLight,
	Emitter = createEmitter,
	Label = createLabel,
	ShapeNode = createShapeNode,
	LinearGravityField = createLinearGravityField,
	RadialGravityField = createRadialGravityField,
	SpringField = createSpringField,
	DragField = createDragField,
	VortexField = createVortexField,
	TurbulenceField = createTurbulenceField,
	NoiseField = createNoiseField,
	VelocityField = createVelocityField
}

-- Call back function
function createNodeAtPosition(position, toolName)
	local createNode = toolFunctions[toolName]
    local node = createNode()
	node.position = position
	return node
end
