import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/item_service.dart';
import '../../services/history_service.dart';

class BorrowItemScreen extends StatefulWidget {
  final Item item;

  const BorrowItemScreen({super.key, required this.item});

  @override
  State<BorrowItemScreen> createState() => _BorrowItemScreenState();
}

class _BorrowItemScreenState extends State<BorrowItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _borrowerNameController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _responsiblePersonController.dispose();
    super.dispose();
  }

  Future<void> _borrowItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create history record
      await HistoryService.borrowItem(
        itemId: widget.item.id,
        itemName: widget.item.name,
        borrowerName: _borrowerNameController.text.trim(),
        responsiblePerson: _responsiblePersonController.text.trim(),
      );

      // Decrease stock
      await ItemService.decreaseStock(widget.item.id, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dipinjam!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meminjam barang: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinjam Barang'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.blue.shade100,
                        ),
                        child: widget.item.image.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.item.image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.inventory_2,
                                      size: 40,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2,
                                size: 40,
                                color: Colors.blue,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stok Tersedia: ${widget.item.stock}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _borrowerNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Peminjam',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama peminjam tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsiblePersonController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Penanggung Jawab',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_user),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Penanggung jawab tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _borrowItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Pinjam Barang',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
