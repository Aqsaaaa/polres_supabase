import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/item.dart';
import '../../services/auth_service.dart';
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
  final _quantityController = TextEditingController(text: '1');
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _borrowItem() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum login')));
      return;
    }

    final int quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0 || quantity > widget.item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jumlah pinjam harus antara 1 dan ${widget.item.stock}',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create history record
      await HistoryService.borrowItem(
        itemId: widget.item.id,
        itemName: widget.item.name,
        borrowerName: currentUser.name,
        responsiblePerson: currentUser.name,
        category: widget.item.category,
        purpose: _purposeController.text.trim(),
        quantity: quantity,
      );

      // Decrease stock
      await ItemService.decreaseStock(widget.item.id, quantity);

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
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pinjam',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty <= 0 || qty > widget.item.stock) {
                    return 'Masukkan jumlah pinjam yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Tujuan Pinjam',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tujuan pinjam tidak boleh kosong';
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
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white,
                        size: 20,
                      )
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
