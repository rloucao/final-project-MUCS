class PlantDetail {
  final int id;
  final String? common_name;
  final String? scientific_name;
  final String? other_name;
  final String? family;
  final String? species_epithet;
  final String? genus;
  final String? origin; // aus JSON-Array-String ['...']
  final String? type;
  final String? cycle;
  final String? propagation;
  final int? hardiness_min;
  final int? hardiness_max;
  final String? watering;
  final String? sunlight;
  final String? pruning_month;
  final String? maintenance;
  final String? growth_rate;
  final bool? drought_tolerant;
  final bool? salt_tolerant;
  final bool? thorny;
  final bool? invasive;
  final bool? tropical;
  final String? care_level;
  final bool? flowers;
  final bool? cones;
  final bool? fruits;
  final bool? edible_fruit;
  final bool? cuisine;
  final bool? medicinal;
  final bool? poisonous_to_humans;
  final bool? poisonous_to_pets;
  final String? description;


  PlantDetail({
    required this.id,
    this.common_name,
    this.scientific_name,
    this.other_name,
    this.family,
    this.species_epithet,
    this.genus,
    this.origin,
    this.type,
    this.cycle,
    this.propagation,
    this.hardiness_min,
    this.hardiness_max,
    this.watering,
    this.sunlight,
    this.pruning_month,
    this.maintenance,
    this.growth_rate,
    this.drought_tolerant,
    this.salt_tolerant,
    this.thorny,
    this.invasive,
    this.tropical,
    this.care_level,
    this.flowers,
    this.cones,
    this.fruits,
    this.edible_fruit,
    this.cuisine,
    this.medicinal,
    this.poisonous_to_humans,
    this.poisonous_to_pets,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'common_name': common_name,
      'scientific_name': scientific_name,
      'other_name': other_name,
      'family': family,
      'species_epithet': species_epithet,
      'genus': genus,
      'origin': origin,
      'type': type,
      'cycle': cycle,
      'propagation': propagation,
      'hardiness_min': hardiness_min,
      'hardiness_max': hardiness_max,
      'watering': watering,
      'sunlight': sunlight,
      'pruning_month': pruning_month,
      'maintenance': maintenance,
      'growth_rate': growth_rate,
      'drought_tolerant': drought_tolerant,
      'salt_tolerant': salt_tolerant,
      'thorny': thorny,
      'invasive': invasive,
      'tropical': tropical,
      'care_level': care_level,
      'flowers': flowers,
      'cones': cones,
      'fruits': fruits,
      'edible_fruit': edible_fruit,
      'cuisine': cuisine,
      'medicinal': medicinal,
      'poisonous_to_humans': poisonous_to_humans,
      'poisonous_to_pets': poisonous_to_pets,
      'description': description
    };
  }

  factory PlantDetail.fromJson(Map<String, dynamic> json) {
    return PlantDetail(
      id: json['id'],
      common_name: json['common_name'],
      scientific_name: json['scientific_name'],
      other_name: json['other_name'],
      family: json['family'],
      species_epithet: json['species_epithet'],
      genus: json['genus'],
      origin: json['origin'],
      type: json['type'],
      cycle: json['cycle'],
      propagation: json['propagation'],
      hardiness_min: json['hardiness_min'],
      hardiness_max: json['hardiness_max'],
      watering: json['watering'],
      sunlight: json['sunlight'],
      pruning_month: json['pruning_month'],
      maintenance: json['maintenance'],
      growth_rate: json['growth_rate'],
      drought_tolerant: json['drought_tolerant'],
      salt_tolerant: json['salt_tolerant'],
      thorny: json['thorny'],
      invasive: json['invasive'],
      tropical: json['tropical'],
      care_level: json['care_level'],
      flowers: json['flowers'],
      cones: json['cones'],
      fruits: json['fruits'],
      edible_fruit: json['edible_fruit'],
      cuisine: json['cuisine'],
      medicinal: json['medicinal'],
      poisonous_to_humans: json['poisonous_to_humans'],
      poisonous_to_pets: json['poisonous_to_pets'],
      description: json['description']
    );
  }
}