class ScmEntity {

	int id = 0;
	int campaingId = 0;
	int remiterId = 0;
	int emiterId = 0;
	Map<String, dynamic> target = {};
	Map<String, dynamic> src = {};
	DateTime createdAt = DateTime.now();
  String sendAt = 'now';
	String slugCamp = '0';

  ///
  Map<String, dynamic> toJson() {

    return {
      'id': id,
      'camp': campaingId,
      'own': emiterId,
      'avo': remiterId,
      'target': target,
      'src': src,
      'slug_camp': slugCamp,
      'sendAt': sendAt
    };
  }

}