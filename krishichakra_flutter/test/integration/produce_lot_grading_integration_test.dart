import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/api/api_endpoints.dart';

void main() {
  group('ProduceBoundingMarker', () {
    test('fromJson deserializes correctly', () {
      final json = {'label': '52mm • Grade A', 'conf': 0.994, 'x': 0.2, 'y': 0.3};
      final marker = ProduceBoundingMarker.fromJson(json);
      expect(marker.label, '52mm • Grade A');
      expect(marker.conf, closeTo(0.994, 0.0001));
      expect(marker.x, closeTo(0.2, 0.0001));
      expect(marker.y, closeTo(0.3, 0.0001));
    });

    test('fromJson handles missing fields gracefully', () {
      final marker = ProduceBoundingMarker.fromJson({});
      expect(marker.label, '');
      expect(marker.conf, 0.0);
    });
  });

  group('ProduceGradeResult', () {
    test('fromJson deserializes integration boundary prototype response', () {
      final json = {
        'status': 'integration_boundary_prototype',
        'crop': 'onion',
        'grade': 'A',
        'quality_score': 0.88,
        'uniformity_pct': 88.0,
        'moisture_pct': 12.0,
        'pest_damage_pct': 0.0,
        'detected_markers': [
          {'label': '52mm • Grade A', 'conf': 0.994, 'x': 0.2, 'y': 0.2},
          {'label': '55mm • Grade A', 'conf': 0.989, 'x': 0.6, 'y': 0.3},
        ],
        'has_image': false,
        'is_certified': false,
        'assessment_type': 'Automated Inspection Prototype (Integration Boundary)',
        'disclaimer': 'Integration boundary prototype. Not an AI certified result.',
        'message': 'Replace with trained YOLO/PyTorch/OpenCV pipeline.',
      };

      final result = ProduceGradeResult.fromJson(json);

      expect(result.status, 'integration_boundary_prototype');
      expect(result.crop, 'onion');
      expect(result.grade, 'A');
      expect(result.qualityScore, closeTo(0.88, 0.0001));
      expect(result.uniformityPct, closeTo(88.0, 0.01));
      expect(result.moisturePct, closeTo(12.0, 0.01));
      expect(result.pestDamagePct, closeTo(0.0, 0.01));
      expect(result.detectedMarkers.length, 2);
      expect(result.detectedMarkers[0].label, '52mm • Grade A');
      expect(result.hasImage, false);

      // CRITICAL: is_certified must always be false for the integration boundary
      expect(result.isCertified, false);
      expect(result.isPrototype, true);
    });

    test('isCertified is false and isPrototype is true', () {
      // This test explicitly verifies the integration boundary contract.
      // A failing test here means someone incorrectly made the prototype claim AI certified.
      final result = ProduceGradeResult.fromJson({
        'status': 'integration_boundary_prototype',
        'crop': 'tomato',
        'is_certified': false,
        'assessment_type': 'Automated Inspection Prototype',
        'disclaimer': 'Prototype',
        'message': 'Not certified',
      });
      expect(result.isCertified, false,
          reason: 'Integration boundary must never be AI certified');
      expect(result.isPrototype, true);
    });

    test('fromJson handles unsupported crop model_not_available response', () {
      final json = {
        'status': 'model_not_available',
        'crop': 'jackfruit',
        'grade': null,
        'quality_score': null,
        'uniformity_pct': null,
        'moisture_pct': null,
        'pest_damage_pct': null,
        'detected_markers': [],
        'has_image': false,
        'is_certified': false,
        'assessment_type': 'None',
        'disclaimer': 'Crop not supported.',
        'message': 'No trained model for this crop.',
      };
      final result = ProduceGradeResult.fromJson(json);
      expect(result.status, 'model_not_available');
      expect(result.grade, null);
      expect(result.isCertified, false);
      expect(result.detectedMarkers, isEmpty);
    });
  });

  group('ApiEndpoints', () {
    test('produceGrade endpoint is correct', () {
      expect(ApiEndpoints.produceGrade, '/api/produce/grade');
    });

    test('produceLots endpoint is correct', () {
      expect(ApiEndpoints.produceLots, '/api/produce/lots');
    });

    test('farmerProduceLots generates correct URL', () {
      expect(ApiEndpoints.farmerProduceLots(42), '/api/produce/lots/42');
    });
  });
}
