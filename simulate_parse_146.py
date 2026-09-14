import json
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Import function from parse_docx_v2
import parse_docx_v2

def main():
    for star in parse_docx_v2.stars:
        if star["ten_sao"].startswith("146.") or star["ten_sao"].startswith("146. Thiên"):
            display_star = {k: v for k, v in star.items() if not k.startswith('_')}
            print(json.dumps(display_star, ensure_ascii=False, indent=2))
            break

if __name__ == "__main__":
    main()
