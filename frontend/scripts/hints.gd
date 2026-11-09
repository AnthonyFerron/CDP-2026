extends CanvasLayer
## Indices, d'après la maquette : H ouvre la fenêtre « Indice » pendant le jeu, et la partie se fige le temps
## de la lire. Chaque zone a trois indices, de plus en plus précis sans jamais donner la solution : chaque
## nouvelle ouverture en révèle un de plus. Au hub, l'indice dit simplement où aller. À partir du troisième,
## des flèches (souris, flèches du clavier, Q et D, croix de la manette) font relire les précédents, sans rien révéler
## de plus. À la manette : Y ouvre et referme, B ou A sur « Fermer » referme.

## Indices de chaque zone, du plus vague au plus précis.
const ZONE_HINTS := {
	&"plaine": [
		"Six fragments de la conversation sont cachés dans des livres de la bibliothèque, sous les ruines. Sur les étagères, cherchez les livres qui dépassent de leur rangée, un signet pendu sous eux. La lettre posée sur la table de lecture explique la tablette.",
		"La conversation suit les étapes d'un projet : on définit d'abord ce qu'il faut faire et pourquoi, puis on prépare, on organise et on suit le travail. Les notes du greffier, dans le scriptorium, le rappellent : chacun parle à son tour.",
		"La bibliothécaire ouvre la discussion en parlant d'organiser la restauration. L'employé la conclut : vérifier le travail, puis clôturer le projet.",
	],
	&"desert": [
		"Des runes sont posées dans les salles du monument, parmi les débris au-dehors et dans la cave. D'autres sont enfouies : maintenez E devant un tas de sable pour le dégager. Certains tas sont vides.",
		"Dans la cave, chaque mur porte un algorithme incomplet. L'un répète une action tant que la jarre n'est pas pleine ; l'autre pose une question avant d'ouvrir la porte. Les écrits laissés au monument, à l'oasis, aux tombes et sur le pupitre de la cave aident à les compléter.",
		"Deux runes ne servent à aucun des deux algorithmes : ce sont des leurres. Une boucle s'ouvre par « TANT QUE », une condition par « SI » et se poursuit par « SINON ».",
	],
	&"marais": [
		"Suivez les pontons et leurs lanternes jusqu'à la crypte, au nord. En bas du long escalier, lisez l'inscription gravée sur le mur face au mécanisme, puis les épitaphes des rois, dans la chambre funéraire de l'ouest.",
		"Le mot à inscrire part du nom du royaume. Chaque lettre se décale dans l'alphabet : trois en avant, puis trois en arrière, et ainsi de suite. L'ardoise d'Ada, au cimetière, montre la méthode sur un autre mot.",
		"Le royaume s'appelle Codia. Sa première lettre, C, avance de trois ; la deuxième, O, recule de trois. Réglez les cercles du centre vers l'extérieur.",
	],
	&"village": [
		"Dix fragments de papier, deux par langage, sont cachés dans la mairie : au rez-de-chaussée et dans le bureau du maire, à l'étage. Ouvrez tiroirs, armoires et coffres, et relisez-les avec I.",
		"Les cinq codes du bureau se résolvent dans l'ordre. Lisez chaque programme ligne par ligne, en notant la valeur de chaque variable à chaque étape, comme sur l'ardoise de l'écolier, dans la maison voisine de la mairie.",
		"Un commentaire HTML ne s'affiche pas. En CSS, un identifiant l'emporte sur une classe. Pour les autres, suivez chaque condition et chaque boucle pas à pas : le registre du sergent, au corps de garde, rappelle ce qu'est un nombre pair.",
	],
}
## Sens de chaque portail depuis la place du village.
const PORTAL_DIRECTIONS := {&"plaine": "nord-ouest", &"desert": "nord-est", &"marais": "sud-est", &"village": "sud-ouest"}
const ZONE_NAMES := {&"plaine": "les plaines d'Hexcole", &"desert": "le désert de Pythania", &"marais": "les marais de Kernel Swamp", &"village": "le village détruit"}

## Nombre d'indices donnés à partir duquel les flèches permettent de relire les précédents.
const BROWSE_FROM := 3

## Indices déjà révélés dans chaque zone, pour la partie en cours.
var revealed := {}

