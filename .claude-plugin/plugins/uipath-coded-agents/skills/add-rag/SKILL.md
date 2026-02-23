---
description: Add Retrieval-Augmented Generation (RAG) capability to your agent
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
---

# Add RAG Capability to Agent

I'll help you add Retrieval-Augmented Generation (RAG) to your UiPath agent, enabling it to answer questions using your documents and knowledge base.

## What is RAG?

RAG combines retrieval and generation to answer questions using your documents:
1. **Index** documents into a vector store
2. **Retrieve** relevant passages for a query
3. **Generate** answers using LLM + retrieved context

**Benefits:**
- Answer questions from your documents
- Reduce hallucinations
- Keep information up-to-date without retraining
- Cite sources in responses

## What This Skill Does

- 📚 Add document indexing capability
- 🔍 Add semantic search/retrieval
- 🤖 Add context-grounded generation
- ⚙️ Configure vector store (Pinecone, ChromaDB, Weaviate, etc.)
- 🧩 Integrate with LangChain or LlamaIndex agents
- ✅ Update schemas and test

## Prerequisites

- Existing UiPath agent (LangChain or LlamaIndex)
- Documents to index (PDF, TXT, MD, DOCX, etc.)
- Vector store choice (or use local ChromaDB)
- LLM configured (OpenAI, Azure OpenAI, Bedrock, etc.)

## Supported Vector Stores

- **ChromaDB** (Local, good for development)
- **Pinecone** (Cloud, scalable)
- **Weaviate** (Open source, self-hosted)
- **Qdrant** (Open source, cloud or self-hosted)
- **FAISS** (Local, Facebook AI)
- **Elasticsearch** (Full-text + vector search)

## Workflow

### Step 1: Choose Your Framework

I'll detect if you're using:
- **LangChain** - Uses LangChain vector stores and retrievers
- **LlamaIndex** - Uses LlamaIndex VectorStoreIndex

### Step 2: Select Vector Store

I'll ask which vector store you want to use:

**For Development (Local):**
- ChromaDB (recommended for starting)
- FAISS (simple, no dependencies)

**For Production (Cloud):**
- Pinecone (managed, scalable)
- Weaviate (self-hosted or cloud)
- Qdrant (self-hosted or cloud)

### Step 3: Add Dependencies

I'll update `pyproject.toml` with required packages:

#### For LangChain + ChromaDB
```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-langchain>=0.4.0",
    "langchain>=0.1.0",
    "langchain-community>=0.0.20",
    "chromadb>=0.4.0",
    "sentence-transformers>=2.2.0",  # For embeddings
]
```

#### For LangChain + Pinecone
```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-langchain>=0.4.0",
    "langchain>=0.1.0",
    "langchain-pinecone>=0.0.1",
    "pinecone-client>=3.0.0",
]
```

#### For LlamaIndex + ChromaDB
```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-llamaindex>=0.3.0",
    "llama-index>=0.10.0",
    "llama-index-vector-stores-chroma>=0.1.0",
    "chromadb>=0.4.0",
]
```

### Step 4: Create Document Ingestion

I'll create a script to index your documents:

#### LangChain Version

```python
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma

def ingest_documents(docs_path: str, persist_directory: str = "./chroma_db"):
    """Ingest documents into vector store."""

    # Load documents
    loader = DirectoryLoader(
        docs_path,
        glob="**/*.{txt,md,pdf}",
        loader_cls=TextLoader
    )
    documents = loader.load()

    # Split into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )
    texts = text_splitter.split_documents(documents)

    # Create embeddings
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )

    # Create vector store
    vectorstore = Chroma.from_documents(
        documents=texts,
        embedding=embeddings,
        persist_directory=persist_directory
    )

    return vectorstore

# Run ingestion
if __name__ == "__main__":
    vectorstore = ingest_documents("./knowledge_base")
    print(f"Indexed {vectorstore._collection.count()} chunks")
```

#### LlamaIndex Version

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core import StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb

