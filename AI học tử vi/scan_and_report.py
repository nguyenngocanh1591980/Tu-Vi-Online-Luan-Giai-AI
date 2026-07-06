import os
import json
import hashlib
import time
from datetime import datetime, timedelta
import re
import shutil

def get_file_hash(filepath):
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        buf = f.read(65536)
        while len(buf) > 0:
            hasher.update(buf)
            buf = f.read(65536)
    return hasher.hexdigest()

def scan_directories(directories):
    state = {}
    for directory in directories:
        for root, _, files in os.walk(directory):
            for file in files:
                filepath = os.path.join(root, file)
                try:
                    stat = os.stat(filepath)
                    size = stat.st_size
                    mtime = stat.st_mtime
                    if size < 10 * 1024 * 1024:  # < 10MB, use hash
                        file_hash = get_file_hash(filepath)
                        state[filepath] = {'size': size, 'mtime': mtime, 'hash': file_hash}
                    else:
                        state[filepath] = {'size': size, 'mtime': mtime}
                except Exception as e:
                    print(f"Error reading {filepath}: {e}")
    return state

def detect_changes(old_state, new_state):
    changes = []
    # Check for modified or added files
    for filepath, new_info in new_state.items():
        if filepath not in old_state:
            changes.append({'file': filepath, 'status': 'added', 'info': new_info})
        else:
            old_info = old_state[filepath]
            if 'hash' in new_info and 'hash' in old_info:
                if new_info['hash'] != old_info['hash']:
                    changes.append({'file': filepath, 'status': 'modified', 'info': new_info})
            else:
                if new_info['size'] != old_info['size'] or new_info['mtime'] != old_info['mtime']:
                    changes.append({'file': filepath, 'status': 'modified', 'info': new_info})
    # Check for deleted files
    for filepath in old_state:
        if filepath not in new_state:
            changes.append({'file': filepath, 'status': 'deleted'})
    return changes

def clean_old_reports(report_dir):
    try:
        now = time.time()
        for file in os.listdir(report_dir):
            filepath = os.path.join(report_dir, file)
            if os.path.isfile(filepath):
                stat = os.stat(filepath)
                # 3 days old (since saving)
                if stat.st_mtime < now - 3 * 24 * 3600:
                    import subprocess
                    ps_script = f'''
                    Add-Type -AssemblyName Microsoft.VisualBasic
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("{filepath}", "OnlyErrorDialogs", "SendToRecycleBin")
                    '''
                    subprocess.run(["powershell", "-Command", ps_script])
    except Exception as e:
        print(f"Error cleaning old reports: {e}")

def get_report_target_dir(filepath, base_report_dir):
    if "Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi" in filepath:
        return os.path.join(base_report_dir, "Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi")
    elif "Tầng 1- Dữ Liệu Chuẩn Hóa" in filepath:
        return os.path.join(base_report_dir, "Tầng 1- Dữ Liệu Chuẩn Hóa")
    elif "Tầng 2- Dữ liệu Bổ sung đã Chọn Lọc" in filepath:
        return os.path.join(base_report_dir, "Tầng 2- Dữ liệu Bổ sung đã Chọn Lọc")
    elif "Tầng 3- Dữ liệu chưa Chọn Lọc" in filepath:
        return os.path.join(base_report_dir, "Tầng 3- Dữ liệu chưa Chọn Lọc")
    return None

def normalize_name(name):
    # Remove extension
    name = os.path.splitext(name)[0]
    import unicodedata
    # Remove accents
    name = unicodedata.normalize('NFKD', name).encode('ASCII', 'ignore').decode('utf-8')
    # Lowercase and replace non-alphanumeric with hyphen
    name = name.lower()
    name = re.sub(r'[^a-z0-9]+', '-', name)
    name = name.strip('-')
    # Remove numerical prefixes like "00-", "01-"
    name = re.sub(r'^[0-9]+-', '', name)
    # Remove "ai-" prefix if exists
    name = re.sub(r'^ai-', '', name)
    return name

