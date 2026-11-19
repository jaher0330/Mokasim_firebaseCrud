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

  // Add / Edit dialog (isang dialog para sa dalawa)
  void _showItemDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final nameCtrl = TextEditingController(text: isEdit ? doc['name'] : '');
    final qtyCtrl =
        TextEditingController(text: isEdit ? doc['quantity'].toString() : '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Edit Item' : 'Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (name.isEmpty) return;

              if (isEdit) {
                await service.updateItem(doc.id, name, qty);
              } else {
                await service.addItem(name, qty);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(isEdit ? 'Edit' : 'Save'),
          ),
        ],
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
        title: const Text('Firebase | Mokasim'), // <-- LASTNAME mo
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
            docs = docs.where((d) => d['isFavorite'] == true).toList();
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
              final doc = docs[index];
              final isFav = doc['isFavorite'] == true;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    doc['name'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Quantity ${doc['quantity']}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => service.toggleFavorite(doc.id, isFav),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showItemDialog(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(doc.id),
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