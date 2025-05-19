// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromoModel implements DiagnosticableTreeMixin {

 String get promotionId; String? get kennelId; String? get cityId; String? get eventId; String? get promoGroupId; String get promoName; DateTime get promoStartDate; DateTime get promoEndDate; int get promoDisplayButtons; String get promoImage; String get promoImageExtension; String get promoOverlayTiming; String? get promoExternalUrl; String? get promoExternalUrlButtonText; int get promoPriority; double? get promoLat; double? get promoLon; double? get promoRadius; String get promoDisplayTimingDotsShape; int get promoDisplayTimingDotsToDisplay; int get promoDisplayTimingDotsSize; int get promoGeographicScope; int get promoImageIsDark; int get promoDisplayTimeInMs;
/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoModelCopyWith<PromoModel> get copyWith => _$PromoModelCopyWithImpl<PromoModel>(this as PromoModel, _$identity);

  /// Serializes this PromoModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PromoModel'))
    ..add(DiagnosticsProperty('promotionId', promotionId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('promoGroupId', promoGroupId))..add(DiagnosticsProperty('promoName', promoName))..add(DiagnosticsProperty('promoStartDate', promoStartDate))..add(DiagnosticsProperty('promoEndDate', promoEndDate))..add(DiagnosticsProperty('promoDisplayButtons', promoDisplayButtons))..add(DiagnosticsProperty('promoImage', promoImage))..add(DiagnosticsProperty('promoImageExtension', promoImageExtension))..add(DiagnosticsProperty('promoOverlayTiming', promoOverlayTiming))..add(DiagnosticsProperty('promoExternalUrl', promoExternalUrl))..add(DiagnosticsProperty('promoExternalUrlButtonText', promoExternalUrlButtonText))..add(DiagnosticsProperty('promoPriority', promoPriority))..add(DiagnosticsProperty('promoLat', promoLat))..add(DiagnosticsProperty('promoLon', promoLon))..add(DiagnosticsProperty('promoRadius', promoRadius))..add(DiagnosticsProperty('promoDisplayTimingDotsShape', promoDisplayTimingDotsShape))..add(DiagnosticsProperty('promoDisplayTimingDotsToDisplay', promoDisplayTimingDotsToDisplay))..add(DiagnosticsProperty('promoDisplayTimingDotsSize', promoDisplayTimingDotsSize))..add(DiagnosticsProperty('promoGeographicScope', promoGeographicScope))..add(DiagnosticsProperty('promoImageIsDark', promoImageIsDark))..add(DiagnosticsProperty('promoDisplayTimeInMs', promoDisplayTimeInMs));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoModel&&(identical(other.promotionId, promotionId) || other.promotionId == promotionId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.promoGroupId, promoGroupId) || other.promoGroupId == promoGroupId)&&(identical(other.promoName, promoName) || other.promoName == promoName)&&(identical(other.promoStartDate, promoStartDate) || other.promoStartDate == promoStartDate)&&(identical(other.promoEndDate, promoEndDate) || other.promoEndDate == promoEndDate)&&(identical(other.promoDisplayButtons, promoDisplayButtons) || other.promoDisplayButtons == promoDisplayButtons)&&(identical(other.promoImage, promoImage) || other.promoImage == promoImage)&&(identical(other.promoImageExtension, promoImageExtension) || other.promoImageExtension == promoImageExtension)&&(identical(other.promoOverlayTiming, promoOverlayTiming) || other.promoOverlayTiming == promoOverlayTiming)&&(identical(other.promoExternalUrl, promoExternalUrl) || other.promoExternalUrl == promoExternalUrl)&&(identical(other.promoExternalUrlButtonText, promoExternalUrlButtonText) || other.promoExternalUrlButtonText == promoExternalUrlButtonText)&&(identical(other.promoPriority, promoPriority) || other.promoPriority == promoPriority)&&(identical(other.promoLat, promoLat) || other.promoLat == promoLat)&&(identical(other.promoLon, promoLon) || other.promoLon == promoLon)&&(identical(other.promoRadius, promoRadius) || other.promoRadius == promoRadius)&&(identical(other.promoDisplayTimingDotsShape, promoDisplayTimingDotsShape) || other.promoDisplayTimingDotsShape == promoDisplayTimingDotsShape)&&(identical(other.promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsToDisplay) || other.promoDisplayTimingDotsToDisplay == promoDisplayTimingDotsToDisplay)&&(identical(other.promoDisplayTimingDotsSize, promoDisplayTimingDotsSize) || other.promoDisplayTimingDotsSize == promoDisplayTimingDotsSize)&&(identical(other.promoGeographicScope, promoGeographicScope) || other.promoGeographicScope == promoGeographicScope)&&(identical(other.promoImageIsDark, promoImageIsDark) || other.promoImageIsDark == promoImageIsDark)&&(identical(other.promoDisplayTimeInMs, promoDisplayTimeInMs) || other.promoDisplayTimeInMs == promoDisplayTimeInMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,promotionId,kennelId,cityId,eventId,promoGroupId,promoName,promoStartDate,promoEndDate,promoDisplayButtons,promoImage,promoImageExtension,promoOverlayTiming,promoExternalUrl,promoExternalUrlButtonText,promoPriority,promoLat,promoLon,promoRadius,promoDisplayTimingDotsShape,promoDisplayTimingDotsToDisplay,promoDisplayTimingDotsSize,promoGeographicScope,promoImageIsDark,promoDisplayTimeInMs]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PromoModel(promotionId: $promotionId, kennelId: $kennelId, cityId: $cityId, eventId: $eventId, promoGroupId: $promoGroupId, promoName: $promoName, promoStartDate: $promoStartDate, promoEndDate: $promoEndDate, promoDisplayButtons: $promoDisplayButtons, promoImage: $promoImage, promoImageExtension: $promoImageExtension, promoOverlayTiming: $promoOverlayTiming, promoExternalUrl: $promoExternalUrl, promoExternalUrlButtonText: $promoExternalUrlButtonText, promoPriority: $promoPriority, promoLat: $promoLat, promoLon: $promoLon, promoRadius: $promoRadius, promoDisplayTimingDotsShape: $promoDisplayTimingDotsShape, promoDisplayTimingDotsToDisplay: $promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsSize: $promoDisplayTimingDotsSize, promoGeographicScope: $promoGeographicScope, promoImageIsDark: $promoImageIsDark, promoDisplayTimeInMs: $promoDisplayTimeInMs)';
}


}

