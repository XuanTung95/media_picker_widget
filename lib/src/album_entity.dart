import 'package:photo_manager/photo_manager.dart';

class AlbumEntity {
  final AssetPathEntity entity;
  final int assetCount;
  String get id => entity.id;

  AlbumEntity({required this.entity, required this.assetCount});
}