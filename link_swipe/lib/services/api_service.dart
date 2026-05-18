import 'dart:convert';
import 'package:http/http.dart' as http;
 
// ── 응답 데이터 모델 ────────────────────────────────────────
// analyze.py 응답: video_id, title, thumbnail_url, channel, category, summary
class VideoCardData {
  final String videoId;
  final String channelName;
  final String title;
  final String summary;
  final String thumbnailUrl;
  final String category;
 
  VideoCardData({
    required this.videoId,
    required this.channelName,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
  });
 
  factory VideoCardData.fromAnalyze(Map<String, dynamic> json) {
    return VideoCardData(
      videoId: json['video_id']?.toString() ?? '',
      channelName: json['channel'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',  // thumbnail_url (언더스코어)
      category: json['category'] ?? '기타',
    );
  }
 
  factory VideoCardData.fromVideos(Map<String, dynamic> json) {
    return VideoCardData(
      videoId: json['video_id']?.toString() ?? '',
      channelName: json['channel'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail'] ?? '',
      category: json['category'] ?? '기타',
    );
  }
}
 
// ── API 서비스 ──────────────────────────────────────────────
class ApiService {
  // 실제 기기 테스트 시: 'http://본인PC_IP:8000' 으로 변경
  static const String baseUrl = 'http://127.0.0.1:8000';
 
  // POST /analyze — 유튜브 URL → 크롤링 + 요약 + 분류
  static Future<VideoCardData> analyzeVideo(String youtubeUrl) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': youtubeUrl}),
        )
        .timeout(const Duration(seconds: 60)); // 자막 분석이 오래 걸릴 수 있음
 
    final body = jsonDecode(res.body);
 
    if (res.statusCode == 200) {
      if (body['error'] != null) {
        throw Exception(body['error']);
      }
      return VideoCardData.fromAnalyze(body);
    }
    throw Exception('서버 오류: ${res.statusCode}');
  }
 
  // GET /videos — 저장된 카드 목록 조회
  static Future<List<VideoCardData>> getVideos() async {
    final res = await http
        .get(Uri.parse('$baseUrl/videos'))
        .timeout(const Duration(seconds: 15));
 
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => VideoCardData.fromVideos(e)).toList();
    }
    throw Exception('목록 조회 실패: ${res.statusCode}');
  }
}