class_name MainMenu
extends Control
## Menus de CodeQuest, d'après les maquettes : accueil (invité ou connecté), connexion, création de compte,
## vérification en deux étapes, classement et introduction d'une nouvelle partie.
## Le compte passe par l'autoload Account, dont les réponses sont simulées en attendant l'API.
##
## Accueil invité : jouer en tant qu'invité, se connecter ou créer un compte ; charger et classement grisés.
## Accueil connecté : nouvelle partie, charger la partie en cours, classement, se déconnecter.
## Nouvelle partie et partie invitée passent par l'introduction, puis le jeu commence dans le bunker du hub.

const SCENE := "res://scenes/ui/menus/main_menu.tscn"
const INTRO_TEXT := [
	"En l'an 5814, le royaume de Codia n'est plus qu'un désert ravagé par dix années de guerre contre Vibelandia.",
	"Devlyn, un ancien héros légendaire, reçoit de Merlon, un mystérieux mage, une mission cruciale : retrouver quatre livres anciens capables d'apaiser le Mont Sam Altan et de restaurer les terres.",
	"Pour les retrouver, il devra explorer les ruines de Codia, surmonter des obstacles et résoudre des énigmes.",
]

var _screen: Control
var _current := &""
## Écran d'où vient la vérification en deux étapes, pour que « Retour » y ramène.
var _verify_origin := &"login"
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(Ornate.Backdrop.new())
	GameState.use_profile(Account.profile_id())
	show_screen(&"home")


## Remplace l'écran affiché : home, login, register, verify, leaderboard ou intro.
func show_screen(screen: StringName) -> void:
	if _screen:
		_screen.queue_free()
	_screen = Control.new()
	_screen.name = String(screen).capitalize().replace(" ", "")
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen)
	_current = screen
	_busy = false
	match screen:
		&"home":
			_build_home()
		&"login":
			_build_login()
		&"register":
			_build_register()
		&"verify":
			_build_verify()
		&"leaderboard":
			_build_leaderboard()
		&"intro":
			_build_intro()


func current_screen() -> StringName:
	return _current


func _hex(caption: String, position: Vector2, size: Vector2, icon_kind := "", highlighted := false, font_size := 48) -> Ornate.HexButton:
	var button := Ornate.HexButton.new()
	button.caption = caption
	button.icon_kind = icon_kind
	button.highlighted = highlighted
	button.font_size = font_size
	button.name = caption.validate_node_name().replace(" ", "")
	Ornate.place(_screen, button, position, size)
	return button


func _pill(parent: Control, caption: String, icon_kind: String, position: Vector2, size: Vector2, font_size := 26) -> Ornate.PillButton:
	var button := Ornate.PillButton.new()
	button.caption = caption
	button.icon_kind = icon_kind
	button.font_size = font_size
	button.name = caption.validate_node_name().replace(" ", "")
	Ornate.place(parent, button, position, size)
	return button


func _back_button(target: StringName) -> void:
	_pill(_screen, "Retour", "arrow_left", Vector2(44, 968), Vector2(236, 74), 28).pressed.connect(show_screen.bind(target))


## Texte d'état sous un formulaire : erreur en rouge, information en vert.
func _status(parent: Control, position: Vector2, width: float) -> Label:
	var status := Ornate.label("", 24, Ornate.ERROR)
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(parent, status, position, Vector2(width, 34))
	return status


func _show_status(status: Label, text: String, good := false) -> void:
	status.text = text
	status.add_theme_color_override("font_color", Ornate.SUCCESS if good else Ornate.ERROR)


func _field(parent: Control, icon_kind: String, placeholder: String, position: Vector2, width: float, secret := false) -> Ornate.Field:
	var field := Ornate.Field.new()
	field.icon_kind = icon_kind
	field.placeholder = placeholder
	field.secret = secret
	field.name = placeholder.validate_node_name().replace(" ", "").replace("-", "")
	Ornate.place(parent, field, position, Vector2(width, 84))
	return field


func _centered(parent: Control, text: String, y: float, size: int, serif := false, color := Ornate.CREAM) -> Label:
	var node := Ornate.label(text, size, color, serif)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(parent, node, Vector2(0, y), Vector2(parent.size.x, size * 1.5))
	return node


