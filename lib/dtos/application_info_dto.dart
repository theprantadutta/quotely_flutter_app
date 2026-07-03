import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/application_info_dto.g.dart';

@JsonSerializable()
class ApplicationInfoDto {
  final String id;
  final bool maintenanceBreak;
  final String currentVersion;
  final String appUpdateUrl;

  /// Latest iOS version on the App Store, managed from the admin dashboard.
  /// iOS has no Play-style in-app update, so the app compares its own version
  /// against this and shows an update banner on the home screen.
  final String? iosCurrentVersion;

  /// App Store link the iOS update banner opens.
  final String? iosAppUpdateUrl;

  ApplicationInfoDto({
    required this.id,
    required this.maintenanceBreak,
    required this.currentVersion,
    required this.appUpdateUrl,
    this.iosCurrentVersion,
    this.iosAppUpdateUrl,
  });

  factory ApplicationInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ApplicationInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationInfoDtoToJson(this);
}
