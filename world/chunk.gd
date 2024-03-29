class_name Chunk
extends StaticBody
# These chunks are instanced and given data by VoxelWorld.
# After that, chunks finish setting themselves up in the _ready() function.
# If a chunk is changed, its "regenerate" method is called.

const CHUNK_SIZE = 9 # Keep in sync with TerrainGenerator. 一个chunk有n^3个cube组成
const TEXTURE_SHEET_WIDTH = 8 # 纹理中一个cube的宽度

const CHUNK_LAST_INDEX = CHUNK_SIZE - 1
const TEXTURE_TILE_SIZE = 1.0 / TEXTURE_SHEET_WIDTH #纹理的1/8

var consts=preload("res://world/const.gd")
var data = {}
var chunk_position = Vector3(0,0,0) # TODO: Vector3i
var init_chunk=false
var _thread
onready var voxel_world = get_parent()

signal chunk_init_ready

func _ready():
	transform.origin = chunk_position * CHUNK_SIZE
	name = str(chunk_position)
	var hint=null
	if init_chunk:
		hint=consts.LOG
	data = TerrainGenerator.fill(chunk_position,hint)
#	if Settings.world_type == 0:
#		data = TerrainGenerator.random_blocks()
#	else:
#		data = TerrainGenerator.flat(chunk_position)

	# We can only add colliders in the main thread due to physics limitations.
	_generate_chunk_collider()
	_generate_chunk_mesh()
	if init_chunk:
		print("signal",chunk_position)
		emit_signal("chunk_init_ready")

	# However, we can use a thread for mesh generation.
#	_thread = Thread.new()
#	_thread.start(self, "_generate_chunk_mesh")


func regenerate():
	# Clear out all old nodes first.
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# Then generate new ones.
	_generate_chunk_collider()
	_generate_chunk_mesh()


func _generate_chunk_collider():
	if data.empty():
		# Avoid errors caused by StaticBody not having colliders.
		_create_block_collider(Vector3.ZERO)
		collision_layer = 0
		collision_mask = 0
		return

	# For each block, generate a collider. Ensure collision layers are enabled.
	collision_layer = 0xFFFFF
	collision_mask = 0xFFFFF
	for block_position in data.keys():
		var block_id = data[block_position]
		if block_id != 27 and block_id != 28:
			_create_block_collider(block_position)


func _generate_chunk_mesh():
	if data.empty():
		return

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# For each block, add data to the SurfaceTool and generate a collider.
	for block_position in data.keys():
		var block_id = data[block_position]
		_draw_block_mesh(surface_tool, block_position, block_id)

	# Create the chunk's mesh from the SurfaceTool data.
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	surface_tool.index()
	var array_mesh = surface_tool.commit()
	var mi = MeshInstance.new()
	mi.mesh = array_mesh
	mi.material_override = preload("res://world/textures/material.tres")
	add_child(mi)


