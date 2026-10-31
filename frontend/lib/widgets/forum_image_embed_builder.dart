import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Widget hiển thị ảnh giữ nguyên trạng thái bộ nhớ RAM (AutomaticKeepAliveClientMixin + cacheWidth)
/// Chống chớp nháy (flicker) khi người dùng cuộn khung soạn thảo QuillEditor hoặc trang chi tiết bài viết,
/// đồng thời đảm bảo đúng tỷ lệ chuẩn: max-width: 100%; height: auto.
class KeepAliveForumImage extends StatefulWidget {
  final String imageUrl;

  const KeepAliveForumImage({
    super.key,
    required this.imageUrl,
  });

  @override
  State<KeepAliveForumImage> createState() => _KeepAliveForumImageState();
}

class _KeepAliveForumImageState extends State<KeepAliveForumImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 1024.0;
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double logicalMaxWidth = screenWidth < 1024.0 ? screenWidth : 1024.0;
    final int targetCacheWidth = (logicalMaxWidth * dpr).round().clamp(320, 1920);

    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            cacheWidth: targetCacheWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (ctx, err, stack) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể tải ảnh: ${widget.imageUrl}',
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EmbedBuilder chuyên dụng cho QuillEditor để render trực quan BlockEmbed.image(url)
/// thay vì hiển thị chuỗi mã HTML thô <img src="..."/>.
class ForumImageEmbedBuilder extends quill.EmbedBuilder {
  const ForumImageEmbedBuilder();

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(quill.Embed node) => quill.Embed.kObjectReplacementCharacter;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data?.toString() ?? '';
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: KeepAliveForumImage(
        key: ValueKey('quill_embed_img_$imageUrl'),
        imageUrl: imageUrl,
      ),
    );
  }
}

/// Chèn BlockEmbed.image(imageUrl) chuẩn vào vị trí con trỏ của QuillController (tuyệt đối không chèn plain text HTML).
void insertImageBlockIntoQuill(quill.QuillController controller, String imageUrl) {
  final docLen = controller.document.length;
  final rawOffset = controller.selection.baseOffset;
  int insertOffset = (rawOffset >= 0 && rawOffset < docLen)
      ? rawOffset
      : (docLen > 0 ? docLen - 1 : 0);

  // Đảm bảo trước BlockEmbed có ký tự xuống dòng để ảnh đứng trên dòng block riêng (childCount == 1)
  final plainBefore = controller.document.toPlainText();
  if (insertOffset > 0 &&
      insertOffset <= plainBefore.length &&
      plainBefore[insertOffset - 1] != '\n') {
    controller.document.insert(insertOffset, '\n');
    insertOffset += 1;
  }

  controller.document.insert(insertOffset, quill.BlockEmbed.image(imageUrl));

  // Đảm bảo sau BlockEmbed có ký tự xuống dòng để người dùng gõ tiếp mượt mà
  final plainAfter = controller.document.toPlainText();
  int nextCursor = insertOffset + 1;
  if (nextCursor < plainAfter.length && plainAfter[nextCursor] != '\n') {
    controller.document.insert(nextCursor, '\n');
    nextCursor += 1;
  }

  final maxCursor = controller.document.length > 0 ? controller.document.length - 1 : 0;
  controller.updateSelection(
    TextSelection.collapsed(offset: nextCursor.clamp(0, maxCursor)),
    quill.ChangeSource.local,
  );
}

/// Phân tích chuỗi nội dung (Delta JSON hoặc chuỗi chứa <img src="..."/> / [img]...[/img])
/// thành danh sách Delta Operations chứa BlockEmbed {'insert': {'image': url}} (an toàn trong Isolate).
List<dynamic> parseForumContentToQuillDeltaOps(String rawContent) {
  if (rawContent.trim().isEmpty) {
    return [
      {'insert': '\n'}
    ];
  }

  try {
    final decoded = jsonDecode(rawContent);
    if (decoded is List && decoded.isNotEmpty) {
      final ops = List<dynamic>.from(decoded);
      final last = ops.last;
      if (last is Map && last['insert'] is String) {
        final s = last['insert'] as String;
        if (!s.endsWith('\n')) {
          ops[ops.length - 1] = {
            ...Map<String, dynamic>.from(last),
            'insert': '$s\n',
          };
        }
      } else {
        ops.add({'insert': '\n'});
      }
      return ops;
    }
  } catch (_) {}

  final imgRegex = RegExp(
    r'<img[^>]+src=["\x27]([^"\x27]+)["\x27][^>]*>|\[img\](.*?)\[\/img\]',
    caseSensitive: false,
  );

  final matches = imgRegex.allMatches(rawContent).toList();
  if (matches.isEmpty) {
    final text = rawContent.endsWith('\n') ? rawContent : '$rawContent\n';
    return [
      {'insert': text}
    ];
  }

  final List<Map<String, dynamic>> ops = [];
  int lastIndex = 0;

  for (final match in matches) {
    if (match.start > lastIndex) {
      final beforeText = rawContent.substring(lastIndex, match.start);
      if (beforeText.isNotEmpty) {
        final normalizedBefore =
            beforeText.endsWith('\n') ? beforeText : '$beforeText\n';
        ops.add({'insert': normalizedBefore});
      }
    }
    final imgUrl = (match.group(1) ?? match.group(2) ?? '').trim();
    if (imgUrl.isNotEmpty) {
      ops.add({
        'insert': {'image': imgUrl}
      });
      ops.add({'insert': '\n'});
    }
    lastIndex = match.end;
  }

  if (lastIndex < rawContent.length) {
    String rem = rawContent.substring(lastIndex);
    if (rem.startsWith('\r\n')) {
      rem = rem.substring(2);
    } else if (rem.startsWith('\n')) {
      rem = rem.substring(1);
    }
    if (rem.isNotEmpty) {
      final normalizedRem = rem.endsWith('\n') ? rem : '$rem\n';
      ops.add({'insert': normalizedRem});
    }
  }

  if (ops.isEmpty) {
    ops.add({'insert': '\n'});
  }

  return ops;
}

/// Tuần tự hóa Quill Document (chứa cả văn bản và BlockEmbed.image) sang chuỗi HTML chuẩn để lưu vào Docker DB.
String serializeQuillDocumentToForumContent(quill.Document document) {
  final buffer = StringBuffer();
  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is String) {
      buffer.write(data.replaceAll('\uFFFC', ''));
    } else if (data is Map) {
      final imgUrl = data['image']?.toString() ?? '';
      if (imgUrl.isNotEmpty) {
        buffer.write('<img src="$imgUrl" style="max-width: 100%; height: auto;"/>');
      }
    }
  }
  return buffer.toString().trim();
}