var _root: Control
var _body: Label
var _counter: Label
var _previous: ArrowButton
var _next: ArrowButton
## Indices révélés à cette ouverture, et celui qui est affiché : les flèches le changent sans rien révéler.
var _shown: Array[String] = []
var _index := 0
var _total := 0


func _ready() -> void:
	layer = 41
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "Hint"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.02, 0.07, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var frame := Ornate.place(_root, Ornate.Frame.new(), Vector2(330, 220), Vector2(1260, 660)) as Ornate.Frame
	frame.title = "Indice"
	frame.title_size = 58
	frame.bottom_diamond = false
	frame.dividers = [80.0, 520.0]
	frame.vertical_dividers = [420.0]
	var bulb := Ornate.IconView.new()
	bulb.kind = "bulb"
	bulb.color = Ornate.GOLD
	bulb.line_width = 3.5
	Ornate.place(frame, bulb, Vector2(570, -190), Vector2(120, 120))
	var book := Ornate.IconView.new()
	book.kind = "question_book"
	book.color = Ornate.GOLD
	Ornate.place(frame, book, Vector2(80, 130), Vector2(280, 280))
	_body = Ornate.label("", 30)
	_body.name = "Body"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Ornate.place(frame, _body, Vector2(460, 104), Vector2(740, 350))
	_counter = Ornate.label("", 22, Ornate.MUTED)
	_counter.name = "Counter"
	Ornate.place(frame, _counter, Vector2(460, 462), Vector2(740, 34))
	# Flèches « précédent » et « suivant », au bout de la ligne du compteur.
	_previous = ArrowButton.new()
	_previous.name = "Previous"
	_previous.kind = "arrow_left"
	Ornate.place(frame, _previous, Vector2(1066, 450), Vector2(64, 50))
	_previous.pressed.connect(browse.bind(-1))
	_next = ArrowButton.new()
	_next.name = "Next"
	_next.kind = "arrow_right"
	Ornate.place(frame, _next, Vector2(1138, 450), Vector2(64, 50))
	_next.pressed.connect(browse.bind(1))
	var close_button := CloseButton.new()
	close_button.name = "Close"
	Ornate.place(frame, close_button, Vector2(1196, -36), Vector2(92, 92))
	close_button.pressed.connect(close)
	var done := Ornate.HexButton.new()
	done.caption = "Fermer"
	done.name = "Done"
	done.highlighted = true
	done.font_size = 44
	Ornate.place(frame, done, Vector2(430, 610), Vector2(400, 96))
	done.pressed.connect(close)
	_root.hide()
	# Parchemin et clochette à l'ouverture, parchemin replié à la fermeture (scripts/ui_sounds.gd).
	UiSounds.watch(_root)
	# Les touches citées (« rouvrez avec H ») suivent la manette ou le clavier.
	Gamepad.watch(func(_pad: bool) -> void:
		if _root.visible:
			_show(_index))


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("hint") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
	elif _root.visible and _previous.visible and (event.is_action_pressed("ui_left") or event.is_action_pressed("move_left")):
		get_viewport().set_input_as_handled()
		browse(-1)
	elif _root.visible and _previous.visible and (event.is_action_pressed("ui_right") or event.is_action_pressed("move_right")):
		get_viewport().set_input_as_handled()
		browse(1)
	elif not _root.visible and event.is_action_pressed("hint") and PauseMenu.active_player(get_tree()) != null:
		get_viewport().set_input_as_handled()
		open()


func is_open() -> bool:
	return _root.visible


## Zone du niveau en cours, d'après sa scène : plaine, desert, marais, village, ou hub.
func current_zone() -> StringName:
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene else ""
	for zone: StringName in ZONE_HINTS:
		if path.contains("/%s/" % zone):
			return zone
	return &"hub"


## Indices à montrer, en en révélant un de plus à chaque appel.
func next_hints(zone: StringName) -> Array[String]:
	var result: Array[String] = []
	if zone == &"hub":
		result.append(_hub_hint())
		return result
	var all: Array = ZONE_HINTS[zone]
	revealed[zone] = mini(int(revealed.get(zone, 0)) + 1, all.size())
	for index in revealed[zone]:
		result.append(all[index])
	return result


