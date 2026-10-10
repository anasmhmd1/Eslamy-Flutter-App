class TextUtils {
  static String removeDiacritics(String text) {
    const diacritics =
        '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656\u0657\u0658\u0659\u065A\u065B\u065C\u065D\u065E\u065F\u0670\u0671\u0610\u0611\u0612\u0613\u0614\u0615\u0616\u0617\u0618\u0619\u061A\u06D6\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4\u06E5\u06E6\u06E7\u06E8\u06EA\u06EB\u06EC\u06ED';

    String normalized = text;
    for (int i = 0; i < diacritics.length; i++) {
      normalized = normalized.replaceAll(diacritics[i], '');
    }

    // Normalize Alef
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Normalize Teh Marbuta
    normalized = normalized.replaceAll('ة', 'ه');
    // Normalize Yaa
    normalized = normalized.replaceAll('ى', 'ي');

    return normalized;
  }
}
