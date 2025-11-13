class ApiResponse<T> {
  final bool success;
  final String? message;
  final PaginationModel? pagination;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.pagination,
    this.data,
  });

  /// Factory for creating ApiResponse from JSON
  factory ApiResponse.fromJson({
    required Map<String, dynamic> json,
    T Function(dynamic data)? fromDataJson,
  }) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
      data: json['data'] != null && fromDataJson != null
          ? fromDataJson(json['data'])
          : null,
    );
  }

  /// Convert ApiResponse back to JSON
  Map<String, dynamic> toJson({dynamic Function(T data)? toDataJson}) {
    return {
      'success': success,
      'message': message,
      'pagination': pagination?.toJson(),
      'data': data != null && toDataJson != null ? toDataJson(data as T) : null,
    };
  }
}


class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'] ?? 0,
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}
