import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/card_store.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

// ── 카테고리 항목 ────────────────────────────────────────────
class CategoryItem {
  final String label;
  final String description;
  bool isSelected;

  CategoryItem({
    required this.label,
    required this.description,
    this.isSelected = true,
  });
}

// ── 메인 스와이프 화면 ───────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  // 드래그 상태
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  int _currentIndex = 0;

  // 카테고리 패널 열림 여부
  bool _isCategoryOpen = false;
  bool _isRecommendationMode = false;

  // 로딩 상태
  bool _isLoading = true;
  String _errorMsg = '';

  static const double _swipeThreshold = 80.0;

  // 카테고리 목록
  final List<CategoryItem> _categories = [
    CategoryItem(label: '자기계발', description: '성장과 동기부여 콘텐츠'),
    CategoryItem(label: '운동', description: '운동 방법과 건강 정보'),
    CategoryItem(label: '요리', description: '레시피와 요리 팁'),
    CategoryItem(label: '여행', description: '여행지와 여행 정보'),
    CategoryItem(label: '뉴스', description: '시사와 뉴스'),
    CategoryItem(label: '콘텐츠', description: '영화, 드라마, 엔터테인먼트'),
    CategoryItem(label: '기타', description: '그 외 다양한 콘텐츠'),
  ];

  // 선택된 카테고리에 해당하는 카드만 (skipped 제외 — 이미 읽음 처리된 카드)
  List<VideoCardData> get _filteredCards {
    final selected = _categories
        .where((c) => c.isSelected)
        .map((c) => c.label)
        .toSet();
    // CardStore에서 직접 읽어 항상 최신 상태 반영
    final storeCards = CardStore.instance.cards;
    return storeCards
        .where((stored) =>
            stored.state != SwipeState.skipped && // 읽음 처리된 카드 제외
            selected.contains(stored.data.category))
        .map((stored) => stored.data)
        .toList();
  }

  List<RecommendationData> _recommendations = [];
  bool _isRecommendationLoading = false;

@override
void initState() {
  super.initState();

  CardStore.instance.add(
    VideoCardData(
      contentId: 0,
      videoId: 'Guide',
      channelName: 'LINK SWIPE!',
      title: 'LINK SWIPE! 사용 방법',
      summary:
          '**🔗 링크를 추가해요.**\n\n'
          '   아래 + 버튼을 눌러 유튜브 링크를 추가해요.\n\n'
          '**✨ AI가 요약해 준 카드를 한눈에 확인해요.**\n\n'
          '   AI가 영상을 분석하고 핵심 내용을 요약해서 카드로 만들어줘요.\n\n'
          '**❤️ 오른쪽 →**\n\n'
          '   다시 보고 싶은 영상을 스와이프해요.\n\n'
          '**❌ ← 왼쪽**\n\n'
          '   더 이상 보지 않을 영상을 스와이프해요.\n\n',
      thumbnailUrl: '',
      category: '기타',
    ),
  );

  _loadFromBackendIfEmpty();
}

  // CardStore가 비어있을 때만 백엔드에서 초기 로드
  Future<void> _loadFromBackendIfEmpty() async {
    if (CardStore.instance.cards.isNotEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final cards = await ApiService.getContents();
      for (final c in cards) {
        CardStore.instance.add(c);
      }
    } catch (_) {}
    setState(() {
      _currentIndex = 0;
      _isLoading = false;
      // 카드도 없고 백엔드도 실패한 경우만 에러
      if (CardStore.instance.cards.isEmpty) {
        _errorMsg = '카드를 불러오지 못했어요';
      }
    });
  }

  // ── 스와이프 진행도 ────────────────────────────────────────
  double get _swipeProgress =>
      (_dragOffset.dx / _swipeThreshold).clamp(-1.0, 1.0);

  bool get _isSwipingRight => _swipeProgress > 0.15;
  bool get _isSwipingLeft => _swipeProgress < -0.15;

  Color get _heartColor {
    if (_isSwipingRight) {
      return Color.lerp(
        const Color(0xFFBBBBBB),
        const Color(0xFFC794A1),
        _swipeProgress.clamp(0, 1),
      )!;
    }
    return const Color(0xFFBBBBBB);
  }

  Color get _closeColor {
    if (_isSwipingLeft) {
      return Color.lerp(
        const Color(0xFFBBBBBB),
        const Color(0xFF6B95A7),
        (-_swipeProgress).clamp(0, 1),
      )!;
    }
    return const Color(0xFFBBBBBB);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta;
      _dragAngle = _dragOffset.dx * 0.0006;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final filtered = _filteredCards;
    if (filtered.isEmpty) return;

    if (_dragOffset.dx > _swipeThreshold) {
      // 오른쪽 스와이프 → 다시보기(liked)
      _applySwipe(filtered, SwipeState.liked);
    } else if (_dragOffset.dx < -_swipeThreshold) {
      // 왼쪽 스와이프 → 읽음(skipped)
      _applySwipe(filtered, SwipeState.skipped);
    } else {
      // 임계값 미달 → 원위치
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
    }
  }

