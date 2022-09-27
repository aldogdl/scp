import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';

class PzaSimyl {

  ///
  static ExtractedResult? esTo(String pza, List<String> pool) {

    // final rating = pza.bestMatch(pool);
    try {
      
      final rating = extractOne( query: pza, choices: pool, cutoff: 60 );
      return rating;
      
    } catch (_) {}

    return null;
  }
}