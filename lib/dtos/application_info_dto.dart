import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/application_info_dto.g.dart';

@JsonSerializable()
class ApplicationInfoDto {
  final String id;
  final bool maintenanceBreak;
  final String currentVersion;
  final String appUpdateUrl;

  ApplicationInfoDto({
    required this.id,
    required this.maintenanceBreak,
    required this.currentVersion,
    required this.appUpdateUrl,
  });

  /// Connect the generated [_$ApplicationInfoDtoFromJson] function to the `fromJson`
  /// factory.
  factory ApplicationInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ApplicationInfoDtoFromJson(json);

  /// Connect the generated [_$ApplicationInfoDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$ApplicationInfoDtoToJson(this);
}
