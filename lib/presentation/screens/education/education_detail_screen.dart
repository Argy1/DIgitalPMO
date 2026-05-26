import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../data/education/education_articles.dart';

class EducationDetailScreen extends StatefulWidget {
  final String articleId;
  const EducationDetailScreen({super.key, required this.articleId});

  @override
  State<EducationDetailScreen> createState() =>
      _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRead = false;
  bool? _feedbackGiven; // true=👍, false=👎

  EducationArticle? get _article {
    try {
      return educationArticles.firstWhere((a) => a.id == widget.articleId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkReadStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkReadStatus() async {
    final box = await Hive.openBox('education_reads');
    final raw = box.get('ids');
    final ids = raw != null ? Set<String>.from(raw as List) : <String>{};
    if (mounted && ids.contains(widget.articleId)) {
      setState(() => _isRead = true);
    }
  }

  Future<void> _markAsRead() async {
    if (_isRead) return;
    setState(() => _isRead = true);
    final box = await Hive.openBox('education_reads');
    final raw = box.get('ids');
    final ids = raw != null
        ? List<String>.from(raw as List)
        : <String>[];
    if (!ids.contains(widget.articleId)) {
      ids.add(widget.articleId);
      await box.put('ids', ids);
    }
    // TODO: POST /education/read { articleId: widget.articleId }
  }

  Future<void> _sendFeedback(bool helpful) async {
    setState(() => _feedbackGiven = helpful);
    // TODO: POST /education/feedback { articleId, helpful }
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;
    if (article == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _SimpleHeader(onBack: () => context.pop()),
              const Expanded(
                child: Center(
                  child: Text(
                    'Artikel tidak ditemukan',
                    style: TextStyle(color: AppColors.textMute),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = article.categoryColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (!_isRead) {
              final max = notification.metrics.maxScrollExtent;
              if (max > 0 &&
                  notification.metrics.pixels / max >= 0.8) {
                _markAsRead();
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Hero header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            color.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -50,
                            child: Opacity(
                              opacity: 0.15,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              article.categoryIcon,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Back button overlay
                    Positioned(
                      top: 8,
                      left: 4,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Read badge
                    if (_isRead)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Sudah dibaca',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.pageMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta: category badge + read time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.schedule,
                              size: 12, color: AppColors.textMute),
                          const SizedBox(width: 3),
                          Text(
                            '${article.readMinutes} menit baca',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMute),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      // Rich content
                      _RichContent(blocks: article.content),
                      const SizedBox(height: 24),
                      // Feedback
                      _buildFeedback(),
                      const SizedBox(height: 24),
                      // Related articles
                      _buildRelated(article),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return PMOCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artikel ini membantu kamu?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FeedbackButton(
                label: '👍 Ya',
                selected: _feedbackGiven == true,
                onTap: _feedbackGiven == null
                    ? () => _sendFeedback(true)
                    : null,
              ),
              const SizedBox(width: 10),
              _FeedbackButton(
                label: '👎 Tidak',
                selected: _feedbackGiven == false,
                onTap: _feedbackGiven == null
                    ? () => _sendFeedback(false)
                    : null,
              ),
              if (_feedbackGiven != null) ...[
                const SizedBox(width: 10),
                Text(
                  'Terima kasih!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelated(EducationArticle article) {
    final related = educationArticles
        .where((a) => article.relatedIds.contains(a.id))
        .take(3)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artikel Terkait',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final r = related[i];
              return GestureDetector(
                onTap: () => context.pushReplacement('/education/${r.id}'),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.cardRadius),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: r.categoryColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(r.categoryIcon,
                            color: r.categoryColor, size: 16),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          r.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.readMinutes} menit',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMute),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Rich content renderer ──────────────────────────────────────────────────

class _RichContent extends StatelessWidget {
  final List<ContentBlock> blocks;
  const _RichContent({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map(_buildBlock).toList(),
    );
  }

  Widget _buildBlock(ContentBlock block) {
    switch (block.type) {
      case ContentType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.text,
              height: 1.7,
            ),
          ),
        );

      case ContentType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        );

      case ContentType.bullet:
        return Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.text,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );

      case ContentType.quote:
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(
            color: AppColors.tealSoft,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.text,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        );

      case ContentType.highlight:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amberSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.4)),
          ),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        );
    }
  }
}

// ── Private helpers ────────────────────────────────────────────────────────

class _SimpleHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _SimpleHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.primary,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FeedbackButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textMute,
          ),
        ),
      ),
    );
  }
}
