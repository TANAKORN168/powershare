import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

typedef OnImagePicked = void Function(File imageFile);

class ImagePickerWidget extends StatefulWidget {
  final String label;
  final File? imageFile;
  final bool isIdCard;
  final double aspectRatio;
  final OnImagePicked onImagePicked;

  const ImagePickerWidget({
    Key? key,
    required this.label,
    required this.imageFile,
    required this.isIdCard,
    required this.aspectRatio,
    required this.onImagePicked,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: widget.isIdCard ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // แสดง Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await Future.delayed(Duration(milliseconds: 100));

      try {
        final rawBytes = await imageFile.readAsBytes();
        final resizedBytes = await compute(resizeImageInIsolate, rawBytes);
        await imageFile.writeAsBytes(resizedBytes);

        widget.onImagePicked(imageFile);
      } catch (e) {
        print('Image resize error: $e');
      } finally {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(widget.imageFile!, fit: BoxFit.cover),
                      )
                    : const Center(child: Icon(Icons.add_a_photo, size: 40)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ฟังก์ชันย่อรูปภาพ
Future<Uint8List> resizeImageInIsolate(Uint8List bytes) async {
  final originalImage = img.decodeImage(bytes);
  if (originalImage == null) throw Exception("Image decode failed");

  double ratio = 0.5;
  int resizedWidth = (originalImage.width * ratio).round();
  int resizedHeight = (originalImage.height * ratio).round();

  final resizedImage = img.copyResize(
    originalImage,
    width: resizedWidth,
    height: resizedHeight,
  );
  return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
}
