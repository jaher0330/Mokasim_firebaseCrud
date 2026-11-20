import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

// Holds the picked image file and its Cloudinary URL
class PickedImage {
  final File file;
  final String url;
  PickedImage({required this.file, required this.url});
}

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  // CLOUDINARY: your Cloud Name and unsigned Upload Preset
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'xhvivyig',
    'flutter_notes_preset',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // PICK + UPLOAD IMAGE
  Future<PickedImage?> pickImageForAddItem() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null; // user cancelled the picker

    final file = File(pickedFile.path);

    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return PickedImage(file: file, url: response.secureUrl);
  }

  // CREATE (with image_url)
  Future<void> addItemWithImage(
      String name, int quantity, String? imageUrl) async {
    await items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'isFavorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  // READ (realtime, newest first)
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE (name / quantity)
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({'name': name, 'quantity': quantity});
  }

  // FAVORITE toggle
  Future<void> toggleFavorite(String id, bool current) {
    return items.doc(id).update({'isFavorite': !current});
  }

  // DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}