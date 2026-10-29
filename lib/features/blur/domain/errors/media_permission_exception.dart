enum MediaPermissionKind { photos, camera }

// Tells the presentation layer what recovery is appropriate.
enum MediaPermissionRecovery { retry, openSettings, restricted }

// A typed failure is safer than throwing unrelated message strings from the
// data source. The controller can inspect its recovery intent directly.
class MediaPermissionException implements Exception {
  const MediaPermissionException({required this.kind, required this.recovery});

  final MediaPermissionKind kind;
  final MediaPermissionRecovery recovery;

  // Only a permanent denial should expose the Open Settings action.
  bool get canOpenSettings => recovery == MediaPermissionRecovery.openSettings;

  // Keep the user-facing copy in one place so controller and UI tests receive
  // consistent guidance for Photos and Camera.
  String get message {
    final permissionName = kind == MediaPermissionKind.photos
        ? 'Photo library'
        : 'Camera';

    switch (recovery) {
      case MediaPermissionRecovery.retry:
        return '$permissionName access is required. Allow access and try again.';
      case MediaPermissionRecovery.openSettings:
        return '$permissionName access is disabled. Open Settings to allow access.';
      case MediaPermissionRecovery.restricted:
        return '$permissionName access is blocked by device restrictions.';
    }
  }

  @override
  String toString() => message;
}
