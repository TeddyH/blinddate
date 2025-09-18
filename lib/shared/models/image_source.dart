import 'dart:io';

abstract class ProfileImageSource {
  const ProfileImageSource();
}

class FileImageSource extends ProfileImageSource {
  final File file;

  const FileImageSource(this.file);
}

class NetworkImageSource extends ProfileImageSource {
  final String url;

  const NetworkImageSource(this.url);
}