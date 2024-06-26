import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../media_picker_widget.dart';
import 'album_entity.dart';
import 'widgets/loading_widget.dart';

class AlbumSelector extends StatefulWidget {
  AlbumSelector(
      {required this.onSelect,
      required this.albums,
      required this.panelController,
      required this.getAlbumName,
      required this.decoration});

  final ValueChanged<AlbumEntity> onSelect;
  final List<AlbumEntity> albums;
  final PanelController panelController;
  final PickerDecoration decoration;
  final String Function(String)? getAlbumName;

  @override
  _AlbumSelectorState createState() => _AlbumSelectorState();
}

class _AlbumSelectorState extends State<AlbumSelector> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return SlidingUpPanel(
        controller: widget.panelController,
        minHeight: 0,
        color: Theme.of(context).canvasColor,
        boxShadow: [],
        isDraggable: false, // TODO: fix bug
        maxHeight: constrains.maxHeight,
        panelBuilder: (sc) {
          return ListView(
            controller: sc,
            children: List<Widget>.generate(
              widget.albums.length,
              (index) => AlbumTile(
                album: widget.albums[index],
                onSelect: () => widget.onSelect(widget.albums[index]),
                decoration: widget.decoration,
                getAlbumName: widget.getAlbumName,
              ),
            ),
          );
        },
      );
    });
  }
}

class AlbumTile extends StatefulWidget {
  AlbumTile(
      {required this.album, required this.onSelect, required this.decoration, this.getAlbumName});

  final AlbumEntity album;
  final VoidCallback onSelect;
  final PickerDecoration decoration;
  final String Function(String)? getAlbumName;

  @override
  _AlbumTileState createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile> {
  Uint8List? albumThumb;
  bool hasError = false;
  int? assetCount;

  @override
  void initState() {
    super.initState();
    _getAlbumThumb(widget.album.entity);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onSelect,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                width: 80,
                height: 80,
                child: !hasError
                    ? albumThumb != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              albumThumb!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : LoadingWidget(
                            decoration: widget.decoration,
                          )
                    : Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                widget.getAlbumName == null ? widget.album.entity.name : widget.getAlbumName!.call(widget.album.entity.name),
                style: widget.decoration.albumTextStyle ??
                    TextStyle(color: Colors.black, fontSize: 18),
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                '${assetCount ?? widget.album.assetCount}',
                style: widget.decoration.albumCountTextStyle ??
                    TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getAlbumThumb(AssetPathEntity album) async {
    List<AssetEntity> media = await album.getAssetListPaged(page: 0, size: 1);
    if (media.isEmpty) {
      return;
    }
    Uint8List? _thumbByte =
        await media[0].thumbnailDataWithSize(ThumbnailSize(80, 80));
    if (_thumbByte != null)
      setState(() => albumThumb = _thumbByte);
    else
      setState(() => hasError = true);
  }
}
