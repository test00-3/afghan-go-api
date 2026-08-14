class ProfileModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? tazkiraNumber;
  final String? email;
  final String? profileImage;
  final String language;
  final bool pushNotifications;
  final bool emailNotifications;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.tazkiraNumber,
    this.email,
    this.profileImage,
    this.language = 'en',
    this.pushNotifications = true,
    this.emailNotifications = false,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      tazkiraNumber: json['tazkira_number'],
      email: json['email'],
      profileImage: json['profile_image'],
      language: json['language'] ?? 'en',
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? false,
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
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? tazkiraNumber,
    String? email,
    String? profileImage,
    String? language,
    bool? pushNotifications,
    bool? emailNotifications,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      tazkiraNumber: tazkiraNumber ?? this.tazkiraNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      language: language ?? this.language,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
