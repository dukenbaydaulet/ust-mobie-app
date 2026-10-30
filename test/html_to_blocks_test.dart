import 'package:flutter_test/flutter_test.dart';
import 'package:ust_mobile_app/features/materials/api_materials_repository.dart';
import 'package:ust_mobile_app/features/materials/material_detail.dart';

void main() {
  test('HTML алдын ала көрінісі бөліктерге бөлінеді', () {
    final blocks = htmlToBlocks('''
<style>p{color:red}</style>
<h2>ҚАЗАҚСТАН РЕСПУБЛИКАСЫ</h2>
<p><b>1. Сабақтың тақырыбы:</b></p>
<p>Бөлшектерді&nbsp;қосу &laquo;және&raquo; азайту<br>екінші жол</p>
<p>   </p>
<script>alert(1)</script>
''');
    expect(blocks, hasLength(4));
    expect((blocks[0] as DocHeading).text, 'ҚАЗАҚСТАН РЕСПУБЛИКАСЫ');
    final section = blocks[1] as DocSection;
    expect(section.number, 1);
    expect(section.title, 'Сабақтың тақырыбы:');
    expect((blocks[2] as DocParagraph).text, 'Бөлшектерді қосу «және» азайту');
    expect((blocks[3] as DocParagraph).text, 'екінші жол');
  });

  test('суреттер толық адреске айналады, data: суреттері өткізіледі', () {
    final blocks = htmlToBlocks(
      '<p>Мәтін</p><p><img src="materials/a/1.png" alt=""><img src="data:image/png;base64,AA"></p>',
      imageUrl: (src) => 'https://ust.kz/storage/files/$src',
    );
    expect(blocks, hasLength(2));
    expect((blocks[0] as DocParagraph).text, 'Мәтін');
    expect((blocks[1] as DocImage).url, 'https://ust.kz/storage/files/materials/a/1.png');
  });

  test('HTML жоқ болса — бос тізім', () {
    expect(htmlToBlocks(null), isEmpty);
    expect(htmlToBlocks('  '), isEmpty);
  });
}
