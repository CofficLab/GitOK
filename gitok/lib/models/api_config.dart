import 'package:flutter/material.dart';

class ApiConfig {
  final String name;
  final List<ApiEndpoint> endpoints;
  final DateTime lastModified;

  ApiConfig({
    required this.name,
    required this.endpoints,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'endpoints': endpoints.map((e) => e.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      name: json['name'],
      endpoints: (json['endpoints'] as List).map((e) => ApiEndpoint.fromJson(e)).toList(),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}

class ApiEndpoint {
  final String name;
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> queryParams;
  final dynamic body;
  final List<ApiResponse> responses;

  ApiEndpoint({
    required this.name,
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParams = const {},
    this.body,
    this.responses = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'method': method,
      'url': url,
      'headers': headers,
      'queryParams': queryParams,
      'body': body,
      'responses': responses.map((r) => r.toJson()).toList(),
    };
  }

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    return ApiEndpoint(
      name: json['name'],
      method: json['method'],
      url: json['url'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, dynamic>.from(json['queryParams'] ?? {}),
      body: json['body'],
      responses: (json['responses'] as List? ?? []).map((r) => ApiResponse.fromJson(r)).toList(),
    );
  }
}

class ApiResponse {
  final DateTime timestamp;
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final Duration duration;

  ApiResponse({
    required this.timestamp,
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'statusCode': statusCode,
      'headers': headers,
      'body': body,
      'duration': duration.inMilliseconds,
    };
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      timestamp: DateTime.parse(json['timestamp']),
      statusCode: json['statusCode'],
      headers: Map<String, String>.from(json['headers']),
      body: json['body'],
      duration: Duration(milliseconds: json['duration']),
    );
  }
}