/// @nodoc
abstract mixin class $PromoModelCopyWith<$Res>  {
  factory $PromoModelCopyWith(PromoModel value, $Res Function(PromoModel) _then) = _$PromoModelCopyWithImpl;
@useResult
$Res call({
 String promotionId, String? kennelId, String? cityId, String? eventId, String? promoGroupId, String promoName, DateTime promoStartDate, DateTime promoEndDate, int promoDisplayButtons, String promoImage, String promoImageExtension, String promoOverlayTiming, String? promoExternalUrl, String? promoExternalUrlButtonText, int promoPriority, double? promoLat, double? promoLon, double? promoRadius, String promoDisplayTimingDotsShape, int promoDisplayTimingDotsToDisplay, int promoDisplayTimingDotsSize, int promoGeographicScope, int promoImageIsDark, int promoDisplayTimeInMs
});




}
/// @nodoc
class _$PromoModelCopyWithImpl<$Res>
    implements $PromoModelCopyWith<$Res> {
  _$PromoModelCopyWithImpl(this._self, this._then);

  final PromoModel _self;
  final $Res Function(PromoModel) _then;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promotionId = null,Object? kennelId = freezed,Object? cityId = freezed,Object? eventId = freezed,Object? promoGroupId = freezed,Object? promoName = null,Object? promoStartDate = null,Object? promoEndDate = null,Object? promoDisplayButtons = null,Object? promoImage = null,Object? promoImageExtension = null,Object? promoOverlayTiming = null,Object? promoExternalUrl = freezed,Object? promoExternalUrlButtonText = freezed,Object? promoPriority = null,Object? promoLat = freezed,Object? promoLon = freezed,Object? promoRadius = freezed,Object? promoDisplayTimingDotsShape = null,Object? promoDisplayTimingDotsToDisplay = null,Object? promoDisplayTimingDotsSize = null,Object? promoGeographicScope = null,Object? promoImageIsDark = null,Object? promoDisplayTimeInMs = null,}) {
  return _then(_self.copyWith(
promotionId: null == promotionId ? _self.promotionId : promotionId // ignore: cast_nullable_to_non_nullable
as String,kennelId: freezed == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,promoGroupId: freezed == promoGroupId ? _self.promoGroupId : promoGroupId // ignore: cast_nullable_to_non_nullable
as String?,promoName: null == promoName ? _self.promoName : promoName // ignore: cast_nullable_to_non_nullable
as String,promoStartDate: null == promoStartDate ? _self.promoStartDate : promoStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,promoEndDate: null == promoEndDate ? _self.promoEndDate : promoEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,promoDisplayButtons: null == promoDisplayButtons ? _self.promoDisplayButtons : promoDisplayButtons // ignore: cast_nullable_to_non_nullable
as int,promoImage: null == promoImage ? _self.promoImage : promoImage // ignore: cast_nullable_to_non_nullable
as String,promoImageExtension: null == promoImageExtension ? _self.promoImageExtension : promoImageExtension // ignore: cast_nullable_to_non_nullable
as String,promoOverlayTiming: null == promoOverlayTiming ? _self.promoOverlayTiming : promoOverlayTiming // ignore: cast_nullable_to_non_nullable
as String,promoExternalUrl: freezed == promoExternalUrl ? _self.promoExternalUrl : promoExternalUrl // ignore: cast_nullable_to_non_nullable
as String?,promoExternalUrlButtonText: freezed == promoExternalUrlButtonText ? _self.promoExternalUrlButtonText : promoExternalUrlButtonText // ignore: cast_nullable_to_non_nullable
as String?,promoPriority: null == promoPriority ? _self.promoPriority : promoPriority // ignore: cast_nullable_to_non_nullable
as int,promoLat: freezed == promoLat ? _self.promoLat : promoLat // ignore: cast_nullable_to_non_nullable
as double?,promoLon: freezed == promoLon ? _self.promoLon : promoLon // ignore: cast_nullable_to_non_nullable
as double?,promoRadius: freezed == promoRadius ? _self.promoRadius : promoRadius // ignore: cast_nullable_to_non_nullable
as double?,promoDisplayTimingDotsShape: null == promoDisplayTimingDotsShape ? _self.promoDisplayTimingDotsShape : promoDisplayTimingDotsShape // ignore: cast_nullable_to_non_nullable
as String,promoDisplayTimingDotsToDisplay: null == promoDisplayTimingDotsToDisplay ? _self.promoDisplayTimingDotsToDisplay : promoDisplayTimingDotsToDisplay // ignore: cast_nullable_to_non_nullable
as int,promoDisplayTimingDotsSize: null == promoDisplayTimingDotsSize ? _self.promoDisplayTimingDotsSize : promoDisplayTimingDotsSize // ignore: cast_nullable_to_non_nullable
as int,promoGeographicScope: null == promoGeographicScope ? _self.promoGeographicScope : promoGeographicScope // ignore: cast_nullable_to_non_nullable
as int,promoImageIsDark: null == promoImageIsDark ? _self.promoImageIsDark : promoImageIsDark // ignore: cast_nullable_to_non_nullable
as int,promoDisplayTimeInMs: null == promoDisplayTimeInMs ? _self.promoDisplayTimeInMs : promoDisplayTimeInMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PromoModel with DiagnosticableTreeMixin implements PromoModel {
   _PromoModel({required this.promotionId, this.kennelId, this.cityId, this.eventId, this.promoGroupId, required this.promoName, required this.promoStartDate, required this.promoEndDate, required this.promoDisplayButtons, required this.promoImage, required this.promoImageExtension, required this.promoOverlayTiming, this.promoExternalUrl, this.promoExternalUrlButtonText, required this.promoPriority, this.promoLat, this.promoLon, this.promoRadius, required this.promoDisplayTimingDotsShape, required this.promoDisplayTimingDotsToDisplay, required this.promoDisplayTimingDotsSize, required this.promoGeographicScope, required this.promoImageIsDark, required this.promoDisplayTimeInMs});
  factory _PromoModel.fromJson(Map<String, dynamic> json) => _$PromoModelFromJson(json);

@override final  String promotionId;
@override final  String? kennelId;
@override final  String? cityId;
@override final  String? eventId;
@override final  String? promoGroupId;
@override final  String promoName;
@override final  DateTime promoStartDate;
@override final  DateTime promoEndDate;
@override final  int promoDisplayButtons;
@override final  String promoImage;
@override final  String promoImageExtension;
@override final  String promoOverlayTiming;
@override final  String? promoExternalUrl;
@override final  String? promoExternalUrlButtonText;
@override final  int promoPriority;
@override final  double? promoLat;
@override final  double? promoLon;
@override final  double? promoRadius;
@override final  String promoDisplayTimingDotsShape;
@override final  int promoDisplayTimingDotsToDisplay;
@override final  int promoDisplayTimingDotsSize;
@override final  int promoGeographicScope;
@override final  int promoImageIsDark;
@override final  int promoDisplayTimeInMs;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoModelCopyWith<_PromoModel> get copyWith => __$PromoModelCopyWithImpl<_PromoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromoModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PromoModel'))
    ..add(DiagnosticsProperty('promotionId', promotionId))..add(DiagnosticsProperty('kennelId', kennelId))..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('promoGroupId', promoGroupId))..add(DiagnosticsProperty('promoName', promoName))..add(DiagnosticsProperty('promoStartDate', promoStartDate))..add(DiagnosticsProperty('promoEndDate', promoEndDate))..add(DiagnosticsProperty('promoDisplayButtons', promoDisplayButtons))..add(DiagnosticsProperty('promoImage', promoImage))..add(DiagnosticsProperty('promoImageExtension', promoImageExtension))..add(DiagnosticsProperty('promoOverlayTiming', promoOverlayTiming))..add(DiagnosticsProperty('promoExternalUrl', promoExternalUrl))..add(DiagnosticsProperty('promoExternalUrlButtonText', promoExternalUrlButtonText))..add(DiagnosticsProperty('promoPriority', promoPriority))..add(DiagnosticsProperty('promoLat', promoLat))..add(DiagnosticsProperty('promoLon', promoLon))..add(DiagnosticsProperty('promoRadius', promoRadius))..add(DiagnosticsProperty('promoDisplayTimingDotsShape', promoDisplayTimingDotsShape))..add(DiagnosticsProperty('promoDisplayTimingDotsToDisplay', promoDisplayTimingDotsToDisplay))..add(DiagnosticsProperty('promoDisplayTimingDotsSize', promoDisplayTimingDotsSize))..add(DiagnosticsProperty('promoGeographicScope', promoGeographicScope))..add(DiagnosticsProperty('promoImageIsDark', promoImageIsDark))..add(DiagnosticsProperty('promoDisplayTimeInMs', promoDisplayTimeInMs));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoModel&&(identical(other.promotionId, promotionId) || other.promotionId == promotionId)&&(identical(other.kennelId, kennelId) || other.kennelId == kennelId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.promoGroupId, promoGroupId) || other.promoGroupId == promoGroupId)&&(identical(other.promoName, promoName) || other.promoName == promoName)&&(identical(other.promoStartDate, promoStartDate) || other.promoStartDate == promoStartDate)&&(identical(other.promoEndDate, promoEndDate) || other.promoEndDate == promoEndDate)&&(identical(other.promoDisplayButtons, promoDisplayButtons) || other.promoDisplayButtons == promoDisplayButtons)&&(identical(other.promoImage, promoImage) || other.promoImage == promoImage)&&(identical(other.promoImageExtension, promoImageExtension) || other.promoImageExtension == promoImageExtension)&&(identical(other.promoOverlayTiming, promoOverlayTiming) || other.promoOverlayTiming == promoOverlayTiming)&&(identical(other.promoExternalUrl, promoExternalUrl) || other.promoExternalUrl == promoExternalUrl)&&(identical(other.promoExternalUrlButtonText, promoExternalUrlButtonText) || other.promoExternalUrlButtonText == promoExternalUrlButtonText)&&(identical(other.promoPriority, promoPriority) || other.promoPriority == promoPriority)&&(identical(other.promoLat, promoLat) || other.promoLat == promoLat)&&(identical(other.promoLon, promoLon) || other.promoLon == promoLon)&&(identical(other.promoRadius, promoRadius) || other.promoRadius == promoRadius)&&(identical(other.promoDisplayTimingDotsShape, promoDisplayTimingDotsShape) || other.promoDisplayTimingDotsShape == promoDisplayTimingDotsShape)&&(identical(other.promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsToDisplay) || other.promoDisplayTimingDotsToDisplay == promoDisplayTimingDotsToDisplay)&&(identical(other.promoDisplayTimingDotsSize, promoDisplayTimingDotsSize) || other.promoDisplayTimingDotsSize == promoDisplayTimingDotsSize)&&(identical(other.promoGeographicScope, promoGeographicScope) || other.promoGeographicScope == promoGeographicScope)&&(identical(other.promoImageIsDark, promoImageIsDark) || other.promoImageIsDark == promoImageIsDark)&&(identical(other.promoDisplayTimeInMs, promoDisplayTimeInMs) || other.promoDisplayTimeInMs == promoDisplayTimeInMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,promotionId,kennelId,cityId,eventId,promoGroupId,promoName,promoStartDate,promoEndDate,promoDisplayButtons,promoImage,promoImageExtension,promoOverlayTiming,promoExternalUrl,promoExternalUrlButtonText,promoPriority,promoLat,promoLon,promoRadius,promoDisplayTimingDotsShape,promoDisplayTimingDotsToDisplay,promoDisplayTimingDotsSize,promoGeographicScope,promoImageIsDark,promoDisplayTimeInMs]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PromoModel(promotionId: $promotionId, kennelId: $kennelId, cityId: $cityId, eventId: $eventId, promoGroupId: $promoGroupId, promoName: $promoName, promoStartDate: $promoStartDate, promoEndDate: $promoEndDate, promoDisplayButtons: $promoDisplayButtons, promoImage: $promoImage, promoImageExtension: $promoImageExtension, promoOverlayTiming: $promoOverlayTiming, promoExternalUrl: $promoExternalUrl, promoExternalUrlButtonText: $promoExternalUrlButtonText, promoPriority: $promoPriority, promoLat: $promoLat, promoLon: $promoLon, promoRadius: $promoRadius, promoDisplayTimingDotsShape: $promoDisplayTimingDotsShape, promoDisplayTimingDotsToDisplay: $promoDisplayTimingDotsToDisplay, promoDisplayTimingDotsSize: $promoDisplayTimingDotsSize, promoGeographicScope: $promoGeographicScope, promoImageIsDark: $promoImageIsDark, promoDisplayTimeInMs: $promoDisplayTimeInMs)';
}


}

