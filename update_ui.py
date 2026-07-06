import re

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Reduce all font sizes by 5
def reduce_font_size(match):
    size = int(match.group(1))
    new_size = size - 5
    if new_size < 5:
        new_size = 5 # limit minimum size
    return f"fontSize: {new_size}"

content = re.sub(r'fontSize:\s*(\d+)', reduce_font_size, content)

# 2. Change (status) to [status] for both Major and Minor stars
content = content.replace("'${s.name}${s.status.isNotEmpty ? \\' (${s.status})\\' : \\'\\'}'", "'${s.name}${s.status.isNotEmpty ? \\' [${s.status}]\\' : \\'\\'}'")

# 3. Update _buildModifierText to stack Phi Hoa text and format correctly
modifier_text_old = """  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox(height: 10);
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('HÓA LỘC') || text.contains('HÓA QUYỀN') || text.contains('HÓA KHOA')) {
      textColor = Colors.green; // Mộc
    } else if (text.contains('HÓA KỴ') || text.contains('HÓA KỊ')) {
      textColor = Colors.black; // Thủy
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }"""

modifier_text_new = """  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('HÓA LỘC') || text.contains('HÓA QUYỀN') || text.contains('HÓA KHOA')) {
      textColor = Colors.green; // Mộc
    } else if (text.contains('HÓA KỴ') || text.contains('HÓA KỊ')) {
      textColor = Colors.black; // Thủy
    }

    if (text.startsWith('P.HÓA')) {
      String cleanText = text.replaceFirst('P.HÓA ', '');
      List<String> parts = cleanText.split(': ');
      if (parts.length == 2) {
        String hoa = parts[0] + ':';
        String cungStr = parts[1];
        List<String> cungParts = cungStr.split(' ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(hoa, style: TextStyle(fontSize: 7, fontFamily: 'Arial', color: textColor, fontWeight: FontWeight.bold)),
            Text(cungParts[0], style: const TextStyle(fontSize: 7, fontFamily: 'Arial', color: Colors.black, fontWeight: FontWeight.bold)),
            if (cungParts.length > 1)
              Text(cungParts.sublist(1).join(' '), style: const TextStyle(fontSize: 7, fontFamily: 'Arial', color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        );
      }
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }"""

# Actually we need to make sure we replace the reduced font size version, so we find the method using regex or replace directly if it exists.
# Wait, if we already reduced font size, the old block has fontSize: 7.
content = content.replace(modifier_text_old, modifier_text_new)

# 4. Remove maxLines: 1 and overflow from _buildStarText to allow wrapping if still needed, but actually at size 8 it will fit. We'll leave it as is for now.

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated palace_cell.dart")
