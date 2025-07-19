import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../models/item.dart';
import '../../services/item_service.dart';
import 'add_item_screen.dart';
import 'add_category_screen.dart';
import 'borrow_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Item> _items = [];
  bool _isLoading = true;
  bool _showActionButtons = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await ItemService.getAllItems();
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error',
              message: 'Gagal memuat data: ${e.toString()}',
              contentType: ContentType.failure,
            ),
          ),
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

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus barang "${item.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ItemService.deleteItem(item.id);
        await _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: const AwesomeSnackbarContent(
                title: 'Success',
                message: 'Barang berhasil dihapus',
                contentType: ContentType.success,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Error',
                message: 'Gagal menghapus barang: ${e.toString()}',
                contentType: ContentType.failure,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Inventori Barang')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 20,
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada barang',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: item.image.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  item.image,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.inventory_2,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              )
                            : const Icon(Icons.inventory_2, color: Colors.blue),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Stok: ${item.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.stock > 0)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.orange,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BorrowItemScreen(item: item),
                                  ),
                                ).then((_) => _loadItems());
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteItem(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _showActionButtons
                ? Column(
                    key: const ValueKey('buttons'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'add_item',
                        onPressed: () {
                          setState(() {
                            _showActionButtons = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddItemScreen(),
                            ),
                          ).then((_) => _loadItems());
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        mini: true,
                        tooltip: 'Add Item',
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'add_category',
                        onPressed: () {
                          setState(() {
                            _showActionButtons = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCategoryScreen(),
                            ),
                          );
                        },
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        mini: true,
                        tooltip: 'Add Category',
                        child: const Icon(Icons.category),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'close_buttons',
                        onPressed: () {
                          setState(() {
                            _showActionButtons = false;
                          });
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        mini: true,
                        tooltip: 'Close',
                        child: const Icon(Icons.close),
                      ),
                    ],
                  )
                : Container(
                    key: const ValueKey('main_button'),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        setState(() {
                          _showActionButtons = true;
                        });
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
