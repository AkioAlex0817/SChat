import 'dart:typed_data';
import 'package:image/image.dart' as imglib;

import 'package:camera/camera.dart';
import 'package:schat/Helper/Constants.dart';

import 'BMP332Header.dart';

class Helper{
  static bool overFileSize(int size){
    double filesizeInKB = size / 1024;
    double fileMB = filesizeInKB / 1024;
    return fileMB > Constants.MAX_FILE_SIZE_MB;
  }

  static String parseFileName(String path){
    return path.substring(path.lastIndexOf("/") + 1);
  }


}

Future<Uint8List> convertImageAndroid(CameraImage image) async {
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;
    const int shift = (0xFF << 24);
    var img = imglib.Image(width, height); // Create Image buffer

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }

    img = imglib.copyRotate(img, -90);
    return imglib.encodePng(img);
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}

Future<Uint8List> convertImageIOS(CameraImage image) async {
  try {
    final int width = image.width;
    final int height = image.height;
    Uint8List lists = image.planes[0].bytes;
    Uint8List bmp = new Uint8List(width * height * 3);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int in_idx = (x + (height - y - 1) * width) * 4;
        int out_idx = (x + y * width) * 3;

        for (int c = 0; c < 3; c++) {
          bmp[out_idx + c] = lists[in_idx + c]; //pixel.toInt();
        }
      }
    }
    BMP332Header header = BMP332Header(image.width, image.height);
    Uint8List result = header.appendBitmap(bmp);
    return result;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}
