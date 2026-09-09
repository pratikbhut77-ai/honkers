/// Simple in-memory session store for the logged-in Honkers user.
/// No Supabase Auth — phone-number based identity.
class HonkersSession {
  static HonkersSession? _instance;
  static HonkersSession get instance => _instance ??= HonkersSession._();
  HonkersSession._();

  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;

  String get userId => _currentUser?['id'] as String? ?? '';
  String get phone => _currentUser?['phone'] as String? ?? '';
  String get fullName => _currentUser?['full_name'] as String? ?? 'Honker';
  String get bio => _currentUser?['bio'] as String? ?? '';
  String? get avatarUrl => _currentUser?['avatar_url'] as String?;

  void setUser(Map<String, dynamic> user) {
    _currentUser = Map<String, dynamic>.from(user);
  }

  void updateProfile({
    required String fullName,
    required String bio,
    String? avatarUrl,
  }) {
    if (_currentUser != null) {
      _currentUser!['full_name'] = fullName;
      _currentUser!['bio'] = bio;
      if (avatarUrl != null) _currentUser!['avatar_url'] = avatarUrl;
    }
  }

  void clear() {
    _currentUser = null;
  }

  bool get isLoggedIn => _currentUser != null;
}