def ingest_documents(docs_path: str, collection_name: str = "knowledge_base"):
    """Ingest documents into vector store."""

    # Load documents
    documents = SimpleDirectoryReader(docs_path).load_data()

    # Create vector store
    db = chromadb.PersistentClient(path="./chroma_db")
    chroma_collection = db.get_or_create_collection(collection_name)
    vector_store = ChromaVectorStore(chroma_collection=chroma_collection)

    # Create index
    storage_context = StorageContext.from_defaults(vector_store=vector_store)
    index = VectorStoreIndex.from_documents(
        documents,
        storage_context=storage_context
    )

    return index

# Run ingestion
if __name__ == "__main__":
    index = ingest_documents("./knowledge_base")
    print("Documents indexed successfully")
```

### Step 5: Add Retrieval to Agent

I'll integrate retrieval into your agent:

#### LangChain Agent with RAG

```python
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_core.tools import tool
from langgraph.graph import StateGraph
from pydantic import BaseModel, Field

class Input(BaseModel):
    """Agent input with question."""
    question: str = Field(description="Question to answer")

class Output(BaseModel):
    """Agent output with answer and sources."""
    answer: str = Field(description="Generated answer")
    sources: list[str] = Field(description="Source documents used")

# Load vector store
embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)
vectorstore = Chroma(
    persist_directory="./chroma_db",
    embedding_function=embeddings
)
retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

@tool
async def search_knowledge_base(query: str) -> str:
    """Search the knowledge base for relevant information.

    Args:
        query: The search query

    Returns:
        Relevant context from documents
    """
    docs = await retriever.ainvoke(query)
    context = "\n\n".join([doc.page_content for doc in docs])
    return context

# Add to your agent
async def main(input: Input) -> Output:
    # Retrieve context
    context = await search_knowledge_base(input.question)

    # Generate answer with context
    llm_response = await llm.ainvoke(
        f"Context:\n{context}\n\nQuestion: {input.question}\n\nAnswer:"
    )

    # Extract sources
    sources = [doc.metadata.get("source", "unknown") for doc in docs]

    return Output(
        answer=llm_response.content,
        sources=sources
    )
```

#### LlamaIndex Agent with RAG

```python
from llama_index.core import VectorStoreIndex, StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core.workflow import Workflow, step, StartEvent, StopEvent
import chromadb
from pydantic import BaseModel, Field

class Input(BaseModel):
    """Agent input with question."""
    question: str = Field(description="Question to answer")

class Output(BaseModel):
    """Agent output with answer and sources."""
    answer: str = Field(description="Generated answer")
    sources: list[str] = Field(description="Source documents used")

class RAGWorkflow(Workflow):
    """RAG workflow using LlamaIndex."""

    def __init__(self):
        super().__init__()

        # Load vector store
        db = chromadb.PersistentClient(path="./chroma_db")
        chroma_collection = db.get_or_create_collection("knowledge_base")
        vector_store = ChromaVectorStore(chroma_collection=chroma_collection)

        # Create index
        storage_context = StorageContext.from_defaults(vector_store=vector_store)
        self.index = VectorStoreIndex.from_vector_store(
            vector_store,
            storage_context=storage_context
        )

        # Create query engine
        self.query_engine = self.index.as_query_engine(similarity_top_k=3)

    @step
    async def query(self, ev: StartEvent) -> StopEvent:
        """Query the knowledge base."""
        question = ev.input.question

        # Query with RAG
        response = await self.query_engine.aquery(question)

        # Extract sources
        sources = [node.metadata.get("file_name", "unknown")
                   for node in response.source_nodes]

        return StopEvent(result=Output(
            answer=str(response),
            sources=sources
        ))

# Create workflow
workflow = RAGWorkflow()

async def main(input: Input) -> Output:
    """Main entry point."""
    result = await workflow.run(input=input)
    return result
```

### Step 6: Update Input/Output Models

I'll update your models to include RAG-specific fields:

```python
class Input(BaseModel):
    """Agent input."""
    question: str = Field(description="Question to answer from knowledge base")
    top_k: int = Field(default=3, description="Number of documents to retrieve")

class Output(BaseModel):
    """Agent output."""
    answer: str = Field(description="Generated answer")
    sources: list[str] = Field(description="Source documents")
    confidence: float | None = Field(default=None, description="Confidence score")
