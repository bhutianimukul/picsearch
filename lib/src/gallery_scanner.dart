import 'package:photo_manager/photo_manager.dart';

/// Lists gallery images (preferring the Screenshots album) so we can detect
/// which screenshots haven't been read into the vault yet.
class GalleryScanner {
  Future<bool> ensurePermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  Future<List<AssetEntity>> screenshots({int limit = 300}) async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return const [];
    final album = albums.firstWhere(
      (a) => a.name.toLowerCase() == 'screenshots',
      orElse: () => albums.firstWhere((a) => a.isAll, orElse: () => albums.first),
    );
    final count = await album.assetCountAsync;
    return album.getAssetListRange(start: 0, end: count < limit ? count : limit);
  }
}
