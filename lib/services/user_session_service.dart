class UserSessionService {
  // A private variable to hold the user ID
  static String? _currentUserId;

  // A 'getter' to allow other parts of the app to read the ID
  String? get currentUserId => _currentUserId;

  // A 'setter' to allow other parts of the app to set the ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }
}