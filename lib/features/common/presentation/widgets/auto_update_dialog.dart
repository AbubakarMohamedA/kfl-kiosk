import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_installer/app_installer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sss/core/models/update_info.dart';
import 'package:sss/core/services/platform_service.dart';

/// Update Status Enum
enum UpdateStatus {
  initial,
  requestingPermission,
  downloading,
  installing,
  completed,
  error,
  permissionDenied,
}

/// Auto Update Dialog Widget with download and install progress
class AutoUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdateComplete;
  final VoidCallback? onSkip;

  const AutoUpdateDialog({
    super.key,
    required this.updateInfo,
    this.onUpdateComplete,
    this.onSkip,
  });

  @override
  State<AutoUpdateDialog> createState() => _AutoUpdateDialogState();
}

class _AutoUpdateDialogState extends State<AutoUpdateDialog> {
  UpdateStatus _status = UpdateStatus.initial;
  double _downloadProgress = 0.0;
  String _downloadedSize = '0 MB';
  String _totalSize = '0 MB';
  String _errorMessage = '';
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    try {
      if (PlatformService.isAndroid) {
        setState(() {
          _status = UpdateStatus.requestingPermission;
        });

        final permissionGranted = await _requestStoragePermission();
        if (!permissionGranted) {
          setState(() {
            _status = UpdateStatus.permissionDenied;
            _errorMessage = 'Storage permission is required to download updates';
          });
          return;
        }
      }

      setState(() {
        _status = UpdateStatus.downloading;
        _downloadProgress = 0.0;
      });

      final filePath = await _downloadUpdate(widget.updateInfo.updateUrl ?? '');

      if (filePath == null) {
        setState(() {
          _status = UpdateStatus.error;
          _errorMessage = 'Failed to download update';
        });
        return;
      }

      setState(() {
        _status = UpdateStatus.installing;
      });

      await _installUpdate(filePath);

      setState(() {
        _status = UpdateStatus.completed;
      });

      widget.onUpdateComplete?.call();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = UpdateStatus.error;
        _errorMessage = 'Update failed: ${e.toString()}';
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // For Android 13+ (SDK 33), we mostly need Install Packages permission for APKs
      if (sdkInt >= 33) {
        final installPermission = await Permission.requestInstallPackages.request();
        return installPermission.isGranted;
      } else if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          final installPermission = await Permission.requestInstallPackages.request();
          return installPermission.isGranted;
        }
        return false;
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final installPermission = await Permission.requestInstallPackages.request();
          return installPermission.isGranted;
        }
        return false;
      }
    }
    return true;
  }

  Future<String?> _downloadUpdate(String url) async {
    try {
      final dio = Dio();
      _cancelToken = CancelToken();

      final Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getTemporaryDirectory();
      }

      if (directory == null) {
        throw Exception('Cannot access storage');
      }

      final fileName = _getFileName();
      final downloadsPath = '${directory.path}/updates';
      final downloadsDir = Directory(downloadsPath);
      
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '$downloadsPath/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await dio.download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
              _downloadedSize = _formatBytes(received);
              _totalSize = _formatBytes(total);
            });
          }
        },
      );

      return filePath;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return null;
      }
      rethrow;
    }
  }

  String _getFileName() {
    final version = widget.updateInfo.latestVersion;
    if (PlatformService.isWindows) return 'update_$version.exe';
    if (PlatformService.isLinux) return 'update_$version.AppImage';
    if (PlatformService.isMacOS) return 'update_$version.dmg';
    if (PlatformService.isIOS) return 'update_$version.ipa';
    if (PlatformService.isAndroid) return 'update_$version.apk';
    return 'update_$version.zip';
  }

  Future<void> _installUpdate(String filePath) async {
    try {
      if (PlatformService.isAndroid) {
        await AppInstaller.installApk(filePath);
      } else if (PlatformService.isWindows || PlatformService.isLinux) {
        if (PlatformService.isLinux) {
          await Process.run('chmod', ['+x', filePath]);
        }
        await Process.start(filePath, [], mode: ProcessStartMode.detached);
        exit(0);
      } else if (PlatformService.isMacOS) {
        await Process.run('open', [filePath]);
      } else {
        throw Exception('Unsupported platform for automatic installation');
      }
    } catch (e) {
      throw Exception('Installation failed: ${e.toString()}');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _cancelUpdate() {
    _cancelToken?.cancel();
    widget.onSkip?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = widget.updateInfo.isMandatory;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isMandatory && _status != UpdateStatus.downloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildContent(theme),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (_status) {
      case UpdateStatus.initial:
        icon = Icons.system_update_alt;
        color = Colors.blue;
        break;
      case UpdateStatus.requestingPermission:
        icon = Icons.lock_open;
        color = Colors.orange;
        break;
      case UpdateStatus.downloading:
        icon = Icons.download;
        color = Colors.blue;
        break;
      case UpdateStatus.installing:
        icon = Icons.install_mobile;
        color = Colors.green;
        break;
      case UpdateStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case UpdateStatus.error:
      case UpdateStatus.permissionDenied:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
        color: color.withValues(alpha: 0.1),
      child: Icon(icon, size: 48, color: color),
    );
  }

  Widget _buildTitle() {
    String title;

    switch (_status) {
      case UpdateStatus.initial:
        title = 'Update Available';
        break;
      case UpdateStatus.requestingPermission:
        title = 'Requesting Permission';
        break;
      case UpdateStatus.downloading:
        title = 'Downloading Update';
        break;
      case UpdateStatus.installing:
        title = 'Installing Update';
        break;
      case UpdateStatus.completed:
        title = 'Update Completed';
        break;
      case UpdateStatus.error:
        title = 'Update Failed';
        break;
      case UpdateStatus.permissionDenied:
        title = 'Permission Required';
        break;
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_status) {
      case UpdateStatus.initial:
        return Column(
          children: [
            Text(
              'A new version (${widget.updateInfo.latestVersion}) is available. Current version: ${widget.updateInfo.currentVersion}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updateInfo.releaseNotes,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Update will download and install automatically',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case UpdateStatus.requestingPermission:
        return Column(
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Please grant permissions to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        );

      case UpdateStatus.downloading:
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_downloadedSize / $_totalSize',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we download the update...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        );

      case UpdateStatus.installing:
        return Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 6, color: theme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Opening installer...',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please complete the installation when prompted',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        );

      case UpdateStatus.completed:
        return Column(
          children: [
            Icon(Icons.celebration, size: 60, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'Download complete! Installation opened.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        );

      case UpdateStatus.error:
      case UpdateStatus.permissionDenied:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActions() {
    final isMandatory = widget.updateInfo.isMandatory;
    
    switch (_status) {
      case UpdateStatus.initial:
        return Row(
          children: [
            if (!isMandatory)
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelUpdate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Later'),
                ),
              ),
            if (!isMandatory) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _startUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Update Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );

      case UpdateStatus.downloading:
        if (!isMandatory) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelUpdate,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Download'),
            ),
          );
        }
        return const SizedBox.shrink();

      case UpdateStatus.error:
      case UpdateStatus.permissionDenied:
        return Row(
          children: [
            if (!isMandatory)
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelUpdate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            if (!isMandatory) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _startUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );

      case UpdateStatus.completed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onUpdateComplete?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
