part of media_picker_widget;

///This class will contain the necessary data of selected media
class Media {
  ///Unique id to identify
  String get id => assetEntity.id;

  ///A low resolution image to show as preview
  Uint8List? thumbnail;

  ///Type of the media, Image/Video
  final MediaType mediaType;

  ///The abstraction of assets (images/videos/audios).
  final AssetEntity assetEntity;

  Media({
    required this.assetEntity,
    required this.mediaType,
    this.thumbnail,
  });
}
