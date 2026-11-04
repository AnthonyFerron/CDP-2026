REPLACEMENTS = [
('''			pedestal.prompt = "Piédestal de %s" % _book_name(zone)''', '''			pedestal.prompt = "Piédestal %s" % _of(_book_name(zone))'''),
('''## Première lettre en majuscule, sans toucher au reste (String.capitalize changerait « d'Hexcole »).''',
 '''## « de » contracté devant un nom de livre : « du Projenomicon », « de l'Algonicon ».
static func _of(name: String) -> String:
	if name.begins_with("le "):
		return "du " + name.substr(3)
	if name.begins_with("les "):
		return "des " + name.substr(4)
	return "de " + name


## Première lettre en majuscule, sans toucher au reste (String.capitalize changerait « d'Hexcole »).'''),
]
