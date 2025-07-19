import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import '../../services/item_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<History> _borrowedItems = [];
  List<History> _returnedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final borrowed = await HistoryService.getBorrowedItems();
      final returned = await HistoryService.getReturnedItems();

      setState(() {
        _borrowedItems = borrowed;
        _returnedItems = returned;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: ${e.toString()}')),
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

  Future<void> _returnItem(History history) async {
    final TextEditingController quantityController = TextEditingController(
      text: history.quantity.toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apakah Anda yakin ingin mengembalikan barang "${history.itemName}"?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah yang dikembalikan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final int? qty = int.tryParse(quantityController.text);
              if (qty == null || qty <= 0 || qty > history.quantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Masukkan jumlah yang valid (1-${history.quantity})',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final int quantityToReturn = int.parse(quantityController.text);
      try {
        // Update history status with partial return
        await HistoryService.returnItem(history.id, quantityToReturn);

        // Increase stock by returned quantity
        await ItemService.increaseStock(history.itemId, quantityToReturn);

        await _loadHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dikembalikan!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengembalikan barang: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  Widget _buildHistoryCard(History history, bool isBorrowed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBorrowed
              ? Colors.orange.shade100
              : Colors.green.shade100,
          child: Icon(
            isBorrowed ? Icons.remove_circle : Icons.check_circle,
            color: isBorrowed ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(
          history.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peminjam: ${history.borrowerName}'),
            Text('Penanggung Jawab: ${history.responsiblePerson}'),
            Text('Kategori: ${history.category}'),
            Text('Tujuan: ${history.purpose}'),
            Text(
              isBorrowed
                  ? 'Dipinjam: ${_formatDate(history.createdAt)}'
                  : 'Dikembalikan: ${_formatDate(history.returnedAt!)}',
            ),
          ],
        ),
        trailing: isBorrowed
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: Colors.green,
                onPressed: () => _returnItem(history),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Column(
            children: [
              TabBar(
                indicatorAnimation: TabIndicatorAnimation.elastic,
                indicatorColor: Color(Colors.blue.value),
                controller: _tabController,

                tabs: const [
                  Tab(text: 'Sedang Dipinjam'),
                  Tab(text: 'Sudah Dikembalikan'),
                ],
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blue,
                size: 50,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Sedang Dipinjam
                _borrowedItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada barang yang sedang dipinjam',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _borrowedItems.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(
                              _borrowedItems[index],
                              true,
                            );
                          },
                        ),
                      ),

                // Sudah Dikembalikan
                _returnedItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada riwayat pengembalian',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _returnedItems.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(
                              _returnedItems[index],
                              false,
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
