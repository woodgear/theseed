extends Label
# Displays some useful debug information in a Label.

onready var player = $"../Player"
onready var voxel_world = $"../VoxelWorld"
var focusd = "true"
var input = ""

func _ready():
	pass

func _process(_delta):
	if Input.is_action_just_pressed("debug"):
		visible = not visible

	text = "pos: " + _vector_to_string_appropriate_digits(player.transform.origin)
	text += "\nchunk_pos: " + str(player.chunk_pos())
	text += "\nEffective render distance: " + str(voxel_world.effective_render_distance)
	text += "\nLooking: " + _cardinal_string_from_radians(player.transform.basis.get_euler().y)
	text += "\nMemory: " + "%3.0f" % (OS.get_static_memory_usage() / 1048576.0) + " MiB"
	text += "\nFPS: " + str(Engine.get_frames_per_second())
	text += "\nfocus: " + str(self.focusd)
	text += "\ninput: " + self.input
	text += "\nplayer_mode: " + str(player.mode)
	
	
func _input(event:InputEvent):
	self.input=show_input(event)
	pass

func _physics_process(delta):
	
	pass

func show_input(event:InputEvent)->String:
	if !event.is_pressed():
		return "mouse"
	if event.is_action_type():
		var action_list=[]
		for action in InputMap.get_actions():
			if InputMap.event_is_action(event, action):
				action_list.append(action)
		if !action_list.empty():
			return "action "+ str(action_list.size())+str(action_list)
		return "action/undefined: "+ event.as_text()
	return event.as_text()
	pass
	
func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		self.focusd="true"

	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		self.focusd="false"

	pass
		
func _vector_to_string_appropriate_digits(vector):
	var ret = "x:{x},y:{y},z:{z}".format( {"x":vector.x,"y":vector.y,"z":vector.z})
	return ret

# Expects a rotation where 0 is North, on the range -PI to PI.
func _cardinal_string_from_radians(angle):
	if angle > TAU * 3 / 8:
		return "South"
	if angle < -TAU * 3 / 8:
		return "South"
	if angle > TAU * 1 / 8:
		return "West"
	if angle < -TAU * 1 / 8:
		return "East"
	return "North"