```

### Step 7: Add Ingestion Script

I'll create `ingest.py` for easy document indexing:

```python
#!/usr/bin/env python3
"""Ingest documents into vector store."""

import sys
from pathlib import Path

# Import your ingestion function
from main import ingest_documents

def main():
    if len(sys.argv) < 2:
        print("Usage: python ingest.py <docs_directory>")
        sys.exit(1)

    docs_path = Path(sys.argv[1])
    if not docs_path.exists():
        print(f"Error: {docs_path} does not exist")
        sys.exit(1)

    print(f"Ingesting documents from {docs_path}...")
    ingest_documents(str(docs_path))
    print("✅ Ingestion complete!")

if __name__ == "__main__":
    main()
```

### Step 8: Create Knowledge Base Directory

I'll create the directory structure:

```
project/
├── main.py                    # Agent with RAG
├── ingest.py                  # Document ingestion script
├── knowledge_base/            # Your documents
│   ├── doc1.txt
│   ├── doc2.pdf
│   └── doc3.md
├── chroma_db/                 # Vector store (created after ingestion)
└── pyproject.toml
```

### Step 9: Run Ingestion

I'll show you how to index your documents:

```bash
# Ingest documents
uv run python ingest.py ./knowledge_base

# Verify ingestion
uv run python -c "
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings()
db = Chroma(persist_directory='./chroma_db', embedding_function=embeddings)
print(f'Total chunks: {db._collection.count()}')
"
```

### Step 10: Test RAG Agent

I'll test the agent with a sample question:

```bash
uv run uipath run main '{
  "question": "What are the main features of UiPath?"
}'
```

Expected output:
```json
{
  "answer": "Based on the documentation, UiPath's main features include...",
  "sources": ["./knowledge_base/overview.md", "./knowledge_base/features.txt"]
}
```

## RAG Configuration Options

### Embedding Models

**Local (Free):**
- `sentence-transformers/all-MiniLM-L6-v2` (fast, good quality)
- `sentence-transformers/all-mpnet-base-v2` (slower, better quality)

**API-based:**
- OpenAI Embeddings (`text-embedding-ada-002`)
- Azure OpenAI Embeddings
- Cohere Embeddings

### Chunk Size Configuration

```python
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,        # Characters per chunk
    chunk_overlap=200,      # Overlap between chunks
    separators=["\n\n", "\n", " ", ""]
)
```

**Guidelines:**
- **Small chunks (500-800)**: Better precision, more chunks
- **Medium chunks (1000-1500)**: Balanced (recommended)
- **Large chunks (2000+)**: More context, fewer chunks

### Retrieval Parameters

```python
retriever = vectorstore.as_retriever(
    search_type="similarity",  # or "mmr" (Maximal Marginal Relevance)
    search_kwargs={
        "k": 3,                # Number of documents to retrieve
        "score_threshold": 0.7  # Minimum similarity score
    }
)
```

## Advanced RAG Patterns

### Multi-Query RAG

Generate multiple queries for better retrieval:

```python
@tool
async def search_with_multi_query(question: str) -> str:
    """Search using multiple query variations."""
    # Generate query variations
    queries = await llm.ainvoke(
        f"Generate 3 variations of this question:\n{question}"
    )

    # Search with each query
    all_docs = []
    for query in queries:
        docs = await retriever.ainvoke(query)
        all_docs.extend(docs)

    # Deduplicate and rank
    unique_docs = deduplicate_documents(all_docs)
    return format_context(unique_docs[:5])
```

### RAG with Reranking

Rerank retrieved documents for better relevance:

```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import CohereRerank

# Create reranker
compressor = CohereRerank(cohere_api_key="your-key")
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=retriever
)

# Use reranking retriever
docs = await compression_retriever.ainvoke(query)
```

### Hybrid Search (Vector + Keyword)

Combine semantic and keyword search:

```python
from langchain.retrievers import EnsembleRetriever
from langchain_community.retrievers import BM25Retriever

# Vector retriever
vector_retriever = vectorstore.as_retriever()

# Keyword retriever
bm25_retriever = BM25Retriever.from_documents(documents)

