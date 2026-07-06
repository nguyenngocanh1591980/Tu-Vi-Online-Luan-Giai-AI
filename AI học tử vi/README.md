# Thư mục "AI học tử vi"

Thư mục này được sử dụng làm **Kho Dữ Liệu (Knowledge Base)** cho AI trong dự án Tử Vi AI. 

## Mục đích sử dụng:
Bạn có thể upload hoặc lưu trữ các tài liệu tại đây để làm dữ liệu huấn luyện hoặc cung cấp ngữ cảnh (RAG - Retrieval-Augmented Generation) cho AI khi đưa ra lời bình giải lá số:
- 📄 **Tài liệu PDF / Word / Text**: Các sách tử vi, phú đoán, cách cục.
- 🎥 **Video / Audio**: Các bài giảng tử vi (nếu hệ thống hỗ trợ trích xuất transcript).
- 📊 **Cơ sở dữ liệu mẫu**: Các mẫu lá số và lời giải tương ứng.

## Hướng phát triển tiếp theo cho Backend Python:
Trong tương lai, Logic Service (Python) của chúng ta có thể tích hợp thư viện như `LangChain`, `LlamaIndex` và vector database (ví dụ: `ChromaDB` hoặc `pgvector` ngay trong PostgreSQL) để đọc các tài liệu trong thư mục này, biến chúng thành Vector và cho phép AI tra cứu kiến thức tử vi chuyên sâu từ chính những tài liệu bạn cung cấp.
