"""Load local study notes (markdown / code / sql) from the uploads directory."""
from pathlib import Path
from langchain_core.documents import Document
from app.config import settings

NOTE_EXTS = {".md", ".markdown", ".c", ".h", ".cpp", ".sql", ".txt", ".py"}


def load_notes() -> list[Document]:
    docs: list[Document] = []
    up = Path(settings.uploads_dir)
    if not up.exists():
        return docs
    for p in sorted(up.iterdir()):
        if not (p.is_file() and p.suffix.lower() in NOTE_EXTS):
            continue
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            text = p.read_text(encoding="utf-8", errors="ignore")
        if not text.strip():
            continue
        docs.append(
            Document(
                page_content=text,
                metadata={
                    "source_type": "note",
                    "file_name": p.name,
                    "file_path": str(p),
                    "title": p.stem,
                },
            )
        )
    return docs
