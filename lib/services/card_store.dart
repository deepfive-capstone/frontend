import 'api_service.dart';

// ── 카드 스와이프 상태 ────────────────────────────────────────
enum SwipeState {
  none,    // 아직 스와이프 안 함 (최근 추가)
  liked,   // 오른쪽 스와이프 → 다시보기
  skipped, // 왼쪽 스와이프 → 읽음
}

// ── 상태를 포함한 카드 래퍼 ──────────────────────────────────
class StoredCard {
  final VideoCardData data;
  SwipeState state;
  final DateTime savedAt;

  StoredCard({
    required this.data,
    this.state = SwipeState.none,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();
}

// ── 앱 전역 카드 저장소 ──────────────────────────────────────
class CardStore {
  CardStore._();
  static final CardStore instance = CardStore._();

  final List<StoredCard> _cards = [];

  List<StoredCard> get cards => List.unmodifiable(_cards);

  // VideoCardData만 필요한 경우 편의용 getter
  List<VideoCardData> get videoCards =>
      _cards.map((c) => c.data).toList();

  // 카드 추가 (링크 분석 완료 시 호출)
  void add(VideoCardData card) {
    // 중복 방지: 같은 video_id면 덮어쓰기
    _cards.removeWhere((c) => c.data.videoId == card.videoId);
    _cards.insert(0, StoredCard(data: card)); // 최신 카드가 맨 앞
  }

// 카드를 맨 뒤로 이동 (liked 순환용)
void moveToEnd(String videoId) {
  final idx = _cards.indexWhere((c) => c.data.videoId == videoId);
  if (idx != -1) {
    final card = _cards.removeAt(idx);
    _cards.add(card);
  }
}

  // 스와이프 상태 업데이트
  void updateState(String videoId, SwipeState state) {
    final idx = _cards.indexWhere((c) => c.data.videoId == videoId);
    if (idx != -1) {
      _cards[idx].state = state;
    }
  }

  // 카드 삭제
  void remove(String videoId) {
    _cards.removeWhere((c) => c.data.videoId == videoId);
  }

  // 전체 삭제
  void clear() => _cards.clear();
}