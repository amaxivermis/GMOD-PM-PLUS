extends FoldableContainer

signal add_texture_group(index: int)
signal remove_texture_group(index: int)

@onready var skins: ItemList = $VBoxContainer/Skins

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_add_pressed() -> void:
	add_group()
	#ModelEditor.undo_manager.create_action("Add new texture group")
	#ModelEditor.undo_manager.add_do_method(add_group)
	#ModelEditor.undo_manager.add_undo_method(Callable(self, remove_group.get_method()).bind(skins.item_count))
	#ModelEditor.undo_manager.commit_action()

func add_group():
	add_texture_group.emit(skins.item_count)
	skins.add_item("Alt " + str(skins.item_count), load("res://user_interface/icons/material_icon.png") )

func remove_group(index):
	remove_texture_group.emit(index)
	skins.remove_item(index)

func _on_remove_pressed() -> void:
	remove_group(skins.get_selected_items()[0])
	#ModelEditor.undo_manager.create_action("Remove texture group")
	#ModelEditor.undo_manager.add_do_method(remove_group.bind(skins.get_selected_items()[0]))
	#ModelEditor.undo_manager.add_undo_method(Callable(self, add_group.get_method()))
	#ModelEditor.undo_manager.commit_action()

func _on_skins_item_selected(index: int) -> void:
	$VBoxContainer/Controls/Remove.disabled = (index == 0)
