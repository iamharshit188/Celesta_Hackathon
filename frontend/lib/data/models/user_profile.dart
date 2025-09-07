import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isOnboardingCompleted;
  final Map<String, dynamic> preferences;
  final int totalAnalyses;
  final int totalBookmarks;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.isOnboardingCompleted = false,
    this.preferences = const {},
    this.totalAnalyses = 0,
    this.totalBookmarks = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt'] ?? '') ?? DateTime.now(),
      isOnboardingCompleted: json['isOnboardingCompleted'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      totalAnalyses: json['totalAnalyses'] ?? 0,
      totalBookmarks: json['totalBookmarks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isOnboardingCompleted': isOnboardingCompleted,
      'preferences': preferences,
      'totalAnalyses': totalAnalyses,
      'totalBookmarks': totalBookmarks,
    };
  }

  String get initials {
    final names = displayName.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isOnboardingCompleted,
    Map<String, dynamic>? preferences,
    int? totalAnalyses,
    int? totalBookmarks,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      preferences: preferences ?? this.preferences,
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        avatarUrl,
        createdAt,
        lastLoginAt,
        isOnboardingCompleted,
        preferences,
        totalAnalyses,
        totalBookmarks,
      ];
}
