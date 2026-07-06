
import re

with open('E:/Tu vi online/frontend/lib/widgets/palace_cell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_buildModifierText = '''  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('L~C') || text.contains('L?C') || text.contains('QUY?N') || text.contains('QUY?N') || text.contains('KHOA')) {
      textColor = Colors.green; // M?c
    } else if (text.contains('K') || text.contains('K?')) {
      textColor = Colors.black; // Th?y
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }'''

start_idx = content.find('  Widget _buildModifierText(String text, {required bool isGreen}) {')
end_idx = content.find('  Widget _buildModifierTextCompact(String text, bool isLeft) {')

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_buildModifierText + '\n\n' + content[end_idx:]
    with open('E:/Tu vi online/frontend/lib/widgets/palace_cell.dart', 'w', encoding='utf-8') as fw:
        fw.write(content)
    print('Replaced _buildModifierText')