/// @nodoc
abstract mixin class _$PromoModelCopyWith<$Res> implements $PromoModelCopyWith<$Res> {
  factory _$PromoModelCopyWith(_PromoModel value, $Res Function(_PromoModel) _then) = __$PromoModelCopyWithImpl;
@override @useResult
$Res call({
 String promotionId, String? kennelId, String? cityId, String? eventId, String? promoGroupId, String promoName, DateTime promoStartDate, DateTime promoEndDate, int promoDisplayButtons, String promoImage, String promoImageExtension, String promoOverlayTiming, String? promoExternalUrl, String? promoExternalUrlButtonText, int promoPriority, double? promoLat, double? promoLon, double? promoRadius, String promoDisplayTimingDotsShape, int promoDisplayTimingDotsToDisplay, int promoDisplayTimingDotsSize, int promoGeographicScope, int promoImageIsDark, int promoDisplayTimeInMs
});




}
/// @nodoc
class __$PromoModelCopyWithImpl<$Res>
    implements _$PromoModelCopyWith<$Res> {
  __$PromoModelCopyWithImpl(this._self, this._then);

  final _PromoModel _self;
  final $Res Function(_PromoModel) _then;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promotionId = null,Object? kennelId = freezed,Object? cityId = freezed,Object? eventId = freezed,Object? promoGroupId = freezed,Object? promoName = null,Object? promoStartDate = null,Object? promoEndDate = null,Object? promoDisplayButtons = null,Object? promoImage = null,Object? promoImageExtension = null,Object? promoOverlayTiming = null,Object? promoExternalUrl = freezed,Object? promoExternalUrlButtonText = freezed,Object? promoPriority = null,Object? promoLat = freezed,Object? promoLon = freezed,Object? promoRadius = freezed,Object? promoDisplayTimingDotsShape = null,Object? promoDisplayTimingDotsToDisplay = null,Object? promoDisplayTimingDotsSize = null,Object? promoGeographicScope = null,Object? promoImageIsDark = null,Object? promoDisplayTimeInMs = null,}) {
  return _then(_PromoModel(
promotionId: null == promotionId ? _self.promotionId : promotionId // ignore: cast_nullable_to_non_nullable
as String,kennelId: freezed == kennelId ? _self.kennelId : kennelId // ignore: cast_nullable_to_non_nullable
as String?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,promoGroupId: freezed == promoGroupId ? _self.promoGroupId : promoGroupId // ignore: cast_nullable_to_non_nullable
as String?,promoName: null == promoName ? _self.promoName : promoName // ignore: cast_nullable_to_non_nullable
as String,promoStartDate: null == promoStartDate ? _self.promoStartDate : promoStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,promoEndDate: null == promoEndDate ? _self.promoEndDate : promoEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,promoDisplayButtons: null == promoDisplayButtons ? _self.promoDisplayButtons : promoDisplayButtons // ignore: cast_nullable_to_non_nullable
as int,promoImage: null == promoImage ? _self.promoImage : promoImage // ignore: cast_nullable_to_non_nullable
as String,promoImageExtension: null == promoImageExtension ? _self.promoImageExtension : promoImageExtension // ignore: cast_nullable_to_non_nullable
as String,promoOverlayTiming: null == promoOverlayTiming ? _self.promoOverlayTiming : promoOverlayTiming // ignore: cast_nullable_to_non_nullable
as String,promoExternalUrl: freezed == promoExternalUrl ? _self.promoExternalUrl : promoExternalUrl // ignore: cast_nullable_to_non_nullable
as String?,promoExternalUrlButtonText: freezed == promoExternalUrlButtonText ? _self.promoExternalUrlButtonText : promoExternalUrlButtonText // ignore: cast_nullable_to_non_nullable
as String?,promoPriority: null == promoPriority ? _self.promoPriority : promoPriority // ignore: cast_nullable_to_non_nullable
as int,promoLat: freezed == promoLat ? _self.promoLat : promoLat // ignore: cast_nullable_to_non_nullable
as double?,promoLon: freezed == promoLon ? _self.promoLon : promoLon // ignore: cast_nullable_to_non_nullable
as double?,promoRadius: freezed == promoRadius ? _self.promoRadius : promoRadius // ignore: cast_nullable_to_non_nullable
as double?,promoDisplayTimingDotsShape: null == promoDisplayTimingDotsShape ? _self.promoDisplayTimingDotsShape : promoDisplayTimingDotsShape // ignore: cast_nullable_to_non_nullable
as String,promoDisplayTimingDotsToDisplay: null == promoDisplayTimingDotsToDisplay ? _self.promoDisplayTimingDotsToDisplay : promoDisplayTimingDotsToDisplay // ignore: cast_nullable_to_non_nullable
as int,promoDisplayTimingDotsSize: null == promoDisplayTimingDotsSize ? _self.promoDisplayTimingDotsSize : promoDisplayTimingDotsSize // ignore: cast_nullable_to_non_nullable
as int,promoGeographicScope: null == promoGeographicScope ? _self.promoGeographicScope : promoGeographicScope // ignore: cast_nullable_to_non_nullable
as int,promoImageIsDark: null == promoImageIsDark ? _self.promoImageIsDark : promoImageIsDark // ignore: cast_nullable_to_non_nullable
as int,promoDisplayTimeInMs: null == promoDisplayTimeInMs ? _self.promoDisplayTimeInMs : promoDisplayTimeInMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
