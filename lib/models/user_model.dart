class UserModel {
  final String uid;
  final String email;
  final String username;
  final String name;
  final String?  profileImageUrl;
  final String? bio;
  final String?  location;  // ✅ New
  final String? phoneNumber;  // ✅ New
  final DateTime createdAt;
  final bool isEmailVerified;
  final double rating;  // ✅ New (for reviews)
  final int reviewCount;  
  final List<String> favoriteEquipmentIds; // ✅ New (for favorites)

  UserModel({
    required this.uid,
    required this. email,
    required this.username,
    required this.name,
    this.profileImageUrl,
    this.bio,
    this.location,
    this. phoneNumber,
    required this. createdAt,
    required this.isEmailVerified,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.favoriteEquipmentIds = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'name':  name,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'location': location,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'rating':  rating,
      'reviewCount':  reviewCount,
      'favoriteEquipmentIds': favoriteEquipmentIds,
    };
  }

  // Create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username:  map['username'] ?? '',
      name: map['name'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      location: map['location'],
      phoneNumber: map['phoneNumber'],
      createdAt:  DateTime.parse(map['createdAt']),
      isEmailVerified: map['isEmailVerified'] ??  false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ??  0,
      favoriteEquipmentIds: List<String>.from(map['favoriteEquipmentIds'] ?? []),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? name,
    String? profileImageUrl,
    String? bio,
    String? location,
    String? phoneNumber,
    DateTime? createdAt,
    bool? isEmailVerified,
    double? rating,
    int? reviewCount,
    List<String>? favoriteEquipmentIds,
  }) {
    return UserModel(
      uid: uid ??  this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this. name,
      profileImageUrl:  profileImageUrl ?? this.profileImageUrl,
      bio: bio ??  this.bio,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this. phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ??  this.reviewCount,
      favoriteEquipmentIds: favoriteEquipmentIds ?? this.favoriteEquipmentIds,
    );
  }

  // Get display rating (e.g., "4.9")
  String get displayRating => rating.toStringAsFixed(1);
  
  // Get review count text (e.g., "(12 reviews)")
  String get reviewText => '($reviewCount ${reviewCount == 1 ? "review" : "reviews"})';
}