part of media_picker_widget;

///The MediaPicker widget that will select media files form storage
class MediaPicker extends StatefulWidget {
  ///The MediaPicker constructor that will select media files form storage
  MediaPicker({
    required this.onPick,
    required this.mediaList,
    required this.onCancel,
    this.mediaCount = MediaCount.multiple,
    this.mediaType = MediaType.all,
    this.decoration,
    this.scrollController,
    this.customWidgets,
    this.getAlbumName,
  });

  ///CallBack on image pick is done
  final ValueChanged<List<Media>> onPick;

  ///Previously selected list of media in your app
  final List<Media> mediaList;

  ///Callback on cancel the picking action
  final VoidCallback onCancel;

  ///make picker to select multiple or single media file
  final MediaCount mediaCount;

  ///Make picker to select specific type of media, video or image
  final MediaType mediaType;

  ///decorate the UI of picker
  final PickerDecoration? decoration;

  ///assign a scroll controller to Media GridView of Picker
  final ScrollController? scrollController;

  ///Custom widgets to add to the grid
  final List<Widget>? customWidgets;

  final String Function(String)? getAlbumName;

  @override
  _MediaPickerState createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  PickerDecoration? _decoration;

  AlbumEntity? _selectedAlbum;
  List<AlbumEntity>? _albums;

  final PanelController _albumController = PanelController();
  final HeaderController _headerController = HeaderController();

  @override
  void initState() {
    _fetchAlbums();
    _decoration = widget.decoration ?? PickerDecoration();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _albums == null
          ? LoadingWidget(
              decoration: widget.decoration!,
            )
          : _albums!.length == 0
              ? (_decoration?.noMediaWidget ?? NoMedia())
              : Column(
                  children: [
                    if (_decoration!.actionBarPosition == ActionBarPosition.top)
                      _buildHeader(),
                    Expanded(
                        child: Stack(
                      children: [
                        Positioned.fill(
                          child: MediaList(
                            album: _selectedAlbum!,
                            headerController: _headerController,
                            previousList: widget.mediaList,
                            mediaCount: widget.mediaCount,
                            decoration: widget.decoration,
                            scrollController: widget.scrollController,
                            customWidgets: widget.customWidgets,
                          ),
                        ),
                        AlbumSelector(
                          panelController: _albumController,
                          albums: _albums!,
                          decoration: widget.decoration!,
                          onSelect: (album) {
                            _headerController.closeAlbumDrawer!();
                            setState(() => _selectedAlbum = album);
                          },
                          getAlbumName: widget.getAlbumName
                        ),
                      ],
                    )),
                    if (_decoration!.actionBarPosition ==
                        ActionBarPosition.bottom)
                      _buildHeader(),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Header(
      onBack: handleBackPress,
      onDone: widget.onPick,
      albumController: _albumController,
      selectedAlbum: _selectedAlbum!,
      controller: _headerController,
      mediaCount: widget.mediaCount,
      decoration: _decoration,
      getAlbumName: widget.getAlbumName,
    );
  }

  _fetchAlbums() async {
    RequestType type = RequestType.common;
    if (widget.mediaType == MediaType.all)
      type = RequestType.common;
    else if (widget.mediaType == MediaType.video)
      type = RequestType.video;
    else if (widget.mediaType == MediaType.image)
      type = RequestType.image;

    PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.authorized ||
        result == PermissionState.limited) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: type);
      List<AlbumEntity> albumsConvert = [];
      for (var item in albums) {
        final assetCount = await item.assetCountAsync;
        if (assetCount > 0) {
          albumsConvert.add(AlbumEntity(entity: item, assetCount: assetCount,));
        }
      }
      setState(() {
        _albums = albumsConvert;
        if (albumsConvert.isNotEmpty) {
          _selectedAlbum = _albums![0];
        }
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  void handleBackPress() {
    if (_albumController.isPanelOpen)
      _albumController.close();
    else
      widget.onCancel();
  }
}
