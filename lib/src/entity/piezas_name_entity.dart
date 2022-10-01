class PiezasNameEntity {

  int id = 0;
  String value = '';
  Map<String, String> simyls = {};

  ///
  void fromJson(Map<String, dynamic> pza) {

    id = pza['id'];
    value = pza['value'];
    simyls = Map<String, String>.from(pza['simyls']);
  }

  ///
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'simyls': simyls
    };
  }
}