def update_skill_memory(filepath):
    if "Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi" not in filepath:
        return
        
    filename = os.path.basename(filepath)
    normalized = normalize_name(filename)
    
    # Check if a matching skill directory exists
    skills_dir = r"E:\Tu vi online\.agents\skills"
    if not os.path.exists(skills_dir):
        return
        
    best_match_dir = None
    best_match_len = 0
    for skill_name in os.listdir(skills_dir):
        skill_path = os.path.join(skills_dir, skill_name)
        if os.path.isdir(skill_path):
            norm_skill = normalize_name(skill_name)
            # if names are very similar
            if norm_skill in normalized or normalized in norm_skill:
                match_len = len(norm_skill)
                if match_len > best_match_len:
                    best_match_len = match_len
                    best_match_dir = skill_path
            elif skill_name == "luong-lam-viec-luan-giai-tieu-han-nam" and "tieu han" in normalized.replace("-"," "):
                best_match_dir = skill_path
                
    if best_match_dir:
        skill_md_path = os.path.join(best_match_dir, "SKILL.md")
        
        # Read the existing SKILL.md to preserve frontmatter if possible
        frontmatter = ""
        try:
            if os.path.exists(skill_md_path):
                with open(skill_md_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content.startswith("---"):
                        parts = content.split("---", 2)
                        if len(parts) >= 3:
                            frontmatter = "---" + parts[1] + "---\n"
        except Exception:
            pass
            
        if not frontmatter:
            frontmatter = f"---\nname: {os.path.basename(best_match_dir)}\ndescription: Tự động cập nhật từ {filename}\n---\n"
            
        # Read the new content
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                new_content = f.read()
        except UnicodeDecodeError:
            print(f"[Format Error] File không đọc được định dạng UTF-8: {filepath}")
            return
            
        # Write to SKILL.md
        with open(skill_md_path, 'w', encoding='utf-8') as f:
            f.write(frontmatter + new_content)
        print(f"Updated skill memory for {filename} -> {best_match_dir}")
    else:
        print(f"No matching skill found for {filename}")

def main():
    dirs_to_scan = [
        r"E:\Tu vi online\AI học tử vi\Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi",
        r"E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học"
    ]
    base_report_dir = r"E:\Tu vi online\AI học tử vi\Kiểm Tra Quá Trình Học Kiến Thức Của AI"
    state_file = os.path.join(base_report_dir, "last_scan_state.json")
    
    old_state = {}
    if os.path.exists(state_file):
        with open(state_file, 'r', encoding='utf-8') as f:
            old_state = json.load(f)
            
    new_state = scan_directories(dirs_to_scan)
    changes = detect_changes(old_state, new_state)
    
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    
    periodic_report_dir = os.path.join(base_report_dir, "Báo Cáo Quét Định Kỳ")
    os.makedirs(periodic_report_dir, exist_ok=True)
    clean_old_reports(periodic_report_dir)
    
    if not changes:
        report_path = os.path.join(periodic_report_dir, f"BaoCao_KhongThayDoi_{timestamp}.txt")
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"Báo cáo quét định kỳ lúc {timestamp}\n")
            f.write("Không phát hiện thay đổi nào trong dữ liệu.\n")
        print(f"No changes detected. Report saved to {report_path}")
    else:
        changes_by_dir = {}
        for change in changes:
            filepath = change['file']
            target_dir = get_report_target_dir(filepath, base_report_dir)
            if target_dir:
                if target_dir not in changes_by_dir:
                    changes_by_dir[target_dir] = []
                changes_by_dir[target_dir].append(change)
                
            # Automatically update skill memory for added or modified text files
            if change['status'] in ['added', 'modified'] and filepath.endswith(('.txt', '.md', '.docx')):
                update_skill_memory(filepath)
        
        for target_dir, dir_changes in changes_by_dir.items():
            os.makedirs(target_dir, exist_ok=True)
            report_path = os.path.join(target_dir, f"BaoCao_CoThayDoi_{timestamp}.txt")
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(f"Báo cáo tổng kết lúc {timestamp}\n")
                f.write("Phát hiện các thay đổi sau:\n\n")
                for change in dir_changes:
                    f.write(f"- File: {change['file']}\n")
                    f.write(f"  Trạng thái: {change['status']}\n")
            print(f"Changes detected. Report saved to {report_path}")
            
    with open(state_file, 'w', encoding='utf-8') as f:
        json.dump(new_state, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    main()
