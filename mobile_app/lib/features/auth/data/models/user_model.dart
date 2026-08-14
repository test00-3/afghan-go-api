class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? tazkiraNumber;
  final String? email;
  final String? profileImage;
  final String language;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.tazkiraNumber,
    this.email,
    this.profileImage,
    this.language = 'en',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      tazkiraNumber: json['tazkira_number'],
      email: json['email'],
      profileImage: json['profile_image'],
      language: json['language'] ?? 'en',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'tazkira_number': tazkiraNumber,
      'email': email,
      'profile_image': profileImage,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? tazkiraNumber,
    String? email,
    String? profileImage,
    String? language,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      tazkiraNumber: tazkiraNumber ?? this.tazkiraNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
