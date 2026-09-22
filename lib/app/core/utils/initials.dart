/// Up to two initials for [name], falling back to the first letter of
/// [email], or '?' if neither is available. Shared by the Profile screen's
/// own avatar and the floating profile button in the main app shell.
String initialsFor(String? name, String? email) {
  if (name != null && name.isNotEmpty) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    if (letters.isNotEmpty) return letters.toUpperCase();
  }
  if (email != null && email.isNotEmpty) return email[0].toUpperCase();
  return '?';
}
