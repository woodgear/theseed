extends Node
# This file manages the creation and deletion of Chunks.

const CHUNK_MIDPOINT = Vector3(0.5, 0.5, 0.5) * Chunk.CHUNK_SIZE
const CHUNK_END_SIZE = Chunk.CHUNK_SIZE - 1

var effective_render_distance = 5
var _old_player_chunk = Vector3() # TODO: Vector3i

var _generating = true
var _deleting = false

var _chunks = {}

onready var player = $"../Player"


func _ready():
	var chunk = Chunk.new()
	var chunk_position = Vector3(0, 0, 0)
	_chunks[chunk_position] = chunk
	self.add_child(chunk)


	
func _process(_delta):

	#if _deleting or player_chunk != _old_player_chunk:
	#	_delete_far_away_chunks(player_chunk)
	#	_generating = true
	
	if not _generating:
		return
	var base = Vector3(0, 0, 0)
	# Check existing chunks within range. If it doesn't exist, create it.
	for x in range(base.x - effective_render_distance, base.x + effective_render_distance):
		for y in range(base.y - effective_render_distance, base.y + effective_render_distance):
			for z in range(base.z - effective_render_distance, base.z + effective_render_distance):
				var chunk_position = Vector3(x,y,z)
				if _chunks.has(chunk_position):
					continue
				var chunk = Chunk.new()
				chunk.chunk_position = chunk_position
				_chunks[chunk_position] = chunk
				self.add_child(chunk)
				return


func get_block_global_position(block_global_position):
	# 每个block是占据一定的物理里空间的
	var chunk_position = (block_global_position / Chunk.CHUNK_SIZE).floor()
	if _chunks.has(chunk_position):
		var chunk = _chunks[chunk_position]
		var sub_position = block_global_position.posmod(Chunk.CHUNK_SIZE)
		#print_debug("cp ",chunk_position," sp ",sub_position)
		if chunk.data.has(sub_position):
			return chunk.data[sub_position]
	return 0


func set_block_global_position(block_global_position, block_id):
	var chunk_position = (block_global_position / Chunk.CHUNK_SIZE).floor()
	var chunk = _chunks[chunk_position]
	var sub_position = block_global_position.posmod(Chunk.CHUNK_SIZE)
	if block_id == 0:
		chunk.data.erase(sub_position)
	else:
		chunk.data[sub_position] = block_id
	chunk.regenerate()
	return
	# We also might need to regenerate some neighboring chunks.
	if Chunk.is_block_transparent(block_id):
		if sub_position.x == 0:
			_chunks[chunk_position + Vector3.LEFT].regenerate()
		elif sub_position.x == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.RIGHT].regenerate()
		if sub_position.z == 0:
			_chunks[chunk_position + Vector3.FORWARD].regenerate()
		elif sub_position.z == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.BACK].regenerate()
		if sub_position.y == 0:
			_chunks[chunk_position + Vector3.DOWN].regenerate()
		elif sub_position.y == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.UP].regenerate()


func clean_up():
	for chunk_position_key in _chunks.keys():
		var thread = _chunks[chunk_position_key]._thread
		if thread:
			thread.wait_to_finish()
	_chunks = {}
	set_process(false)
	for c in get_children():
		c.free()

