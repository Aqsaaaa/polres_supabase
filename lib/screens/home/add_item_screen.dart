import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../services/item_service.dart';
import '../../utils/constants.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  File? _pickedImage;
  String? _uploadedImageUrl;

   List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

   @override
    void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await CategoryService.getAllCategories();
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories[0];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Check file size (limit to 5MB)
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB in bytes

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file terlalu besar. Maksimal 5MB.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _pickedImage = file;
          _uploadedImageUrl = null; // Reset uploaded URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
        );
      }
    }
  }

  void _showPickOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih sumber gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_pickedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate file extension
      final extension = _pickedImage!.path.split('.').last.toLowerCase();
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception(
          'Format file tidak didukung. Gunakan JPG, PNG, GIF, atau WebP.',
        );
      }

      // Generate unique filename with proper structure
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'items/${user.id}/$timestamp.$extension';

      print('Uploading file: $fileName');
      print('File size: ${_pickedImage!.lengthSync() / 1024 / 1024} MB');
      print('File extension: $extension');

      // Delete old image if exists
      if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
        try {
          final oldFileName = _uploadedImageUrl!.split('/').last;
          await supabase.storage.from('item-images').remove([
            'items/${user.id}/$oldFileName',
          ]);
        } catch (e) {
          print('Failed to delete old image: $e');
        }
      }

      // Upload image to Supabase storage with proper options
      final storageResponse = await supabase.storage
          .from('item-images')
          .upload(
            fileName,
            _pickedImage!,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false, // Don't overwrite existing files
            ),
          );

      print('Upload response: $storageResponse');

      // Get public URL
      final publicUrl = supabase.storage
          .from('item-images')
          .getPublicUrl(fileName);

      print('Public URL: $publicUrl');

      setState(() {
        _imageController.text = publicUrl;
        _uploadedImageUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar berhasil diupload!')),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      String errorMessage = 'Gagal mengupload gambar';

      // Handle specific Supabase errors
      if (e.toString().contains('duplicate')) {
        errorMessage = 'File dengan nama yang sama sudah ada';
      } else if (e.toString().contains('too large')) {
        errorMessage = 'Ukuran file terlalu besar';
      } else if (e.toString().contains('not allowed')) {
        errorMessage = 'Format file tidak diizinkan';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'Kuota storage telah habis';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if image is uploaded, if not upload now
    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu')),
        );
        return;
      }
      setState(() {
        _isUploading = true;
      });
      await _uploadImage();
      setState(() {
        _isUploading = false;
      });
      if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
        // Upload failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengupload gambar')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ItemService.createItem(
        name: _nameController.text.trim(),
        image: _uploadedImageUrl!.trim(),
        stock: int.parse(_stockController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil ditambahkan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan barang: ${e.toString()}')),
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

  Widget _buildImagePreview() {
    if (_isUploading) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Uploading...'),
            ],
          ),
        ),
      );
    }

    if (_pickedImage != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _pickedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
    }

    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _uploadedImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, color: Colors.red, size: 40),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isLoading ? null : _showPickOptionsDialog,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Tap to select image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<Category>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<Category>(
          value: category,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (Category? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Kategori harus dipilih';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Barang'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama barang tidak boleh kosong';
                  }
                  return null;
                },
              ),
               const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              // Image picker section
              _buildImagePreview(),

              // Show upload status
              if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gambar berhasil diupload',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok harus berupa angka';
                  }
                  if (int.parse(value) < 0) {
                    return 'Stok tidak boleh negatif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || _isUploading) ? null : _addItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.blue,
                          size: 50,
                        ),
                      )
                    : const Text(
                        'Tambah Barang',
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
