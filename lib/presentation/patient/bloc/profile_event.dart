abstract class ProfileEvent {}

class ProfileFetchRequested extends ProfileEvent {}

class ProfilePictureUpdated extends ProfileEvent {
  final String newUrl;
  ProfilePictureUpdated(this.newUrl);
}

class ProfilePictureUploadRequested extends ProfileEvent {
  final String imagePath;
  ProfilePictureUploadRequested(this.imagePath);
}

class ProfileInfoUpdated extends ProfileEvent {
  final Map<String, dynamic> updatedFields;
  ProfileInfoUpdated(this.updatedFields);
}

class ProfileNotificationSettingsUpdated extends ProfileEvent {
  final bool popupNotifications;
  final bool emailNotifications;
  
  ProfileNotificationSettingsUpdated({
    required this.popupNotifications,
    required this.emailNotifications,
  });
}