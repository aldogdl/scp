import 'package:fuzzywuzzy/model/extracted_result.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class PzaSimil {

  static ExtractedResult? esTo(String pza, List<String> pool) {

    // final rating = pza.bestMatch(pool);
    try {
      
      final rating = extractOne( query: pza, choices: pool, cutoff: 60 );
      return rating;
      
    } catch (_) {}

    return null;
  }
}