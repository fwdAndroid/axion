import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File?> compressVideo(File inputFile) async {
  try {
    final appDir = await getTemporaryDirectory();
    final outputPath = p.join(
      appDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    final command =
        '-i "${inputFile.path}" '
        '-vcodec libx264 '
        '-profile:v baseline '
        '-level 3.0 '
        '-preset veryfast '
        '-crf 23 '
        '-acodec aac '
        '-movflags +faststart '
        '"$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (returnCode?.isValueSuccess() == true) {
      print('✅ Compression successful: $outputPath');
      return File(outputPath);
    } else {
      final logs = await session.getAllLogsAsString();
      print('❌ FFmpeg error:\n$logs');
      return null;
    }
  } catch (e) {
    print("❌ Compression exception: $e");
    return null;
  }
}
