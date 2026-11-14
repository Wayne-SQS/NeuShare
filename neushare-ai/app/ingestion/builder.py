"""Build / ensure the FAISS index from notes + resource metadata."""
import logging
from pathlib import Path
from app.config import settings
from app.ingestion import loader, resource_loader, splitter, vectorstore as vs_mod

log = logging.getLogger("builder")


def build_index() -> tuple[int, int, int]:
    notes = loader.load_notes()
    resources = resource_loader.load_resources()
    chunks = splitter.split_documents(notes + resources)
    log.info("building index: notes=%d resources=%d chunks=%d", len(notes), len(resources), len(chunks))
    vs_mod.build_vectorstore(chunks)
    return len(notes), len(resources), len(chunks)


def index_exists() -> bool:
    return Path(settings.vectorstore_dir, "index.faiss").exists()


def ensure_index():
    """Build the index on startup if it does not exist yet."""
    if index_exists():
        return None
    log.info("vectorstore missing; building index on startup...")
    return build_index()
