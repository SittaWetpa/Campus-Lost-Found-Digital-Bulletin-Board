import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.showDecideHint = false,
  });

  final ItemRequest request;
  final VoidCallback onTap;
  final bool showDecideHint;

  @override
  Widget build(BuildContext context) {
    final msg = request.message ?? request.visitorAnswer ?? '';
    final truncated = msg.length > 90 ? '${msg.substring(0, 90)}…' : msg;
    final isFound = request.type == RequestType.found;
    final isPending = request.status == RequestStatus.pending;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  request.requesterName.isNotEmpty
                      ? request.requesterName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            request.requesterName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID ${request.studentId} · ${_relativeTime(request.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (isFound && request.photoUrl != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: request.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                          if (truncated.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                truncated,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else if (truncated.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        truncated,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    // Footer row — always visible
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPending ? 'View & decide →' : 'Read more →',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isPending
                                ? const Color(0xFFB45309)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        if (showDecideHint && isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Action needed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA96C00),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Chevron — affordance that the card drills in
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, Color bg) = switch (status) {
      RequestStatus.pending =>
        (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      RequestStatus.approved =>
        (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      RequestStatus.rejected =>
        (const Color(0xFFDC2626), const Color(0xFFFFE4E6)),
      RequestStatus.cancelled =>
        (const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
