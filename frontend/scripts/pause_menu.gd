extends CanvasLayer
## Menu pause, d'après la maquette : Échap (ou P) fige la partie et le chronomètre ; « Reprendre » relance,
## « Menu principal » sauvegarde et revient à l'accueil. Le panneau rappelle les commandes.
## Il ne s'ouvre que pendant le jeu, quand le joueur a la main : ni dans un menu, ni dans une énigme ouverte,
## ni pendant une cinématique.

var _root: Control
## La souris était capturée à l'image précédente : sur le web, la perte du verrou de la souris (Échap,
## changement d'onglet) ouvre la pause, faute de toujours recevoir la touche.
var _was_captured := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "Pause"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.02, 0.07, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var frame := Ornate.place(_root, Ornate.Frame.new(), Vector2(330, 150), Vector2(1260, 780)) as Ornate.Frame
	frame.title = "Pause"
	frame.title_size = 62
	frame.vertical_dividers = [630.0]
	var resume := Ornate.HexButton.new()
	resume.caption = "Reprendre"
	resume.name = "Resume"
	resume.highlighted = true
	resume.font_size = 50
	Ornate.place(frame, resume, Vector2(56, 240), Vector2(524, 108))
	resume.pressed.connect(close)
	var menu := Ornate.HexButton.new()
	menu.caption = "Menu principal"
	menu.name = "MainMenu"
	menu.font_size = 46
	Ornate.place(frame, menu, Vector2(56, 400), Vector2(524, 108))
	menu.pressed.connect(_on_main_menu)
	var shortcuts := Ornate.label("H : indice     F : plein écran", 22, Ornate.MUTED)
	shortcuts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(frame, shortcuts, Vector2(56, 640), Vector2(524, 34))
	var commands := Ornate.place(frame, Ornate.Frame.new(), Vector2(676, 120), Vector2(530, 590)) as Ornate.Frame
	commands.title = "Commandes"
	commands.title_size = 36
	commands.bottom_diamond = false
	commands.dividers = [Ornate.commands(commands, 70.0, 58.0, 70.0, Vector2(84, 190))]
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _root.visible:
		get_viewport().set_input_as_handled()
		close()
	elif can_open():
		get_viewport().set_input_as_handled()
		open()


func _process(_delta: float) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if OS.has_feature("web") and _was_captured and not captured and not _root.visible and can_open():
		open()
	_was_captured = captured


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not _root.visible and can_open():
		open()


func is_open() -> bool:
	return _root.visible


## Le joueur est dans un niveau et a la main.
func can_open() -> bool:
	var player := active_player(get_tree())
	return player != null and not Hints.is_open()


## Joueur du niveau en cours, s'il a la main : aucun menu, énigme ou cinématique en cours.
static func active_player(tree: SceneTree) -> Player:
	var scene := tree.current_scene
	if tree.paused or not scene or not scene.has_node("Player"):
		return null
	var player := scene.get_node("Player") as Player
	if not player or player.process_mode == Node.PROCESS_MODE_DISABLED:
		return null
	return player


func open() -> void:
	_root.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_root.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_was_captured = true


func _on_main_menu() -> void:
	_root.hide()
	GameState.save_game()
	# Partie connectée : la position part au serveur, dont le chronomètre s'arrête dans le menu.
	GameSync.save_position()
	Transition.change_scene(MainMenu.SCENE)
