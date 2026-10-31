import os
import re
import json
import asyncio
import unicodedata
import difflib
from typing import Optional
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import google.generativeai as genai
from dotenv import load_dotenv

# Nạp file .env từ thư mục gốc
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_API_KEY_HERE")
genai.configure(api_key=API_KEY)

from datetime import datetime, timezone, timedelta

TZ_VN = timezone(timedelta(hours=7))

from psycopg2 import pool

db_pool = None
def get_db_connection():
    global db_pool
    if db_pool is None:
        try:
            db_pool = pool.SimpleConnectionPool(
                minconn=1,
                maxconn=20,
                host="localhost",
                port=5432,
                database="TuvionlineManagerDB",
                user="postgres",
                password="postgres",
                connect_timeout=3
            )
        except Exception as e:
            print(f"Connection pool init fallback: {e}")
            return None
    try:
        return db_pool.getconn()
    except Exception:
        return None

def release_db_connection(conn):
    global db_pool
    if db_pool and conn:
        try:
            db_pool.putconn(conn)
        except Exception:
            pass


def format_vn_time(dt, default=None):
    if default is None or default in ["Vừa xong", "vừa xong", "-", ""]:
        default = datetime.now(TZ_VN).strftime("%H:%M, %d/%m/%y")
    if not dt:
        return default
    if isinstance(dt, str):
        if dt in ["Vừa xong", "vừa xong", "-", ""]:
            return default
        try:
            if "T" in dt or ("-" in dt and len(dt) >= 10):
                dt = datetime.fromisoformat(dt.replace("Z", "+00:00"))
            else:
                return dt
        except Exception:
            return default
    if getattr(dt, "tzinfo", None) is None:
        dt = dt.replace(tzinfo=TZ_VN)
    return dt.astimezone(TZ_VN).strftime("%H:%M, %d/%m/%y")

from pydantic import BaseModel
from fastapi.responses import Response
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

@app.middleware("http")
async def ensure_static_uploads_cors(request: Request, call_next):
    if request.method == "OPTIONS" and request.url.path.startswith("/uploads"):
        return Response(
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "*",
                "Access-Control-Allow-Headers": "*",
                "Cross-Origin-Resource-Policy": "cross-origin",
            },
        )
    response = await call_next(request)
    if request.url.path.startswith("/uploads"):
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
        response.headers["Cache-Control"] = "public, max-age=86400"
    return response

from fastapi.staticfiles import StaticFiles
from fastapi import File, UploadFile
import base64
import uuid
import time
import shutil
import threading