# Combine
ensemble_retriever = EnsembleRetriever(
    retrievers=[vector_retriever, bm25_retriever],
    weights=[0.7, 0.3]  # 70% vector, 30% keyword
)
```

## Document Types Supported

### Text Files
- `.txt`, `.md`, `.rst`
- Direct loading, no special handling

### PDFs
```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("document.pdf")
pages = loader.load_and_split()
```

### Word Documents
```python
from langchain_community.document_loaders import Docx2txtLoader

loader = Docx2txtLoader("document.docx")
documents = loader.load()
```

### Web Pages
```python
from langchain_community.document_loaders import WebBaseLoader

loader = WebBaseLoader("https://example.com")
documents = loader.load()
```

### CSV/Excel
```python
from langchain_community.document_loaders import CSVLoader

loader = CSVLoader("data.csv")
documents = loader.load()
```

## Production Considerations

### Vector Store Persistence

**ChromaDB (Local):**
```python
vectorstore = Chroma(
    persist_directory="./chroma_db",  # Persists to disk
    embedding_function=embeddings
)
```

**Pinecone (Cloud):**
```python
import pinecone
from langchain_community.vectorstores import Pinecone

pinecone.init(api_key="your-key", environment="us-east1-gcp")
vectorstore = Pinecone.from_documents(
    documents=texts,
    embedding=embeddings,
    index_name="knowledge-base"
)
```

### Incremental Updates

Add new documents without reindexing everything:

```python
# Add new documents
new_docs = SimpleDirectoryReader("./new_docs").load_data()
for doc in new_docs:
    index.insert(doc)

# Or batch insert
index.insert_nodes(new_docs)
```

### Monitoring RAG Quality

Track retrieval quality:

```python
@traced(span_name="rag_query")
async def query_with_metrics(question: str) -> dict:
    """Query with quality metrics."""
    start_time = time.time()

    # Retrieve
    docs = await retriever.ainvoke(question)

    # Log metrics
    metrics = {
        "num_docs_retrieved": len(docs),
        "avg_score": sum(doc.metadata.get("score", 0) for doc in docs) / len(docs),
        "retrieval_time": time.time() - start_time
    }

    return {"docs": docs, "metrics": metrics}
```

## Best Practices

✅ **Do:**
- Start with a small document set to test
- Use appropriate chunk sizes (1000-1500 chars)
- Add metadata to documents (source, date, category)
- Monitor retrieval quality
- Use reranking for better results
- Cache embeddings when possible

❌ **Don't:**
- Index sensitive data without proper access controls
- Use very large chunks (>2000 chars)
- Forget to persist vector stores
- Skip document preprocessing
- Ignore retrieval metrics
- Mix unrelated documents in one index

## Troubleshooting

### Poor Retrieval Quality

**Symptoms:** Irrelevant documents retrieved

**Fixes:**
- Reduce chunk size
- Increase `top_k`
- Try different embedding model
- Add reranking
- Improve document quality

### Slow Indexing

**Symptoms:** Ingestion takes too long

**Fixes:**
- Use batch embedding
- Reduce chunk overlap
- Use faster embedding model
- Process in parallel

### High Memory Usage

**Symptoms:** Out of memory errors

**Fixes:**
- Use cloud vector store (Pinecone)
- Process documents in batches
- Reduce embedding dimensions
- Use disk-based vector store

## Next Steps

After adding RAG:
1. **Test thoroughly** with various questions
2. **Create evaluations** for RAG quality
3. **Monitor retrieval metrics**
4. **Iterate on chunk size and retrieval params**
5. **Deploy** with `/uipath-coded-agents:deploy`

## Let's Add RAG to Your Agent!

Tell me:
- Which framework? (LangChain or LlamaIndex)
- Which vector store? (ChromaDB for dev, Pinecone for prod)
- Where are your documents?
- What embedding model? (default: sentence-transformers/all-MiniLM-L6-v2)

**Example prompts:**
- "Add RAG with ChromaDB to my LangChain agent"
- "Add LlamaIndex RAG with Pinecone"
- "Set up RAG for my documents in ./docs folder"
