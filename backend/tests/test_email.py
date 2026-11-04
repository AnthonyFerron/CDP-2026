import smtplib

import pytest
from pydantic import SecretStr

from app.core.config import Settings
from app.core.errors import ServiceUnavailableError
from app.main import app
from app.services.email import SmtpEmailSender, get_email_sender

from conftest import DEFAULT_PASSWORD


class FakeSMTP:
    instances: list["FakeSMTP"] = []

    def __init__(self, host, port, timeout):
        self.host, self.port, self.timeout = host, port, timeout
        self.calls: list[str] = []
        self.sent = []
        FakeSMTP.instances.append(self)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def starttls(self, context):
        self.calls.append("starttls")

    def login(self, username, password):
        self.calls.append(f"login:{username}:{password}")

    def send_message(self, message):
        self.sent.append(message)


def smtp_settings(**overrides) -> Settings:
    values = {
        "database_url": "postgresql+psycopg://u:p@localhost/x",
        "email_backend": "smtp",
        "smtp_host": "smtp.example.com",
        "smtp_port": 587,
        "smtp_username": "jeu",
        "smtp_password": SecretStr("mot-de-passe-smtp"),
        "email_from": "CodeQuest <no-reply@example.com>",
    }
    values.update(overrides)
    return Settings(**values)


def test_smtp_sender_uses_starttls_and_credentials(monkeypatch):
    FakeSMTP.instances.clear()
    monkeypatch.setattr(smtplib, "SMTP", FakeSMTP)

    SmtpEmailSender(smtp_settings()).send("devlyn@example.com", "Sujet", "Corps 123456")

    client = FakeSMTP.instances[0]
    assert (client.host, client.port) == ("smtp.example.com", 587)
    assert client.calls == ["starttls", "login:jeu:mot-de-passe-smtp"]
    message = client.sent[0]
    assert message["To"] == "devlyn@example.com"
    assert message["From"] == "CodeQuest <no-reply@example.com>"
    assert "123456" in message.get_content()


def test_unconfigured_smtp_is_reported_clearly():
    with pytest.raises(ServiceUnavailableError):
        SmtpEmailSender(smtp_settings(smtp_host="")).send("devlyn@example.com", "Sujet", "Corps")


class BrokenSender:
    def send(self, to, subject, body):
        raise smtplib.SMTPServerDisconnected("connexion perdue")


def test_login_reports_email_failures(api):
    api.register(email="devlyn@example.com")
    app.dependency_overrides[get_email_sender] = lambda: BrokenSender()

    response = api.client.post(
        "/api/v1/auth-challenges", json={"email": "devlyn@example.com", "password": DEFAULT_PASSWORD}
    )

    assert response.status_code == 503