# --- Accueil ------------------------------------------------------------------------------------------------

func _build_home() -> void:
	GameState.use_profile(Account.profile_id())
	var commands := Ornate.place(_screen, Ornate.Frame.new(), Vector2(58, 172), Vector2(512, 718)) as Ornate.Frame
	commands.title = "Commandes"
	commands.book_bottom = true
	commands.dividers = [Ornate.commands(commands, 108.0, 64.0, 74.0)]
	Ornate.place(_screen, Ornate.Logo.new(), Vector2(640, 40), Vector2(640, 420))
	var logged := Account.is_logged_in()
	var first := _hex("Nouvelle partie" if logged else "Jouer en tant qu'invité", Vector2(632, 492), Vector2(656, 116), "", true, 50 if logged else 44)
	first.name = "NewGame"
	first.pressed.connect(_on_new_game)
	var load_button := _hex("Charger partie", Vector2(632, 632), Vector2(656, 116))
	load_button.name = "LoadGame"
	load_button.disabled = not logged or not GameState.can_continue()
	load_button.pressed.connect(_on_load_game)
	var ranking := _hex("Classement", Vector2(632, 772), Vector2(656, 116))
	ranking.name = "Leaderboard"
	ranking.disabled = not logged
	ranking.pressed.connect(show_screen.bind(&"leaderboard"))
	_build_profile(logged)
	var studio := TextureRect.new()
	studio.texture = Ornate.STUDIO
	studio.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	studio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	Ornate.place(_screen, studio, Vector2(1762, 958), Vector2(118, 104))
	var shortcuts := Ornate.label(Ornate.SHORTCUTS, 22, Ornate.MUTED)
	shortcuts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_screen, shortcuts, Vector2(560, 1012), Vector2(800, 34))
	if not logged:
		var note := Ornate.label("Connectez-vous pour reprendre une partie et figurer au classement.", 22, Ornate.MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(_screen, note, Vector2(560, 920), Vector2(800, 34))


## Carte du joueur, à droite : portrait et déconnexion, ou silhouette et boutons de connexion.
func _build_profile(logged: bool) -> void:
	var card := Ornate.place(_screen, Ornate.Frame.new(), Vector2(1330, 266), Vector2(372, 494)) as Ornate.Frame
	card.name = "Profile"
	if logged:
		card.dividers = [352.0]
		var portrait := TextureRect.new()
		portrait.texture = Ornate.PORTRAIT
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Ornate.place(card, portrait, Vector2(46, 14), Vector2(280, 262))
		var name_label := Ornate.label(Account.pseudo, 50, Ornate.CREAM, true, 8)
		name_label.name = "Pseudo"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(card, name_label, Vector2(0, 272), Vector2(372, 70))
		_pill(card, "Se déconnecter", "logout", Vector2(30, 392), Vector2(312, 70), 23).pressed.connect(_on_logout)
	else:
		card.dividers = [254.0]
		var silhouette := Ornate.IconView.new()
		silhouette.kind = "user"
		silhouette.line_width = 5.0
		Ornate.place(card, silhouette, Vector2(126, 70), Vector2(120, 120))
		_pill(card, "Se connecter", "login", Vector2(30, 300), Vector2(312, 70)).pressed.connect(show_screen.bind(&"login"))
		_pill(card, "Créer un compte", "user_add", Vector2(30, 392), Vector2(312, 70), 24).pressed.connect(show_screen.bind(&"register"))


func _on_new_game() -> void:
	if Account.is_logged_in() and GameState.can_continue():
		_confirm("Une partie est déjà en cours.\nEn commencer une nouvelle effacera sa progression.", "Nouvelle partie", show_screen.bind(&"intro"))
	else:
		show_screen(&"intro")


func _on_load_game() -> void:
	get_tree().change_scene_to_file(GameState.HUB_SCENE)


func _on_logout() -> void:
	Account.logout()
	GameState.use_profile(Account.profile_id())
	show_screen(&"home")


## Fenêtre de confirmation par-dessus l'écran : « Annuler » la ferme, l'autre bouton lance l'action.
func _confirm(text: String, accept: String, action: Callable) -> void:
	var shade := ColorRect.new()
	shade.name = "Confirm"
	shade.color = Color(0.05, 0.02, 0.06, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(shade)
	var frame := Ornate.place(shade, Ornate.Frame.new(), Vector2(560, 360), Vector2(800, 360)) as Ornate.Frame
	frame.title = "Attention"
	var message := Ornate.label(text, 30)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(frame, message, Vector2(50, 80), Vector2(700, 120))
	var cancel := Ornate.HexButton.new()
	cancel.caption = "Annuler"
	cancel.name = "Cancel"
	cancel.font_size = 34
	Ornate.place(frame, cancel, Vector2(60, 240), Vector2(320, 80))
	cancel.pressed.connect(shade.queue_free)
	var ok := Ornate.HexButton.new()
	ok.caption = accept
	ok.name = "Accept"
	ok.font_size = 34
	ok.highlighted = true
	Ornate.place(frame, ok, Vector2(420, 240), Vector2(320, 80))
	ok.pressed.connect(action)


# --- Connexion et création de compte ------------------------------------------------------------------------

func _build_login() -> void:
	var frame := Ornate.place(_screen, Ornate.Frame.new(), Vector2(460, 172), Vector2(1000, 760)) as Ornate.Frame
	frame.title = "Se connecter"
	frame.title_size = 52
	frame.dividers = [560.0]
	var address := _field(frame, "mail", "Adresse e-mail", Vector2(120, 120), 760)
	address.name = "Email"
	var password := _field(frame, "lock", "Mot de passe", Vector2(120, 226), 760, true)
	password.name = "Password"
	var status := _status(frame, Vector2(120, 330), 480)
	var forgot := Ornate.TextLink.new()
	forgot.caption = "Mot de passe oublié ?"
	forgot.name = "Forgot"
	Ornate.place(frame, forgot, Vector2(610, 322), Vector2(270, 44))
	var submit := Ornate.HexButton.new()
	submit.caption = "Se connecter"
	submit.icon_kind = "login"
	submit.name = "Submit"
	submit.highlighted = true
	Ornate.place(frame, submit, Vector2(220, 400), Vector2(560, 104))
	_centered(frame, "Pas encore de compte ?", 590, 28)
	_pill(frame, "Créer un compte", "user_add", Vector2(260, 650), Vector2(480, 76), 28).pressed.connect(show_screen.bind(&"register"))
	_back_button(&"home")
	var attempt := func() -> void:
		if _busy:
			return
		_busy = true
		_show_status(status, "Connexion…", true)
		var result: Dictionary = await Account.login(address.text.strip_edges(), password.text)
		_busy = false
		if not is_instance_valid(status):
			return
		if not result.ok:
			_show_status(status, result.error)
		elif result.get("needs_code", false):
			_verify_origin = &"login"
			show_screen(&"verify")
		else:
			show_screen(&"home")
	submit.pressed.connect(attempt)
	password.line.text_submitted.connect(func(_text: String) -> void: attempt.call())
	address.line.text_submitted.connect(func(_text: String) -> void: password.line.grab_focus())
	forgot.pressed.connect(func() -> void:
		var result: Dictionary = await Account.request_password_reset(address.text.strip_edges())
		if not is_instance_valid(status):
			return
		if result.ok:
			_show_status(status, "Si un compte existe, un e-mail vient d'être envoyé.", true)
		else:
			_show_status(status, result.error))
	address.line.grab_focus.call_deferred()


func _build_register() -> void:
	var frame := Ornate.place(_screen, Ornate.Frame.new(), Vector2(430, 172), Vector2(1060, 760)) as Ornate.Frame
	frame.title = "Créer un compte"
	frame.title_size = 52
	frame.dividers = [620.0]
	var pseudo := _field(frame, "user", "Pseudo", Vector2(150, 110), 760)
	pseudo.name = "Pseudo"
	var address := _field(frame, "mail", "Adresse e-mail", Vector2(150, 214), 760)
	address.name = "Email"
	var password := _field(frame, "lock", "Mot de passe", Vector2(150, 318), 760, true)
	password.name = "Password"
	var status := _status(frame, Vector2(150, 418), 760)
	var submit := Ornate.HexButton.new()
	submit.caption = "Créer un compte"
	submit.icon_kind = "user_add"
	submit.name = "Submit"
	submit.highlighted = true
	Ornate.place(frame, submit, Vector2(200, 470), Vector2(660, 104))
	var already := Ornate.label("Déjà un compte ?", 28)
	Ornate.place(frame, already, Vector2(300, 652), Vector2(240, 44))
	var link := Ornate.TextLink.new()
	link.caption = "Se connecter"
	link.name = "ToLogin"
	link.font_size = 28
	Ornate.place(frame, link, Vector2(540, 650), Vector2(200, 48))
	link.pressed.connect(show_screen.bind(&"login"))
	_back_button(&"home")
	var attempt := func() -> void:
		if _busy:
			return
		_busy = true
		_show_status(status, "Création du compte…", true)
		var result: Dictionary = await Account.register(pseudo.text, address.text.strip_edges(), password.text)
		_busy = false
		if not is_instance_valid(status):
			return
		if not result.ok:
			_show_status(status, result.error)
		else:
			_verify_origin = &"register"
			show_screen(&"verify")
	submit.pressed.connect(attempt)
	pseudo.line.text_submitted.connect(func(_text: String) -> void: address.line.grab_focus())
	address.line.text_submitted.connect(func(_text: String) -> void: password.line.grab_focus())
	password.line.text_submitted.connect(func(_text: String) -> void: attempt.call())
	pseudo.line.grab_focus.call_deferred()


# --- Vérification en deux étapes ----------------------------------------------------------------------------

func _build_verify() -> void:
	var frame := Ornate.place(_screen, Ornate.Frame.new(), Vector2(430, 172), Vector2(1060, 760)) as Ornate.Frame
	frame.title = "Vérification en deux étapes"
	frame.title_size = 46
	frame.dividers = [610.0]
	for item in [["shield_lock", Vector2(470, 70), 120.0], ["laurel_left", Vector2(380, 100), 90.0], ["laurel_right", Vector2(590, 100), 90.0]]:
		var view := Ornate.IconView.new()
		view.kind = item[0]
		view.color = Ornate.GOLD
		view.line_width = 3.5
		Ornate.place(frame, view, item[1], Vector2(item[2], item[2]))
	_centered(frame, "Entrez le code de vérification", 214, 40, true)
	_centered(frame, "Nous avons envoyé un code à votre adresse e-mail.", 280, 26)
	var boxes := Ornate.CodeBoxes.new()
	boxes.name = "Code"
	Ornate.place(frame, boxes, Vector2(160, 340), Vector2(740, 96))
	var status := _status(frame, Vector2(150, 448), 760)
	var submit := Ornate.HexButton.new()
	submit.caption = "Valider"
	submit.icon_kind = "check"
	submit.name = "Submit"
	submit.highlighted = true
	submit.disabled = true
	Ornate.place(frame, submit, Vector2(250, 492), Vector2(560, 100))
	var resend := Ornate.TextLink.new()
	resend.caption = "Renvoyer le code"
	resend.name = "Resend"
	resend.font_size = 28
	Ornate.place(frame, resend, Vector2(410, 640), Vector2(240, 50))
	_back_button(_verify_origin)
	boxes.changed.connect(func() -> void:
		submit.disabled = not boxes.is_complete()
		submit.queue_redraw())
	var attempt := func() -> void:
		if _busy or not boxes.is_complete():
			return
		_busy = true
		_show_status(status, "Vérification…", true)
		var result: Dictionary = await Account.verify_code(boxes.code())
		_busy = false
		if not is_instance_valid(status):
			return
		if result.ok:
			GameState.use_profile(Account.profile_id())
			show_screen(&"home")
		else:
			_show_status(status, result.error)
			boxes.clear()
	submit.pressed.connect(attempt)
	boxes.submitted.connect(attempt)
	resend.pressed.connect(func() -> void:
		var result: Dictionary = await Account.resend_code()
		if is_instance_valid(status):
			_show_status(status, "Un nouveau code vient d'être envoyé." if result.ok else result.error, result.ok))
	boxes.boxes[0].grab_focus.call_deferred()


# --- Classement ---------------------------------------------------------------------------------------------

func _build_leaderboard() -> void:
	var frame := Ornate.place(_screen, Ornate.Frame.new(), Vector2(350, 110), Vector2(1220, 870)) as Ornate.Frame
	frame.title = "Classement"
	frame.title_size = 54
	frame.bottom_diamond = false
	for item in [["laurel_left", Vector2(250, -80)], ["laurel_right", Vector2(860, -80)]]:
		var laurel := Ornate.IconView.new()
		laurel.kind = item[0]
		laurel.color = Ornate.GOLD
		Ornate.place(frame, laurel, item[1], Vector2(110, 110))
	var subtitle := _centered(frame, "Les meilleurs explorateurs de Codia", 70, 30, true)
	subtitle.name = "Subtitle"
	var header := Ornate.place(frame, LeaderboardHeader.new(), Vector2(70, 130), Vector2(1080, 80))
	header.name = "Header"
	var scroll := ScrollContainer.new()
	scroll.name = "Rows"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Ornate.place(frame, scroll, Vector2(76, 226), Vector2(1068, 520))
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	var status := _centered(frame, "Chargement du classement…", 420, 28)
	status.name = "Status"
	_hex("Retour", Vector2(750, 932), Vector2(420, 96), "arrow_left", false, 40).pressed.connect(show_screen.bind(&"home"))
	var result: Dictionary = await Account.fetch_leaderboard()
	if not is_instance_valid(status):
		return
	if not result.ok:
		status.text = result.get("error", "Le classement est indisponible pour l'instant.")
		return
	var entries: Array = result.get("entries", [])
	status.text = "" if not entries.is_empty() else "Aucun temps enregistré pour l'instant.\nRéunissez les quatre livres pour ouvrir le classement."
	if entries.is_empty():
		status.size.y = 100
	for index in entries.size():
		var row := LeaderboardRow.new()
		row.rank = index + 1
		row.pseudo = entries[index].get("pseudo", "?")
		row.seconds = float(entries[index].get("seconds", 0.0))
		row.mine = row.pseudo == Account.pseudo
		row.custom_minimum_size = Vector2(1040, 76 if index < 3 else 62)
		rows.add_child(row)


## Temps au format minutes:secondes, comme le chronomètre.
static func format_time(seconds: float) -> String:
	var total := int(round(seconds))
	return "%02d:%02d" % [total / 60, total % 60]


class LeaderboardHeader:
	extends Control
	## En-tête du classement : rang, joueur et temps réalisé sur la durée de la partie.

	func _draw() -> void:
		var shape := Ornate.hexagon(Rect2(Vector2.ZERO, size), 28)
		var top := Color(0.38, 0.22, 0.1)
		var low := Color(0.22, 0.12, 0.07)
		draw_polygon(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
		draw_polyline(Ornate.closed(shape), Ornate.GOLD, 4.0)
		var y := size.y / 2
		Ornate.centered_text(self, Ornate.SERIF, Vector2(92, y), "#", 32, Ornate.CREAM)
		Ornate.icon(self, "user", Vector2(250, y), 16, Ornate.GOLD_LIGHT, 3.0)
		draw_string(Ornate.SERIF, Vector2(282, y + 12), "Joueur", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Ornate.CREAM)
		Ornate.icon(self, "stopwatch", Vector2(650, y), 18, Ornate.GOLD_LIGHT, 3.0)
		draw_string(Ornate.SERIF, Vector2(684, y + 10), "Temps réalisé", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Ornate.CREAM)
		draw_string(Ornate.TEXT, Vector2(920, y + 10), "(sur %s)" % MainMenu.format_time(GameState.TOTAL_TIME), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Ornate.MUTED)


class LeaderboardRow:
	extends Control
	## Ligne du classement : les trois premiers sur fond or, argent et bronze, avec des lauriers.

	var rank := 1
	var pseudo := ""
	var seconds := 0.0
	var mine := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var medal: Color = [Ornate.GOLD, Ornate.SILVER, Ornate.BRONZE][rank - 1] if rank <= 3 else Ornate.GOLD_DARK
		if rank <= 3:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(medal.darkened(0.55), 0.9)
			box.border_color = medal
			box.set_border_width_all(3)
			box.set_corner_radius_all(10)
			draw_style_box(box, rect)
			Ornate.icon(self, "laurel_left", Vector2(78, size.y / 2), 26, medal, 2.5)
			Ornate.icon(self, "laurel_right", Vector2(110, size.y / 2), 26, medal, 2.5)
		else:
			draw_line(Vector2(10, size.y - 1), Vector2(size.x - 10, size.y - 1), Color(Ornate.GOLD_DARK, 0.7), 1.5)
		if mine:
			draw_rect(rect.grow(-2), Color(Ornate.GOLD_LIGHT, 0.12))
		var font_size := 36 if rank <= 3 else 30
		Ornate.centered_text(self, Ornate.SERIF, Vector2(94, size.y / 2), str(rank), font_size, Ornate.CREAM)
		draw_texture_rect(Ornate.PORTRAIT, Rect2(Vector2(196, size.y / 2 - 26), Vector2(50, 52)), false)
		draw_string(Ornate.SERIF, Vector2(276, size.y / 2 + font_size * 0.36), pseudo, HORIZONTAL_ALIGNMENT_LEFT, 420, font_size, Ornate.CREAM)
		Ornate.centered_text(self, Ornate.SERIF, Vector2(800, size.y / 2), MainMenu.format_time(seconds), font_size, Ornate.CREAM)


# --- Introduction ------------------------------------------------------------------------------------------

func _build_intro() -> void:
	var frame := Ornate.place(_screen, Ornate.Frame.new(), Vector2(360, 108), Vector2(1200, 860)) as Ornate.Frame
	frame.title = "Introduction"
	frame.title_size = 52
	frame.bottom_diamond = false
	var portrait := TextureRect.new()
	portrait.texture = Ornate.PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	Ornate.place(frame, portrait, Vector2(70, 90), Vector2(290, 370))
	var line := Ornate.place(frame, VerticalOrnament.new(), Vector2(380, 90), Vector2(20, 380))
	line.name = "Ornament"
	var story := VBoxContainer.new()
	story.add_theme_constant_override("separation", 12)
	Ornate.place(frame, story, Vector2(430, 92), Vector2(710, 380))
	for paragraph in INTRO_TEXT:
		var text := Ornate.label(paragraph, 25)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(710, 0)
		story.add_child(text)
	var goal_title := Ornate.place(frame, GoalTitle.new(), Vector2(60, 486), Vector2(1080, 80))
	goal_title.name = "GoalTitle"
	var goal := Ornate.place(frame, GoalBox.new(), Vector2(90, 580), Vector2(1020, 150))
	goal.name = "Goal"
	var text := Ornate.label("Retrouver les 4 livres en une heure pour éviter l'éruption du Mont Sam Altan.", 30)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Ornate.place(goal, text, Vector2(200, 20), Vector2(600, 110))
	_hex("Commencer", Vector2(760, 912), Vector2(400, 104), "", true, 46).pressed.connect(_on_begin)
	_back_button(&"home")


func _on_begin() -> void:
	GameState.reset()
	Hints.revealed.clear()
	get_tree().change_scene_to_file(GameState.HUB_SCENE)


class VerticalOrnament:
	extends Control
	func _draw() -> void:
		var x := size.x / 2
		draw_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 1.5, size.y / 2), Vector2(x, size.y), Vector2(x - 1.5, size.y / 2)]),
			PackedColorArray([Color(Ornate.GOLD, 0.0), Ornate.GOLD, Color(Ornate.GOLD, 0.0), Ornate.GOLD]))
		Ornate.diamond(self, Vector2(x, size.y / 2), 12)


class GoalTitle:
	extends Control
	func _draw() -> void:
		Ornate.divider(self, Vector2(40, size.y / 2), Vector2(size.x / 2 - 180, size.y / 2), false)
		Ornate.divider(self, Vector2(size.x / 2 + 180, size.y / 2), Vector2(size.x - 40, size.y / 2), false)
		for x in [size.x / 2 - 196, size.x / 2 + 196]:
			Ornate.diamond(self, Vector2(x, size.y / 2), 10)
		Ornate.plaque(self, size / 2, "But du jeu", 34)


class GoalBox:
	extends Control
	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.17, 0.09, 0.07)
		box.border_color = Ornate.GOLD
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		Ornate.icon(self, "book", Vector2(110, size.y / 2 - 10), 62, Ornate.GOLD_LIGHT)
		Ornate.icon(self, "volcano", Vector2(size.x - 110, size.y / 2 + 6), 70)
