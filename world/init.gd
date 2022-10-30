extends Node


func _ready():
	if is_kuku():
		init_kuku()
	pass

func is_kuku()->bool:
	return true
	pass
	
func init_kuku():
	# 用左边的屏幕
	OS.set_current_screen(1)
	OS.window_position=Vector2(0,0)
	
	var size=OS.get_screen_size(-1)
	var dock_width=150  # const
	var win_x=size.y-dock_width # the screen 1 is in portrait mode
	var win_y=win_x*1.0/16*9 # 16:9
	OS.window_size=Vector2(win_x,win_y) 


