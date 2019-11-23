import 'dart:typed_data';

class BMP332Header {
  int _width;
  int _height;

  Uint8List _bmp;
  int _totalHeaderSize;

  BMP332Header(this._width, this._height) : assert(_width & 3 == 0) {
    int baseHeaderSize = 54;
    _totalHeaderSize = baseHeaderSize /* + 1024*/; // base + color map
    int fileLength = _totalHeaderSize + _width * _height * 3; // header + bitmap
    _bmp = new Uint8List(fileLength);
    ByteData bd = _bmp.buffer.asByteData();
    bd.setUint8(0, 0x42);
    bd.setUint8(1, 0x4d);
    bd.setUint32(2, fileLength, Endian.little); // file length
    bd.setUint32(10, _totalHeaderSize, Endian.little); // start of the bitmap
    bd.setUint32(14, 40, Endian.little); // info header size
    bd.setUint32(18, _width, Endian.little);
    bd.setUint32(22, _height, Endian.little);
    bd.setUint16(26, 1, Endian.little); // planes
    bd.setUint32(28, 24, Endian.little); // bpp
    bd.setUint32(30, 0, Endian.little); // compression
    bd.setUint32(34, _width * _height * 3, Endian.little); // bitmap size
  }

  /// Insert the provided bitmap after the header and return the whole BMP
  Uint8List appendBitmap(Uint8List bitmap) {
    int size = _width * _height * 3;
    assert(bitmap.length == size);
    _bmp.setRange(_totalHeaderSize, _totalHeaderSize + size, bitmap);
    return _bmp;
  }
}
