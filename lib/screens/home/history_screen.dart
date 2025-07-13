import 'package:flutter/material.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import '../../services/item_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin mengembalikan barang "${history.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update history status
        await HistoryService.returnItem(history.id);
        
        // Increase stock
        await ItemService.increaseStock(history.itemId, 1);
        
        await _loadHistory();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dikembalikan!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengembalikan barang: ${e.toString()}')),
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
          backgroundColor: isBorrowed ? Colors.orange.shade100 : Colors.green.shade100,
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
        title: const Text('Riwayat Peminjaman'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sedang Dipinjam'),
            Tab(text: 'Sudah Dikembalikan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Sedang Dipinjam
                _borrowedItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey,
                            ),
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
                            return _buildHistoryCard(_borrowedItems[index], true);
                          },
                        ),
                      ),
                
                // Sudah Dikembalikan
                _returnedItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey,
                            ),
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
                            return _buildHistoryCard(_returnedItems[index], false);
                          },
                        ),
                      ),
              ],
            ),
    );
  }
} 