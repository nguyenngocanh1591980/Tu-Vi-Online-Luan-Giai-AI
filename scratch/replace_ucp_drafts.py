with open(r'E:\Tu vi online\frontend\lib\screens\forum\ucp_drafts_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_list = '''                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drafts.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFF2E3B5F)),
                    itemBuilder: (ctx, index) {
                      final draft = drafts[index];
                      final isSelected = _selectedDraftIds.contains(draft.id);
                      final titleDisplay = draft.title.startsWith('TL:') ? draft.title : 'TL: ${draft.title}';
                      final topicDisplay = draft.topicTitle.isNotEmpty ? 'Chủ đề: ${draft.topicTitle}' : 'Chủ đề: Talkshow hướng nghiệp tháng 7/2026';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        color: isSelected ? const Color(0xFF1F2B48) : Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cột 1: Tiêu đề nháp & Tên chủ đề
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleDisplay,
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    topicDisplay,
                                    style: const TextStyle(
                                      color: Color(0xFF90A4AE),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Cột 2: Đã lưu vào ngày & Link Nạp bản nháp • Xem/sửa
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    draft.time.isNotEmpty ? draft.time : '10:30, 30/10/26',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 3),
                                  InkWell(
                                    onTap: () {
                                      if (draftProvider != null) {
                                        _handleRehydrateDraft(draftProvider, draft);
                                      }
                                    },
                                    child: const Text(
                                      'Nạp bản nháp • Xem/sửa',
                                      style: TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 11.5,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFE53935),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Cột 3: Checkbox Chọn
                            SizedBox(
                              width: 50,
                              child: Center(
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFE53935),
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF546E7A)),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedDraftIds.add(draft.id);
                                      } else {
                                        _selectedDraftIds.remove(draft.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),'''

new_column = '''                  Column(
                    children: [
                      for (int index = 0; index < drafts.length; index++) ...[
                        if (index > 0)
                          const Divider(height: 1, color: Color(0xFF2E3B5F)),
                        _buildDraftItemRow(drafts[index], draftProvider),
                      ],
                    ],
                  ),'''

helper_method = '''
  Widget _buildDraftItemRow(ForumDraftItem draft, DraftProvider? draftProvider) {
    final isSelected = _selectedDraftIds.contains(draft.id);
    final titleDisplay = draft.title.startsWith('TL:') ? draft.title : 'TL: ${draft.title}';
    final topicDisplay = draft.topicTitle.isNotEmpty ? 'Chủ đề: ${draft.topicTitle}' : 'Chủ đề: Talkshow hướng nghiệp tháng 7/2026';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      color: isSelected ? const Color(0xFF1F2B48) : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột 1: Tiêu đề nháp & Tên chủ đề
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleDisplay,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  topicDisplay,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Đã lưu vào ngày & Link Nạp bản nháp • Xem/sửa
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.time.isNotEmpty ? draft.time : '10:30, 30/10/26',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () {
                    if (draftProvider != null) {
                      _handleRehydrateDraft(draftProvider, draft);
                    }
                  },
                  child: const Text(
                    'Nạp bản nháp • Xem/sửa',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cột 3: Checkbox Chọn
          SizedBox(
            width: 50,
            child: Center(
              child: Checkbox(
                value: isSelected,
                activeColor: const Color(0xFFE53935),
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF546E7A)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedDraftIds.add(draft.id);
                    } else {
                      _selectedDraftIds.remove(draft.id);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'''

# Replace old_list with new_column, and append helper_method before the last '}'
text_normalized = text.replace('\r\n', '\n')
old_list_normalized = old_list.replace('\r\n', '\n')
new_column_normalized = new_column.replace('\r\n', '\n')

if old_list_normalized in text_normalized:
    text_normalized = text_normalized.replace(old_list_normalized, new_column_normalized, 1)
    # replace the very last '}\n' with helper_method
    last_brace_idx = text_normalized.rfind('}')
    text_normalized = text_normalized[:last_brace_idx] + helper_method.strip() + '\n'
    with open(r'E:\Tu vi online\frontend\lib\screens\forum\ucp_drafts_screen.dart', 'w', encoding='utf-8') as f:
        f.write(text_normalized)
    print('Updated ucp_drafts_screen.dart successfully!')
else:
    print('Target old_list not found!')
