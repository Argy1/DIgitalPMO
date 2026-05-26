import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pmo_card.dart';
import '../../../core/widgets/pmo_header.dart';
import '../../../data/education/education_articles.dart';

class EducationListScreen extends StatefulWidget {
  const EducationListScreen({super.key});

  @override
  State<EducationListScreen> createState() => _EducationListScreenState();
}

class _EducationListScreenState extends State<EducationListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  Set<String> _readIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReadIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReadIds() async {
    final box = await Hive.openBox('education_reads');
    final raw = box.get('ids');
    if (mounted) {
      setState(() {
        _readIds = raw != null ? Set<String>.from(raw as List) : {};
      });
    }
  }

  List<EducationArticle> get _filtered {
    final q = _searchQuery.toLowerCase();
    return educationArticles.where((a) {
      final matchSearch = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.preview.toLowerCase().contains(q);
      final matchCategory =
          _selectedCategory == 'Semua' || a.category == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PMOHeader(
              title: 'Pusat Edukasi TB',
              onBack: () => context.pop(),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari artikel...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMute, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMute, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.clear,
                              color: AppColors.textMute, size: 18),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: educationCategories.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = educationCategories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textMute,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Article list
            Expanded(
              child: articles.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: articles.length,
                      separatorBuilder: (ctx, i) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) =>
                          _ArticleCard(
                        article: articles[i],
                        isRead: _readIds.contains(articles[i].id),
                        onTap: () => context
                            .push('/education/${articles[i].id}'),
                      ),
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
          const Icon(Icons.search_off,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text(
            'Artikel tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Belum ada artikel di kategori ini',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMute),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final EducationArticle article;
  final bool isRead;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = article.categoryColor;

    return PMOCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(article.categoryIcon,
                color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (article.isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BARU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMute,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.textMute),
                    const SizedBox(width: 3),
                    Text(
                      '${article.readMinutes} menit baca',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMute),
                    ),
                    const Spacer(),
                    if (isRead)
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 3),
                          Text(
                            'Sudah dibaca',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.textMute),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
