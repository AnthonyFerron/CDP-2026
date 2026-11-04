REPLACEMENTS = [
('	material.albedo_color = Color(0.65, 0.88, 1.0, 0.7)', '	material.albedo_color = Color(0.5, 0.78, 1.0, 0.4)'),
('''		return "Vous portez %s. Posez-le sur son piédestal, dans la salle du trône, au cœur des ruines du château, au nord." % " et ".join(names)''',
 '''		return "Vous portez %s : posez-le dans la salle du trône du château, au nord." % " et ".join(names)'''),
('	camera.look_at(center + Vector3(1.0, -1.4, 1.0))', '	camera.look_at(center + Vector3(0.8, -1.8, 1.2))'),
]
