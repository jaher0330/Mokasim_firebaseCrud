import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'crud_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  bool showOnlyFavorites = false; // FAVORITE FILTER

  // ADD / EDIT dialog
  void _showItemDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data =
        isEdit ? doc.data() as Map<String, dynamic> : <String, dynamic>{};
    final nameCtrl =
        TextEditingController(text: isEdit ? (data['name'] ?? '') : '');
    final qtyCtrl =
        TextEditingController(text: isEdit ? '${data['quantity'] ?? 0}' : '');

    File? selectedImageFile;
    String? selectedImageUrl;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Item' : 'Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // IMAGE (Add dialog only, same as the slides)
                if (!isEdit) ...[
                  const SizedBox(height: 10),
                  if (selectedImageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedImageFile!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(uploading ? 'Uploading...' : 'Upload Image'),
                    onPressed: uploading
                        ? null
                        : () async {
                            setDialogState(() => uploading = true);
                            try {
                              final pickedFile =
                                  await service.pickImageForAddItem();
                              if (!context.mounted) return;
                              if (pickedFile != null) {
                                setDialogState(() {
                                  selectedImageFile = pickedFile.file;
                                  selectedImageUrl = pickedFile.url;
                                });
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upload failed: $e')),
                              );
                            }
                            if (!context.mounted) return;
                            setDialogState(() => uploading = false);
                          },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? Colors.orange : Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: uploading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty || qtyCtrl.text.trim().isEmpty) return;
                      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;

                      if (isEdit) {
                        await service.updateItem(doc.id, name, qty);
                      } else {
                        await service.addItemWithImage(
                            name, qty, selectedImageUrl);
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
              child: Text(isEdit ? 'Edit' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE UI (confirmation)
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Firebase | Mokasim'), // <-- your LASTNAME
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // FAVORITE FILTER BUTTON
          IconButton(
            tooltip: 'Show favorites',
            icon: Icon(
              showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => showOnlyFavorites = !showOnlyFavorites),
          ),
          // LOGOUT
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (showOnlyFavorites) {
            docs = docs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['isFavorite'] == true)
                .toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Text(
                showOnlyFavorites ? 'No favorites yet' : 'No items found',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final imageUrl = data['image_url'];
              final isFav = data['isFavorite'] == true;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // IMAGE from Cloudinary
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : null,
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Quantity ${data['quantity'] ?? 0}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => service.toggleFavorite(item.id, isFav),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showItemDialog(doc: item),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}