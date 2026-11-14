"""Split documents into chunks suitable for embedding."""
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from langchain_core.documents import Document

_HEADERS = [("#", "h1"), ("##", "h2"), ("###", "h3")]

_md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on=_HEADERS, strip_headers=False)
_rec_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    separators=["\n## ", "\n### ", "\n\n", "\n", "。", "；", " ", ""],
)


def split_documents(docs: list[Document]) -> list[Document]:
    result: list[Document] = []
    for d in docs:
        fn = (d.metadata.get("file_name") or "").lower()
        if d.metadata.get("source_type") == "note" and fn.endswith((".md", ".markdown")):
            chunks = _md_splitter.split_text(d.page_content)
            for c in chunks:
                c.metadata = {**d.metadata, **c.metadata}
            chunks = _rec_splitter.split_documents(chunks)
        else:
            chunks = _rec_splitter.split_documents([d])
        # ensure every chunk carries the source_type + key metadata
        for c in chunks:
            c.metadata = {**d.metadata, **c.metadata}
        result.extend(chunks)
    return result
