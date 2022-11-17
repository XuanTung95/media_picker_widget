import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import 'album_entity.dart';
import 'header_controller.dart';
import 'widgets/media_tile.dart';

class MediaList extends StatefulWidget {
  MediaList({
    required this.album,
    required this.headerController,
    required this.previousList,
    this.mediaCount,
    this.decoration,
    this.scrollController,
    this.customWidgets,
  });

  final AlbumEntity album;
  final HeaderController headerController;
  final List<Media> previousList;
  final MediaCount? mediaCount;
  final PickerDecoration? decoration;
  final ScrollController? scrollController;
  final List<Widget>? customWidgets;

  @override
  _MediaListState createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  List<Widget> _mediaList = [];
  int currentPage = 0;
  int? lastPage;
  bool loadedAll = false;
  bool loadingAssets = false;
  AlbumEntity? album;

  List<Media> selectedMedias = [];

  @override
  void initState() {
    album = widget.album;
    if (widget.mediaCount == MediaCount.multiple) {
      selectedMedias.addAll(widget.previousList);
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.headerController.updateSelection!(selectedMedias));
    }
    _fetchNewMedia();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetAlbum();
  }

  @override
  Widget build(BuildContext context) {
    final customLength = (widget.customWidgets?.length ?? 0);
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        _handleScrollEvent(scroll);
        return true;
      },
      child: GridView.builder(
        controller: widget.scrollController,
        itemCount: _mediaList.length + customLength,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.decoration!.columnCount),
        itemBuilder: (BuildContext context, int index) {
          if (index < customLength) {
            return widget.customWidgets![index];
          }
          return _mediaList[index - customLength];
        },
      ),
    );
  }

  _resetAlbum() {
    if (album != null) {
      if (album!.id != widget.album.id) {
        _mediaList.clear();
        album = widget.album;
        currentPage = 0;
        loadedAll = false;
        _fetchNewMedia();
      }
    }
  }

  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  _fetchNewMedia() async {
    if (loadingAssets || loadedAll) {
      return;
    }
    loadingAssets = true;
    lastPage = currentPage;
    PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.authorized ||
        result == PermissionState.limited) {
      List<AssetEntity> media =
          await album!.entity.getAssetListPaged(page: currentPage, size: 60);
      List<Widget> temp = [];

      for (var asset in media) {
        temp.add(MediaTile(
          key: ValueKey(asset.id),
          media: asset,
          onSelected: (isSelected, media) {
            if (isSelected)
              setState(() => selectedMedias.add(media));
            else
              setState(() => selectedMedias
                  .removeWhere((_media) => _media.id == media.id));
            widget.headerController.updateSelection!(selectedMedias);
          },
          isSelected: isPreviouslySelected(asset),
          decoration: widget.decoration,
        ));
      }

      setState(() {
        _mediaList.addAll(temp);
        loadedAll = media.isEmpty;
        currentPage++;
      });
    } else {
      PhotoManager.openSetting();
    }
    loadingAssets = false;
  }

  bool isPreviouslySelected(AssetEntity media) {
    bool isSelected = false;
    for (var asset in selectedMedias) {
      if (asset.id == media.id) isSelected = true;
    }
    return isSelected;
  }
}