func _draw_block_mesh(surface_tool, block_sub_position, block_id):
	var verts = calculate_block_verts(block_sub_position)
	var uvs = calculate_block_uvs(block_id)
	var top_uvs = uvs
	var bottom_uvs = uvs

	# Bush blocks get drawn in their own special way.
	if block_id == 27 or block_id == 28:
		_draw_block_face(surface_tool, [verts[2], verts[0], verts[7], verts[5]], uvs)
		_draw_block_face(surface_tool, [verts[7], verts[5], verts[2], verts[0]], uvs)
		_draw_block_face(surface_tool, [verts[3], verts[1], verts[6], verts[4]], uvs)
		_draw_block_face(surface_tool, [verts[6], verts[4], verts[3], verts[1]], uvs)
		return

	# Allow some blocks to have different top/bottom textures.
	if block_id == 3: # Grass.
		top_uvs = calculate_block_uvs(0)
		bottom_uvs = calculate_block_uvs(2)
	elif block_id == 5: # Furnace.
		top_uvs = calculate_block_uvs(31)
		bottom_uvs = top_uvs
	elif block_id == 12: # Log. 原木
		top_uvs = calculate_block_uvs(30)
		bottom_uvs = top_uvs
	elif block_id == 19: # Bookshelf.
		top_uvs = calculate_block_uvs(4)
		bottom_uvs = top_uvs

	# Main rendering code for normal blocks.
	var other_block_position = block_sub_position + Vector3.LEFT
	var other_block_id = 0
	if other_block_position.x == -1:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[2], verts[0], verts[3], verts[1]], uvs)

	other_block_position = block_sub_position + Vector3.RIGHT
	other_block_id = 0
	if other_block_position.x == CHUNK_SIZE:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[7], verts[5], verts[6], verts[4]], uvs)

	other_block_position = block_sub_position + Vector3.FORWARD
	other_block_id = 0
	if other_block_position.z == -1:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[6], verts[4], verts[2], verts[0]], uvs)

	other_block_position = block_sub_position + Vector3.BACK
	other_block_id = 0
	if other_block_position.z == CHUNK_SIZE:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[3], verts[1], verts[7], verts[5]], uvs)

	other_block_position = block_sub_position + Vector3.DOWN
	other_block_id = 0
	if other_block_position.y == -1:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[4], verts[5], verts[0], verts[1]], bottom_uvs)

	other_block_position = block_sub_position + Vector3.UP
	other_block_id = 0
	if other_block_position.y == CHUNK_SIZE:
		other_block_id = voxel_world.get_block_global_position(other_block_position + chunk_position * CHUNK_SIZE)
	elif data.has(other_block_position):
		other_block_id = data[other_block_position]
	if block_id != other_block_id and is_block_transparent(other_block_id):
		_draw_block_face(surface_tool, [verts[2], verts[3], verts[6], verts[7]], top_uvs)


func _draw_block_face(surface_tool, verts, uvs):
	surface_tool.add_uv(uvs[1]); surface_tool.add_vertex(verts[1])
	surface_tool.add_uv(uvs[2]); surface_tool.add_vertex(verts[2])
	surface_tool.add_uv(uvs[3]); surface_tool.add_vertex(verts[3])

	surface_tool.add_uv(uvs[2]); surface_tool.add_vertex(verts[2])
	surface_tool.add_uv(uvs[1]); surface_tool.add_vertex(verts[1])
	surface_tool.add_uv(uvs[0]); surface_tool.add_vertex(verts[0])


func _create_block_collider(block_sub_position):
	var collider = CollisionShape.new()
	collider.shape = BoxShape.new()
	collider.shape.extents = Vector3.ONE / 2
	collider.transform.origin = block_sub_position + Vector3.ONE /2
	add_child(collider)


static func calculate_block_uvs(block_id):
	# This method only supports square texture sheets.
	var row = block_id / TEXTURE_SHEET_WIDTH
	var col = block_id % TEXTURE_SHEET_WIDTH

	return [
		TEXTURE_TILE_SIZE * Vector2(col, row),
		TEXTURE_TILE_SIZE * Vector2(col, row + 1),
		TEXTURE_TILE_SIZE * Vector2(col + 1, row),
		TEXTURE_TILE_SIZE * Vector2(col + 1, row + 1),
	]


static func calculate_block_verts(block_position):
	return [
		Vector3(block_position.x, block_position.y, block_position.z),
		Vector3(block_position.x, block_position.y, block_position.z + 1),
		Vector3(block_position.x, block_position.y + 1, block_position.z),
		Vector3(block_position.x, block_position.y + 1, block_position.z + 1),
		Vector3(block_position.x + 1, block_position.y, block_position.z),
		Vector3(block_position.x + 1, block_position.y, block_position.z + 1),
		Vector3(block_position.x + 1, block_position.y + 1, block_position.z),
		Vector3(block_position.x + 1, block_position.y + 1, block_position.z + 1),
	]


static func is_block_transparent(block_id):
	return block_id == 0 or (block_id > 25 and block_id < 30)
