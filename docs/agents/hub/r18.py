REPLACEMENTS = [
('''        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
        groups = list(''', '''        lines += [f'[node name="{self.root_name}" type="Node3D"]']
        if self.root_script:
            lines.append(f'script = ExtResource("{self.scripts[self.root_script]}")')
        lines.append("")
        groups = list('''),
('''        self.pivots = {}
        self.scripts = {}
''', '''        self.pivots = {}
        self.scripts = {}
        self.root_script = None

    def batched(self, script):
        """Script de la racine qui regroupe les modèles de chaque groupe en MultiMesh au chargement."""
        self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.root_script = script
'''),
('''    scene = StagedScene("HubProps")
    build_camp(scene)''', '''    scene = StagedScene("HubProps")
    scene.batched("res://scenes/levels/hub/hub_batch.gd")
    build_camp(scene)'''),
]
