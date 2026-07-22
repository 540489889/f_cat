import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// AI 宠物 onboarding 分析服务
///
/// 对接 https://ai.jolipaw.cn/api/v1/pet/onboarding/analyze
/// 将用户的语音/文字介绍 + 宠物照片发送给 AI，返回结构化数据分析结果。
class PetAiService {
  PetAiService._();

  static const String _baseUrl = 'https://ai.jolipaw.cn';

  /// 获取 LLM 专用 Token（AI 服务需要此 token，而非主后端的 JWT）
  static Future<String?> _getAiToken() async {
    try {
      final tokenRes = await ApiClient.instance.get('/app/member/getLLmToken');
      if (tokenRes.isSuccess && tokenRes.data != null) {
        final token = tokenRes.data is String
            ? tokenRes.data as String
            : (tokenRes.data as Map?)?.cast<String, dynamic>()['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          debugPrint('[PetAiService] 成功获取 LLM Token');
          return token;
        }
      }
      debugPrint('[PetAiService] 获取 LLM Token 失败: ${tokenRes.message}');
    } catch (e) {
      debugPrint('[PetAiService] 获取 LLM Token 异常: $e');
    }
    return null;
  }

  /// 从 URL 下载图片并作为 MultipartFile 返回
  static Future<http.MultipartFile?> _downloadAsFile(String url,
      {required String fieldName}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return http.MultipartFile.fromBytes(
          fieldName,
          response.bodyBytes,
          filename: 'photo.jpg',
        );
      }
      debugPrint('[PetAiService] 下载图片失败: $url status=${response.statusCode}');
    } catch (e) {
      debugPrint('[PetAiService] 下载图片异常: $e');
    }
    return null;
  }

  /// 分析宠物介绍
  ///
  /// [description] - 用户输入的文本介绍
  /// [headimg] - 正脸照 URL（已上传到 OSS）
  /// [imgs] - 逗号分隔的多角度照片 URL（已上传到 OSS）
  /// 返回解析后的 data map，失败或出错返回 null
  static Future<Map<String, dynamic>?> analyzePetIntroduction({
    required String description,
    String? headimg,
    String? imgs,
  }) async {
    // 先获取 LLM 专用 Token，失败则无法调用
    String? aiToken = await _getAiToken();
    if (aiToken == null) {
      debugPrint('[PetAiService] 无法获取 LLM Token，跳过 AI 分析');
      return null;
    }

    // 从 OSS URL 下载图片，作为 photo 文件上传
    if (headimg == null || headimg.isEmpty) {
      debugPrint('[PetAiService] 缺少 headimg，无法分析');
      return null;
    }
    final photoFile = await _downloadAsFile(headimg, fieldName: 'photo');
    if (photoFile == null) {
      debugPrint('[PetAiService] 下载图片失败，跳过 AI 分析');
      return null;
    }

    // 最多尝试 2 次（首次 + 401 重新获取 token 后重试 1 次）
    const maxAttempts = 2;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final uri = Uri.parse('$_baseUrl/api/v1/pet/onboarding/analyze');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $aiToken';
      request.fields['description'] = description;
      request.files.add(photoFile);

      try {
        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        debugPrint('[PetAiService] status=${response.statusCode}');
        debugPrint('[PetAiService] body=${response.body}');

        // 401 且是首次尝试时，重新获取 LLM Token 后重试
        if (response.statusCode == 401 && attempt == 0) {
          debugPrint('[PetAiService] 收到 401，重新获取 LLM Token 后重试...');
          final newToken = await _getAiToken();
          if (newToken != null) {
            aiToken = newToken;
            continue;
          }
          debugPrint('[PetAiService] 重新获取 LLM Token 失败，无法重试');
          return null;
        }

        if (response.statusCode != 200) {
          debugPrint('[PetAiService] HTTP error: ${response.statusCode}');
          return null;
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final code = body['code'];
        // AI 接口成功 code 为 0
        if (code == 0 || code == '0') {
          return body['data'] as Map<String, dynamic>?;
        }
        debugPrint('[PetAiService] API error code=$code msg=${body["msg"]}');
        return null;
      } catch (e) {
        debugPrint('[PetAiService] 请求异常: $e');
        return null;
      }
    }
    return null;
  }
}
