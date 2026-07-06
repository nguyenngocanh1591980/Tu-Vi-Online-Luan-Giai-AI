import os
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
# Using HuggingFace embeddings which is free and runs locally
from langchain_community.embeddings import HuggingFaceEmbeddings

DB_DIR = "./chroma_db"
DOCS_DIR = "../AI học tử vi"

def get_vector_store():
    # Khởi tạo mô hình nhúng (Embeddings model)
    embeddings = HuggingFaceEmbeddings(model_name="keepitreal/vietnamese-sbert")
    
    if os.path.exists(DB_DIR):
        # Nếu đã có DB, load lên
        vector_store = Chroma(persist_directory=DB_DIR, embedding_function=embeddings)
        return vector_store
    return None

def train_knowledge_base():
    print(f"Bắt đầu đọc tài liệu từ: {DOCS_DIR}")
    
    if not os.path.exists(DOCS_DIR):
        os.makedirs(DOCS_DIR)
        
    # Nạp toàn bộ PDF trong thư mục
    from langchain_community.document_loaders import DirectoryLoader, PyPDFLoader, TextLoader
    
    pdf_loader = DirectoryLoader(DOCS_DIR, glob="**/*.pdf", loader_cls=PyPDFLoader)
    txt_loader = DirectoryLoader(DOCS_DIR, glob="**/*.txt", loader_cls=TextLoader)
    
    docs = []
    try:
        docs.extend(pdf_loader.load())
    except Exception as e:
        print(f"Lỗi load PDF: {e}")
        
    try:
        docs.extend(txt_loader.load())
    except Exception as e:
        print(f"Lỗi load TXT: {e}")

    
    if not docs:
        return "Không tìm thấy tài liệu PDF nào trong thư mục 'AI học tử vi'."

    # Cắt nhỏ tài liệu
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        separators=["\n\n", "\n", ".", " ", ""]
    )
    chunks = text_splitter.split_documents(docs)
    
    print(f"Đã cắt thành {len(chunks)} đoạn văn bản.")
    
    # Khởi tạo Embeddings
    embeddings = HuggingFaceEmbeddings(model_name="keepitreal/vietnamese-sbert")
    
    # Tạo và lưu trữ vào ChromaDB
    vector_store = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=DB_DIR
    )
    
    return f"Đã nạp thành công {len(docs)} tài liệu, chia thành {len(chunks)} đoạn kiến thức."
