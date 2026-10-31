with open(r'E:\Tu vi online\frontend\lib\router\app_router.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_block = [
    '        GoRoute(\n',
    "          path: '/forum/post/:id',\n",
    '          builder: (context, state) {\n',
    "            final id = state.pathParameters['id'] ?? '1';\n",
    '            return FutureBuilder(\n',
    '              future: post_detail.loadLibrary(),\n',
    '              builder: (context, snapshot) {\n',
    '                if (snapshot.connectionState == ConnectionState.done) {\n',
    '                  return post_detail.PostDetailScreen(id: id);\n',
    '                }\n',
    '                return const Center(child: CircularProgressIndicator());\n',
    '              },\n',
    '            );\n',
    '          },\n',
    '        ),\n',
    '        GoRoute(\n',
    "          path: '/forum/topic/:id',\n",
    '          builder: (context, state) {\n',
    "            final id = state.pathParameters['id'] ?? '1';\n",
    '            return FutureBuilder(\n',
    '              future: post_detail.loadLibrary(),\n',
    '              builder: (context, snapshot) {\n',
    '                if (snapshot.connectionState == ConnectionState.done) {\n',
    '                  return post_detail.PostDetailScreen(id: id);\n',
    '                }\n',
    '                return const Center(child: CircularProgressIndicator());\n',
    '              },\n',
    '            );\n',
    '          },\n',
    '        ),\n'
]

lines[391:421] = new_block

with open(r'E:\Tu vi online\frontend\lib\router\app_router.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Successfully updated app_router.dart')