Future<void> _applySwipe(
  List<VideoCardData> filtered,
  SwipeState state,
) async {
  final safeIndex = _currentIndex.clamp(0, filtered.length - 1);
  final card = filtered[safeIndex];

  // 로컬 상태 변경
  CardStore.instance.updateState(card.videoId, state);

  // 백엔드 상태 변경
  try {
    await ApiService.updateStatus(
      card.contentId,
      state == SwipeState.liked ? 'liked' : 'skipped',
    );
  } catch (e) {
    debugPrint('PATCH 실패: $e');
  }

  if (state == SwipeState.liked) {
    CardStore.instance.moveToEnd(card.videoId);
  }

  setState(() {
    _currentIndex = 0;
    _dragOffset = Offset.zero;
    _dragAngle = 0;
  });
}


  // 버튼으로 스와이프 (REQ-030 / REQ-031)
  void _swipeRight() async {
    final filtered = _filteredCards;
    if (filtered.isEmpty) return;
    await _applySwipe(filtered, SwipeState.liked);
  }

  void _swipeLeft() async {
    final filtered = _filteredCards;
    if (filtered.isEmpty) return;
    await _applySwipe(filtered, SwipeState.skipped);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
            if (_isCategoryOpen) _buildCategoryOverlay(),
          ],
        ),
      ),
    );
  }

  // ── 본문: 로딩 / 에러 / 카드 없음 / 카드 스택 ────────────
Widget _buildBody() {
  if (_isLoading) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF1A1A1A),
        strokeWidth: 2,
      ),
    );
  }

  if (_isRecommendationMode) {
    if (_isRecommendationLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _buildRecommendationList();
  }

  final filtered = _filteredCards;

  if (filtered.isEmpty) {
    return const Center(
      child: Text(
        '카드가 없어요',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFFAAAAAA),
        ),
      ),
    );
  }

return _buildCardStack(filtered);
  }

  // ── 상단바 ────────────────────────────────────────────────
Widget _buildTopBar() {
  final filtered = _filteredCards;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isCategoryOpen = true),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 26,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            GestureDetector(
              onTap: _swipeLeft,
              child: Icon(
                Icons.close_rounded,
                size: 32,
                color: _closeColor,
              ),
            ),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRecommendationMode = false;
                        _currentIndex = 0;
                      });
                    },
                    child: Text(
                      '내 영상',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: !_isRecommendationMode
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: !_isRecommendationMode
                            ? const Color(0xFF383838)
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    '|',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(

                    onTap: () async {
                        final cards = _filteredCards;

                        if (cards.isEmpty) return;

                        setState(() {
                          _isRecommendationMode = true;
                          _currentIndex = 0;
                          _isRecommendationLoading = true;
                        });

                        try {
                          _recommendations =
                              await ApiService.getRecommendations(
                            cards.first.contentId,
                          );
                        } catch (e) {
                          debugPrint('추천 불러오기 실패: $e');
                        }

                        setState(() {
                          _isRecommendationLoading = false;
                        });
                      },
                      child: Text(
                        '추천',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _isRecommendationMode
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: _isRecommendationMode
                            ? const Color(0xFF383838)
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: _swipeRight,
              child: Icon(
                Icons.favorite_border_rounded,
                size: 32,
                color: _heartColor,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ── 카드 스택 ─────────────────────────────────────────────
  Widget _buildCardStack(List<VideoCardData> cards) {
    final safeIndex = _currentIndex.clamp(0, cards.length - 1);

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // 다음 카드 (뒤에 살짝 보임)
          if (cards.length > 1)
            Positioned(
              left: 20,
              right: 20,
              top: 12,
              bottom: 0,
              child: Transform.scale(
                scale: 0.95,
                child: _buildCard(
                    cards[(safeIndex + 1) % cards.length], isBack: true),
              ),
            ),
          // 현재 카드
          Positioned(
            left: 20,
            right: 20,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: _dragAngle,
                  child: _buildCard(cards[safeIndex]),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── 카드 위젯 ─────────────────────────────────────────────
  Widget _buildCard(VideoCardData card, {bool isBack = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: 0,
        right: 0,
        top: 0,
        bottom: 10,
      ),

      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 173, 173, 173), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 98, 98, 98).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: isBack ? const NeverScrollableScrollPhysics() : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 채널명
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                card.channelName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // 썸네일
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://www.youtube.com/watch?v=${card.videoId}',
                      );

                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: card.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            '${ApiService.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.thumbnailUrl)}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbPlaceholder(card.category),
                          )
                        : _thumbPlaceholder(card.category),
                     ),
                  ),
               ),
            ),
            // 제목
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                card.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),
            ),

            // 요약
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: MarkdownBody(
                data: card.summary,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                      height: 1.6,
                    ),
                    h2: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }

  // ── 썸네일 플레이스홀더 ────────────────────────────────────
  Widget _thumbPlaceholder(String category) {
    final colorMap = {
      '자기계발': const Color(0xFFCDB5B0),
      '운동': const Color(0xFFB5C8CD),
      '요리': const Color(0xFFCDC8B5),
      '여행': const Color(0xFFB5CDB8),
      '뉴스': const Color(0xFFBDB5CD),
      '콘텐츠': const Color(0xFFCDBDB5),
      '기타': const Color(0xFFCCCCCC),
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorMap[category] ?? const Color(0xFFCCCCCC),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ── 카테고리 오버레이 패널 ────────────────────────────────
  Widget _buildCategoryOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isCategoryOpen = false),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isCategoryOpen = false),
                            child: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 24,
                                color: Color(0xFF444444)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                cat.isSelected = !cat.isSelected;
                                _currentIndex = 0;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    cat.isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 22,
                                    color: cat.isSelected
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFBBBBBB),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.label,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cat.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildRecommendationList() {
  if (_recommendations.isEmpty) {
    return const Center(
      child: Text(
        '추천 영상이 없습니다',
        style: TextStyle(
          color: Color(0xFFAAAAAA),
        ),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _recommendations.length,
    itemBuilder: (context, index) {
      final item = _recommendations[index];

      return GestureDetector(
        onTap: () async {
           final uri = Uri.parse(item.youtubeUrl);

          await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
           );
            },
  child: Container(
    height: 110,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 140,
                height: 110,
                child: item.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        '${ApiService.baseUrl}/proxy/image?url=${Uri.encodeComponent(item.thumbnailUrl)}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE0E0E0),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE0E0E0),
                      ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
    },
  );
}
}