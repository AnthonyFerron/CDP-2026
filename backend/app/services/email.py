"""Envoi des e-mails : SMTP en production, console en développement, mémoire dans les tests."""

import logging
import smtplib
import ssl
from dataclasses import dataclass, field
from email.message import EmailMessage
from functools import lru_cache
from typing import Protocol

from app.core.config import Settings, get_settings
from app.core.errors import ServiceUnavailableError

logger = logging.getLogger(__name__)


class EmailSender(Protocol):
    def send(self, to: str, subject: str, body: str) -> None: ...


class ConsoleEmailSender:
    """Écrit l'e-mail dans les logs. Réservé au développement : le code 2FA y apparaît en clair."""

    def send(self, to: str, subject: str, body: str) -> None:
        logger.warning("EMAIL_BACKEND=console (développement uniquement) — e-mail pour %s\n%s\n%s", to, subject, body)


@dataclass
class SentEmail:
    to: str
    subject: str
    body: str


@dataclass
class MemoryEmailSender:
    """Garde les e-mails en mémoire, pour que les tests lisent les codes envoyés."""

    outbox: list[SentEmail] = field(default_factory=list)

    def send(self, to: str, subject: str, body: str) -> None:
        self.outbox.append(SentEmail(to, subject, body))


class SmtpEmailSender:
    def __init__(self, settings: Settings):
        self._settings = settings

    def send(self, to: str, subject: str, body: str) -> None:
        s = self._settings
        if not s.smtp_host:
            logger.error("EMAIL_BACKEND=smtp mais SMTP_HOST est vide : aucun e-mail ne peut partir.")
            raise ServiceUnavailableError("L'envoi d'e-mails n'est pas encore configuré sur le serveur.")
        message = EmailMessage()
        message["From"] = s.email_from
        message["To"] = to
        message["Subject"] = subject
        message.set_content(body)

        context = ssl.create_default_context()
        if s.smtp_security == "ssl":
            client = smtplib.SMTP_SSL(s.smtp_host, s.smtp_port, timeout=s.smtp_timeout_seconds, context=context)
        else:
            client = smtplib.SMTP(s.smtp_host, s.smtp_port, timeout=s.smtp_timeout_seconds)
        with client:
            if s.smtp_security == "starttls":
                client.starttls(context=context)
            if s.smtp_username:
                client.login(s.smtp_username, s.smtp_password.get_secret_value())
            client.send_message(message)


@lru_cache
def get_email_sender() -> EmailSender:
    settings = get_settings()
    if settings.email_backend == "smtp":
        return SmtpEmailSender(settings)
    if settings.email_backend == "memory":
        return MemoryEmailSender()
    return ConsoleEmailSender()


def send_login_code(sender: EmailSender, to: str, username: str, code: str, ttl_seconds: int) -> None:
    minutes = ttl_seconds // 60
    body = (
        f"Bonjour {username},\n\n"
        f"Voici votre code de connexion : {code}\n\n"
        f"Il est valable {minutes} minutes et ne peut servir qu'une fois.\n"
        "Si vous n'avez pas demandé à vous connecter, ignorez cet e-mail : "
        "sans ce code, personne ne peut accéder à votre compte.\n"
    )
    sender.send(to, f"Votre code de connexion : {code}", body)
