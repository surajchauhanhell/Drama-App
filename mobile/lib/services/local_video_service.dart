import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class LocalVideoService {
  
  Future<bool> hasPermission() async {
    // 1. Try PermissionHandler first (More reliable for status check)
    if (Platform.isAndroid) {
       // Android 13+ (SDK 33) uses READ_MEDIA_VIDEO
       // Lower versions use READ_EXTERNAL_STORAGE
       // We can check both or check based on SDK version, 
       // but checking 'videos' usually maps correctly on newer, 'storage' on older.
       
       final videos = await Permission.videos.status;
       final storage = await Permission.storage.status;
       final manage = await Permission.manageExternalStorage.status;

       if (videos.isGranted || storage.isGranted || manage.isGranted) {
         return true;
       }
       // Also check LIMITED (Android 14)
       if (videos.isLimited) {
         return true;
       }
    }

    // 2. Fallback to PhotoManager (which handles request flow)
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth; // isAuth includes authorized and limited
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  // Fetch all video albums (folders)
  Future<List<AssetPathEntity>> fetchVideoFolders() async {
    // If we are here, we likely have permission or want to try anyway.
    final PermissionState ps = await PhotoManager.requestPermissionExtend(); 
    
    // If denied strictly, return empty
    if (!ps.isAuth) {
        // Double check using permission_handler, 
        // sometimes PhotoManager returns false even if PermissionHandler says yes (rare edge case)
        if (Platform.isAndroid && (await Permission.videos.isGranted || await Permission.storage.isGranted)) {
           // If permission_handler says yes, we proceed. 
           // PhotoManager usually re-validates self.
        } else {
           return [];
        }
    }

    // Get strictly video albums
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      return paths;
    } catch (e) {
      // If error occurs despite permission, return empty.
      return [];
    }
  }

  // Fetch videos from a specific album
  Future<List<AssetEntity>> fetchVideosFromFolder(AssetPathEntity folder, {int start = 0, int end = 100}) async {
    return await folder.getAssetListRange(start: start, end: end);
  }

  Future<bool> deleteVideo(AssetEntity video) async {
    try {
      final List<String> result = await PhotoManager.editor.deleteWithIds([video.id]);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> renameVideo(AssetEntity video, String newName) async {
    final file = await video.file;
    if (file == null) return false;

    try {
      final String dir = file.parent.path;
      final String extension = file.path.split('.').last;
      final String newPath = '$dir/$newName.$extension';
      
      await file.rename(newPath);
      // Note: This rename is physical file rename. 
      // MediaStore might take a moment to reflect or might need a scan.
      // PhotoManager might need to refresh.
      return true;
    } catch (e) {
      print("Rename failed: $e");
      return false;
    }
  }
}