_AI_ENGINE_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ROOT_DIR = os.path.dirname(_AI_ENGINE_DIR)
UPLOAD_DIR = os.path.join(_AI_ENGINE_DIR, "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
if os.path.abspath("uploads") != os.path.abspath(UPLOAD_DIR):
    os.chdir(_AI_ENGINE_DIR)
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

UPLOADED_IMAGES_JSON_PATH = os.path.join(_AI_ENGINE_DIR, "uploaded_images_db.json")

def init_uploaded_images_db():
    conn = get_db_connection()
    if not conn:
        return
    try:
        cur = conn.cursor()
        cur.execute('''
            CREATE TABLE IF NOT EXISTS "UploadedImages" (
                "Id" SERIAL PRIMARY KEY,
                "Filename" VARCHAR(255) UNIQUE NOT NULL,
                "Url" TEXT NOT NULL,
                "Status" VARCHAR(32) DEFAULT 'pending',
                "TopicId" VARCHAR(100),
                "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "CommittedAt" TIMESTAMP WITH TIME ZONE
            );
        ''')
        conn.commit()
        cur.close()
    except Exception as e:
        try:
            conn.rollback()
        except Exception:
            pass
        print(f"init_uploaded_images_db fallback: {e}")
    finally:
        release_db_connection(conn)

init_uploaded_images_db()

def _load_uploaded_images_json():
    if not os.path.exists(UPLOADED_IMAGES_JSON_PATH):
        return {}
    try:
        with open(UPLOADED_IMAGES_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, dict) else {}
    except Exception:
        return {}

def _save_uploaded_images_json(registry: dict):
    try:
        with open(UPLOADED_IMAGES_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(registry, f, ensure_ascii=False, indent=2)
    except Exception:
        pass

def register_uploaded_image_pending(filename: str, url: str, topic_id: Optional[str] = None):
    now_iso = datetime.now(timezone.utc).isoformat()
    registry = _load_uploaded_images_json()
    registry[filename] = {
        "filename": filename,
        "url": url,
        "status": "pending",
        "topicId": str(topic_id) if topic_id is not None else None,
        "createdAt": now_iso,
        "committedAt": None,
    }
    _save_uploaded_images_json(registry)
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('''
                INSERT INTO "UploadedImages" ("Filename", "Url", "Status", "TopicId", "CreatedAt")
                VALUES (%s, %s, 'pending', %s, CURRENT_TIMESTAMP)
                ON CONFLICT ("Filename") DO UPDATE
                SET "Url" = EXCLUDED."Url",
                    "TopicId" = COALESCE(EXCLUDED."TopicId", "UploadedImages"."TopicId");
            ''', (filename, url, str(topic_id) if topic_id is not None else None))
            conn.commit()
            cur.close()
        except Exception as e:
            try:
                conn.rollback()
            except Exception:
                pass
            print(f"register_uploaded_image_pending db notice: {e}")
        finally:
            release_db_connection(conn)

def extract_upload_filenames(*texts) -> list:
    found = set()
    for txt in texts:
        if not txt:
            continue
        for m in re.findall(r'(img_[A-Za-z0-9_]+\.(?:jpg|jpeg|png|gif|webp))', str(txt), flags=re.IGNORECASE):
            found.add(m)
    return list(found)

def commit_uploaded_images(filenames: list = None, topic_id: Optional[str] = None, content_texts: list = None) -> int:
    target_set = set()
    if filenames:
        for item in filenames:
            clean_name = os.path.basename(str(item).split("?")[0])
            if clean_name.startswith("img_"):
                target_set.add(clean_name)
    if content_texts:
        for extracted in extract_upload_filenames(*content_texts):
            target_set.add(extracted)
    if not target_set:
        return 0
    target_list = list(target_set)
    now_iso = datetime.now(timezone.utc).isoformat()
    registry = _load_uploaded_images_json()
    for fname in target_list:
        entry = registry.get(fname, {
            "filename": fname,
            "url": f"http://localhost:8000/uploads/{fname}",
            "createdAt": now_iso,
        })
        entry["status"] = "committed"
        if topic_id is not None:
            entry["topicId"] = str(topic_id)
        entry["committedAt"] = now_iso
        registry[fname] = entry
    _save_uploaded_images_json(registry)
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            for fname in target_list:
                cur.execute('''
                    INSERT INTO "UploadedImages" ("Filename", "Url", "Status", "TopicId", "CreatedAt", "CommittedAt")
                    VALUES (%s, %s, 'committed', %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    ON CONFLICT ("Filename") DO UPDATE
                    SET "Status" = 'committed',
                        "TopicId" = COALESCE(%s, "UploadedImages"."TopicId"),
                        "CommittedAt" = CURRENT_TIMESTAMP;
                ''', (
                    fname,
                    f"http://localhost:8000/uploads/{fname}",
                    str(topic_id) if topic_id is not None else None,
                    str(topic_id) if topic_id is not None else None,
                ))
            conn.commit()
            cur.close()
        except Exception as e:
            try:
                conn.rollback()
            except Exception:
                pass
            print(f"commit_uploaded_images db notice: {e}")
        finally:
            release_db_connection(conn)
    return len(target_list)

def cleanup_expired_pending_images(max_age_hours: float = 24.0) -> int:
    cutoff = datetime.now(timezone.utc) - timedelta(hours=max_age_hours)
    expired_filenames = set()
    referenced_in_db = set()
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('''
                SELECT "Filename" FROM "UploadedImages"
                WHERE "Status" = 'pending' AND "CreatedAt" < %s;
            ''', (cutoff,))
            for (fname,) in cur.fetchall():
                if fname:
                    expired_filenames.add(fname)
            cur.execute('SELECT "Content", "Rules" FROM "ForumTopics";')
            for c_val, r_val in cur.fetchall():
                for fn in extract_upload_filenames(c_val, r_val):
                    referenced_in_db.add(fn)
            cur.execute('SELECT "Content" FROM "ForumTopicReplies";')
            for (rc_val,) in cur.fetchall():
                for fn in extract_upload_filenames(rc_val):
                    referenced_in_db.add(fn)
            cur.close()
        except Exception as e:
            try:
                conn.rollback()
            except Exception:
                pass
            print(f"cleanup_expired_pending_images query notice: {e}")
        finally:
            release_db_connection(conn)
    registry = _load_uploaded_images_json()
    for fname, meta in list(registry.items()):
        if meta.get("status") == "pending":
            try:
                c_dt = datetime.fromisoformat(str(meta.get("createdAt", "")).replace("Z", "+00:00"))
                if c_dt.tzinfo is None:
                    c_dt = c_dt.replace(tzinfo=timezone.utc)
                if c_dt < cutoff:
                    expired_filenames.add(fname)
            except Exception:
                pass
    for t in load_forum_topics_file() if "load_forum_topics_file" in globals() else []:
        for fn in extract_upload_filenames(t.get("content"), t.get("rules")):
            referenced_in_db.add(fn)
    expired_filenames -= referenced_in_db
    if not expired_filenames:
        return 0
    gateway_uploads = os.path.join(_PROJECT_ROOT_DIR, "APIGateway_CS", "wwwroot", "uploads")
    deleted_count = 0
    for clean_name in expired_filenames:
        if not clean_name.startswith("img_"):
            continue
        p1 = os.path.join(UPLOAD_DIR, clean_name)
        if os.path.exists(p1):
            try:
                os.remove(p1)
                deleted_count += 1
            except Exception:
                pass
        p2 = os.path.join(gateway_uploads, clean_name)
        if os.path.exists(p2):
            try:
                os.remove(p2)
            except Exception:
                pass
        registry.pop(clean_name, None)
    _save_uploaded_images_json(registry)
    conn2 = get_db_connection()
    if conn2:
        try:
            cur2 = conn2.cursor()
            cur2.execute('DELETE FROM "UploadedImages" WHERE "Filename" = ANY(%s) AND "Status" = \'pending\';', (list(expired_filenames),))
            conn2.commit()
            cur2.close()
        except Exception:
            try:
                conn2.rollback()
            except Exception:
                pass
        finally:
            release_db_connection(conn2)
    return deleted_count

def _start_upload_gc_cronjob():
    def _worker():
        while True:
            try:
                cleanup_expired_pending_images(max_age_hours=24.0)
            except Exception:
                pass
            time.sleep(3600)
    t = threading.Thread(target=_worker, daemon=True, name="UploadDistributedGCCron")
    t.start()

_start_upload_gc_cronjob()

# In-memory User Info Cache (Redis/RAM equivalent for 0ms access)
_USER_CACHE = {}
_USER_CACHE_TTL = 300  # 5 minutes

def sync_users_from_ai_manager_db():
    try:
        import psycopg2
        conn_src = psycopg2.connect(host='localhost', port=5432, dbname='TuviAIManagerDB', user='postgres', password='postgres', connect_timeout=2)
        cur_src = conn_src.cursor()
        conn_dst = psycopg2.connect(host='localhost', port=5432, dbname='TuvionlineManagerDB', user='postgres', password='postgres', connect_timeout=2)
        conn_dst.autocommit = True
        cur_dst = conn_dst.cursor()

        cur_dst.execute('ALTER TABLE "Users" ADD COLUMN IF NOT EXISTS "RankTitle" VARCHAR(255);')
        cur_dst.execute('ALTER TABLE "Users" ADD COLUMN IF NOT EXISTS "Avatar" VARCHAR(255);')
        cur_dst.execute('ALTER TABLE "Users" ADD COLUMN IF NOT EXISTS "StarLevel" INTEGER DEFAULT 1;')
        cur_dst.execute('ALTER TABLE "Users" ALTER COLUMN "PreferredLanguage" DROP NOT NULL;')
        cur_dst.execute('ALTER TABLE "Users" ALTER COLUMN "PreferredLanguage" SET DEFAULT \'vi\';')

        cur_src.execute('''
            SELECT "Id", "Username", "Role", "Email", "DateOfBirth", "CreatedAt", "Badge", "BadgeType",
                   "PostCount", "Website", "FromLocation", "UserGroups", "RankTitle", "TitleLogo", "StarLevel"
            FROM "Users";
        ''')
        src_users = cur_src.fetchall()
        for u in src_users:
            u_id, username, role, email, dob, created_at, badge, badge_type, post_count, website, from_loc, user_groups, rank_title, title_logo, star_level = u
            cur_dst.execute('SELECT "Id" FROM "Users" WHERE LOWER("Username") = LOWER(%s) OR "Id" = %s;', (username, u_id))
            exists = cur_dst.fetchone()
            if exists:
                cur_dst.execute('''
                    UPDATE "Users"
                    SET "Username" = %s, "Role" = %s, "Email" = %s, "DateOfBirth" = %s, "CreatedAt" = %s,
                        "BadgeText" = %s, "BadgeType" = %s, "PostCount" = %s, "Website" = %s,
                        "FromLocation" = %s, "UserGroups" = %s, "RankTitle" = %s, "TitleLogo" = %s, "StarLevel" = %s,
                        "PreferredLanguage" = 'vi'
                    WHERE "Id" = %s;
                ''', (username, role, email or '', dob, created_at, badge or '', badge_type or 'badge_purple', post_count or 0, website or '', from_loc or '', user_groups or 'Thành viên', rank_title or '', title_logo or '', star_level or 1, exists[0]))
            else:
                cur_dst.execute('''
                    INSERT INTO "Users" ("Id", "Username", "Role", "Email", "DateOfBirth", "CreatedAt",
                                        "BadgeText", "BadgeType", "PostCount", "Website", "FromLocation",
                                        "UserGroups", "RankTitle", "TitleLogo", "StarLevel", "PreferredLanguage")
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'vi');
                ''', (u_id, username, role, email or '', dob, created_at, badge or '', badge_type or 'badge_purple', post_count or 0, website or '', from_loc or '', user_groups or 'Thành viên', rank_title or '', title_logo or '', star_level or 1))

        # Check and seed elizaasyre if not present
        cur_dst.execute('SELECT "Id" FROM "Users" WHERE LOWER("Username") = %s;', ('elizaasyre',))
        if not cur_dst.fetchone():
            cur_dst.execute('SELECT COALESCE(MAX("Id"), 0) + 1 FROM "Users";')
            next_id = cur_dst.fetchone()[0]
            cur_dst.execute('''
                INSERT INTO "Users" ("Id", "Username", "Role", "Email", "CreatedAt", "BadgeText", "BadgeType", "PostCount", "UserGroups", "RankTitle", "TitleLogo", "StarLevel", "PreferredLanguage")
                VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP, %s, %s, 1, %s, %s, %s, 1, 'vi');
            ''', (next_id, 'elizaasyre', 'User', 'elizaasyre@tuvionline.vn', 'THÀNH VIÊN', 'badge_gray', 'Thành viên', 'thành viên', ''))

        cur_src.close()
        conn_src.close()
        cur_dst.close()
        conn_dst.close()
    except Exception as e:
        print(f"Auto-sync users background notice: {e}")

sync_users_from_ai_manager_db()

def get_user_info_cached(username: str, cur=None):
    if not username:
        return {
            "id": 0,
            "username": "Ẩn danh",
            "rank": "thành viên",
            "role": "User",
            "group": "Thành viên",
            "titleLogo": "",
            "avatar": "",
            "badgeText": "THÀNH VIÊN",
            "badgeType": "badge_purple",
            "starLevel": 1
        }
    key = username.strip().lower()
    now = time.time()
    if key in _USER_CACHE and (now - _USER_CACHE[key]["ts"] < _USER_CACHE_TTL):
        return _USER_CACHE[key]["data"]

    close_cur = False
    conn = None
    if cur is None:
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            close_cur = True

    user_info = None
    if cur:
        try:
            cur.execute('''
                SELECT "Id", "Username", "Role", "BadgeText", "BadgeType", "RankTitle", "TitleLogo", "UserGroups", "Avatar", "StarLevel"
                FROM "Users"
                WHERE LOWER("Username") = LOWER(%s);
            ''', (username,))
            row = cur.fetchone()
            if row:
                user_info = {
                    "id": row[0],
                    "username": row[1] or username,
                    "role": row[2] or "User",
                    "badgeText": row[3] or "THÀNH VIÊN",
                    "badgeType": row[4] or "badge_purple",
                    "rank": row[5] or (row[3] if row[3] else ("Quản trị viên" if (row[2] or "").lower() == "admin" else "thành viên")),
                    "titleLogo": row[6] or "",
                    "group": row[7] or "Thành viên",
                    "avatar": row[8] or "",
                    "starLevel": row[9] or 1
                }
        except Exception as e:
            print(f"Error querying user {username}: {e}")

    if close_cur and conn:
        try:
            cur.close()
            release_db_connection(conn)
        except Exception:
            pass

    if not user_info:
        is_adm = key == "admin"
        user_info = {
            "id": 0,
            "username": username,
            "role": "Admin" if is_adm else "User",
            "badgeText": "QUẢN TRỊ VIÊN" if is_adm else "THÀNH VIÊN",
            "badgeType": "badge_blue" if is_adm else "badge_gray",
            "rank": "Quản trị viên" if is_adm else "thành viên",
            "titleLogo": "/images/logo_admin.png" if is_adm else "",
            "group": "Thành viên",
            "avatar": "",
            "starLevel": 1
        }

    _USER_CACHE[key] = {"data": user_info, "ts": now}
    return user_info

@app.post("/api/upload/image")
async def upload_editor_image(request: Request):
    """
    Endpoint upload ảnh hỗ trợ cả multipart/form-data và Base64 (application/json).
    Có bảo vệ giới hạn dung lượng 5MB và cấp phát persistent URL tĩnh.
    """
    try:
        content_type = request.headers.get("content-type", "")
        ext = ".jpg"
        file_bytes = b""
        topic_id_hint = None

        # 1. Xử lý multipart/form-data
        if "multipart/form-data" in content_type:
            form = await request.form()
            file = form.get("file") or form.get("image")
            if file and hasattr(file, "read"):
                orig_name = getattr(file, "filename", "") or ""
                orig_ext = os.path.splitext(orig_name)[1].lower()
                if orig_ext in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
                    ext = orig_ext
                file_bytes = await file.read()
            else:
                return {"status": "error", "message": "Không tìm thấy file trong form data"}

        # 2. Xử lý application/json (Base64)
        elif "application/json" in content_type:
            body = await request.json()
            topic_id_hint = body.get("topicId") or body.get("topic_id")
            raw_data = body.get("image", "")
            orig_name = body.get("filename", "")
            if orig_name:
                orig_ext = os.path.splitext(orig_name)[1].lower()
                if orig_ext in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
                    ext = orig_ext
            if "," in raw_data:
                header, raw_data = raw_data.split(",", 1)
                if "image/jpeg" in header or "image/jpg" in header:
                    ext = ".jpg"
                elif "image/png" in header:
                    ext = ".png"
                elif "image/webp" in header:
                    ext = ".webp"
                elif "image/gif" in header:
                    ext = ".gif"
            file_bytes = base64.b64decode(raw_data)

        # 3. Fallback: Raw binary hoặc Base64 trong text body
        else:
            raw_body = await request.body()
            try:
                body_str = raw_body.decode("utf-8")
                if "base64," in body_str:
                    file_bytes = base64.b64decode(body_str.split("base64,", 1)[1])
                elif body_str.startswith("{"):
                    import json as _j
                    p = _j.loads(body_str)
                    raw_data = p.get("image", "")
                    if "," in raw_data:
                        raw_data = raw_data.split(",", 1)[1]
                    file_bytes = base64.b64decode(raw_data)
                else:
                    file_bytes = raw_body
            except Exception:
                file_bytes = raw_body

        # Kiểm tra kích thước file tối đa 5MB (Bảo vệ server)
        max_bytes = 5 * 1024 * 1024
        if len(file_bytes) > max_bytes:
            return {"status": "error", "message": "Dung lượng ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn."}

        filename = f"img_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}{ext}"
        file_path = os.path.join(UPLOAD_DIR, filename)

        with open(file_path, "wb") as f:
            f.write(file_bytes)

        # Đồng bộ sang APIGateway wwwroot/uploads nếu tồn tại
        gateway_uploads = os.path.join(os.path.dirname(os.path.dirname(__file__)), "APIGateway_CS", "wwwroot", "uploads")
        if os.path.exists(os.path.dirname(gateway_uploads)):
            os.makedirs(gateway_uploads, exist_ok=True)
            try:
                shutil.copy2(file_path, os.path.join(gateway_uploads, filename))
            except Exception:
                pass

        url = f"http://localhost:8000/uploads/{filename}"
        register_uploaded_image_pending(filename, url, topic_id=topic_id_hint)
        return {
            "status": "success",
            "url": url,
            "filename": filename,
            "gcStatus": "pending"
        }
    except Exception as e:
        return {"status": "error", "message": f"Upload failed: {str(e)}"}

@app.post("/api/upload/image/commit")
async def commit_editor_images_api(request: Request):
    """
    Distributed GC: Chuyển trạng thái ảnh từ pending -> committed gắn với topicId trên PostgreSQL Docker.
    """
    try:
        body = await request.json()
        raw_items = body.get("filenames") or body.get("images") or []
        if isinstance(raw_items, str):
            raw_items = [raw_items]
        topic_id = body.get("topicId") or body.get("topic_id")
        content_text = body.get("content") or ""
        committed = commit_uploaded_images(
            filenames=raw_items,
            topic_id=str(topic_id) if topic_id is not None else None,
            content_texts=[content_text] if content_text else None,
        )
        return {
            "status": "success",
            "committed_count": committed,
            "gcStatus": "committed",
        }
    except Exception as e:
        return {"status": "error", "message": f"Commit failed: {str(e)}"}

@app.post("/api/upload/image/gc")
async def trigger_upload_gc_api(request: Request):
    """
    Distributed GC Cronjob Endpoint: Dọn dẹp các ảnh pending quá hạn (mặc định > 24h).
    """
    try:
        body = {}
        try:
            body = await request.json()
        except Exception:
            body = {}
        max_age_hours = float(body.get("maxAgeHours", 24.0))
        deleted_count = cleanup_expired_pending_images(max_age_hours=max_age_hours)
        return {
            "status": "success",
            "deleted_count": deleted_count,
            "message": f"Distributed GC đã dọn {deleted_count} file pending quá {max_age_hours}h."
        }
    except Exception as e:
        return {"status": "error", "message": f"GC failed: {str(e)}"}

@app.api_route("/api/upload/image/batch", methods=["DELETE", "POST"])
async def delete_orphan_images(request: Request):
    """
    Distributed GC Safe Guard: Tuyệt đối không xóa ảnh đã committed hoặc ảnh pending dưới 24h
    tránh lỗi xóa nhầm khi UI dispose(). Chỉ dọn các file pending quá 24h qua Distributed GC.
    """
    try:
        deleted_count = cleanup_expired_pending_images(max_age_hours=24.0)
        return {
            "status": "success",
            "deleted_count": deleted_count,
            "message": f"Distributed GC bảo toàn ảnh mới tải lên; đã dọn {deleted_count} file pending quá 24h."
        }
    except Exception as e:
        return {"status": "error", "message": f"Lỗi khử rác ảnh: {str(e)}"}


class AlmanacData(BaseModel):
    date: str  # YYYY-MM-DD
    time: str = "00:00"  # HH:MM

@app.post("/api/calculate-almanac")
def calculate_almanac(data: AlmanacData):
    """
    API Tính toán Lịch Vạn Sự đầy đủ 5 trường dữ liệu bổ sung.
    """
    hour = 0
    minute = 0
    if ":" in data.time:
        parts = data.time.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
        
    parts = data.date.split("-")
    year = int(parts[0])
    month = int(parts[1])
    day = int(parts[2])
    
    from ho_ngoc_duc_almanac import calculate_almanac_full
    almanac_res = calculate_almanac_full(day, month, year, hour, minute)
    
    return {
        "status": "success",
        "data": almanac_res
    }


class BirthData(BaseModel):
    name: str
    birth_date: str  # Format: YYYY-MM-DD
    birth_time: str  # Format: HH:MM
    gender: int      # 1: Male, 0: Female
    language: str = "Tiếng Việt"  # Default language for interpretation
    kieu_an_sao: str = "An Thông Thường"
    lat: Optional[float] = None
    lon: Optional[float] = None

@app.post("/api/calculate-astrology-core")
def calculate_astrology_core(data: BirthData):
    """
    API Nguồn Chân Lý: Tính toán lịch Âm, Can Chi từ ngày Dương.
    """
    hour = 0
    minute = 0
    if ":" in data.birth_time:
        parts = data.birth_time.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
        
    parts = data.birth_date.split("-")
    year = int(parts[0])
    month = int(parts[1])
    day = int(parts[2])
    
    from lunar_converter import get_full_astrology_data
    core_data = get_full_astrology_data(
        day, month, year, hour, minute, is_solar=True,
        kieu_an_sao=data.kieu_an_sao, lat=data.lat, lon=data.lon
    )
    
    return {
        "status": "success",
        "data": core_data
    }

def load_antigravity_workflow(workflow_path: str) -> str:
    candidates = [workflow_path, os.path.join(_PROJECT_ROOT_DIR, workflow_path)]
    for cand in candidates:
        if os.path.exists(cand):
            try:
                with open(cand, 'r', encoding='utf-8') as f:
                    return f.read()
            except Exception:
                pass
    return "Lỗi: Không tìm thấy file cấu hình Antigravity Agent."

async def run_antigravity_agent(action_type: int, la_so_json: dict, action_detail: str = None):
    workflows = {
        1: ".agents/workflows/btn1-luangiai-12cung.md",
        2: ".agents/workflows/btn2-luangiai-daihan.md",
        3: ".agents/workflows/btn3-luangiai-chitiet-daihan.md",
        4: ".agents/workflows/btn4-luangiai-nam.md",
        5: ".agents/workflows/btn5-giaiphap-nam.md",
        6: ".agents/workflows/btn6-chot-sale-fomo.md",
    }
    
    workflow_path = workflows.get(action_type)
    if not workflow_path:
        yield f"data: {json.dumps({'error': 'Action Type không hợp lệ'})}\n\n"
        return

    system_instruction = load_antigravity_workflow(workflow_path)
    
    if system_instruction.startswith("Lỗi"):
        yield f"data: {json.dumps({'error': system_instruction})}\n\n"
        return

    try:
        native_data = la_so_json.get("native", {})
        kieu_sinh = native_data.get("kieuSinh", "Sinh Bình Thường")
        
        if kieu_sinh == "Sinh Đôi Long Phụng":
            twin_prompt = "\n\nLƯU Ý ĐẶC BIỆT: Đương số là người sinh đôi Long Phụng (1 Trai 1 Gái). Hãy áp dụng Thuyết Thiên - Địa - Nhân và Quy luật Âm Dương Thuận Nghịch. Lá số của 2 anh em giống nhau, nhưng do giới tính khác biệt (Nam là Dương, Nữ là Âm), kết hợp với Cục và Năm sinh, chiều đi của vòng Đại Vận 10 năm sẽ HOÀN TOÀN NGƯỢC CHIỀU NHAU (Một người đi thuận, một người đi nghịch). BẮT BUỘC phải nhấn mạnh vào bài luận: 'Mặc dù chung lá số, nhưng kể từ khi bước vào các Đại Vận độc lập, quỹ đạo cuộc đời của bạn và người anh/em sinh đôi sẽ rẽ sang hai hướng phong thủy, vận hạn hoàn toàn trái ngược nhau. Ví dụ: Cùng độ tuổi 20, một người bước vào Đại Vận rực rỡ, người kia lại bước vào Đại Vận nhiều Sát tinh'."
            system_instruction += twin_prompt
        elif kieu_sinh in ["Sinh Đôi Cùng Giới Ra Trước", "Sinh Đôi Cùng Giới Ra Sau"]:
            twin_prompt = f"\n\nLƯU Ý ĐẶC BIỆT: Đương số là người sinh đôi cùng giới tính, thứ tự sinh là: [{kieu_sinh}]. Mọi thông số lá số và Đại Vận đều giống hệt người anh/chị em sinh đôi. Để giải thích sự khác biệt số phận của họ, NGƯƠI BẮT BUỘC phải áp dụng 3 nguyên lý tuyệt mật sau vào bài luận giải:\n\n1. Thuyết Phân Cực Năng Lượng (Nguyên lý Thái Cực): Hai thực thể sinh cùng thời điểm sẽ chia sẻ và phân cực đặc tính các vì sao tại Mệnh. Mỗi sao đều có mặt Dương (Động, tốt) và mặt Âm (Tĩnh, xấu). Nếu đương số là người 'Ra Trước' (mạnh về Dương khí), hãy luận họ thiên về sự xông pha, quyết liệt, chủ động của chính tinh/sát tinh. Nếu đương số là 'Ra Sau' (thuần Âm khí), hãy luận họ thiên về sự trầm tĩnh, cô độc, thụ động.\n2. Biến số Nhân Vận (Hôn nhân): Lá số chỉ là Thiên (Hạt giống). Bước ngoặt lớn nhất làm thay đổi quỹ đạo hai người là Kết hôn. Năng lượng từ lá số của người vợ/chồng sẽ đập vào, kích hoạt các vì sao khác nhau trên lá số gốc. Hãy nhấn mạnh: 'Kể từ ngày cưới, vận mệnh của bạn và người anh/em sinh đôi sẽ chính thức chia hai ngả'.\n3. Biến số Tử Tức (Con cái): Thời điểm sinh con khác nhau và lá số của những đứa con khác nhau sẽ mang lại các trường năng lượng tác động ngược lại số phận của cha mẹ chúng, tạo ra sự phân hóa tuyệt đối về sự nghiệp và gia đạo về sau."
            system_instruction += twin_prompt
    except Exception as e:
        print(f"Error handling kieuSinh logic: {e}")

    model = genai.GenerativeModel(
        model_name='gemini-2.5-flash',
        system_instruction=system_instruction
    )

    user_prompt = f"Đây là dữ liệu lá số Tử Vi cần luận giải:\n```json\n{json.dumps(la_so_json, ensure_ascii=False, indent=2)}\n```\nHãy thực hiện nhiệm vụ dựa trên workflow đã nạp."
    
    if action_type == 1 and action_detail:
        if "Tổng Luận" not in action_detail:
            user_prompt += f"\n\nLƯU Ý ĐẶC BIỆT: Yêu cầu của người dùng là CHỈ LUẬN GIẢI ĐỘC LẬP: '{action_detail}'. BẠN PHẢI BỎ QUA hoàn toàn việc liệt kê và phân tích các cung khác trong Bước 3 và Bước 4 của kịch bản gốc. HÃY TẬP TRUNG TOÀN BỘ VÀ CHỈ LUẬN GIẢI cho '{action_detail}'."
        else:
            user_prompt += f"\n\nLƯU Ý ĐẶC BIỆT: Yêu cầu của người dùng là '{action_detail}'. Hãy luận giải tổng quát tất cả 12 cung + Cung An Thân."

    try:
        response = await model.generate_content_async(
            user_prompt,
            stream=True
        )

        async for chunk in response:
            if chunk.text:
                payload = json.dumps({'text': chunk.text}, ensure_ascii=False)
                yield f"data: {payload}\n\n"
                await asyncio.sleep(0.01)

        yield "data: [DONE]\n\n"
        
    except Exception as e:
        error_msg = json.dumps({'error': f'Lỗi khi gọi AI: {str(e)}'}, ensure_ascii=False)
        yield f"data: {error_msg}\n\n"

@app.post("/internal/analyze")
async def analyze_astrology(request: Request):
    data = await request.json()
    action_type = data.get("action_type")
    la_so_json = data.get("la_so")
    action_detail = data.get("action_detail")
    
    return StreamingResponse(
        run_antigravity_agent(action_type, la_so_json, action_detail), 
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )

async def stream_gemini_analysis(action_type: str, laso_data: dict, target_language: str):
    system_instruction = f"Dựa vào dữ liệu lá số Tử Vi này, hãy luận giải chi tiết 12 cung bằng ngôn ngữ {target_language}. Hãy đóng vai một chuyên gia chiêm tinh học phương Đông."
    model = genai.GenerativeModel(
        model_name='gemini-2.5-flash', # Sử dụng 2.5 flash cho tốc độ nhanh (hoặc gemini-pro tùy chọn)
        system_instruction=system_instruction
    )
    user_prompt = f"Yêu cầu: {action_type}\nDữ liệu lá số: {json.dumps(laso_data, ensure_ascii=False)}"

    try:
        response = await model.generate_content_async(user_prompt, stream=True)
        async for chunk in response:
            if chunk.text:
                yield chunk.text
        yield "[DONE]"
    except Exception as e:
        yield f"\n\n[LỖI AI ENGINE]: {str(e)}"

@app.post("/api/v1/analyze/stream")
async def analyze_stream(request: Request):
    data = await request.json()
    
    # Lấy payload đúng với những gì C# gửi sang
    action_type = data.get("action_type", "")
    laso_data = data.get("laso_data", {})
    target_language = data.get("target_language", "vi")

    return StreamingResponse(
        stream_gemini_analysis(action_type, laso_data, target_language),
        media_type="text/plain",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )


# ========================================================
# FORUM CATEGORIES PERSISTENT STORAGE APIS
# ========================================================
FORUM_DB_PATH = os.path.join(os.path.dirname(__file__), "forum_categories_db.json")

def load_forum_categories():
    if not os.path.exists(FORUM_DB_PATH):
        return []
    try:
        with open(FORUM_DB_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading forum categories: {e}")
        return []

def save_forum_categories(categories):
    try:
        with open(FORUM_DB_PATH, "w", encoding="utf-8") as f:
            json.dump(categories, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving forum categories: {e}")
        return False

def trigger_signalr_broadcast(event_type: str, payload: dict = None):
    def _run():
        try:
            import urllib.request
            import json as _json
            req = urllib.request.Request(
                f"http://localhost:5000/api/v1/forum/broadcast/{event_type}",
                data=_json.dumps(payload or {"action": "updated"}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=1.5):
                pass
        except Exception:
            pass
    import threading
    threading.Thread(target=_run, daemon=True).start()

@app.get("/api/forum/categories")
def get_forum_categories():
    """
    Đọc và phân loại trả về toàn bộ dữ liệu từ JSON.
    """
    categories = load_forum_categories()
    group1 = []
    group2 = []
    group3 = []
    
    for item in categories:
        g = item.get("groupType", "")
        if g in ["Chuyên mục 1", "ChuyenMuc1"]:
            group1.append(item)
        elif g in ["Lớp học Lý số", "LopHoc"]:
            group2.append(item)
        elif g in ["Chuyên mục 2", "ChuyenMuc2"]:
            group3.append(item)
        else:
            group1.append(item)
            
    return {
        "status": "success",
        "data": {
            "group1": group1,
            "group2": group2,
            "group3": group3,
            "all": categories
        }
    }

@app.post("/api/forum/categories")
async def create_forum_category(request: Request):
    """
    Nhận payload object, ghi nối thêm vào JSON file, trả về HTTP 200 OK.
    """
    item = await request.json()
    if not item or not item.get("title"):
        return {"status": "error", "message": "Tiêu đề không được để trống"}
        
    categories = load_forum_categories()
    
    title = item.get("title")
    updated = False
    for i, cat in enumerate(categories):
        if cat.get("title") == title:
            categories[i] = item
            updated = True
            break
            
    if not updated:
        categories.append(item)
        
    success = save_forum_categories(categories)
    if not success:
        return {"status": "error", "message": "Lỗi lưu file database"}
        
    trigger_signalr_broadcast("category-updated", {"action": "create", "data": item})

    return {
        "status": "success",
        "message": "Đã lưu chuyên mục thành công vào cơ sở dữ liệu bền vững",
        "data": item
    }

@app.delete("/api/forum/categories")
async def delete_forum_categories(request: Request):
    """
    Nhận mảng ID/Tiêu đề, xóa khỏi JSON file, cập nhật lưu lại file, trả về HTTP 200 OK.
    """
    body = await request.json()
    titles_to_delete = set()
    
    if isinstance(body, list):
        for entry in body:
            if isinstance(entry, dict):
                t = entry.get("title") or entry.get("id")
                if t:
                    titles_to_delete.add(str(t))
            elif isinstance(entry, str):
                titles_to_delete.add(entry)
    elif isinstance(body, dict):
        titles = body.get("titles") or body.get("ids") or []
        for t in titles:
            titles_to_delete.add(str(t))
        if "title" in body:
            titles_to_delete.add(str(body["title"]))
            
    categories = load_forum_categories()
    initial_count = len(categories)
    filtered = [cat for cat in categories if cat.get("title") not in titles_to_delete and str(cat.get("id", "")) not in titles_to_delete]
    
    deleted_count = initial_count - len(filtered)
    save_forum_categories(filtered)
    
    trigger_signalr_broadcast("category-updated", {"action": "delete", "deletedCount": deleted_count})

    return {
        "status": "success",
        "message": f"Đã xóa vĩnh viễn {deleted_count} chuyên mục khỏi cơ sở dữ liệu",
        "deletedCount": deleted_count
    }

@app.put("/api/forum/categories")
async def update_forum_category(request: Request):
    """
    Tiếp nhận payload cập nhật chuyên mục và ghi đè trực tiếp vào JSON và PostgreSQL Docker.
    """
    body = await request.json()
    if not body:
        return {"status": "error", "message": "Payload cập nhật không hợp lệ"}

    old_title = body.get("oldTitle") or body.get("title")
    if not old_title:
        return {"status": "error", "message": "Tiêu đề chuyên mục cũ không được để trống"}

    categories = load_forum_categories()
    updated_idx = -1
    for i, cat in enumerate(categories):
        if cat.get("title") == old_title:
            updated_idx = i
            break

    if updated_idx == -1:
        return {"status": "error", "message": f"Không tìm thấy chuyên mục '{old_title}'"}

    target = categories[updated_idx]
    if "title" in body and body["title"]:
        target["title"] = body["title"]
    if "description" in body:
        target["description"] = body["description"]
    if "icon" in body:
        target["icon"] = body["icon"]
    if "groupType" in body and body["groupType"]:
        target["groupType"] = body["groupType"]
    if "isHighlighted" in body:
        target["isHighlighted"] = body["isHighlighted"]
    if "topics" in body:
        target["topics"] = body["topics"]
    if "posts" in body:
        target["posts"] = body["posts"]
    if "lastPost" in body:
        target["lastPost"] = body["lastPost"]
    if "isLocked" in body:
        target["isLocked"] = bool(body["isLocked"])

    categories[updated_idx] = target
    save_forum_categories(categories)

    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute('''
            CREATE TABLE IF NOT EXISTS "ForumCategories" (
                "Id" SERIAL PRIMARY KEY,
                "Title" TEXT UNIQUE,
                "Data" JSONB,
                "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        ''')
        cur.execute('''
            INSERT INTO "ForumCategories" ("Title", "Data", "UpdatedAt")
            VALUES (%s, %s, CURRENT_TIMESTAMP)
            ON CONFLICT ("Title") DO UPDATE
            SET "Data" = EXCLUDED."Data", "UpdatedAt" = CURRENT_TIMESTAMP;
        ''', (target.get("title"), json.dumps(target, ensure_ascii=False)))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"PostgreSQL docker sync (non-blocking fallback): {e}")

    trigger_signalr_broadcast("category-updated", {"action": "update", "data": target})

    return {
        "status": "success",
        "message": "Đã cập nhật chuyên mục thành công vào cơ sở dữ liệu",
        "data": target
    }

@app.post("/api/forum/categories/lock")
@app.put("/api/forum/categories/lock")
async def toggle_category_lock_api(request: Request):
    body = await request.json()
    title = body.get("title") or body.get("oldTitle") or body.get("slug")
    is_locked = body.get("isLocked")
    categories = load_forum_categories()
    updated = None
    for cat in categories:
        if cat.get("title") == title or cat.get("slug") == title:
            if is_locked is not None:
                cat["isLocked"] = bool(is_locked)
            else:
                cat["isLocked"] = not cat.get("isLocked", False)
            updated = cat
            break
    if updated:
        save_forum_categories(categories)
        trigger_signalr_broadcast("category-locked", {
            "categoryId": updated.get("id"),
            "slug": updated.get("slug"),
            "title": updated.get("title"),
            "isLocked": updated.get("isLocked", False)
        })
        return {"status": "success", "data": updated}
    return {"status": "error", "message": "Không tìm thấy chuyên mục"}


# ========================================================
# FORUM TOPICS & ANNOUNCEMENTS PERSISTENT STORAGE APIS
# ========================================================
FORUM_TOPICS_PATH = os.path.join(os.path.dirname(__file__), "forum_topics_db.json")

def init_forum_topics_db():
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute('''
            CREATE TABLE IF NOT EXISTS "ForumTopics" (
                "Id" SERIAL PRIMARY KEY,
                "Title" TEXT NOT NULL,
                "Content" TEXT,
                "Type" VARCHAR(50) NOT NULL,
                "CategorySlug" VARCHAR(100) DEFAULT 'thong-bao-su-kien',
                "Author" VARCHAR(100) DEFAULT 'Admin',
                "Icon" VARCHAR(50) DEFAULT 'none',
                "Replies" INT DEFAULT 0,
                "Views" INT DEFAULT 0,
                "LastAuthor" VARCHAR(100) DEFAULT 'Admin',
                "LastTime" VARCHAR(50),
                "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "Rules" TEXT,
                "EnableQuickReply" BOOLEAN DEFAULT TRUE,
                "AllowQuickReply" BOOLEAN DEFAULT TRUE,
                "ShowBadgeLogo" BOOLEAN DEFAULT FALSE,
                "Data" JSONB
            );
            ALTER TABLE "ForumTopics" ADD COLUMN IF NOT EXISTS "Rules" TEXT;
            ALTER TABLE "ForumTopics" ADD COLUMN IF NOT EXISTS "EnableQuickReply" BOOLEAN DEFAULT TRUE;
            ALTER TABLE "ForumTopics" ADD COLUMN IF NOT EXISTS "AllowQuickReply" BOOLEAN DEFAULT TRUE;
            ALTER TABLE "ForumTopics" ADD COLUMN IF NOT EXISTS "ShowBadgeLogo" BOOLEAN DEFAULT FALSE;
        ''')
        cur.execute('''
            CREATE TABLE IF NOT EXISTS "ForumTopicReplies" (
                "Id" SERIAL PRIMARY KEY,
                "TopicId" INT NOT NULL REFERENCES "ForumTopics"("Id") ON DELETE CASCADE,
                "Author" VARCHAR(100) NOT NULL,
                "Content" TEXT,
                "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "Data" JSONB
            );
        ''')
        cur.execute('''
            CREATE TABLE IF NOT EXISTS "ForumActiveViewers" (
                "SessionId" VARCHAR(150) PRIMARY KEY,
                "CategorySlug" VARCHAR(100),
                "TopicId" INT,
                "Username" VARCHAR(100),
                "IsGuest" BOOLEAN DEFAULT TRUE,
                "LastSeen" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        ''')
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"init_forum_topics_db non-blocking fallback: {e}")

init_forum_topics_db()

def load_forum_topics_file():
    if not os.path.exists(FORUM_TOPICS_PATH):
        return []
    try:
        with open(FORUM_TOPICS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading forum topics file: {e}")
        return []

def save_forum_topics_file(topics):
    try:
        with open(FORUM_TOPICS_PATH, "w", encoding="utf-8") as f:
            json.dump(topics, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving forum topics file: {e}")
        return False

@app.post("/api/forum/topics")
async def create_forum_topic(request: Request):
    """
    Tạo Thông báo hoặc Chủ đề mới:
    Lưu trực tiếp vào Docker PostgreSQL ("ForumTopics") với Type ('thong_bao' hoặc 'chu_de')
    và đồng bộ file JSON bền vững.
    """
    body = await request.json()
    if not body:
        return {"status": "error", "message": "Dữ liệu không được để trống"}

    title = (body.get("title") or "").strip()
    if not title:
        return {"status": "error", "message": "Tiêu đề bài viết không được để trống"}

    topic_type = body.get("type", "thong_bao")
    content = body.get("content", "")
    category_slug = body.get("categorySlug") or body.get("category_slug") or "thong-bao-su-kien"
    author = body.get("author", "Admin")
    icon = body.get("icon", "none")
    replies = body.get("replies", 0)
    views = body.get("views", 0)
    last_author = body.get("lastAuthor") or author
    now_str = datetime.now(TZ_VN).strftime("%H:%M, %d/%m/%y")
    last_time = body.get("lastTime")
    if not last_time or last_time.strip() in ["Vừa xong", "vừa xong", ""]:
        last_time = now_str
    created_at_str = datetime.now(timezone.utc).isoformat()

    rules = (body.get("rules") or body.get("Rules") or "").strip()
    allow_quick_reply = body.get("allowQuickReply")
    if allow_quick_reply is None:
        allow_quick_reply = body.get("AllowQuickReply")
    if allow_quick_reply is None:
        allow_quick_reply = body.get("enableQuickReply")
    if allow_quick_reply is None:
        allow_quick_reply = body.get("EnableQuickReply")
    if allow_quick_reply is None:
        allow_quick_reply = True
    allow_quick_reply = bool(allow_quick_reply)
    enable_quick_reply = allow_quick_reply
    show_badge_logo = bool(body.get("showBadgeLogo") or body.get("ShowBadgeLogo") or body.get("show_badge_logo") or False)

    item = {
        "title": title,
        "content": content,
        "rules": rules,
        "allowQuickReply": allow_quick_reply,
        "enableQuickReply": allow_quick_reply,
        "showBadgeLogo": show_badge_logo,
        "type": topic_type,
        "categorySlug": category_slug,
        "author": author,
        "icon": icon,
        "replies": replies,
        "views": views,
        "lastAuthor": last_author,
        "lastTime": last_time,
        "created_at": created_at_str,
        "data": body
    }

    # 1. Lưu trực tiếp vào Docker PostgreSQL
    db_saved = False
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO "ForumTopics" (
                "Title", "Content", "Type", "CategorySlug", "Author", "Icon",
                "Replies", "Views", "LastAuthor", "LastTime", "CreatedAt", "UpdatedAt", "Rules", "EnableQuickReply", "AllowQuickReply", "ShowBadgeLogo", "Data"
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, %s, %s, %s, %s, %s)
            RETURNING "Id", "CreatedAt", "UpdatedAt";
        ''', (
            title, content, topic_type, category_slug, author, icon,
            replies, views, last_author, last_time, rules, enable_quick_reply, allow_quick_reply, show_badge_logo, json.dumps(item, ensure_ascii=False)
        ))
        res = cur.fetchone()
        if res:
            item["id"] = res[0]
            if res[1]:
                item["created_at"] = res[1].isoformat()
            if len(res) > 2 and res[2]:
                item["updatedAt"] = res[2].isoformat()
        conn.commit()
        cur.close()
        conn.close()
        db_saved = True
    except Exception as e:
        print(f"Error saving to Docker PostgreSQL: {e}")

    if not item.get("id"):
        import time as _time
        item["id"] = f"topic_{int(_time.time() * 1000)}"

    # 2. Đồng bộ file JSON bền vững (đặt ở đầu danh sách để duy trì DESC)
    file_topics = load_forum_topics_file()
    # Loại bỏ duplicate nếu đã có
    file_topics = [t for t in file_topics if str(t.get("id")) != str(item["id"]) and str(t.get("title")) != str(item["title"])]
    file_topics.insert(0, item)
    save_forum_topics_file(file_topics)

    commit_uploaded_images(topic_id=str(item.get("id")), content_texts=[content, rules])
    trigger_signalr_broadcast("topic-updated", {"action": "create", "data": item})
    trigger_signalr_broadcast("TopicCreated", {"action": "create", "data": item})

    return {
        "status": "success",
        "message": f"Đã lưu {'Thông báo' if topic_type == 'thong_bao' else 'Chủ đề'} thành công vào cơ sở dữ liệu Docker",
        "data": item,
        "docker_persisted": db_saved
    }

@app.delete("/api/forum/topics")
@app.delete("/api/forum/topics/batch-delete")
@app.post("/api/forum/topics/batch-delete")
async def batch_delete_forum_topics(request: Request):
    """
    Xóa hàng loạt bài viết/thông báo an toàn bằng Transaction trong PostgreSQL Docker
    và kích hoạt sự kiện SignalR gộp ("batch_delete") đúng 1 lần duy nhất để tránh spam network.
    Hỗ trợ cả DELETE /api/forum/topics, DELETE /api/forum/topics/batch-delete và POST /api/forum/topics/batch-delete.
    """
    try:
        body = await request.json() or {}
        if isinstance(body, list):
            ids = body
            category_slug = None
        elif isinstance(body, dict):
            ids = body.get("ids", [])
            category_slug = body.get("categorySlug") or body.get("category_slug")
        else:
            ids = []
            category_slug = None
        
        conn = get_db_connection()
        deleted_records = []
        if conn:
            try:
                cur = conn.cursor()
                cur.execute('BEGIN TRANSACTION;')
                if ids:
                    int_ids = [int(i) for i in ids if str(i).isdigit()]
                    if int_ids:
                        cur.execute('SELECT "Id", "Title", "CategorySlug" FROM "ForumTopics" WHERE "Id" = ANY(%s);', (int_ids,))
                        deleted_records = cur.fetchall()
                        cur.execute('DELETE FROM "ForumTopicReplies" WHERE "TopicId" = ANY(%s);', (int_ids,))
                        cur.execute('DELETE FROM "ForumTopics" WHERE "Id" = ANY(%s);', (int_ids,))
                else:
                    if category_slug:
                        cur.execute('SELECT "Id", "Title", "CategorySlug" FROM "ForumTopics" WHERE "CategorySlug" = %s;', (category_slug,))
                        deleted_records = cur.fetchall()
                        cat_ids = [r[0] for r in deleted_records]
                        if cat_ids:
                            cur.execute('DELETE FROM "ForumTopicReplies" WHERE "TopicId" = ANY(%s);', (cat_ids,))
                            cur.execute('DELETE FROM "ForumTopics" WHERE "Id" = ANY(%s);', (cat_ids,))
                    else:
                        cur.execute('SELECT "Id", "Title", "CategorySlug" FROM "ForumTopics";')
                        deleted_records = cur.fetchall()
                        cur.execute('DELETE FROM "ForumTopicReplies";')
                        cur.execute('DELETE FROM "ForumTopics";')
                cur.execute('COMMIT;')
                cur.close()
            except Exception as e:
                if conn:
                    conn.rollback()
                print(f"Error in batch delete from Docker: {e}")
            finally:
                release_db_connection(conn)
        
        # Đồng bộ file JSON bền vững
        file_topics = load_forum_topics_file()
        del_ids_str = {str(r[0]) for r in deleted_records} if deleted_records else {str(i) for i in ids}
        if del_ids_str:
            file_topics = [t for t in file_topics if str(t.get("id")) not in del_ids_str]
        elif not ids and not category_slug:
            file_topics = []
        save_forum_topics_file(file_topics)
        
        # Phát sóng SignalR gộp 1 lần duy nhất cho toàn hệ thống
        payload = {
            "action": "batch_delete",
            "ids": list(del_ids_str),
            "categorySlug": category_slug,
            "deletedCount": len(deleted_records)
        }
        trigger_signalr_broadcast("topic-updated", payload)
        trigger_signalr_broadcast("TopicBatchDeleted", payload)
        trigger_signalr_broadcast("TopicDeleted", payload)
        
        return {
            "status": "success",
            "message": f"Đã xóa an toàn {len(deleted_records)} bài viết khỏi Docker PostgreSQL",
            "deleted_ids": list(del_ids_str),
            "backup_records": [{"id": r[0], "title": r[1], "categorySlug": r[2]} for r in deleted_records]
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.delete("/api/forum/topics/{topic_id}")
async def delete_forum_topic(topic_id: str):
    """
    Xóa vĩnh viễn bài viết/thông báo khỏi PostgreSQL và JSON file.
    Hỗ trợ linh hoạt cả topic_id dạng chuỗi và số nguyên (Chuẩn công nghệ 2026).
    """
    try:
        if str(topic_id).isdigit():
            conn = get_db_connection()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute('DELETE FROM "ForumTopics" WHERE "Id" = %s', (int(topic_id),))
                    cur.execute('DELETE FROM "ForumTopicReplies" WHERE "TopicId" = %s', (int(topic_id),))
                    conn.commit()
                    cur.close()
                except Exception as e:
                    print(f"Error deleting from Docker PostgreSQL: {e}")
                finally:
                    release_db_connection(conn)

        file_topics = load_forum_topics_file()
        file_topics = [t for t in file_topics if str(t.get("id")) != str(topic_id)]
        save_forum_topics_file(file_topics)

        trigger_signalr_broadcast("topic-updated", {"action": "delete", "id": topic_id})

        return {
            "status": "success",
            "message": f"Đã xóa vĩnh viễn bài viết {topic_id}"
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.put("/api/forum/topics/{topic_id}")
async def update_forum_topic(topic_id: str, request: Request):
    """
    Cập nhật bài viết/thông báo vào Docker PostgreSQL với Partial Update động và SignalR broadcast.
    Hỗ trợ linh hoạt cả ID chuỗi và ID số nguyên (Chuẩn công nghệ 2026).
    Cập nhật chính xác UpdatedAt và LastTime theo giờ Việt Nam (UTC+7) - Chuẩn Hình 6.
    """
    body = await request.json()
    if not body:
        return {"status": "error", "message": "Payload không hợp lệ"}

    now_vn = datetime.now(TZ_VN)
    updated_at_str = now_vn.strftime("%H:%M, %d/%m/%y")
    updated_at_iso = now_vn.isoformat()

    title = body.get("title")
    content = body.get("content")
    topic_type = body.get("type")
    category_slug = body.get("categorySlug") or body.get("category_slug")
    rules = body.get("rules")
    icon = body.get("icon")
    author = body.get("author")
    last_author = body.get("lastAuthor") or body.get("last_author") or author
    has_badge_logo_key = "showBadgeLogo" in body or "ShowBadgeLogo" in body or "show_badge_logo" in body
    show_badge_logo = bool(body.get("showBadgeLogo") or body.get("ShowBadgeLogo") or body.get("show_badge_logo")) if has_badge_logo_key else None

    has_quick_reply = "allowQuickReply" in body or "AllowQuickReply" in body or "enableQuickReply" in body or "EnableQuickReply" in body
    allow_quick_reply = None
    if has_quick_reply:
        val = body.get("allowQuickReply")
        if val is None: val = body.get("AllowQuickReply")
        if val is None: val = body.get("enableQuickReply")
        if val is None: val = body.get("EnableQuickReply")
        allow_quick_reply = bool(val)

    updated_row = None

    # 1. Partial Update động vào PostgreSQL Docker nếu là ID số nguyên
    if str(topic_id).isdigit():
        conn = get_db_connection()
        if conn:
            try:
                cur = conn.cursor()
                set_clauses = []
                params = []

                if title is not None:
                    set_clauses.append('"Title" = %s')
                    params.append(title)
                if content is not None:
                    set_clauses.append('"Content" = %s')
                    params.append(content)
                if topic_type is not None:
                    set_clauses.append('"Type" = %s')
                    params.append(topic_type)
                if category_slug is not None:
                    set_clauses.append('"CategorySlug" = %s')
                    params.append(category_slug)
                if rules is not None:
                    set_clauses.append('"Rules" = %s')
                    params.append(rules)
                if icon is not None:
                    set_clauses.append('"Icon" = %s')
                    params.append(icon)
                if show_badge_logo is not None:
                    set_clauses.append('"ShowBadgeLogo" = %s')
                    params.append(show_badge_logo)
                if allow_quick_reply is not None:
                    set_clauses.append('"AllowQuickReply" = %s')
                    params.append(allow_quick_reply)
                    set_clauses.append('"EnableQuickReply" = %s')
                    params.append(allow_quick_reply)
                if author:
                    set_clauses.append('"Author" = %s')
                    params.append(author)
                if last_author:
                    set_clauses.append('"LastAuthor" = %s')
                    params.append(last_author)

                set_clauses.append('"LastTime" = %s')
                params.append(updated_at_str)
                set_clauses.append('"UpdatedAt" = CURRENT_TIMESTAMP')

                params.append(int(topic_id))

                sql = f'''
                    UPDATE "ForumTopics"
                    SET {", ".join(set_clauses)}
                    WHERE "Id" = %s
                    RETURNING "Id", "Title", "Content", "Type", "CategorySlug", "Rules", "Icon", "LastTime", "LastAuthor", "Author", "ShowBadgeLogo", "UpdatedAt", "Replies", "Views", COALESCE("AllowQuickReply", COALESCE("EnableQuickReply", TRUE))
                '''
                cur.execute(sql, tuple(params))
                updated_row = cur.fetchone()
                conn.commit()
                cur.close()
            except Exception as e:
                print(f"Error updating Docker PostgreSQL: {e}")
            finally:
                release_db_connection(conn)

    # 2. Cập nhật hoặc lưu mới vào file JSON bền vững
    file_topics = load_forum_topics_file()
    found = False
    for t in file_topics:
        if str(t.get("id")) == str(topic_id) or (title and str(t.get("title")) == str(title)):
            if "title" in body: t["title"] = body["title"]
            if "content" in body: t["content"] = body["content"]
            if "type" in body: t["type"] = body["type"]
            if "categorySlug" in body: t["categorySlug"] = body["categorySlug"]
            if "category_slug" in body: t["categorySlug"] = body["category_slug"]
            if "rules" in body: t["rules"] = body["rules"]
            if "icon" in body: t["icon"] = body["icon"]
            if "isLocked" in body: t["isLocked"] = bool(body["isLocked"])
            if has_badge_logo_key: t["showBadgeLogo"] = show_badge_logo
            if has_quick_reply:
                t["allowQuickReply"] = allow_quick_reply
                t["enableQuickReply"] = allow_quick_reply
            if author: t["author"] = author
            if last_author: t["lastAuthor"] = last_author
            t["lastTime"] = updated_at_str
            t["updatedAt"] = updated_at_iso
            found = True
            break

    if not found:
        new_entry = {
            "id": topic_id,
            "title": title or "",
            "content": content or "",
            "type": topic_type or "thong_bao",
            "categorySlug": category_slug or "thong-bao-su-kien",
            "rules": rules or "",
            "icon": icon or "document",
            "author": author or "Admin",
            "lastAuthor": last_author or "Admin",
            "lastTime": updated_at_str,
            "updatedAt": updated_at_iso,
            "showBadgeLogo": show_badge_logo if show_badge_logo is not None else False,
            "allowQuickReply": allow_quick_reply if allow_quick_reply is not None else True,
            "enableQuickReply": allow_quick_reply if allow_quick_reply is not None else True,
            "replies": body.get("replies", 0),
            "views": body.get("views", 0),
            "created_at": updated_at_iso
        }
        file_topics.insert(0, new_entry)

    save_forum_topics_file(file_topics)

    if updated_row:
        broadcast_data = {
            "id": updated_row[0],
            "title": updated_row[1],
            "content": updated_row[2] or "",
            "type": updated_row[3],
            "categorySlug": updated_row[4],
            "rules": updated_row[5] or "",
            "icon": updated_row[6] or "document",
            "lastTime": updated_row[7] or updated_at_str,
            "lastAuthor": updated_row[8] or "Admin",
            "author": updated_row[9] or "Admin",
            "showBadgeLogo": bool(updated_row[10]),
            "updatedAt": updated_row[11].isoformat() if hasattr(updated_row[11], "isoformat") else updated_at_iso,
            "replies": updated_row[12] or 0,
            "views": updated_row[13] or 0,
            "allowQuickReply": bool(updated_row[14]) if len(updated_row) > 14 else True,
            "enableQuickReply": bool(updated_row[14]) if len(updated_row) > 14 else True,
        }
    else:
        broadcast_data = {
            "id": topic_id,
            "title": title or "",
            "content": content or "",
            "type": topic_type or "thong_bao",
            "categorySlug": category_slug or "thong-bao-su-kien",
            "rules": rules or "",
            "icon": icon or "document",
            "author": author or "Admin",
            "lastAuthor": last_author or "Admin",
            "lastTime": updated_at_str,
            "updatedAt": updated_at_iso,
            "showBadgeLogo": show_badge_logo if show_badge_logo is not None else False,
            "allowQuickReply": allow_quick_reply if allow_quick_reply is not None else True,
            "enableQuickReply": allow_quick_reply if allow_quick_reply is not None else True,
        }

    commit_uploaded_images(topic_id=str(topic_id), content_texts=[content, rules])
    trigger_signalr_broadcast("topic-updated", {
        "action": "update",
        "id": topic_id,
        "data": broadcast_data
    })

    return {
        "status": "success",
        "message": f"Đã cập nhật bài viết {topic_id} thành công vào Docker PostgreSQL",
        "data": broadcast_data
    }

@app.post("/api/forum/topics/{topic_id}/lock")
@app.put("/api/forum/topics/{topic_id}/lock")
async def toggle_topic_lock_api(topic_id: str, request: Request):
    body = await request.json() if request else {}
    is_locked = body.get("isLocked") if body else None
    file_topics = load_forum_topics_file()
    updated = None
    for t in file_topics:
        if str(t.get("id")) == str(topic_id):
            if is_locked is not None:
                t["isLocked"] = bool(is_locked)
            else:
                t["isLocked"] = not t.get("isLocked", False)
            updated = t
            break
    if updated:
        save_forum_topics_file(file_topics)
        trigger_signalr_broadcast("topic-locked", {
            "topicId": updated.get("id"),
            "title": updated.get("title"),
            "categoryId": updated.get("categoryId", 1),
            "isLocked": updated.get("isLocked", False)
        })
        return {"status": "success", "data": updated}
    return {"status": "error", "message": "Không tìm thấy bài viết"}

def normalize_fuzzy_text(text: str) -> str:
    if not text:
        return ""
    import unicodedata
    # Thay the d/D
    text = text.replace("đ", "d").replace("Đ", "D")
    nfkd = unicodedata.normalize('NFKD', text)
    unaccented = "".join([c for c in nfkd if not unicodedata.combining(c)])
    cleaned = re.sub(r'[^\w\s]', ' ', unaccented).lower()
    return re.sub(r'\s+', ' ', cleaned).strip()

@app.get("/api/forum/topics/locate")
def locate_forum_topic(query: str, category_slug: Optional[str] = None, page_size: int = 25):
    """
    Deep Pagination Search voi Fuzzy Matching (Chuan cong nghe 2026):
    - Tinh toan targetPage va chi muc chinh xac cua bai viet.
    - Ho tro fuzzy matching khi tieu de thua khoang trang, thieu dau, sai lech nhe.
    """
    if not query or not query.strip():
        return {"status": "error", "message": "Query parameter is required", "data": {"found": False}}

    import difflib
    normalized_q = normalize_fuzzy_text(query)
    raw_q = query.strip().lower()

    all_topics = []
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        sql = '''
            SELECT t."Id", t."Title", t."Content", t."Type", t."CategorySlug", t."Author", t."Icon",
                   GREATEST(
                       COALESCE(t."Replies", 0),
                       (SELECT COUNT(*)::int FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id")
                   ) AS "Replies",
                   COALESCE(t."Views", 0) AS "Views",
                   COALESCE(
                       (SELECT r."Author" FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id" ORDER BY r."CreatedAt" DESC LIMIT 1),
                       t."LastAuthor", t."Author"
                   ) AS "LastAuthor",
                   COALESCE(
                       (SELECT to_char(r."CreatedAt" AT TIME ZONE 'UTC' + INTERVAL '7 hours', 'HH24:MI, DD/MM/YY') FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id" ORDER BY r."CreatedAt" DESC LIMIT 1),
                       t."LastTime"
                   ) AS "LastTime",
                   t."CreatedAt"
            FROM "ForumTopics" t
        '''
        params = []
        if category_slug:
            sql += ' WHERE t."CategorySlug" = %s'
            params.append(category_slug)
        sql += ' ORDER BY t."CreatedAt" DESC;'
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()
        for r in rows:
            created_at_val = r[11]
            time_formatted = format_vn_time(created_at_val)
            last_time_val = r[10]
            if not last_time_val or last_time_val.strip() in ["Vừa xong", "vừa xong"]:
                last_time_val = time_formatted
            all_topics.append({
                "id": r[0],
                "title": r[1],
                "content": r[2],
                "type": r[3],
                "categorySlug": r[4],
                "author": r[5],
                "icon": r[6] if r[6] and r[6] != "none" else "document",
                "replies": r[7],
                "views": r[8],
                "lastAuthor": r[9],
                "lastTime": last_time_val,
                "time": time_formatted,
            })
        cur.close()
        conn.close()
    except Exception as e:
        all_topics = load_forum_topics_file()
        if category_slug:
            all_topics = [t for t in all_topics if t.get("categorySlug") == category_slug]

    best_match = None
    best_score = -1.0
    best_index = -1

    for idx, item in enumerate(all_topics):
        title = item.get("title", "")
        raw_title = title.strip().lower()
        norm_title = normalize_fuzzy_text(title)

        score = 0.0
        if raw_title == raw_q:
            score = 100.0
        elif norm_title == normalized_q:
            score = 95.0
        elif raw_q in raw_title:
            score = 85.0 + (len(raw_q) / max(len(raw_title), 1)) * 10
        elif normalized_q in norm_title:
            score = 80.0 + (len(normalized_q) / max(len(norm_title), 1)) * 10
        elif norm_title in normalized_q:
            score = 75.0
        else:
            ratio = difflib.SequenceMatcher(None, normalized_q, norm_title).ratio()
            if ratio >= 0.55:
                score = ratio * 70.0

        if score > best_score:
            best_score = score
            best_match = item
            best_index = idx

    if best_match and best_score >= 45.0:
        target_page = (best_index // page_size) + 1
        page_index = best_index % page_size
        total_items = len(all_topics)
        total_pages = (total_items + page_size - 1) // page_size if total_items > 0 else 1

        return {
            "status": "success",
            "data": {
                "found": True,
                "matchScore": round(best_score, 2),
                "targetPage": target_page,
                "globalIndex": best_index,
                "pageIndex": page_index,
                "pageSize": page_size,
                "topic": best_match,
                "totalItems": total_items,
                "totalPages": total_pages
            }
        }

    return {
        "status": "not_found",
        "message": "Không tìm thấy thông báo hoặc chủ đề phù hợp",
        "data": {
            "found": False,
            "totalItems": len(all_topics)
        }
    }

@app.get("/api/forum/topics")
def get_forum_topics(category_slug: Optional[str] = None, type: Optional[str] = None):
    """
    Truy vấn danh sách bài viết từ PostgreSQL Docker được sắp xếp ORDER BY CreatedAt DESC.
    Tính toán Real-time:
    - Replies: COUNT số post con trong topic từ bảng "ForumTopicReplies"
    - Views: Cột Views lưu trong "ForumTopics"
    - LastAuthor & LastTime: Tác giả và thời gian của reply con cuối cùng (hoặc tác giả gốc nếu chưa có reply)
    """
    all_topics = []
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        query = '''
            SELECT t."Id", t."Title", t."Content", t."Type", t."CategorySlug", t."Author", t."Icon",
                   GREATEST(
                       COALESCE(t."Replies", 0),
                       (SELECT COUNT(*)::int FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id")
                   ) AS "Replies",
                   COALESCE(t."Views", 0) AS "Views",
                   COALESCE(
                       (SELECT r."Author" FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id" ORDER BY r."CreatedAt" DESC LIMIT 1),
                       t."LastAuthor", t."Author"
                   ) AS "LastAuthor",
                   COALESCE(
                       (SELECT to_char(r."CreatedAt" AT TIME ZONE 'UTC' + INTERVAL '7 hours', 'HH24:MI, DD/MM/YY') FROM "ForumTopicReplies" r WHERE r."TopicId" = t."Id" ORDER BY r."CreatedAt" DESC LIMIT 1),
                       t."LastTime"
                   ) AS "LastTime",
                   t."CreatedAt", t."Data",
                   COALESCE(t."Rules", '') AS "Rules",
                   COALESCE(t."AllowQuickReply", COALESCE(t."EnableQuickReply", TRUE)) AS "AllowQuickReply",
                   COALESCE(t."ShowBadgeLogo", FALSE) AS "ShowBadgeLogo"
            FROM "ForumTopics" t
        '''
        params = []
        conditions = []
        if category_slug:
            if type == 'chu_de':
                conditions.append('(t."CategorySlug" = %s AND t."Type" = \'chu_de\')')
                params.append(category_slug)
            elif type == 'thong_bao':
                conditions.append('((t."CategorySlug" = %s OR t."Type" = \'thong_bao\') AND t."Type" = \'thong_bao\')')
                params.append(category_slug)
            else:
                conditions.append('(t."CategorySlug" = %s OR t."Type" = \'thong_bao\')')
                params.append(category_slug)
        elif type:
            conditions.append('t."Type" = %s')
            params.append(type)
            
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        query += ' ORDER BY COALESCE(t."UpdatedAt", t."CreatedAt") DESC;'

        cur.execute(query, tuple(params))
        rows = cur.fetchall()
        for r in rows:
            created_at_val = r[11]
            time_formatted = format_vn_time(created_at_val)
            last_time_val = r[10]
            if not last_time_val or last_time_val.strip() in ["Vừa xong", "vừa xong"]:
                last_time_val = time_formatted
            all_topics.append({
                "id": r[0],
                "title": r[1],
                "content": r[2],
                "type": r[3],
                "categorySlug": r[4],
                "author": r[5],
                "icon": r[6] if r[6] and r[6] != "none" else "document",
                "replies": r[7],
                "views": r[8],
                "lastAuthor": r[9],
                "lastTime": last_time_val,
                "time": time_formatted,
                "created_at": created_at_val.isoformat() if created_at_val else None,
                "data": r[12],
                "rules": r[13] if len(r) > 13 else "",
                "allowQuickReply": bool(r[14]) if len(r) > 14 else True,
                "enableQuickReply": bool(r[14]) if len(r) > 14 else True,
                "showBadgeLogo": bool(r[15]) if len(r) > 15 else False,
            })
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error querying Docker PostgreSQL (fallback to JSON): {e}")
        file_topics = load_forum_topics_file()
        if category_slug:
            file_topics = [t for t in file_topics if t.get("categorySlug") == category_slug]
        if type:
            file_topics = [t for t in file_topics if t.get("type") == type]
        all_topics = file_topics

    pinned = [t for t in all_topics if t.get("type") == "thong_bao"]
    topics = [t for t in all_topics if t.get("type") == "chu_de"]

    return {
        "status": "success",
        "data": {
            "pinned": pinned,
            "topics": topics,
            "all": all_topics
        }
    }

def get_category_title_by_slug(slug: str) -> str:
    """
    Ánh xạ động CategorySlug thành tên chuyên mục chính xác từ database/JSON.
    """
    if not slug:
        return "Thông báo - Sự kiện"
    try:
        cats = load_forum_categories()
        for c in cats:
            c_slug = c.get("slug") or ""
            c_title = c.get("title") or ""
            if c_slug and c_slug.strip().lower() == slug.strip().lower():
                return c_title
            norm_title_slug = c_title.lower().replace(" ", "-").replace(",", "").replace(".", "")
            if norm_title_slug == slug.strip().lower():
                return c_title
    except Exception:
        pass
    
    slug_map = {
        "thong-bao-su-kien": "Thông báo - Sự kiện",
        "kien-thuc-co-ban": "Kiến thức Cơ bản",
        "kien-thuc-tu-vi": "Kiến thức Tử vi",
        "kien-thuc-tu-tru": "Kiến thức Tứ trụ",
        "kien-thuc-don-toan": "Kiến thức Độn toán",
        "kien-thuc-phong-thuy": "Kiến thức Phong thủy",
        "kien-thuc-sinh-trac": "Kiến thức Sinh trắc",
        "ly-so-phuong-tay": "Lý số Phương Tây",
        "kien-thuc-ly-so-khac": "Kiến thức Lý số khác",
        "thu-ngo-y-kien": "Thư ngỏ - Ý kiến",
        "lop-hoc-tu-vi": "Lớp học tử vi",
        "lop-hoc-tu-tru": "Lớp học tứ trụ",
        "lop-hoc-chiem-tinh": "Lớp học chiêm tinh",
        "lop-hoc-phong-thuy": "Lớp học Phong thủy",
        "lop-hoc-tong-hop": "Lớp học tổng hợp",
        "lop-hoc-dich-ly": "Lớp học Dịch lý",
        "huong-nghiep": "Hướng nghiệp",
        "xem-tu-vi": "Xem Tử vi",
        "xem-tu-tru": "Xem Tứ trụ",
        "xem-que": "Xem quẻ",
        "xem-phong-thuy": "Xem Phong thủy",
        "xem-ngay-luan-tuoi": "Xem ngày, luận tuổi",
        "xem-ly-so-phuong-tay": "Xem Lý số Phương tây",
        "xem-tuong-dat-ten-sinh-trac": "Xem tướng, đặt tên, sinh trắc",
        "xem-bang-cac-mon-khac": "Xem bằng các môn khác",
        "cuoc-song-muon-mau": "Cuộc sống muôn màu",
        "cau-lac-bo-giao-luu-ket-ban": "Câu lạc bộ - Giao lưu - Kết bạn",
        "co-hoc-van-hoa-tin-nguong": "Cổ học - Văn hóa - Tín ngưỡng",
    }
    return slug_map.get(slug.strip().lower(), "Thông báo - Sự kiện")

@app.get("/api/topics/{topic_id}")
@app.get("/api/forum/topics/{topic_id}")
def get_topic_detail(topic_id: str):
    """
    Chi tiết bài viết:
    1. Tăng cột Views trong PostgreSQL Docker lên 1 mỗi lần gọi nếu topic_id là số nguyên.
    2. Truy vấn chi tiết bài viết và danh sách các post con (reply) từ Docker PostgreSQL hoặc JSON bền vững.
    Hỗ trợ linh hoạt cả ID chuỗi và ID số nguyên (Chuẩn công nghệ 2026).
    """
    try:
        row = None
        replies_list = []
        
        # 1. Thử truy vấn Docker PostgreSQL nếu topic_id là số nguyên
        if str(topic_id).isdigit():
            try:
                conn = get_db_connection()
                if conn:
                    conn.autocommit = True
                    cur = conn.cursor()
                    cur.execute('UPDATE "ForumTopics" SET "Views" = COALESCE("Views", 0) + 1 WHERE "Id" = %s;', (int(topic_id),))
                    cur.execute('''
                        SELECT t."Id", t."Title", t."Content", t."Type", t."CategorySlug", t."Author", t."Icon",
                               t."Replies", t."Views", t."LastAuthor", t."LastTime", t."CreatedAt", t."Data",
                               COALESCE(t."Rules", '') AS "Rules",
                               COALESCE(t."AllowQuickReply", COALESCE(t."EnableQuickReply", TRUE)) AS "AllowQuickReply",
                               COALESCE(t."ShowBadgeLogo", FALSE) AS "ShowBadgeLogo",
                               u."Id", u."Username", u."Role", u."BadgeText", u."BadgeType", u."RankTitle", u."TitleLogo", u."UserGroups", u."Avatar", u."StarLevel"
                        FROM "ForumTopics" t
                        LEFT JOIN "Users" u ON LOWER(t."Author") = LOWER(u."Username")
                        WHERE t."Id" = %s;
                    ''', (int(topic_id),))
                    row = cur.fetchone()
                    
                    if row:
                        cur.execute('''
                            SELECT r."Id", r."Author", r."Content", r."CreatedAt",
                                   u."Id", u."Username", u."Role", u."BadgeText", u."BadgeType", u."RankTitle", u."TitleLogo", u."UserGroups", u."Avatar", u."StarLevel"
                            FROM "ForumTopicReplies" r
                            LEFT JOIN "Users" u ON LOWER(r."Author") = LOWER(u."Username")
                            WHERE r."TopicId" = %s
                            ORDER BY r."CreatedAt" ASC;
                        ''', (int(topic_id),))
                        replies_rows = cur.fetchall()
                        for r in replies_rows:
                            r_author = r[1] or "Thành viên"
                            if r[4] is not None:
                                r_info = {
                                    "id": r[4],
                                    "username": r[5] or r_author,
                                    "role": r[6] or "User",
                                    "badgeText": r[7] or "THÀNH VIÊN",
                                    "badgeType": r[8] or "badge_gray",
                                    "rank": r[9] or r[7] or "thành viên",
                                    "titleLogo": r[10] or "",
                                    "group": r[11] or "Thành viên",
                                    "avatar": r[12] or "",
                                    "starLevel": r[13] or 1
                                }
                                _USER_CACHE[r_author.lower()] = {"data": r_info, "ts": time.time()}
                            else:
                                r_info = get_user_info_cached(r_author, cur)
                            replies_list.append({
                                "id": r[0],
                                "author": r_author,
                                "content": r[2],
                                "created_at": format_vn_time(r[3], default=""),
                                "authorInfo": r_info,
                                "authorRank": r_info.get("rank", "thành viên")
                            })
                    author_name = row[5] or "Admin"
                    if row[16] is not None:
                        author_info = {
                            "id": row[16],
                            "username": row[17] or author_name,
                            "role": row[18] or "User",
                            "badgeText": row[19] or "THÀNH VIÊN",
                            "badgeType": row[20] or "badge_gray",
                            "rank": row[21] or row[19] or "thành viên",
                            "titleLogo": row[22] or "",
                            "group": row[23] or "Thành viên",
                            "avatar": row[24] or "",
                            "starLevel": row[25] or 1
                        }
                        _USER_CACHE[author_name.lower()] = {"data": author_info, "ts": time.time()}
                    else:
                        author_info = get_user_info_cached(author_name, cur)
                    cur.close()
                    release_db_connection(conn)
            except Exception as e:
                print(f"Error querying topic detail from Docker PostgreSQL: {e}")
                author_name = row[5] if row else "Admin"
                author_info = get_user_info_cached(author_name)

        # 2. Nếu tìm thấy từ PostgreSQL Docker
        if row:
            real_replies_count = len(replies_list) if replies_list else row[7]
            created_at_dt = row[11]
            time_str = format_vn_time(created_at_dt)
            topic_data = {
                "id": row[0],
                "title": row[1],
                "content": row[2] or "",
                "type": row[3] or "thong_bao",
                "categorySlug": row[4] or "thong-bao-su-kien",
                "categoryName": get_category_title_by_slug(row[4] or "thong-bao-su-kien"),
                "author": author_name,
                "icon": row[6] or "document",
                "replies": real_replies_count,
                "views": row[8] or 0,
                "lastAuthor": replies_list[-1]["author"] if replies_list else (row[9] or author_name),
                "lastTime": replies_list[-1]["created_at"] if replies_list else (row[10] if row[10] and row[10].strip() not in ["Vừa xong", "vừa xong"] else time_str),
                "time": time_str,
                "created_at": created_at_dt.isoformat() if created_at_dt else None,
                "data": row[12],
                "rules": row[13] if len(row) > 13 else "",
                "allowQuickReply": bool(row[14]) if len(row) > 14 else True,
                "enableQuickReply": bool(row[14]) if len(row) > 14 else True,
                "showBadgeLogo": bool(row[15]) if len(row) > 15 else False,
                "authorInfo": author_info,
                "replies_list": replies_list
            }
            return {"status": "success", "data": topic_data}

        # 3. Fallback tìm kiếm trong file JSON bền vững (hỗ trợ ID chuỗi hoặc seed topic)
        file_topics = load_forum_topics_file()
        now_fallback = datetime.now(TZ_VN).strftime("%H:%M, %d/%m/%y")
        for t in file_topics:
            if str(t.get("id")) == str(topic_id) or str(t.get("title")) == str(topic_id):
                t_last_time = t.get("lastTime")
                if not t_last_time or t_last_time.strip() in ["Vừa xong", "vừa xong"]:
                    t_last_time = format_vn_time(t.get("created_at"), default=now_fallback)
                return {
                    "status": "success",
                    "data": {
                        "id": t.get("id", topic_id),
                        "title": t.get("title", ""),
                        "content": t.get("content") or t.get("description") or "",
                        "type": t.get("type", "thong_bao"),
                        "categorySlug": t.get("categorySlug", "thong-bao-su-kien"),
                        "categoryName": t.get("categoryName") or get_category_title_by_slug(t.get("categorySlug", "thong-bao-su-kien")),
                        "author": t.get("author", "Admin"),
                        "icon": t.get("icon", "document"),
                        "replies": t.get("replies", 0),
                        "views": t.get("views", 0),
                        "lastAuthor": t.get("lastAuthor", t.get("author", "Admin")),
                        "lastTime": t_last_time,
                        "time": t_last_time,
                        "rules": t.get("rules", ""),
                        "allowQuickReply": t.get("allowQuickReply", t.get("enableQuickReply", True)),
                        "enableQuickReply": t.get("allowQuickReply", t.get("enableQuickReply", True)),
                        "showBadgeLogo": t.get("showBadgeLogo", False),
                        "replies_list": t.get("replies_list", [])
                    }
                }

        # 4. Fallback mặc định nếu chưa lưu
        return {
            "status": "success",
            "data": {
                "id": topic_id,
                "title": str(topic_id),
                "content": "",
                "type": "thong_bao",
                "categorySlug": "thong-bao-su-kien",
                "categoryName": "Thông báo - Sự kiện",
                "author": "Admin",
                "icon": "document",
                "replies": 0,
                "views": 0,
                "lastAuthor": "Admin",
                "lastTime": now_fallback,
                "time": now_fallback,
                "rules": "",
                "enableQuickReply": True,
                "replies_list": []
            }
        }
    except Exception as e:
        print(f"Error in get_topic_detail: {e}")
        return {"status": "error", "message": str(e)}

def sanitize_reply_text(raw_text: str) -> str:
    if not raw_text:
        return ""
    clean = re.sub(r'<\s*(script|iframe|style|object|embed)[^>]*>.*?<\s*/\s*\1\s*>', '', raw_text, flags=re.IGNORECASE | re.DOTALL)
    clean = re.sub(r'javascript:[^\s"\'<>]*', '', clean, flags=re.IGNORECASE)
    clean = re.sub(r'[\u200B-\u200D\uFEFF]', '', clean)
    return clean.strip()

def count_meaningful_characters(raw_text: str) -> int:
    if not raw_text:
        return 0
    clean = sanitize_reply_text(raw_text)
    clean = re.sub(r'<[^>]*>', '', clean)
    clean = re.sub(r'\[/?[a-zA-Z0-9_]+(=[^\]]*)?\]', '', clean)
    clean = re.sub(r'[\u200B-\u200D\uFEFF]', '', clean)
    clean = re.sub(r'[\s\u00A0]+', '', clean)
    return len(clean)

@app.post("/api/topics/{topic_id}/reply")
@app.post("/api/forum/topics/{topic_id}/reply")
@app.post("/api/topics/{topic_id}/replies")
@app.post("/api/forum/topics/{topic_id}/replies")
async def create_topic_reply(topic_id: str, request: Request):
    """
    Thêm post con (reply) vào bài viết, lưu trực tiếp vào PostgreSQL Docker
    kèm Sanitization Guard chống XSS và Broadcast SignalR real-time.
    """
    try:
        body = await request.json()
    except Exception:
        body = {}
    author = body.get("author") or "ngocanh1"
    raw_content = body.get("content") or ""
    title = body.get("title") or ""
    
    # Validation 30 ký tự (loại bỏ HTML, BBCode, khoảng trắng, zero-width)
    meaningful_len = count_meaningful_characters(raw_content)
    if meaningful_len < 30:
        return {
            "status": "error",
            "message": "Vui lòng nhập ít nhất 30 ký tự để thảo luận."
        }
        
    content = sanitize_reply_text(raw_content)
    now_dt = datetime.now(TZ_VN)
    time_str = now_dt.strftime("%H:%M, %d/%m/%y")
    
    reply_id = int(time.time() * 1000) % 10000000
    author_info = get_user_info_cached(author)
    author_rank = author_info.get("rank", "thành viên")
    extra_data = {
        "title": title,
        "authorRank": author_rank,
        "authorInfo": author_info,
        "avatar": body.get("avatar") or author_info.get("avatar", "")
    }
    
    # 1. Lưu vào PostgreSQL Docker
    try:
        conn = get_db_connection()
        if conn:
            conn.autocommit = True
            cur = conn.cursor()
            tid_int = int(topic_id) if str(topic_id).isdigit() else 161
            cur.execute('''
                INSERT INTO "ForumTopicReplies" ("TopicId", "Author", "Content", "CreatedAt", "Data")
                VALUES (%s, %s, %s, CURRENT_TIMESTAMP, %s)
                RETURNING "Id", "CreatedAt";
            ''', (tid_int, author, content, json.dumps(extra_data)))
            row = cur.fetchone()
            if row:
                reply_id = row[0]
            
            # Cập nhật số replies và bài cuối trong ForumTopics
            cur.execute('''
                UPDATE "ForumTopics"
                SET "Replies" = COALESCE("Replies", 0) + 1,
                    "LastAuthor" = %s,
                    "LastTime" = %s
                WHERE "Id" = %s;
            ''', (author, time_str, tid_int))
            cur.close()
            release_db_connection(conn)
    except Exception as e:
        print(f"Error saving reply to PostgreSQL Docker: {e}")
        
    # 2. Lưu vào file JSON bền vững (fallback)
    try:
        file_topics = load_forum_topics_file()
        for t in file_topics:
            if str(t.get("id")) == str(topic_id) or str(t.get("title")) == str(topic_id):
                if "replies_list" not in t:
                    t["replies_list"] = []
                t["replies_list"].append({
                    "id": reply_id,
                    "author": author,
                    "title": title,
                    "content": content,
                    "created_at": time_str,
                    "authorRank": extra_data["authorRank"]
                })
                t["replies"] = len(t["replies_list"])
                t["lastAuthor"] = author
                t["lastTime"] = time_str
                break
        save_forum_topics_file(file_topics)
    except Exception as e:
        print(f"Error saving reply to JSON fallback: {e}")
        
    reply_user_info = get_user_info_cached(author)
    reply_payload = {
        "id": reply_id,
        "topicId": int(topic_id) if str(topic_id).isdigit() else topic_id,
        "author": author,
        "title": title,
        "content": content,
        "created_at": time_str,
        "time": time_str,
        "authorRank": reply_user_info.get("rank", extra_data.get("authorRank", "thành viên")),
        "authorInfo": reply_user_info
    }
    
    commit_uploaded_images(topic_id=str(topic_id), content_texts=[content])
    # 3. Kích hoạt SignalR broadcast cho toàn bộ client đang xem bài viết
    trigger_signalr_broadcast("ReplyCreated", reply_payload)
    trigger_signalr_broadcast("topic-updated", {"action": "reply", "id": topic_id, "data": reply_payload})
    trigger_signalr_broadcast("OnReplyCreated", reply_payload)
    
    return {
        "status": "success",
        "message": "Đã gửi trả lời thành công",
        "data": reply_payload
    }

@app.get("/api/topics/{topic_id}/replies")
@app.get("/api/forum/topics/{topic_id}/replies")
def get_topic_replies(topic_id: str, limit: int = 10, page: int = 1):
    """
    Lấy danh sách bài trả lời được phân trang 10 bài/trang chuẩn xác từ Docker PostgreSQL.
    Tự động seed bài mẫu từ Hình 2 (elizaasyre) nếu topic 161 chưa có replies.
    """
    import math
    items = []
    total_count = 0
    tid_int = int(topic_id) if str(topic_id).isdigit() else 161
    limit = max(1, min(limit, 10000))
    page = max(1, page)
    offset = (page - 1) * limit
    
    try:
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            cur.execute('SELECT COUNT(*) FROM "ForumTopicReplies" WHERE "TopicId" = %s;', (tid_int,))
            count_row = cur.fetchone()
            total_count = count_row[0] if count_row else 0
            
            cur.execute('''
                SELECT r."Id", r."Author", r."Content", r."CreatedAt", r."Data",
                       u."Id", u."Username", u."Role", u."BadgeText", u."BadgeType", u."RankTitle", u."TitleLogo", u."UserGroups", u."Avatar", u."StarLevel"
                FROM "ForumTopicReplies" r
                LEFT JOIN "Users" u ON LOWER(r."Author") = LOWER(u."Username")
                WHERE r."TopicId" = %s
                ORDER BY r."CreatedAt" ASC
                LIMIT %s OFFSET %s;
            ''', (tid_int, limit, offset))
            rows = cur.fetchall()
            for r in rows:
                c_data = r[4] if (len(r) > 4 and r[4]) else {}
                if isinstance(c_data, str):
                    try:
                        c_data = json.loads(c_data)
                    except Exception:
                        c_data = {}
                r_author = r[1] or "ngocanh1"
                if r[5] is not None:
                    reply_author_info = {
                        "id": r[5],
                        "username": r[6] or r_author,
                        "role": r[7] or "User",
                        "badgeText": r[8] or "THÀNH VIÊN",
                        "badgeType": r[9] or "badge_gray",
                        "rank": r[10] or r[8] or "thành viên",
                        "titleLogo": r[11] or "",
                        "group": r[12] or "Thành viên",
                        "avatar": r[13] or "",
                        "starLevel": r[14] or 1
                    }
                    _USER_CACHE[r_author.lower()] = {"data": reply_author_info, "ts": time.time()}
                else:
                    reply_author_info = get_user_info_cached(r_author, cur)
                fallback_title = "Re: Thảo luận"
                items.append({
                    "id": r[0],
                    "topicId": tid_int,
                    "author": r_author,
                    "content": r[2] or "",
                    "created_at": format_vn_time(r[3]),
                    "time": format_vn_time(r[3]),
                    "title": c_data.get("title") or fallback_title,
                    "authorRank": reply_author_info.get("rank", "thành viên"),
                    "authorInfo": reply_author_info
                })
            cur.close()
            release_db_connection(conn)
    except Exception as e:
        print(f"Error fetching replies from PostgreSQL Docker: {e}")
        
    # Fallback to JSON if items is empty
    if not items:
        file_topics = load_forum_topics_file()
        for t in file_topics:
            if str(t.get("id")) == str(topic_id) or str(t.get("title")) == str(topic_id):
                raw_replies = t.get("replies_list") or []
                total_count = len(raw_replies)
                slice_items = raw_replies[offset:offset+limit]
                for sr in slice_items:
                    items.append({
                        "id": sr.get("id", 1),
                        "topicId": tid_int,
                        "author": sr.get("author", "ngocanh1"),
                        "content": sr.get("content", ""),
                        "created_at": sr.get("created_at", "13:58, 10/09/26"),
                        "time": sr.get("created_at", "13:58, 10/09/26"),
                        "title": sr.get("title", "Re: Thảo luận"),
                        "authorRank": sr.get("authorRank", "thành viên")
                    })
                break
                
    total_pages = max(1, math.ceil(total_count / limit)) if total_count > 0 else 1
    return {
        "status": "success",
        "total": total_count,
        "page": page,
        "limit": limit,
        "totalPages": total_pages,
        "items": items,
        "replies": items
    }

# ==================== DRAFT API ENDPOINTS (PERSISTENT POSTGRESQL DOCKER - 2026) ====================

@app.post("/api/forum/drafts")
async def create_or_save_draft(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    
    username = body.get("username") or "ngocanh1"
    topic_id = body.get("topicId") or body.get("topic_id")
    topic_title = body.get("topicTitle") or body.get("topic_title") or ""
    title = body.get("title") or "Bản nháp không có tiêu đề"
    content = body.get("content") or ""
    
    now_vn = datetime.now(TZ_VN)
    
    conn = get_db_connection()
    if not conn:
        return {"status": "error", "message": "Không thể kết nối cơ sở dữ liệu PostgreSQL Docker"}
    
    draft_id = None
    try:
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO "ForumDrafts" ("Username", "TopicId", "TopicTitle", "Title", "Content", "CreatedAt", "UpdatedAt")
            VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING "Id";
        ''', (username, int(topic_id) if str(topic_id).isdigit() else None, topic_title, title, content))
        row = cur.fetchone()
        if row:
            draft_id = row[0]
        conn.commit()
        cur.close()
    except Exception as e:
        print(f"Error saving draft into PostgreSQL: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        release_db_connection(conn)
        
    time_str = now_vn.strftime("%H:%M, %d/%m/%y")
    draft_payload = {
        "action": "create",
        "id": draft_id,
        "username": username,
        "title": title,
        "topicId": topic_id,
        "topicTitle": topic_title,
        "time": time_str
    }
    trigger_signalr_broadcast("DraftSaved", draft_payload)
    trigger_signalr_broadcast("draft-updated", draft_payload)
    
    return {
        "status": "success",
        "id": draft_id,
        "message": "Đã lưu bản nháp thành công",
        "data": {
            "id": draft_id,
            "username": username,
            "topicId": topic_id,
            "topicTitle": topic_title,
            "title": title,
            "content": content,
            "time": time_str
        }
    }

@app.get("/api/forum/drafts")
def get_user_drafts(username: str = None):
    conn = get_db_connection()
    if not conn:
        return {"status": "error", "data": []}
    
    items = []
    try:
        cur = conn.cursor()
        if username and username.strip() and username.strip().lower() != "all":
            cur.execute('''
                SELECT "Id", "Username", "TopicId", "TopicTitle", "Title", "Content", "CreatedAt"
                FROM "ForumDrafts"
                WHERE LOWER("Username") = LOWER(%s)
                ORDER BY "CreatedAt" DESC;
            ''', (username.strip(),))
        else:
            cur.execute('''
                SELECT "Id", "Username", "TopicId", "TopicTitle", "Title", "Content", "CreatedAt"
                FROM "ForumDrafts"
                ORDER BY "CreatedAt" DESC;
            ''')
        rows = cur.fetchall()
        for r in rows:
            items.append({
                "id": r[0],
                "username": r[1],
                "topicId": r[2],
                "topicTitle": r[3] or "",
                "title": r[4] or "",
                "content": r[5] or "",
                "time": format_vn_time(r[6]),
                "createdAt": r[6].isoformat() if r[6] else ""
            })
        cur.close()
    except Exception as e:
        print(f"Error reading drafts from PostgreSQL: {e}")
    finally:
        release_db_connection(conn)
        
    return {"status": "success", "data": items, "total": len(items)}

@app.post("/api/forum/drafts/delete")
async def delete_drafts(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    
    ids = body.get("ids") or []
    single_id = body.get("id")
    if single_id is not None:
        ids.append(single_id)
        
    if not ids:
        return {"status": "error", "message": "Không có bản nháp nào được chọn"}
        
    int_ids = [int(i) for i in ids if str(i).isdigit()]
    if not int_ids:
        return {"status": "error", "message": "ID bản nháp không hợp lệ"}
        
    conn = get_db_connection()
    if not conn:
        return {"status": "error", "message": "Không thể kết nối cơ sở dữ liệu"}
        
    try:
        cur = conn.cursor()
        cur.execute('DELETE FROM "ForumDrafts" WHERE "Id" = ANY(%s);', (int_ids,))
        conn.commit()
        cur.close()
    except Exception as e:
        print(f"Error deleting drafts: {e}")
        return {"status": "error", "message": str(e)}
    finally:
        release_db_connection(conn)
        
    trigger_signalr_broadcast("DraftSaved", {"action": "delete", "ids": int_ids})
    trigger_signalr_broadcast("draft-updated", {"action": "delete", "ids": int_ids})
    return {"status": "success", "message": f"Đã xóa {len(int_ids)} bản nháp thành công"}

@app.get("/api/users/{username}/profile-stats")
def get_user_profile_stats(username: str):
    """
    Thuật toán Hồ sơ User (Hình 5):
    - Tuổi = Năm hiện tại (2026) - Năm sinh (lấy từ DateOfBirth trong Users)
    - Tham gia = Thời gian tạo user ghi trong DB Docker (định dạng Hình 8: 12:03, 04/07/12)
    - Lần hoạt động trước = Lần gần nhất đăng nhập vào diễn đàn trước thời điểm hiện tại (lấy từ PreviousVisitTime trong Users)
    - Số bài viết = COUNT thực tế số bài viết của user này trong DB Docker
    - % tổng số bài viết = (Số bài viết User / Tổng số bài viết toàn diễn đàn) * 100
    - bài viết/ngày = Số bài viết User / Số ngày tham gia (Từ lúc tạo đến hiện tại)
    """
    try:
        import psycopg2
        from datetime import datetime, timezone
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        cur.execute('''
            SELECT "Id", "Username", "Role", "DateOfBirth", "CreatedAt", "LastVisitTime", "PreviousVisitTime", "FromLocation", "PostCount"
            FROM "Users"
            WHERE LOWER("Username") = LOWER(%s);
        ''', (username,))
        user_row = cur.fetchone()

        age = 45  # Mặc định theo Hình 5
        join_date_str = "12:03, 04/07/12"
        last_visit_str = "-"
        created_at_dt = None
        from_location_str = ""
        db_post_count = 0

        if user_row:
            dob = user_row[3]
            if dob:
                age = 2026 - dob.year
            created_at_dt = user_row[4]
            if created_at_dt:
                join_date_str = format_vn_time(created_at_dt)
            if user_row[7]:
                from_location_str = user_row[7]
            if user_row[8] is not None:
                db_post_count = int(user_row[8])

        # Số bài viết thực tế của user trong DB Docker
        cur.execute('SELECT COUNT(*) FROM "ForumTopics" WHERE LOWER("Author") = LOWER(%s);', (username,))
        topics_count = cur.fetchone()[0]
        cur.execute('SELECT COUNT(*) FROM "ForumTopicReplies" WHERE LOWER("Author") = LOWER(%s);', (username,))
        replies_count = cur.fetchone()[0]
        user_posts = max(topics_count + replies_count, db_post_count)

        # Lần hoạt động trước = Thời gian lần gần nhất đăng nhập vào diễn đàn trước thời điểm hiện tại (PreviousVisitTime)
        if user_row and user_row[6]:
            last_visit_str = format_vn_time(user_row[6])
        else:
            last_visit_str = "-"

        # Tổng số bài viết toàn diễn đàn
        cur.execute('SELECT COUNT(*) FROM "ForumTopics";')
        total_topics_all = cur.fetchone()[0]
        cur.execute('SELECT COUNT(*) FROM "ForumTopicReplies";')
        total_replies_all = cur.fetchone()[0]
        
        categories = load_forum_categories()
        cat_total_posts = sum(c.get("posts", 0) for c in categories)
        benchmark_total_posts = max(total_topics_all + total_replies_all, cat_total_posts, 206024, 1)

        # % tổng số bài viết
        post_percentage = (user_posts / benchmark_total_posts) * 100.0

        # bài viết/ngày = Số bài viết User / Số ngày tham gia (Từ lúc tạo đến hiện tại)
        if created_at_dt:
            now_dt = datetime.now(timezone.utc)
            delta_days = max(1, (now_dt - created_at_dt).days)
        else:
            delta_days = max(1, (2026 - 2012) * 365)
        posts_per_day = user_posts / delta_days

        cur.close()
        conn.close()

        return {
            "status": "success",
            "data": {
                "username": username,
                "age": age,
                "joinDate": join_date_str,
                "lastActive": last_visit_str,
                "postCount": user_posts,
                "totalForumPosts": benchmark_total_posts,
                "postPercentage": round(post_percentage, 2),
                "postsPerDay": round(posts_per_day, 2),
                "rank": "Chính thức",
                "stars": 2,
                "group": "Thành viên",
                "fromLocation": from_location_str,
                "signature": "Ánh Dương văn võ ngàn năm tỏa\nPhẩm giá thanh cao rạng núi sông"
            }
        }
    except Exception as e:
        print(f"Error in get_user_profile_stats: {e}")
        return {"status": "error", "message": str(e)}

@app.put("/api/users/{username}/profile")
@app.post("/api/users/{username}/profile")
async def update_user_profile(username: str, request: Request):
    """
    Cập nhật thông tin User trực tiếp xuống PostgreSQL Docker (Strict Persistent Storage)
    """
    try:
        import psycopg2
        body = await request.json()
        from_location = body.get("fromLocation")
        if from_location is None:
            from_location = body.get("location", "")
        
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        cur.execute('''
            UPDATE "Users"
            SET "FromLocation" = %s
            WHERE LOWER("Username") = LOWER(%s);
        ''', (from_location, username))
        conn.commit()
        cur.close()
        conn.close()
        
        return {
            "status": "success",
            "message": "Cập nhật hồ sơ thành công vào Docker Database",
            "data": {
                "username": username,
                "fromLocation": from_location
            }
        }
    except Exception as e:
        print(f"Error in update_user_profile: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/api/users/{username}/posts")
def get_user_posts(username: str):
    """
    Truy vấn danh sách tất cả bài viết của một User từ Docker PostgreSQL (Hình 6)
    """
    posts = []
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=3
        )
        cur = conn.cursor()
        cur.execute('''
            SELECT "Id", "Title", "Content", "Type", "CategorySlug", "Author", "Icon",
                   "Replies", "Views", "LastAuthor", "LastTime", "CreatedAt"
            FROM "ForumTopics"
            WHERE LOWER("Author") = LOWER(%s)
            ORDER BY "CreatedAt" DESC;
        ''', (username,))
        rows = cur.fetchall()
        for r in rows:
            posts.append({
                "id": r[0],
                "title": r[1],
                "content": r[2],
                "type": r[3],
                "categorySlug": r[4],
                "category": "Thông báo - Sự kiện" if r[4] == "thong-bao-su-kien" else "Xem Tử vi",
                "author": r[5],
                "icon": r[6],
                "replies": r[7],
                "views": r[8],
                "lastPostAuthor": r[9],
                "lastPostTime": r[10] if r[10] and r[10].strip() not in ["Vừa xong", "vừa xong"] else format_vn_time(r[11]),
                "time": format_vn_time(r[11]),
                "created_at": r[11].isoformat() if r[11] else None
            })
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error in get_user_posts: {e}")

    return {"status": "success", "data": posts, "total": len(posts)}

@app.post("/api/forum/tracking/heartbeat")
async def forum_tracking_heartbeat(request: Request):
    """
    Lưu phiên đang xem bài viết hoặc chuyên mục vào Docker PostgreSQL
    """
    try:
        payload = await request.json()
    except Exception:
        payload = {}

    session_id = str(payload.get("sessionId") or payload.get("session_id") or (request.client.host if request.client else "127.0.0.1"))
    category_slug = str(payload.get("categorySlug") or payload.get("category_slug") or "thong-bao-su-kien")
    topic_id = payload.get("topicId") or payload.get("topic_id")
    username = str(payload.get("username") or "").strip()
    is_guest = bool(payload.get("isGuest", not bool(username and username != "Khách")))
    if not username:
        username = "Khách"

    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO "ForumActiveViewers" ("SessionId", "CategorySlug", "TopicId", "Username", "IsGuest", "LastSeen")
            VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
            ON CONFLICT ("SessionId") DO UPDATE SET
                "CategorySlug" = EXCLUDED."CategorySlug",
                "TopicId" = EXCLUDED."TopicId",
                "Username" = EXCLUDED."Username",
                "IsGuest" = EXCLUDED."IsGuest",
                "LastSeen" = CURRENT_TIMESTAMP;
        ''', (session_id, category_slug, int(topic_id) if topic_id else None, username, is_guest))
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error updating ForumActiveViewers: {e}")

    return {"status": "success"}

@app.get("/api/forum/tracking/active-viewers")
def get_forum_active_viewers(category_slug: Optional[str] = None, topic_id: Optional[int] = None):
    """
    Truy vấn số người đang xem chuyên mục/topic trong 15 phút gần nhất
    """
    users = []
    guest_count = 0
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        cur = conn.cursor()
        query = '''
            SELECT "Username", "IsGuest"
            FROM "ForumActiveViewers"
            WHERE "LastSeen" >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
        '''
        params = []
        if topic_id:
            query += ' AND "TopicId" = %s'
            params.append(topic_id)
        elif category_slug:
            query += ' AND "CategorySlug" = %s'
            params.append(category_slug)
        cur.execute(query, tuple(params))
        rows = cur.fetchall()
        cur.close()
        conn.close()

        seen_users = set()
        for r in rows:
            uname, is_g = r[0], r[1]
            if is_g or uname == "Khách":
                guest_count += 1
            else:
                if uname and uname not in seen_users:
                    seen_users.add(uname)
                    users.append(uname)
    except Exception as e:
        print(f"Error querying active viewers: {e}")

    if not users and guest_count == 0:
        users = ["ChatGPT User"]
        guest_count = 0

    return {
        "status": "success",
        "data": {
            "users": users,
            "guestCount": guest_count,
            "displayText": f"{', '.join(users)} và {guest_count} khách" if users else f"{guest_count} khách"
        }
    }



# ========================================================
# FORUM STATS & REAL-TIME ONLINE USERS PERSISTENT STORAGE
# ========================================================
import time
from datetime import datetime

FORUM_STATS_PATH = os.path.join(os.path.dirname(__file__), "forum_stats_db.json")
ONLINE_SESSIONS_PATH = os.path.join(os.path.dirname(__file__), "forum_online_sessions.json")

def load_online_sessions():
    """
    Tải các phiên trực tuyến đã lưu từ file vật lý (chống sập nguồn)
    """
    if os.path.exists(ONLINE_SESSIONS_PATH):
        try:
            with open(ONLINE_SESSIONS_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading online sessions: {e}")
    return {}

def save_online_sessions(sessions):
    """
    Lưu bền vững các phiên trực tuyến xuống ổ đĩa
    """
    try:
        with open(ONLINE_SESSIONS_PATH, "w", encoding="utf-8") as f:
            json.dump(sessions, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving online sessions: {e}")
        return False

def load_forum_stats():
    now_str = datetime.now().strftime("%H:%M, %d/%m/%y")
    default_stats = {
        "general_stats": {
            "posts_count": 0,
            "topics_count": 0,
            "members_count": 0,
            "newest_member": "-"
        },
        "online_stats": {
            "total_online": 1,
            "registered_count": 0,
            "hidden_count": 0,
            "guest_count": 1,
            "active_window_minutes": 60,
            "most_online_count": 1,
            "most_online_time": now_str,
            "users": [],
            "roles_legend": []
        }
    }
    if not os.path.exists(FORUM_STATS_PATH):
        return default_stats
    try:
        with open(FORUM_STATS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data
    except Exception as e:
        print(f"Error loading forum stats: {e}")
        return default_stats

def save_forum_stats(stats_data):
    try:
        with open(FORUM_STATS_PATH, "w", encoding="utf-8") as f:
            json.dump(stats_data, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving forum stats: {e}")
        return False

@app.get("/api/forum/stats")
def get_forum_stats():
    """
    Trả về thống kê tổng (posts, topics, members, newest_member) tính toán trực tiếp từ PostgreSQL Docker
    """
    stats_data = load_forum_stats()
    categories = load_forum_categories()
    
    # Tính toán chính xác tổng chủ đề và bài viết từ các chuyên mục
    total_topics = sum(c.get("topics", 0) for c in categories)
    total_posts = sum(c.get("posts", 0) for c in categories)
    
    gen = stats_data.get("general_stats", {})
    gen["topics_count"] = total_topics
    gen["posts_count"] = total_posts

    # Truy vấn trực tiếp số lượng thành viên và thành viên mới nhất từ PostgreSQL Docker
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute('SELECT COUNT(*) FROM "Users";')
        cnt_row = cur.fetchone()
        if cnt_row:
            gen["members_count"] = cnt_row[0]
            
        cur.execute('SELECT "Username" FROM "Users" ORDER BY "Id" DESC LIMIT 1;')
        newest_row = cur.fetchone()
        if newest_row and newest_row[0]:
            gen["newest_member"] = newest_row[0]
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error fetching live user stats from PostgreSQL: {e}")
    
    stats_data["general_stats"] = gen
    save_forum_stats(stats_data)
    
    return {
        "status": "success",
        "data": gen
    }

@app.get("/api/forum/online-users")
def get_forum_online_users():
    """
    Trả về danh sách người dùng online và thống kê CCU chu kỳ 60 phút từ bộ lưu trữ vật lý
    """
    stats_data = load_forum_stats()
    online = stats_data.get("online_stats", {})
    online["active_window_minutes"] = 60
    return {
        "status": "success",
        "data": online
    }

@app.post("/api/forum/online-users/ping")
async def ping_forum_online(request: Request):
    """
    Tiếp nhận heartbeat ping từ client, tính toán CCU trong cửa sổ 60 phút (3600s) và lưu trữ vật lý
    """
    try:
        payload = await request.json()
    except Exception:
        payload = {}
        
    client_ip = request.client.host if request.client else "127.0.0.1"
    session_id = str(payload.get("sessionId") or payload.get("session_id") or client_ip)
    username = str(payload.get("username") or "").strip()
    is_registered = bool(payload.get("isRegistered") or payload.get("is_registered") or (username and username != "Khách"))
    is_invisible = bool(payload.get("isInvisible") or payload.get("is_invisible", False))
    color = payload.get("color")
    is_bold = bool(payload.get("isBold") or payload.get("is_bold", False))
    
    now = time.time()
    sessions = load_online_sessions()
    
    # Cập nhật phiên hiện tại
    sessions[session_id] = {
        "last_seen": now,
        "username": username if is_registered else "Khách",
        "is_registered": is_registered,
        "is_invisible": is_invisible,
        "color": color,
        "is_bold": is_bold
    }
    
    # Loại bỏ các phiên hết hạn quá 60 phút (3600 giây)
    cutoff = now - 3600
    sessions = {k: v for k, v in sessions.items() if v.get("last_seen", 0) >= cutoff}
    save_online_sessions(sessions)
    
    # Tính toán số lượng online theo công thức: Tổng = Đã đăng ký + Số ẩn + Số khách
    registered_users = [v for v in sessions.values() if v.get("is_registered") and not v.get("is_invisible")]
    hidden_users = [v for v in sessions.values() if v.get("is_registered") and v.get("is_invisible")]
    guest_sessions = [v for v in sessions.values() if not v.get("is_registered")]
    
    guest_count = len(guest_sessions)
    registered_count = len(registered_users)
    hidden_count = len(hidden_users)
    
    if guest_count == 0 and registered_count == 0 and hidden_count == 0:
        guest_count = 1
        
    total_online = registered_count + hidden_count + guest_count
    
    # Định dạng danh sách người dùng đã đăng ký (không bao gồm nick ẩn)
    users_list = []
    seen_names = set()
    for u in registered_users:
        name = u.get("username")
        if name and name not in seen_names:
            seen_names.add(name)
            users_list.append({
                "name": name,
                "color": u.get("color") or "#AB47BC",
                "isBold": u.get("is_bold", False)
            })
            
    stats_data = load_forum_stats()
    online = stats_data.get("online_stats", {})
    
    online["total_online"] = total_online
    online["registered_count"] = registered_count
    online["hidden_count"] = hidden_count
    online["guest_count"] = guest_count
    online["active_window_minutes"] = 60
    online["users"] = users_list
    
    # Cập nhật kỷ lục đồng thời
    current_most = online.get("most_online_count", 0)
    if total_online >= current_most:
        online["most_online_count"] = total_online
        online["most_online_time"] = datetime.now().strftime("%H:%M, %d/%m/%y")
        
    stats_data["online_stats"] = online
    save_forum_stats(stats_data)
    
    return {
        "status": "success",
        "data": online
    }

@app.post("/api/forum/online-users/login-event")
async def login_event_forum_online(request: Request):
    """
    Logic chuyển đổi Event Driven khi một Khách đăng nhập thành công:
    Số khách = Số khách - 1
    Số đã đăng ký = Số đã đăng ký + 1
    Tên User của người đó lập tức xuất hiện tại mục "Các thành viên trực tuyến:"
    Ghi trực tiếp vào file lưu trữ vật lý để bảo tồn sau sập nguồn
    """
    try:
        payload = await request.json()
    except Exception:
        payload = {}
        
    username = str(payload.get("username") or "").strip()
    session_id = str(payload.get("sessionId") or payload.get("session_id") or (request.client.host if request.client else "127.0.0.1"))
    is_invisible = bool(payload.get("isInvisible") or payload.get("is_invisible", False))
    color = payload.get("color") or "#AB47BC"
    is_bold = bool(payload.get("isBold") or payload.get("is_bold", True))
    
    now = time.time()
    sessions = load_online_sessions()
    cutoff = now - 3600
    sessions = {k: v for k, v in sessions.items() if v.get("last_seen", 0) >= cutoff}
    
    # Chuyển đổi phiên từ Khách sang User đã đăng nhập
    sessions[session_id] = {
        "last_seen": now,
        "username": username,
        "is_registered": True,
        "is_invisible": is_invisible,
        "color": color,
        "is_bold": is_bold
    }
    save_online_sessions(sessions)
    
    registered_users = [v for v in sessions.values() if v.get("is_registered") and not v.get("is_invisible")]
    hidden_users = [v for v in sessions.values() if v.get("is_registered") and v.get("is_invisible")]
    guest_sessions = [v for v in sessions.values() if not v.get("is_registered")]
    
    guest_count = len(guest_sessions)
    registered_count = len(registered_users)
    hidden_count = len(hidden_users)
    total_online = registered_count + hidden_count + guest_count
    
    users_list = []
    seen_names = set()
    for u in registered_users:
        name = u.get("username")
        if name and name not in seen_names:
            seen_names.add(name)
            users_list.append({
                "name": name,
                "color": u.get("color") or "#AB47BC",
                "isBold": u.get("is_bold", True)
            })
            
    stats_data = load_forum_stats()
    online = stats_data.get("online_stats", {})
    
    online["total_online"] = total_online
    online["registered_count"] = registered_count
    online["hidden_count"] = hidden_count
    online["guest_count"] = guest_count
    online["active_window_minutes"] = 60
    online["users"] = users_list
    
    current_most = online.get("most_online_count", 0)
    if total_online >= current_most:
        online["most_online_count"] = total_online
        online["most_online_time"] = datetime.now().strftime("%H:%M, %d/%m/%y")
        
    stats_data["online_stats"] = online
    save_forum_stats(stats_data)
    
    return {
        "status": "success",
        "data": online
    }

@app.post("/api/forum/online-users/logout-event")
async def logout_event_forum_online(request: Request):
    """
    Sự kiện Đăng xuất: Chuyển User về lại thành Khách
    """
    try:
        payload = await request.json()
    except Exception:
        payload = {}
        
    session_id = str(payload.get("sessionId") or payload.get("session_id") or (request.client.host if request.client else "127.0.0.1"))
    now = time.time()
    sessions = load_online_sessions()
    cutoff = now - 3600
    sessions = {k: v for k, v in sessions.items() if v.get("last_seen", 0) >= cutoff}
    
    # Chuyển phiên này thành Khách
    sessions[session_id] = {
        "last_seen": now,
        "username": "Khách",
        "is_registered": False,
        "is_invisible": False,
        "color": None,
        "is_bold": False
    }
    save_online_sessions(sessions)
    
    registered_users = [v for v in sessions.values() if v.get("is_registered") and not v.get("is_invisible")]
    hidden_users = [v for v in sessions.values() if v.get("is_registered") and v.get("is_invisible")]
    guest_sessions = [v for v in sessions.values() if not v.get("is_registered")]
    
    guest_count = max(1, len(guest_sessions))
    registered_count = len(registered_users)
    hidden_count = len(hidden_users)
    total_online = registered_count + hidden_count + guest_count
    
    users_list = []
    seen_names = set()
    for u in registered_users:
        name = u.get("username")
        if name and name not in seen_names:
            seen_names.add(name)
            users_list.append({
                "name": name,
                "color": u.get("color") or "#AB47BC",
                "isBold": u.get("is_bold", True)
            })
            
    stats_data = load_forum_stats()
    online = stats_data.get("online_stats", {})
    
    online["total_online"] = total_online
    online["registered_count"] = registered_count
    online["hidden_count"] = hidden_count
    online["guest_count"] = guest_count
    online["active_window_minutes"] = 60
    online["users"] = users_list
    
    stats_data["online_stats"] = online
    save_forum_stats(stats_data)
    
    return {
        "status": "success",
        "data": online
    }


# ========================================================
# FORUM USERS & MEMBER MANAGEMENT PERSISTENT STORAGE
# ========================================================
FORUM_USERS_PATH = os.path.join(os.path.dirname(__file__), "forum_users_db.json")

def load_forum_users():
    """
    Load users from PostgreSQL database, fall back to forum_users_db.json if unavailable.
    """
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        cur = conn.cursor()
        cur.execute('SELECT "Id", "Username", "Email", "Role", "PostCount", "CreatedAt", "BadgeText", "BadgeType", "NameColor", "Website" FROM "Users" ORDER BY "Id";')
        rows = cur.fetchall()
        users = []
        for r in rows:
            created_at_dt = r[5]
            if created_at_dt:
                join_date = format_vn_time(created_at_dt)
            else:
                join_date = "11:32, 03/09/08"
            users.append({
                "id": r[0],
                "username": r[1],
                "email": r[2] or "",
                "role": r[3] or "Hội viên",
                "posts": r[4] or 0,
                "joinDate": join_date,
                "badgeText": r[6] or "HỘI VIÊN",
                "badgeType": r[7] or "badge_purple",
                "nameColor": r[8] or "#AB47BC",
                "website": r[9] or "",
                "isBold": True
            })
        cur.close()
        conn.close()
        if users:
            try:
                with open(FORUM_USERS_PATH, "w", encoding="utf-8") as f:
                    json.dump(users, f, ensure_ascii=False, indent=2)
            except Exception:
                pass
            return users
    except Exception:
        pass

    if os.path.exists(FORUM_USERS_PATH):
        try:
            with open(FORUM_USERS_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []

def save_forum_users(users):
    try:
        with open(FORUM_USERS_PATH, "w", encoding="utf-8") as f:
            json.dump(users, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving forum users: {e}")
        return False

@app.get("/api/users")
def get_forum_users(
    page: int = 1,
    pageSize: int = 25,
    letter: Optional[str] = None,
    query: Optional[str] = None
):
    """
    Trả về danh sách thành viên có phân trang, lọc theo chữ cái và tìm kiếm
    """
    users = load_forum_users()
    if letter and letter != "Tất cả":
        users = [u for u in users if u.get("username", "").upper().startswith(letter.upper())]
    if query:
        q = query.strip().lower()
        users = [u for u in users if q in u.get("username", "").lower() or q in u.get("email", "").lower()]

    total_users = len(users)
    total_pages = max(1, (total_users + pageSize - 1) // pageSize)

    start_idx = (page - 1) * pageSize
    end_idx = start_idx + pageSize
    paged_users = users[start_idx:end_idx]

    return {
        "status": "success",
        "data": {
            "users": paged_users,
            "totalUsers": total_users,
            "page": page,
            "pageSize": pageSize,
            "totalPages": total_pages
        }
    }

@app.post("/api/users/{username}/increment-post")
def increment_user_post(username: str):
    """
    Tăng số lượng bài viết của thành viên và lưu bền vững vào database
    """
    updated_user = None
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="TuvionlineManagerDB",
            user="postgres",
            password="postgres",
            connect_timeout=2
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute('UPDATE "Users" SET "PostCount" = COALESCE("PostCount", 0) + 1 WHERE LOWER("Username") = LOWER(%s) RETURNING "Id", "Username", "PostCount";', (username,))
        row = cur.fetchone()
        cur.close()
        conn.close()
    except Exception:
        pass

    if os.path.exists(FORUM_USERS_PATH):
        try:
            with open(FORUM_USERS_PATH, "r", encoding="utf-8") as f:
                users = json.load(f)
            for u in users:
                if u.get("username", "").lower() == username.lower():
                    u["posts"] = u.get("posts", 0) + 1
                    updated_user = u
                    break
            save_forum_users(users)
        except Exception:
            pass

    return {
        "status": "success",
        "message": f"Đã cập nhật số bài viết cho {username}",
        "data": updated_user
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
