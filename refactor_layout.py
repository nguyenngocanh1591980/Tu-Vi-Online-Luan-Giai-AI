import re

content = open('frontend/lib/screens/horoscope_info_screen.dart', 'r', encoding='utf-8').read()

def replace_field(field_name, content_str, is_wrap=False):
    # Find _buildSectionTitle('field_name')
    title_pattern = r"_buildSectionTitle\('" + field_name + r"'\),\s*"
    match = re.search(title_pattern, content_str)
    if not match:
        return content_str
    
    start_idx = match.start()
    end_title = match.end()
    
    # Next, find _buildIndentedRow or Padding/Wrap for the field
    row_pattern = r"_buildIndentedRow\(\["
    wrap_pattern = r"Padding\(\s*padding:.*?child: (?:Wrap|Column)\(\s*crossAxisAlignment:.*?\s*children: \["
    
    if is_wrap:
        match2 = re.search(wrap_pattern, content_str[end_title:])
    else:
        match2 = re.search(row_pattern, content_str[end_title:])
        
    if not match2:
        return content_str
        
    start_row = end_title + match2.start()
    
    # We want to insert the label at the beginning of the children list of that Row/Wrap
    children_start = content_str.find('[', start_row)
    if children_start == -1: return content_str
    
    # Insert the label
    label_widget = f"SizedBox(width: 120, child: Text('{field_name}', style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 16),"
    
    # We remove the _buildSectionTitle entirely!
    new_content = content_str[:start_idx] + content_str[end_title:children_start+1] + '\n                            ' + label_widget + content_str[children_start+1:]
    return new_content

fields = ['Họ tên', 'Địa chỉ', 'Điện thoại', 'Kiểu an sao', 'Kiểu Sinh', 'Giới tính', 'Loại lịch']
for f in fields:
    content = replace_field(f, content)

# For 'Ngày sinh' and 'Năm xem', they use Wrap/Column inside Padding
content = replace_field('Ngày sinh', content, is_wrap=True)
content = replace_field('Năm xem', content, is_wrap=True)

open('frontend/lib/screens/horoscope_info_screen.dart', 'w', encoding='utf-8').write(content)
print('Refactored!')
