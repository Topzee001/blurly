enum MediaPermissionKind { photos, camera }

enum MediaPermissionRecovery { retry, openSettings, restricted }

class MediaPermissionException implements Exception {
  final MediaPermissionKind kind;
  final MediaPermissionRecovery recovery;

  MediaPermissionException({required this.kind, required this.recovery});

  bool get canOpenSettings => recovery == MediaPermissionRecovery.openSettings;

  String get message {
    final permissionName = kind == MediaPermissionKind.photos
        ? 'Photos Library'
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
