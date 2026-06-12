import 'dart:convert';
import 'package:http/http.dart' as http;
import '../user_data.dart';

// ── 응답 데이터 모델 ────────────────────────────────────────
class VideoCardData {
  final int contentId;
  final String videoId;
  final String channelName;
  final String title;
  final String summary;
  final String thumbnailUrl;
  final String category;
  final String status;

  VideoCardData({
    required this.contentId,
    required this.videoId,
    required this.channelName,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.category,
    this.status = 'analyze',
  });

  // POST /contents 응답 파싱
  factory VideoCardData.fromJson(Map<String, dynamic> json) {
    return VideoCardData(
      contentId:    json['content_id'] ?? 0,
      videoId:      json['video_id']?.toString() ?? '',
      channelName:  json['channel'] ?? '',
      title:        json['title'] ?? '',
      summary:      json['summary'] ?? '',
      thumbnailUrl: json['thumbnail'] ?? '',
      category:     json['category'] ?? '기타',
      status:       json['status'] ?? 'analyze',
    );
  }
}

// ── API 서비스 ──────────────────────────────────────────────
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (UserData.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${UserData.accessToken}';
    }
    return headers;
  }

  // GET /contents — URL 분석 요청 → 카드 생성
  static Future<VideoCardData> analyzeVideo(String youtubeUrl, {int? parentContentId}) async {
    final bodyMap = <String, dynamic>{'url': youtubeUrl};
    if (parentContentId != null) {
      bodyMap['parent_content_id'] = parentContentId;
    }

    final res = await http
        .post(
          Uri.parse('$baseUrl/contents'),
          headers: _headers,
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 50000));

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (body['error'] != null) throw Exception(body['error']);
      return VideoCardData.fromJson(body);
    }
    throw Exception('서버 오류 ${res.statusCode}: ${res.body}',);
  }

  // GET /contents — 카드 목록 조회 (카테고리 필터 선택)
  static Future<List<VideoCardData>> getContents({List<String>? categories}) async {
    String url = '$baseUrl/contents';
    if (categories != null && categories.isNotEmpty) {
      final params = categories.map((c) => 'category=$c').join('&');
      url += '?$params';
    }

    final res = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 1000));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List items = data is Map ? (data['items'] ?? []) : data;
      return items.map((e) => VideoCardData.fromJson(e)).toList();
    }
    throw Exception('목록 조회 실패: ${res.statusCode}');
  }

  // PATCH /contents/{content_id}/status — 스와이프 상태 변경
  static Future<void> updateStatus(int contentId, String status) async {
    await http
        .patch(
          Uri.parse('$baseUrl/contents/$contentId/status'),
          headers: _headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
  }

  // DELETE /contents/{content_id} — 카드 삭제
  static Future<void> deleteContent(int contentId) async {
    await http
        .delete(
          Uri.parse('$baseUrl/contents/$contentId'),
          headers: _headers,
          body: jsonEncode({'content_ids': [contentId]}),
        )
        .timeout(const Duration(seconds: 10));
  }

  // GET /contents/{content_id}/recommend — 영상 맞춤 추천 목록 조회
  static Future<List<VideoCardData>> getRecommendations(int contentId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/contents/$contentId/recommend'), headers: _headers)
        .timeout(const Duration(seconds: 30));

    print('===== 추천 API =====');
    print('status: ${res.statusCode}');
    print('body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final Map<String, dynamic> recommendationsObj = data['recommendations'] ?? {};
      final List items = recommendationsObj['recommendations'] ?? [];
      
      return items.map((e) => VideoCardData(
        contentId: 0,
        videoId: e['video_id']?.toString() ?? '',
        channelName: e['channel'] ?? '',
        title: e['title'] ?? '',
        summary: '추천 점수: ${e['final_score'] ?? ''} (클릭하여 찜하기)',
        thumbnailUrl: e['thumbnail_url'] ?? '',
        category: e['category'] ?? '기타',
        status: 'recommend',
      )).toList();
    }
    throw Exception('추천 목록 조회 실패: ${res.statusCode}');
  }

  static Future<void> logout() async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/logout'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('로그아웃 실패');
    }
  }

  static Future<void> deleteAccount() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/user/me'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('회원탈퇴 실패');
    }
  }

  static Future<Map<String, dynamic>> updateNickname(String nickname) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/user/nickname'),
      headers: _headers,
      body: jsonEncode({'nickname': nickname}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('닉네임 변경 실패: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/login/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': 'test'}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('로그인 실패: ${res.statusCode}');
  }
}
