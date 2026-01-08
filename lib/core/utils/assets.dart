class AssetsData {
  static const logo = 'assets/images/1.png';
  // static const arabic = 'assets/images/arabic.jpg';
  static const profile = 'assets/images/profile.png';
  static const course = 'assets/images/Screenshot 2024-06-07 140828.png';
  static const pp = 'assets/images/photo_2024-08-05_13-54-10.jpg';
  static const video = 'assets/images/img_1.png';
  static const logoIcon = 'assets/images/logoIcon.png';
  //static const background = 'assets/images/image.png';
  static List<String> avatars = getAvatars();
}

List<String> getAvatars() {
  List<String> avatars = [];
  for (var i = 1; i <= 15; i++) {
    avatars.add('assets/images/avatar/$i.png');
  }
  return avatars;
}
