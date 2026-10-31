with open('frontend/lib/router/app_router.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update imports
text = text.replace(
    "import '../screens/forum/post_detail_screen.dart' deferred as post_detail;",
    "import '../screens/forum/post_detail_screen.dart';"
)
text = text.replace(
    "import '../screens/forum/member_profile_screen.dart' deferred as member_profile;",
    "import '../screens/forum/member_profile_screen.dart';"
)
text = text.replace(
    "import '../screens/forum/member_email_screen.dart' deferred as member_email;",
    "import '../screens/forum/member_email_screen.dart';"
)

# 2. Update routes
old_profile_route = """        GoRoute(
          path: '/forum/profile',
          builder: (context, state) {
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen();
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),"""

new_profile_route = """        GoRoute(
          path: '/forum/profile',
          builder: (context, state) => const MemberProfileScreen(),
        ),"""

assert old_profile_route in text, "old_profile_route not found"
text = text.replace(old_profile_route, new_profile_route)

old_post_routes = """        GoRoute(
          path: '/forum/post/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            return FutureBuilder(
              future: post_detail.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return post_detail.PostDetailScreen(id: id);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/topic/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            return FutureBuilder(
              future: post_detail.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return post_detail.PostDetailScreen(id: id);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),"""

new_post_routes = """        GoRoute(
          path: '/forum/post/:id',
          builder: (context, state) => PostDetailScreen(id: state.pathParameters['id'] ?? '1'),
        ),
        GoRoute(
          path: '/forum/topic/:id',
          builder: (context, state) => PostDetailScreen(id: state.pathParameters['id'] ?? '1'),
        ),"""

assert old_post_routes in text, "old_post_routes not found"
text = text.replace(old_post_routes, new_post_routes)

# Add alias /forum/post/:id/reply
old_reply_block = """        GoRoute(
          path: '/forum/topic/:id/reply',"""

new_reply_block = """        GoRoute(
          path: '/forum/post/:id/reply',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            final extra = state.extra as Map<String, dynamic>?;
            final queryQuote = state.uri.queryParameters['quote'];
            final queryIndexStr = state.uri.queryParameters['index'];
            final queryIndex = queryIndexStr != null ? int.tryParse(queryIndexStr) : null;

            final quotedPostId = extra?['quotedPostId']?.toString() ?? queryQuote;
            final quotedPostIndex = (extra?['quotedPostIndex'] as int?) ?? queryIndex;

            return PostReplyScreen(
              topicId: id,
              initialQuoteAuthor: extra?['quoteAuthor'] as String?,
              initialQuoteContent: extra?['quoteContent'] as String?,
              initialTitle: extra?['initialTitle'] as String?,
              initialContent: extra?['initialContent'] as String?,
              rehydrateDraft: extra?['rehydrateDraft'] as ForumDraftItem?,
              quotedPostId: quotedPostId,
              quotedPostIndex: quotedPostIndex,
            );
          },
        ),
        GoRoute(
          path: '/forum/topic/:id/reply',"""

assert old_reply_block in text, "old_reply_block not found"
text = text.replace(old_reply_block, new_reply_block)

old_member_routes = """        GoRoute(
          path: '/forum/member/:username/email',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_email.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_email.MemberEmailScreen(targetUsername: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/member/:username',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen(username: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/user/:username',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen(username: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),"""

new_member_routes = """        GoRoute(
          path: '/forum/member/:username/email',
          builder: (context, state) => MemberEmailScreen(
            targetUsername: state.pathParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/forum/member/:username',
          builder: (context, state) => MemberProfileScreen(
            username: state.pathParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/forum/user/:username',
          builder: (context, state) => MemberProfileScreen(
            username: state.pathParameters['username'] ?? '',
          ),
        ),"""

assert old_member_routes in text, "old_member_routes not found"
text = text.replace(old_member_routes, new_member_routes)

with open('frontend/lib/router/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Successfully updated app_router.dart')
