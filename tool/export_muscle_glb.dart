// Offline exporter: turns the procedural muscle mesh into a real glTF 2.0
// binary (assets/models/muscle.glb) with one material per muscle group, plus a
// generated Dart file listing the material order so the runtime can recolor
// each muscle by index. Run with:
//
//   flutter test tool/export_muscle_glb.dart
//
// It is a test only so the Flutter libraries muscle_body.dart imports are
// available; it asserts nothing beyond "the file was written".
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:apex_lifter_mobile/widgets/muscle_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export muscle.glb + material manifest', () {
    final mesh = MuscleBodyPainter.exportMesh();
    final nVerts = mesh.positions.length ~/ 3;

    // ── Transform design space → glTF space ────────────────────────────────
    // Design space: x 0..200, y grows downward, z small. glTF is Y-up and
    // metres-ish, so centre on the origin, flip Y, and scale to ~2 units tall.
    const sc = 2.0 / 440.0;
    final gPos = Float32List(nVerts * 3);
    final gNrm = Float32List(nVerts * 3);
    for (var i = 0; i < nVerts; i++) {
      gPos[i * 3] = (mesh.positions[i * 3] - 100) * sc;
      gPos[i * 3 + 1] = -(mesh.positions[i * 3 + 1] - 220) * sc;
      gPos[i * 3 + 2] = mesh.positions[i * 3 + 2] * sc;
      gNrm[i * 3] = mesh.normals[i * 3];
      gNrm[i * 3 + 1] = -mesh.normals[i * 3 + 1];
      gNrm[i * 3 + 2] = mesh.normals[i * 3 + 2];
    }

    // ── Material table: 0 = skin, then one per muscle-group set ────────────
    // Order is deterministic (the exporter emits a matching Dart manifest), so
    // the runtime can recolor by material index without relying on names.
    final groupNames = mesh.groupNames; // index g → material g+1
    final materialCount = groupNames.length + 1;

    // Assign each triangle to a material: the most common non-skin set among
    // its three vertices, else skin. Muscle bellies stay coherent this way.
    final byMaterial = List.generate(materialCount, (_) => <int>[]);
    final tris = mesh.triangles;
    for (var f = 0; f < tris.length; f += 3) {
      final a = mesh.groupOfVertex[tris[f]];
      final b = mesh.groupOfVertex[tris[f + 1]];
      final c = mesh.groupOfVertex[tris[f + 2]];
      int mat;
      if (a >= 0 && (a == b || a == c)) {
        mat = a + 1;
      } else if (b >= 0 && b == c) {
        mat = b + 1;
      } else {
        final pick = a >= 0 ? a : (b >= 0 ? b : c);
        mat = pick >= 0 ? pick + 1 : 0;
      }
      byMaterial[mat]
        ..add(tris[f])
        ..add(tris[f + 1])
        ..add(tris[f + 2]);
    }

    // ── Binary buffer: positions, normals, then per-material index blocks ──
    final bin = BytesBuilder();
    int align4(int len) => (4 - (len % 4)) % 4;

    final posBytes = gPos.buffer.asUint8List();
    final nrmBytes = gNrm.buffer.asUint8List();
    bin.add(posBytes);
    bin.add(nrmBytes);

    final bufferViews = <Map<String, dynamic>>[
      {'buffer': 0, 'byteOffset': 0, 'byteLength': posBytes.length, 'target': 34962},
      {'buffer': 0, 'byteOffset': posBytes.length, 'byteLength': nrmBytes.length, 'target': 34962},
    ];

    // Accessor 0 = POSITION (needs min/max), 1 = NORMAL.
    final min = [double.infinity, double.infinity, double.infinity];
    final max = [
      double.negativeInfinity,
      double.negativeInfinity,
      double.negativeInfinity
    ];
    for (var i = 0; i < nVerts; i++) {
      for (var k = 0; k < 3; k++) {
        final v = gPos[i * 3 + k];
        if (v < min[k]) min[k] = v;
        if (v > max[k]) max[k] = v;
      }
    }
    final accessors = <Map<String, dynamic>>[
      {
        'bufferView': 0,
        'componentType': 5126, // float
        'count': nVerts,
        'type': 'VEC3',
        'min': min,
        'max': max,
      },
      {
        'bufferView': 1,
        'componentType': 5126,
        'count': nVerts,
        'type': 'VEC3',
      },
    ];

    // One primitive per non-empty material.
    final primitives = <Map<String, dynamic>>[];
    for (var m = 0; m < materialCount; m++) {
      final idx = byMaterial[m];
      if (idx.isEmpty) continue;
      final u32 = Uint32List.fromList(idx);
      final bytes = u32.buffer.asUint8List();
      final offset = bin.length;
      bin.add(bytes);
      final pad = align4(bin.length);
      for (var p = 0; p < pad; p++) {
        bin.addByte(0);
      }
      final viewIndex = bufferViews.length;
      bufferViews.add({
        'buffer': 0,
        'byteOffset': offset,
        'byteLength': bytes.length,
        'target': 34963,
      });
      final accIndex = accessors.length;
      accessors.add({
        'bufferView': viewIndex,
        'componentType': 5125, // unsigned int (mesh exceeds 65535 verts)
        'count': idx.length,
        'type': 'SCALAR',
      });
      primitives.add({
        'attributes': {'POSITION': 0, 'NORMAL': 1},
        'indices': accIndex,
        'material': m,
      });
    }

    // ── Materials: matte anatomy look; muscles gray by default (the runtime
    // recolors trained ones blue), skin a lighter gray. ───────────────────
    List<double> rgb(int hex) => [
          ((hex >> 16) & 0xFF) / 255,
          ((hex >> 8) & 0xFF) / 255,
          (hex & 0xFF) / 255,
        ];
    final materials = <Map<String, dynamic>>[];
    for (var m = 0; m < materialCount; m++) {
      final name = m == 0 ? 'Skin' : groupNames[m - 1].join('+');
      final color = m == 0 ? rgb(0xC2C7D1) : rgb(0xACB3BF);
      materials.add({
        'name': name,
        'pbrMetallicRoughness': {
          'baseColorFactor': [...color, 1.0],
          'metallicFactor': 0.0,
          'roughnessFactor': 0.72,
        },
        'doubleSided': true,
      });
    }

    final gltf = {
      'asset': {'version': '2.0', 'generator': 'apex_lifter muscle exporter'},
      'scene': 0,
      'scenes': [
        {'nodes': [0]}
      ],
      'nodes': [
        {'mesh': 0, 'name': 'Body'}
      ],
      'meshes': [
        {'primitives': primitives, 'name': 'Muscle'}
      ],
      'materials': materials,
      'accessors': accessors,
      'bufferViews': bufferViews,
      'buffers': [
        {'byteLength': bin.length}
      ],
    };

    // ── Assemble the GLB container (12-byte header + JSON chunk + BIN chunk).
    final jsonBytes = utf8.encode(json.encode(gltf));
    final jsonPad = align4(jsonBytes.length);
    final jsonChunk = BytesBuilder()
      ..add(jsonBytes)
      ..add(Uint8List(jsonPad)..fillRange(0, jsonPad, 0x20)); // pad with spaces
    final binBytes = bin.toBytes();
    final binPad = align4(binBytes.length);

    final total = 12 +
        8 +
        jsonChunk.length +
        8 +
        binBytes.length +
        binPad;

    final out = BytesBuilder();
    void u32le(int v) {
      final b = ByteData(4)..setUint32(0, v, Endian.little);
      out.add(b.buffer.asUint8List());
    }

    u32le(0x46546C67); // "glTF"
    u32le(2); // version
    u32le(total);
    // JSON chunk
    u32le(jsonChunk.length);
    u32le(0x4E4F534A); // "JSON"
    out.add(jsonChunk.toBytes());
    // BIN chunk
    u32le(binBytes.length + binPad);
    u32le(0x004E4942); // "BIN\0"
    out.add(binBytes);
    for (var p = 0; p < binPad; p++) {
      out.addByte(0);
    }

    File('assets_src/muscle.glb').writeAsBytesSync(out.toBytes());

    // ── Emit the material-order manifest for the runtime recolorer ─────────
    final buf = StringBuffer()
      ..writeln('// GENERATED by tool/export_muscle_glb.dart — do not edit.')
      ..writeln('//')
      ..writeln('// The muscle groups owning each glTF material of muscle.glb,')
      ..writeln('// in material-index order (index 0 is skin → empty list).')
      ..writeln('const List<List<String>> kMuscleMaterialGroups = [');
    buf.writeln('  [], // 0: Skin');
    for (var m = 0; m < groupNames.length; m++) {
      final names = groupNames[m].map((g) => "'$g'").join(', ');
      buf.writeln('  [$names], // ${m + 1}');
    }
    buf.writeln('];');
    File('lib/widgets/muscle_glb_materials.dart')
        .writeAsStringSync(buf.toString());

    // ignore: avoid_print
    print('Wrote muscle.glb: $nVerts verts, ${tris.length ~/ 3} tris, '
        '$materialCount materials, ${out.length} bytes');
    expect(File('assets_src/muscle.glb').existsSync(), isTrue);
  });
}
