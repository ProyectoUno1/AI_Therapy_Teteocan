
class PatientProfileData {
  final String? profilePictureUrl;
  final String? username;
  final int? usedMessages;
  final int? messageLimit;
  final bool? isPremium;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;

  PatientProfileData({
    this.profilePictureUrl,
    this.username,
    this.usedMessages,
    this.messageLimit,
    this.isPremium,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
  });

  factory PatientProfileData.fromMap(Map<String, dynamic> map) {
    return PatientProfileData(
      profilePictureUrl: map['profile_picture_url'] as String?,
      username: map['username'] as String?,
      usedMessages: map['messageCount'] as int?,
      messageLimit: map['messageLimit'] as int?,
      isPremium: map['isPremium'] as bool?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
    );
  }

  PatientProfileData copyWith({
    String? profilePictureUrl,
    String? username,
    int? usedMessages,
    int? messageLimit,
    bool? isPremium,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) {
    return PatientProfileData(
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      username: username ?? this.username,
      usedMessages: usedMessages ?? this.usedMessages,
      messageLimit: messageLimit ?? this.messageLimit,
      isPremium: isPremium ?? this.isPremium,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final PatientProfileData profileData;
  ProfileLoaded(this.profileData);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileUpdateSuccess extends ProfileLoaded {
  ProfileUpdateSuccess(super.profileData);
}