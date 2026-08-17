from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
source = root / "Lista de Retos y Preguntas.txt"
target = root / "flutter_app" / "lib" / "imported_adult_content.dart"

heading_map = {
    "PAREJAS – ATREVIDO": "pareja_atrevido",
    "PAREJAS – EXTREMO": "pareja_extremo",
    "FIESTA – ATREVIDO": "fiesta_atrevido",
    "FIESTA – EXTREMO": "fiesta_extremo",
}
blocked = (
    "sin que lo sepamos", "sin protección", "asfix", "respiración",
    "infecciones", "embarazo", "mientras otros miraban", "te graben",
    "grabar (", "vídeo explícito", "video explícito", "penetre/a",
    "oral profundo", "use la boca", "sin que se diera cuenta",
    "hasta que yo diga", "obligara", "violencia erótica",
)

data = {key: {"verdad": [], "reto": []} for key in heading_map.values()}
current = None
kind = None
for raw in source.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    matched_heading = next((name for name in heading_map if line.startswith(name)), None)
    if matched_heading:
        current = heading_map[matched_heading]
        kind = None
    elif line == "PREGUNTAS DE VERDAD (50)":
        kind = "verdad"
    elif line == "RETOS (50)":
        kind = "reto"
    elif current and kind and re.match(r"^\d+\.\s+", line):
        text = re.sub(r"^\d+\.\s+", "", line).strip()
        if not any(term in text.lower() for term in blocked):
            data[current][kind].append(text)

def dart_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"

lines = [
    "// Generated from Lista de Retos y Preguntas.txt.",
    "// Potentially unsafe/non-consensual challenges are intentionally excluded.",
    "const importedAdultContent = <String, Map<String, List<String>>>{",
]
for category, groups in data.items():
    lines.append(f"  '{category}': {{")
    for item_type, values in groups.items():
        lines.append(f"    '{item_type}': [")
        lines.extend(f"      {dart_string(value)}," for value in values)
        lines.append("    ],")
    lines.append("  },")
lines.append("};")
target.write_text("\n".join(lines) + "\n", encoding="utf-8")

for category, groups in data.items():
    print(category, {key: len(value) for key, value in groups.items()})
