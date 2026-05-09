String initialsFromName(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final String firstInitial = parts[0].isNotEmpty ? parts[0][0] : '';
    final String lastInitial = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
    return (firstInitial + lastInitial).toUpperCase();
  }
  if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return '?';
}
