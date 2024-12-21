class UserProfile {
  final String? name;
  final String? email;
  final String? photoURL;
  final int? friendCount;
  final int? followerCount;
  final List<String> friends;
  final List<String> followers;

  UserProfile({
    this.name,
    this.email,
    this.photoURL,
    this.friendCount,
    this.followerCount,
    required this.friends,
    required this.followers,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      friendCount: data['friendCount'] as int? ?? 0,
      followerCount: data['followerCount'] as int? ?? 0,
      friends: List<String>.from(data['friends'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }
}
