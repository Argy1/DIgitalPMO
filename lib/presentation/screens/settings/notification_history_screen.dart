import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_header.dart';

// ── Model ───────────────────────────────────────────────────────────────────

class _NotifItem {
  final String id;
  final String type; // 'obat' | 'kontrol' | 'edukasi' | 'ai'
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  _NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDateKey(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return 'Hari Ini';
  if (d == today.subtract(const Duration(days: 1))) return 'Kemarin';
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

IconData _notifIcon(String type) {
  switch (type) {
    case 'obat':
      return Icons.medication_rounded;
    case 'kontrol':
      return Icons.calendar_month_rounded;
    case 'edukasi':
      return Icons.menu_book_rounded;
    case 'ai':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _notifColor(String type) {
  switch (type) {
    case 'obat':
      return AppColors.primary;
    case 'kontrol':
      return AppColors.amber;
    case 'edukasi':
      return const Color(0xFF2E86DE);
    case 'ai':
      return const Color(0xFF8B5CF6);
    default:
      return AppColors.textMute;
  }
}

const _filterLabels = ['Semua', 'Obat', 'Kontrol', 'Edukasi', 'AI'];
const _filterTypes = ['', 'obat', 'kontrol', 'edukasi', 'ai'];

// ── Screen ───────────────────────────────────────────────────────────────────

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  List<_NotifItem> _notifications = [];
  bool _isLoading = true;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final items = await ApiService.instance.getNotificationHistory(limit: 50);
      if (!mounted) return;
      setState(() {
        _notifications = items.map((raw) {
          final m = raw as Map<String, dynamic>;
          final sentAt = m['sent_at'] as String?;
          final time = sentAt != null
              ? (DateTime.tryParse(sentAt) ?? DateTime.now())
              : DateTime.now();
          return _NotifItem(
            id: m['id'] as String? ?? '',
            type: m['type'] as String? ?? 'obat',
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
            time: time,
            isRead: m['is_read'] as bool? ?? false,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_NotifItem> get _filtered {
    final type = _filterTypes[_filterIndex];
    if (type.isEmpty) return List.from(_notifications);
    return _notifications.where((n) => n.type == type).toList();
  }

  // Build ordered list of date keys, preserving order
  List<String> _orderedDateKeys(List<_NotifItem> items) {
    final seen = <String>[];
    for (final n in items) {
      final key = _formatDateKey(n.time);
      if (!seen.contains(key)) seen.add(key);
    }
    return seen;
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _dismiss(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  void _markRead(String id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) _notifications[idx].isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final dateKeys = _orderedDateKeys(items);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Riwayat Notifikasi',
              onBack: () => context.pop(),
              rightAction: unreadCount > 0
                  ? GestureDetector(
                      onTap: _markAllRead,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Baca semua ($unreadCount)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _filterLabels.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final selected = _filterIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _filterLabels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textMute,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? _buildEmpty()
                  : CustomScrollView(
                      slivers: [
                        for (final dateKey in dateKeys) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _DateHeaderDelegate(dateKey),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, idx) {
                                final group = items
                                    .where((n) =>
                                        _formatDateKey(n.time) == dateKey)
                                    .toList();
                                if (idx >= group.length) return null;
                                final n = group[idx];
                                return _NotifTile(
                                  item: n,
                                  onDismiss: () => _dismiss(n.id),
                                  onTap: () => _markRead(n.id),
                                );
                              },
                              childCount: items
                                  .where(
                                      (n) => _formatDateKey(n.time) == dateKey)
                                  .length,
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 32),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _filterIndex == 0
                ? 'Semua notifikasi akan muncul di sini'
                : 'Tidak ada notifikasi ${_filterLabels[_filterIndex].toLowerCase()}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMute),
          ),
        ],
      ),
    );
  }
}

// ── Sticky date header ───────────────────────────────────────────────────────

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  const _DateHeaderDelegate(this.label);

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMute,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate old) => old.label != label;
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotifTile({
    required this.item,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _notifColor(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.danger.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline,
            color: AppColors.danger, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead ? AppColors.card : AppColors.tealSoft,
            borderRadius:
                BorderRadius.circular(AppDimensions.cardRadius - 4),
            border: Border.all(
              color: item.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_notifIcon(item.type),
                        color: color, size: 20),
                  ),
                  if (!item.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: item.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: item.isRead
                            ? AppColors.text
                            : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMute,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(item.time),
                style: TextStyle(
                  fontSize: 11,
                  color: item.isRead
                      ? AppColors.textMute
                      : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
