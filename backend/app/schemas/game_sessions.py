import math
from datetime import datetime
from typing import Annotated, Literal

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, field_validator, model_validator

from app.schemas.common import DbId

Level = Literal["hub", "plaine", "desert", "marais", "village"]
GameStatus = Literal["in_progress", "completed", "game_over", "abandoned"]


def normalize_angle(value: float) -> float:
    return math.remainder(value, math.tau)


Coordinate = Annotated[float, Field(ge=-10_000, le=10_000, allow_inf_nan=False)]
Rotation = Annotated[
    float,
    Field(
        ge=-1_000,
        le=1_000,
        allow_inf_nan=False,
        description="Orientation du joueur autour de l'axe Y, en radians. Ramenée entre -π et π.",
    ),
    AfterValidator(normalize_angle),
]


class PlayerState(BaseModel):
    """Niveau et position du joueur, tels que Godot les connaît."""

    model_config = ConfigDict(extra="forbid")

    current_level: Level = "hub"
    position_x: Coordinate = 0.0
    position_y: Coordinate = 0.0
    position_z: Coordinate = 0.0
    rotation_y: Rotation = 0.0


class GameSessionCreate(PlayerState):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [{"current_level": "hub", "position_x": 0.0, "position_y": 1.0, "position_z": 4.5, "rotation_y": 0.0}]
        },
    )


class GameSessionUpdate(BaseModel):
    """Sauvegarde : seuls le niveau et la position sont modifiables par le client."""

    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [{"current_level": "desert", "position_x": 12.5, "position_y": 0.0, "position_z": -3.2, "rotation_y": 1.57}]
        },
    )

    current_level: Level | None = None
    position_x: Coordinate | None = None
    position_y: Coordinate | None = None
    position_z: Coordinate | None = None
    rotation_y: Rotation | None = None

    @model_validator(mode="after")
    def _check_fields(self) -> "GameSessionUpdate":
        if not self.model_fields_set:
            raise ValueError("Indiquez au moins un champ à sauvegarder.")
        for name in self.model_fields_set:
            if getattr(self, name) is None:
                raise ValueError(f"Le champ {name} ne peut pas être null.")
        return self


class CompletionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra={"examples": [{"placed_puzzle_ids": [1, 2, 3, 4]}]})

    placed_puzzle_ids: list[DbId] = Field(
        min_length=1,
        max_length=50,
        description="Identifiants des énigmes dont le livre a été posé sur son piédestal, au château.",
    )

    @field_validator("placed_puzzle_ids")
    @classmethod
    def _unique(cls, value: list[int]) -> list[int]:
        if len(set(value)) != len(value):
            raise ValueError("Un même livre ne peut pas être posé deux fois.")
        return value


class GameSessionRead(BaseModel):
    id_game_sessions: int
    status: GameStatus
    current_level: str
    position_x: float
    position_y: float
    position_z: float
    rotation_y: float
    started_at: datetime
    last_saved_at: datetime
    finished_at: datetime | None
    elapsed_seconds: float = Field(description="Temps de jeu consommé, pauses exclues et pénalités incluses, calculé par le serveur.")
    remaining_seconds: float = Field(description="Temps restant avant l'éruption, à afficher dans Godot.")
    duration_seconds: int = Field(description="Durée totale d'une partie.")
    is_paused: bool = Field(description="Vrai si la partie est en cours et que son chronomètre est arrêté.")
    is_rankable: bool = Field(
        description="Vrai si la partie peut encore figurer (ou figure) au classement : déroulement entièrement "
        "chronométré par le serveur, sans import ni résolution invraisemblable."
    )


class ImportedPuzzle(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id_puzzles: DbId
    hints_used: int = Field(default=0, ge=0, le=100)


class GameImportRequest(PlayerState):
    """Progression d'un invité, lue dans la sauvegarde locale de Godot."""

    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "status": "in_progress",
                    "elapsed_seconds": 1250.5,
                    "current_level": "hub",
                    "position_x": 0.0,
                    "position_y": 1.0,
                    "position_z": 4.5,
                    "rotation_y": 0.0,
                    "solved_puzzles": [{"id_puzzles": 1, "hints_used": 1}, {"id_puzzles": 2, "hints_used": 0}],
                }
            ]
        },
    )

    status: Literal["in_progress", "completed", "game_over"]
    elapsed_seconds: float = Field(ge=0, le=86_400, allow_inf_nan=False, description="Temps consommé, en secondes.")
    solved_puzzles: list[ImportedPuzzle] = Field(default_factory=list, max_length=50)

    @field_validator("solved_puzzles")
    @classmethod
    def _unique(cls, value: list[ImportedPuzzle]) -> list[ImportedPuzzle]:
        ids = [puzzle.id_puzzles for puzzle in value]
        if len(set(ids)) != len(ids):
            raise ValueError("Une énigme ne peut apparaître qu'une fois.")
        return value
