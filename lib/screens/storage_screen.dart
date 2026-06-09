import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
import '../services/card_store.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

// ── 저장된 카드 모델 ─────────────────────────────────────────
// CardStore의 SwipeState를 그대로 사용
class SavedCard {
  final String id;
  final String channelName;
  final String title;
  final String thumbnailUrl;
  final String category;
  final String summary;
  SwipeState state;

  SavedCard({
    required this.id,
    required this.channelName,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
    required this.summary,
    required this.state,
  });

  factory SavedCard.fromStoredCard(StoredCard stored) {
    return SavedCard(
      id: stored.data.videoId,
      channelName: stored.data.channelName,
      title: stored.data.title,
      thumbnailUrl: stored.data.thumbnailUrl,
      category: stored.data.category,
      summary: stored.data.summary,
      state: stored.state,
    );
  }
}

// ── 카테고리 모델 ────────────────────────────────────────────
class StorageCategory {
  final String name;
  final Color color;
  const StorageCategory({required this.name, required this.color});
}

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _isLoadingData = false;

  Future<void> loadData() async {
    setState(() {
      _allCards = CardStore.instance.cards
          .map((s) => SavedCard.fromStoredCard(s))
          .toList();
    });
  }

  final TextEditingController _searchCtrl = TextEditingController();

  // 선택된 카테고리 (다중선택, 빈 set = 전체)
  final Set<String> _selectedCategories = {};

  // 선택된 타입 (단일 선택, null = 전체)
  SwipeState? _selectedState;

  // 체크박스 선택 모드
  bool _isSelectMode = false;
  final Set<String> _checkedIds = {};

  // 카테고리 목록
  final List<StorageCategory> _categories = const [
    StorageCategory(name: '자기계발', color: Color.fromARGB(255, 255, 237, 156)),
    StorageCategory(name: '운동', color: Color.fromARGB(255, 188, 228, 160)),
    StorageCategory(name: '요리', color: Color.fromARGB(255, 222, 169, 159)),
    StorageCategory(name: '여행', color: Color.fromARGB(255, 139, 188, 199)),
    StorageCategory(name: '뉴스', color: Color.fromARGB(255, 181, 181, 181)),
    StorageCategory(name: '콘텐츠', color: Color.fromARGB(255, 196, 158, 219)),
    StorageCategory(name: '기타', color: Color.fromARGB(255, 232, 187, 141)),
  ];

  IconData _categoryIcon(String category) {
    switch (category) {
      case '자기계발':
        return Icons.auto_awesome;
      case '운동':
        return Icons.fitness_center;
      case '요리':
        return Icons.restaurant;
      case '여행':
        return Icons.flight;
      case '뉴스':
        return Icons.newspaper;
      case '콘텐츠':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  List<SavedCard> _allCards = [];

  // ── 필터 로직 ─────────────────────────────────────────────
  List<SavedCard> get _filteredCards {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _allCards.where((card) {
      final catMatch = _selectedCategories.isEmpty ||
          _selectedCategories.contains(card.category);
      final stateMatch =
          _selectedState == null || card.state == _selectedState;
      final searchMatch = query.isEmpty ||
          card.title.toLowerCase().contains(query) ||
          card.channelName.toLowerCase().contains(query);
      return catMatch && stateMatch && searchMatch;
    }).toList();
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_selectedCategories.contains(name)) {
        _selectedCategories.remove(name);
      } else {
        _selectedCategories.add(name);
      }
    });
  }

  void _toggleState(SwipeState state) {
    setState(() {
      _selectedState = _selectedState == state ? null : state;
      // skipped 필터 선택 시 선택 모드 자동 진입
      _isSelectMode = _selectedState == SwipeState.skipped;
      _checkedIds.clear();
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _checkedIds.clear();
    });
  }

  void _toggleCheck(String id) {
    setState(() {
      if (_checkedIds.contains(id)) {
        _checkedIds.remove(id);
      } else {
        _checkedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      final allIds = _filteredCards.map((c) => c.id).toSet();
      if (_checkedIds.containsAll(allIds) && allIds.isNotEmpty) {
        _checkedIds.clear();
      } else {
        _checkedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

Future<void> _deleteChecked() async {
  try {
    final cardsToDelete = CardStore.instance.cards
        .where((c) => _checkedIds.contains(c.data.videoId))
        .toList();

    for (final card in cardsToDelete) {
      await ApiService.deleteContent(
        card.data.contentId,
      );

      CardStore.instance.remove(
        card.data.videoId,
      );
    }

    setState(() {
      _allCards.removeWhere(
        (c) => _checkedIds.contains(c.id),
      );

      _checkedIds.clear();
      _isSelectMode = false;
    });
  } catch (e) {
    debugPrint('DELETE 실패: $e');
  }
}

  void _restoreChecked() {
    setState(() {
      for (final id in _checkedIds) {
        CardStore.instance.updateState(id, SwipeState.none);
      }
      for (final card in _allCards) {
        if (_checkedIds.contains(card.id)) {
          card.state = SwipeState.none;
        }
      }
      _checkedIds.clear();
      _isSelectMode = false;
    });
  }

  Color _stateActiveColor(SwipeState state) {
    switch (state) {
      case SwipeState.liked:
        return const Color(0xFFC794A1);
      case SwipeState.skipped:
        return const Color(0xFF6B95A7);
      case SwipeState.none:
        return const Color(0xFF1A1A1A);
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildCategoryHeader(),
              const SizedBox(height: 12),
              _buildCategoryScroll(),
              const SizedBox(height: 12),
              if (_isSelectMode) _buildSelectToolbar(),
              const SizedBox(height: 4),
              Expanded(
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1A1A),
                          strokeWidth: 2,
                        ),
                      )
                    : _buildCardGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 검색창 ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(Icons.search_rounded,
                size: 18, color: Color(0xFFAAAAAA)),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A1A)),
                decoration: const InputDecoration(
                  hintText: '검색',
                  hintStyle:
                      TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 카테고리 헤더 (타이틀 + 타입 필터 버튼) ───────────────
  Widget _buildCategoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          _stateBtn(SwipeState.liked,
              activeIcon: Icons.favorite_border,
              inactiveIcon: Icons.favorite_border_rounded),
          const SizedBox(width: 12),
          _stateBtn(SwipeState.skipped,
              activeIcon: Icons.close_rounded,
              inactiveIcon: Icons.close_rounded),
          const SizedBox(width: 12),
          _stateBtn(SwipeState.none,
              activeIcon: Icons.radio_button_unchecked,
              inactiveIcon: Icons.radio_button_unchecked),
        ],
      ),
    );
  }

  Widget _stateBtn(SwipeState state,
      {required IconData activeIcon, required IconData inactiveIcon}) {
    final isSelected = _selectedState == state;
    return GestureDetector(
      onTap: () => _toggleState(state),
      child: Icon(
        isSelected ? activeIcon : inactiveIcon,
        size: 22,
        color: isSelected
            ? _stateActiveColor(state)
            : const Color(0xFFAAAAAA),
      ),
    );
  }

  // ── 카테고리 원형 가로 스크롤 ─────────────────────────────
  Widget _buildCategoryScroll() {
    return SizedBox(
      height: 96,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final cat = _categories[i];
            final isSelected = _selectedCategories.contains(cat.name);
            return GestureDetector(
              onTap: () => _toggleCategory(cat.name),
              child: Container(
                width: 74,
                margin: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: isSelected ? 1.0 : 0.35,
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _categoryIcon(cat.name),
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFAAAAAA),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectToolbar() {
    final hasChecked = _checkedIds.isNotEmpty;
    final allSelected =
        _checkedIds.containsAll(_filteredCards.map((c) => c.id).toSet()) &&
            _filteredCards.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _toolbarBtn(
            label: '전체 선택',
            icon: allSelected
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            onTap: _selectAll,
            color: allSelected
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF555555),
          ),
          const SizedBox(width: 16),
          _toolbarBtn(
            label: '삭제',
            icon: Icons.delete_outline_rounded,
            onTap: hasChecked ? _deleteChecked : null,
            color: hasChecked
                ? const Color.fromARGB(255, 99, 99, 99)
                : const Color(0xFFCCCCCC),
          ),
          const SizedBox(width: 16),
          _toolbarBtn(
            label: '복구',
            icon: Icons.refresh_rounded,
            onTap: hasChecked ? _restoreChecked : null,
            color: hasChecked
                ? const Color.fromARGB(255, 129, 129, 129)
                : const Color(0xFFCCCCCC),
          ),
          if (hasChecked) ...[
            const Spacer(),
            Text('${_checkedIds.length}개 선택',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888888))),
          ],
        ],
      ),
    );
  }

  Widget _toolbarBtn({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── 2열 카드 그리드 ───────────────────────────────────────
  Widget _buildCardGrid() {
    final cards = _filteredCards;
    if (cards.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadData,
        color: const Color(0xFF1A1A1A),
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text('카드가 없어요',
                  style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadData,
      color: const Color(0xFF1A1A1A),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, i) => _buildGridCard(cards[i]),
      ),
    );
  }

  Widget _buildGridCard(SavedCard card) {
    final isChecked = _checkedIds.contains(card.id);
    return GestureDetector(
      onTap: _isSelectMode
          ? () => _toggleCheck(card.id)
          : () => _showCardDetail(card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: card.thumbnailUrl.isNotEmpty
                      ? Image.network(card.thumbnailUrl,
                          width: double.infinity, fit: BoxFit.cover)
                      : _thumbPlaceholder(card.category),
                ),
                // 스와이프 상태 뱃지
                Positioned(
                  top: 6,
                  left: 6,
                  child: _stateBadge(card.state),
                ),
                if (_isSelectMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF1A1A1A)
                            : Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFBBBBBB),
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                if (_isSelectMode && isChecked)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        Container(color: Colors.black.withOpacity(0.15)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.channelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            card.title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 카드 상세 팝업 ────────────────────────────────────────
  void _showCardDetail(SavedCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 채널명
                    Text(card.channelName,
                      style: const TextStyle(
                        fontSize: 13, color: Color(0xFF888888),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF888888),
                      )),
                    const SizedBox(height: 12),
                    // 썸네일
                    if (card.thumbnailUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://www.youtube.com/watch?v=${card.id}',
                          );

                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              card.thumbnailUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // 카테고리 뱃지
                    Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        card.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 10),
                    // 제목
                    Text(card.title,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A), height: 1.3,
                      )),
                    const SizedBox(height: 12),
                    // 요약
                    MarkdownBody(
                      data: card.summary,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                            height: 1.6,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 카드 상태 뱃지 ────────────────────────────────────────
  Widget _stateBadge(SwipeState state) {
    if (state == SwipeState.none) return const SizedBox.shrink();
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        state == SwipeState.liked
            ? Icons.favorite_border
            : Icons.close_rounded,
        size: 13,
        color: state == SwipeState.liked
            ? const Color(0xFFC794A1)
            : const Color(0xFF6B95A7),
      ),
    );
  }

  Widget _thumbPlaceholder(String category) {
    final colorMap = {
      '자기계발': const Color(0xFF8E8E8E),
      '운동': const Color(0xFF8E8E8E),
      '요리': const Color(0xFF8E8E8E),
      '여행': const Color(0xFF8E8E8E),
      '뉴스': const Color(0xFF8E8E8E),
      '콘텐츠': const Color(0xFF8E8E8E),
      '기타': const Color(0xFF8E8E8E),
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorMap[category] ?? const Color(0xFFD9C9C5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}