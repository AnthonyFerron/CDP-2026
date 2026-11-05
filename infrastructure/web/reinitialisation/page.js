// Page « nouveau mot de passe » : lit le jeton du lien reçu par e-mail, puis appelle
// POST /api/v1/password-resets/confirmations (même domaine, servi par Caddy).
//
// Le jeton est retiré de la barre d'adresse dès la lecture, pour ne rester ni dans l'historique ni dans un
// lien copié. Il est gardé pour cet onglet seulement (sessionStorage), afin qu'un rechargement ne le perde pas,
// et effacé dès qu'il a servi ou qu'il est refusé. Il n'est jamais écrit dans la console.
"use strict";

(function () {
	const API = "/api/v1/password-resets/confirmations";
	const STORE = "codequest-reinitialisation";
	const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;
	// Règles du serveur (backend/app/schemas/users.py), les mêmes qu'à l'inscription.
	const MIN = 8;
	const MAX = 128;

	const form = document.getElementById("form");
	const password = document.getElementById("password");
	const confirmation = document.getElementById("confirmation");
	const show = document.getElementById("show");
	const submit = document.getElementById("submit");
	const status = document.getElementById("status");
	const after = document.getElementById("after");
	const back = document.getElementById("back");
	const title = document.getElementById("title");

	function remember(value) {
		try {
			if (value) {
				sessionStorage.setItem(STORE, value);
			} else {
				sessionStorage.removeItem(STORE);
			}
		} catch (error) {
			// Stockage indisponible (navigation privée) : le jeton reste seulement en mémoire.
		}
	}

	function recall() {
		try {
			return sessionStorage.getItem(STORE) || "";
		} catch (error) {
			return "";
		}
	}

	function readToken() {
		const params = new URLSearchParams(window.location.search);
		const fromUrl = params.get("token");
		if (fromUrl !== null) {
			// Retire le jeton de l'adresse, en gardant le reste.
			params.delete("token");
			const query = params.toString();
			window.history.replaceState(null, "", window.location.pathname + (query ? "?" + query : ""));
			remember(fromUrl.trim());
			return fromUrl.trim();
		}
		return recall();
	}

	function say(message, kind) {
		status.textContent = message;
		status.className = "status" + (kind ? " " + kind : "");
	}

	// Fin du parcours : le formulaire disparaît, il reste le message et le retour au jeu.
	function finish(heading, message, kind) {
		remember("");
		form.hidden = true;
		title.firstElementChild.textContent = heading;
		say(message, kind);
		after.hidden = kind === "success";
		back.hidden = false;
		back.focus();
	}

	function localProblem(first, second) {
		const length = Array.from(first).length;
		if (length < MIN || length > MAX) {
			return "Le mot de passe doit compter de " + MIN + " à " + MAX + " caractères.";
		}
		if (!/\p{L}/u.test(first) || !/\p{Nd}/u.test(first)) {
			return "Le mot de passe doit contenir au moins une lettre et un chiffre.";
		}
		if (first !== second) {
			return "Les deux mots de passe ne correspondent pas.";
		}
		return "";
	}

	// Erreur de validation de FastAPI (422) : une liste d'erreurs par champ.
	function validationMessage(detail) {
		if (!Array.isArray(detail)) {
			return "Ce mot de passe n'est pas accepté.";
		}
		for (const item of detail) {
			const field = Array.isArray(item.loc) ? item.loc[item.loc.length - 1] : "";
			const message = typeof item.msg === "string" ? item.msg : "";
			if (message.startsWith("Value error, ")) {
				return message.slice("Value error, ".length);
			}
			if (field === "password") {
				return "Le mot de passe doit compter de " + MIN + " à " + MAX + " caractères.";
			}
			if (field === "token") {
				return "Ce lien de réinitialisation n'est pas valide. Demandez-en un nouveau depuis le jeu.";
			}
		}
		return "Ce mot de passe n'est pas accepté.";
	}

	async function send(token, newPassword) {
		let response;
		try {
			response = await fetch(API, {
				method: "POST",
				headers: { "Content-Type": "application/json", "Accept": "application/json" },
				body: JSON.stringify({ token: token, password: newPassword }),
				credentials: "omit",
				cache: "no-store",
				referrerPolicy: "no-referrer",
			});
		} catch (error) {
			return { kind: "retry", message: "Impossible de joindre le serveur. Vérifiez votre connexion, puis réessayez." };
		}
		let data = null;
		try {
			data = await response.json();
		} catch (error) {
			data = null;
		}
		const detail = data && data.detail;
		if (response.ok) {
			return { kind: "done", message: (data && data.message) || "Votre mot de passe a été modifié." };
		}
		if (response.status === 400) {
			return { kind: "dead", message: typeof detail === "string" ? detail : "Ce lien n'est plus valable." };
		}
		if (response.status === 422) {
			return { kind: "retry", message: validationMessage(detail) };
		}
		if (response.status === 429) {
			return { kind: "retry", message: "Trop de tentatives\u00a0: patientez un peu avant de réessayer." };
		}
		return { kind: "retry", message: "Le serveur est momentanément indisponible. Réessayez dans quelques instants." };
	}

	const token = readToken();
	if (!token || !JWT_SHAPE.test(token)) {
		finish(
			"Lien incomplet",
			"Ce lien de réinitialisation est incomplet ou abîmé. Ouvrez le lien de l'e-mail en entier, "
				+ "ou demandez-en un nouveau depuis le jeu.",
			"error",
		);
		return;
	}

	form.hidden = false;
	password.focus();

	show.addEventListener("change", function () {
		const type = show.checked ? "text" : "password";
		password.type = type;
		confirmation.type = type;
	});

	form.addEventListener("submit", async function (event) {
		event.preventDefault();
		if (submit.disabled) {
			return;
		}
		const problem = localProblem(password.value, confirmation.value);
		if (problem) {
			say(problem, "error");
			(problem.includes("correspondent") ? confirmation : password).focus();
			return;
		}
		submit.disabled = true;
		submit.firstElementChild.textContent = "Enregistrement…";
		say("", "");
		const result = await send(token, password.value);
		submit.disabled = false;
		submit.firstElementChild.textContent = "Enregistrer";
		if (result.kind === "done") {
			password.value = "";
			confirmation.value = "";
			finish("Mot de passe modifié", result.message, "success");
		} else if (result.kind === "dead") {
			finish("Lien non valable", result.message, "error");
		} else {
			say(result.message, "error");
		}
	});
})();
