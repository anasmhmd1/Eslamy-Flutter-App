class Reciter {
  final String id;
  final String name;
  final String serverUrl; // Base URL for audio files

  const Reciter({
    required this.id,
    required this.name,
    required this.serverUrl,
  });
}

class ReciterRepository {
  static const List<Reciter> reciters = [
    Reciter(
      id: 'mishary',
      name: 'مشاري راشد العفاسي',
      serverUrl: 'https://server8.mp3quran.net/afs',
    ),
    Reciter(
      id: 'abdulbasit_mujawwad',
      name: 'عبد الباسط عبد الصمد (مجود)',
      serverUrl: 'https://server7.mp3quran.net/basit',
    ),
    Reciter(
      id: 'abdulbasit_murattal',
      name: 'عبد الباسط عبد الصمد (مرتل)',
      serverUrl: 'https://server11.mp3quran.net/a_bast',
    ),
    Reciter(
      id: 'sudais',
      name: 'عبد الرحمن السديس',
      serverUrl: 'https://server11.mp3quran.net/sds',
    ),
    Reciter(
      id: 'shuraim',
      name: 'سعود الشريم',
      serverUrl: 'https://server7.mp3quran.net/shur',
    ),
    Reciter(
      id: 'maher',
      name: 'ماهر المعيقلي',
      serverUrl: 'https://server12.mp3quran.net/maher',
    ),
    Reciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      serverUrl: 'https://server13.mp3quran.net/husr',
    ),
    Reciter(
      id: 'husary_mujawwad',
      name: 'محمود خليل الحصري (مجود)',
      serverUrl: 'https://server13.mp3quran.net/husa',
    ),
    Reciter(
      id: 'minshawi_mujawwad',
      name: 'محمد صديق المنشاوي (مجود)',
      serverUrl: 'https://server10.mp3quran.net/minsh',
    ),
    Reciter(
      id: 'minshawi_murattal',
      name: 'محمد صديق المنشاوي (مرتل)',
      serverUrl: 'https://server6.mp3quran.net/minsh',
    ),
    Reciter(
      id: 'ghamdi',
      name: 'سعد الغامدي',
      serverUrl: 'https://server7.mp3quran.net/s_gmd',
    ),
    Reciter(
      id: 'ajmi',
      name: 'أحمد بن علي العجمي',
      serverUrl: 'https://server10.mp3quran.net/ajm',
    ),
    Reciter(
      id: 'fares',
      name: 'فارس عباد',
      serverUrl: 'https://server8.mp3quran.net/frs_a',
    ),
    Reciter(
      id: 'basfar',
      name: 'عبد الله بصفر',
      serverUrl: 'https://server9.mp3quran.net/basfr',
    ),
    Reciter(
      id: 'banna',
      name: 'محمود علي البنا',
      serverUrl: 'https://server8.mp3quran.net/bna',
    ),
    Reciter(
      id: 'hudhaify',
      name: 'علي بن عبد الرحمن الحذيفي',
      serverUrl: 'https://server11.mp3quran.net/hthfi',
    ),
    Reciter(
      id: 'tablawi',
      name: 'محمد الطبلاوي',
      serverUrl: 'https://server12.mp3quran.net/tblawi',
    ),
    Reciter(
      id: 'dosari',
      name: 'ياسر الدوسري',
      serverUrl: 'https://server11.mp3quran.net/yasser',
    ),
    Reciter(
      id: 'juhany',
      name: 'عبد الله الجهني',
      serverUrl: 'https://server7.mp3quran.net/a_jhn',
    ),
    Reciter(
      id: 'bukhatir',
      name: 'أحمد بن علي البخاطر',
      serverUrl: 'https://server8.mp3quran.net/bukh',
    ),
    Reciter(
      id: 'qatami',
      name: 'ناصر القطامي',
      serverUrl: 'https://server6.mp3quran.net/qtm',
    ),
  ];

  static Reciter getReciterById(String id) {
    return reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
  }
}
