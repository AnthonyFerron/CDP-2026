# Faux serveur SMTP pour les tests fonctionnels du jeu (frontend/tests/run_tests.gd).
# Pour chaque destinataire, il ajoute le code de connexion reçu à <MAIL_DIR>/<adresse>.log, un code par ligne.
#
#   pip install aiosmtpd
#   MAIL_DIR=/tmp/mail python frontend/tests/mailsink.py
#
# L'API de test l'utilise avec EMAIL_BACKEND=smtp, SMTP_HOST=<hôte>, SMTP_PORT=1025, SMTP_SECURITY=none.

import asyncio, email, os, re
from email import policy
from aiosmtpd.controller import Controller

MAIL_DIR = os.environ.get("MAIL_DIR", "/mail")

class Handler:
    async def handle_DATA(self, server, session, envelope):
        message = email.message_from_bytes(envelope.content, policy=policy.default)
        body = message.get_body(preferencelist=("plain",)).get_content()
        match = re.search(r"code de connexion : (\d{6})", body)
        for recipient in envelope.rcpt_tos:
            with open(os.path.join(MAIL_DIR, f"{recipient}.log"), "a") as log:
                log.write((match.group(1) if match else "?") + "\n")
        return "250 OK"

controller = Controller(Handler(), hostname="0.0.0.0", port=1025)
controller.start()
print("SMTP de test prêt", flush=True)
asyncio.new_event_loop().run_forever()
