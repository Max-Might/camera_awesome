import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerapreview.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome_example/main.dart' as app;
import 'package:camerawesome_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imgUtils;

/// -------------------------------------------
/// Integretions test
/// -------------------------------------------
/// start these with :
/// flutter drive --driver=test_driver/app_test.dart test_driver/app.dart
/// or for android native : (first go in android folder of example)
/// ./gradlew app:connectedAndroidTest -Ptarget=`pwd`/../test_driver/app.dart
/// or for iOS native :
///
void main() {

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("start camera preview", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: true)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
  });

  testWidgets("take photo works with selected photo size", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: false)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
    var takePhotoBtnFinder = find.byKey(ValueKey("takePhotoButton"));
    // take photo
    await tester.tap(takePhotoBtnFinder);
    await tester.pump(Duration(seconds: 2));
    expect(cameraPreview.photoSize.value, isNotNull);
    // checks photo exists + size
    final Directory extDir = await getTemporaryDirectory();
    var testDir = await Directory('${extDir.path}/test');
    final String filePath = '${testDir.path}/photo_test.jpg';
    expect(await File(filePath).exists(), isTrue);
    var file = await File(filePath);
    var img = imgUtils.decodeImage(file.readAsBytesSync());
    expect(img.width, equals(cameraPreview.photoSize.value.width));
    expect(img.height, equals(cameraPreview.photoSize.value.height));
    // delete photo
    file.deleteSync();
  });

  testWidgets("change selected photo size param then take photo", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: false)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
    var takePhotoBtnFinder = find.byKey(ValueKey("takePhotoButton"));
    // change photo size preset
    var previousResolution = (find.byKey(ValueKey("resolutionTxt")).evaluate().first.widget as Text).data;
    var resolButtonFinder = find.byKey(ValueKey("resolutionButton"));
    (resolButtonFinder.evaluate().first.widget as FlatButton).onPressed();
    await tester.pump(Duration(milliseconds: 1000));
    await tester.pumpAndSettle(Duration(milliseconds: 1000));
    var optionsFinder = find.byKey(ValueKey("resOption"));
    await tester.tap(optionsFinder.last);
    await tester.pump(Duration(milliseconds: 500));
    var currentResolution = (find.byKey(ValueKey("resolutionTxt")).evaluate().first.widget as Text).data;
    expect(previousResolution, isNot(equals(currentResolution)));
    // take photo
    await tester.tap(takePhotoBtnFinder);
    await tester.pump(Duration(seconds: 2));
    // checks photo exists + size
    final Directory extDir = await getTemporaryDirectory();
    var testDir = await Directory('${extDir.path}/test');
    final String filePath = '${testDir.path}/photo_test.jpg';
    expect(await File(filePath).exists(), isTrue);
    var file = await File(filePath);
    var img = imgUtils.decodeImage(file.readAsBytesSync());
    expect(img.width, equals(cameraPreview.photoSize.value.width));
    expect(img.height, equals(cameraPreview.photoSize.value.height));
    // delete photo
    file.deleteSync();
  });

  testWidgets('Image stream properly delivers images', (WidgetTester tester) async {
    ValueNotifier<Size> photoSize = ValueNotifier(null);
    ValueNotifier<Sensors> sensor = ValueNotifier(Sensors.BACK);
    Stream<Uint8List> imageStream;
    Uint8List imgData;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(top: 0, left: 0, bottom: 0, right: 0,
                child: Center(
                  child: CameraAwesome(
                    selectDefaultSize: (availableSizes) => availableSizes[0],
                    photoSize: photoSize,
                    sensor: sensor,
                    imagesStreamBuilder: (stream) async {
                      imageStream = stream;
                      imgData = await imageStream.first;
                      expect(imgData, isNotNull);
                      var img = imgUtils.decodeImage(imgData);
                      expect(img, isNotNull);
                      expect(img.getBytes().length, greaterThan(0));
                      expect(img.width, greaterThan(0));
                      expect(img.height, greaterThan(0));
                      print("check stream image has been done");
                    }
                  ),
                )
              )
            ],
          ),
        )
      )
    );
    await Future.delayed(Duration(seconds: 3));
  });
}