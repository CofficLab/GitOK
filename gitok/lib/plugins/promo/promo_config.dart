class PromoConfig {
  final String name;
  final String backgroundImage;
  final List<PromoElement> elements;
  final DateTime lastModified;

  PromoConfig({
    required this.name,
    required this.backgroundImage,
    required this.elements,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'backgroundImage': backgroundImage,
      'elements': elements.map((e) => e.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory PromoConfig.fromJson(Map<String, dynamic> json) {
    return PromoConfig(
      name: json['name'],
      backgroundImage: json['backgroundImage'],
      elements: (json['elements'] as List).map((e) => PromoElement.fromJson(e)).toList(),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}

class PromoElement {
  final String type; // 'text', 'image', 'shape'
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Map<String, dynamic> properties;

  PromoElement({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    required this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'properties': properties,
    };
  }

  factory PromoElement.fromJson(Map<String, dynamic> json) {
    return PromoElement(
      type: json['type'],
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      rotation: json['rotation'] ?? 0,
      properties: json['properties'],
    );
  }
}