func open() -> void:
	var zone := current_zone()
	_shown = next_hints(zone)
	_total = 0 if zone == &"hub" else ZONE_HINTS[zone].size()
	# Le dernier indice révélé s'affiche d'abord : il précise les précédents. À partir du troisième, les
	# flèches permettent de relire les précédents, sans en révéler de nouveau.
	_previous.visible = _total > 0 and _shown.size() >= BROWSE_FROM
	_next.visible = _previous.visible
	_show(_shown.size() - 1)
	_root.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Affiche l'indice précédent (-1) ou le suivant (+1) parmi ceux déjà révélés.
func browse(step: int) -> void:
	if _root.visible and _previous.visible:
		_show(clampi(_index + step, 0, _shown.size() - 1))


func _show(index: int) -> void:
	_index = index
	_body.text = Gamepad.adapt(_shown[index])
	var reopen := Gamepad.button_name(&"hint") if Gamepad.active else "H"
	_counter.text = "" if _total == 0 else "Indice %d sur %d" % [index + 1, _total] \
		+ ("  ·  rouvrez avec %s pour un indice plus précis" % reopen if _shown.size() < _total else "")
	_previous.disabled = index <= 0
	_next.disabled = index >= _shown.size() - 1
	_previous.queue_redraw()
	_next.queue_redraw()


func close() -> void:
	_root.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _hub_hint() -> String:
	if not GameState.intro_done:
		return "Parlez au roi Codeon V et à Merlon, dans le bunker : ils vous confieront la mission avant que vous ne remontiez à la surface."
	var carried := GameState.carried_books()
	if not carried.is_empty():
		return "Vous portez %s. Posez-le sur son piédestal, autour du cercle magique de la salle du trône, au fond du donjon du château, au nord du village." % GameState.BOOK_NAMES[carried.back()]
	if GameState.placed_books.size() >= GameState.BOOK_COUNT:
		return "Les quatre livres sont réunis et Codia renaît. Explorez le royaume à votre guise : tous les portails sont ouverts."
	for zone in GameState.ZONE_ORDER:
		if not GameState.has_book(GameState.ZONE_BOOKS[zone]):
			return "Le prochain livre se trouve dans %s. Son portail vous attend au %s du village." % [ZONE_NAMES[zone], PORTAL_DIRECTIONS[zone]]
	return "Rapportez chaque livre au château."


class CloseButton:
	extends Button
	## Bouton de fermeture : un octogone doré et une croix.

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		# Un seul maillage pour le fond, le bord et la croix (Ornate.Sketch).
		var pen := Ornate.Sketch.new(self)
		var shape := Ornate.chamfered(Rect2(Vector2.ZERO, size), size.x * 0.28)
		var lit := Gamepad.hovered(self)
		pen.polygon(shape, Color(0.36, 0.2, 0.09) if lit else Color(0.22, 0.12, 0.08))
		pen.polyline(Ornate.closed(shape), Ornate.GOLD_LIGHT if lit else Ornate.GOLD, 5.0)
		Ornate.icon(pen, "close", size / 2, size.x * 0.3, Ornate.CREAM, 3.5)
		pen.draw(self)


class ArrowButton:
	extends Button
	## Flèche dessinée pour parcourir les indices, dans le style du bouton de fermeture ; grise au bout de la liste.

	var kind := "arrow_left"

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var shape := Ornate.chamfered(Rect2(Vector2.ZERO, size), size.y * 0.28)
		var lit := Gamepad.hovered(self) and not disabled
		var fill := Color(0.24, 0.22, 0.24) if disabled else (Color(0.36, 0.2, 0.09) if lit else Color(0.22, 0.12, 0.08))
		var border := Color(0.62, 0.62, 0.64) if disabled else (Ornate.GOLD_LIGHT if lit else Ornate.GOLD)
		var pen := Ornate.Sketch.new(self)
		pen.polygon(shape, fill)
		pen.polyline(Ornate.closed(shape), border, 3.0)
		Ornate.icon(pen, kind, size / 2, size.y * 0.36, Color(0.6, 0.58, 0.58) if disabled else Ornate.CREAM, 3.0)
		pen.draw(self)
