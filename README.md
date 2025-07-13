# Aplikasi Manajemen Barang Flutter + Supabase

Aplikasi manajemen inventori yang dibangun dengan Flutter dan menggunakan Supabase sebagai backend database. Aplikasi ini memiliki fitur autentikasi lengkap dan sistem manajemen peminjaman barang yang terintegrasi.

## Fitur Utama

### 🔐 Autentikasi
- Login dengan email dan password
- Registrasi user baru
- Setup profil user (nama lengkap)
- Logout

### 📦 Manajemen Inventori
- Tambah barang baru dengan gambar dan stok
- Lihat daftar semua barang
- Hapus barang
- Update stok otomatis saat peminjaman/pengembalian

### 📋 Sistem Peminjaman
- Pinjam barang dengan data peminjam dan penanggung jawab
- Riwayat peminjaman yang lengkap
- Status barang (dipinjam/dikembalikan)
- Pengembalian barang dengan update stok otomatis

### 📊 Riwayat Transaksi
- Tab untuk barang yang sedang dipinjam
- Tab untuk barang yang sudah dikembalikan
- Informasi lengkap: peminjam, penanggung jawab, waktu

## Struktur Database

### Tabel `users`
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Tabel `items`
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `image` (TEXT, URL gambar)
- `stock` (INTEGER)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Tabel `transactions`
- `id` (UUID, Primary Key)
- `item_id` (UUID, Foreign Key)
- `item_name` (TEXT)
- `borrower_name` (TEXT)
- `responsible_person` (TEXT)
- `status` (TEXT: 'borrowed'/'returned')
- `created_at` (TIMESTAMP)
- `returned_at` (TIMESTAMP)

## Setup Aplikasi

### 1. Setup Supabase

1. Buat project baru di [Supabase](https://supabase.com)
2. Jalankan script SQL di `database_setup.sql` di SQL Editor Supabase
3. Catat URL dan Anon Key dari Settings > API

### 2. Setup Environment Variables

Buat file `.env` di root project:

```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run Aplikasi

```bash
flutter run
```

## Cara Penggunaan

### Registrasi dan Login
1. Buka aplikasi
2. Klik "Daftar" untuk membuat akun baru
3. Masukkan email dan password
4. Setelah registrasi, lengkapi profil dengan nama lengkap
5. Login dengan email dan password

### Manajemen Barang
1. Di tab "Inventori", klik tombol "+" untuk tambah barang
2. Isi nama barang, URL gambar (opsional), dan stok
3. Barang akan muncul di daftar inventori
4. Klik icon hapus untuk menghapus barang

### Peminjaman Barang
1. Di daftar inventori, klik icon pinjam (orange) pada barang yang tersedia
2. Isi nama peminjam dan penanggung jawab
3. Klik "Pinjam Barang"
4. Stok akan berkurang otomatis dan data masuk ke riwayat

### Pengembalian Barang
1. Di tab "Riwayat", pilih tab "Sedang Dipinjam"
2. Klik icon centang (hijau) pada barang yang akan dikembalikan
3. Konfirmasi pengembalian
4. Status berubah menjadi "Dikembalikan" dan stok bertambah

## Teknologi yang Digunakan

- **Frontend**: Flutter
- **Backend**: Supabase
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth
- **State Management**: Flutter StatefulWidget
- **UI**: Material Design 3

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Model data
│   ├── user.dart
│   ├── item.dart
│   └── history.dart
├── services/                 # Service layer
│   ├── auth_service.dart
│   ├── item_service.dart
│   └── history_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── profile/
│   │   └── profile_setup_screen.dart
│   └── home/
│       ├── home_screen.dart
│       ├── inventory_screen.dart
│       ├── add_item_screen.dart
│       ├── borrow_item_screen.dart
│       ├── history_screen.dart
│       └── profile_screen.dart
└── utils/
    └── constants.dart        # Konstanta aplikasi
```

## Keamanan

- Row Level Security (RLS) diaktifkan di semua tabel
- User hanya bisa mengakses data mereka sendiri
- Autentikasi wajib untuk semua operasi CRUD
- Validasi input di frontend dan backend

## Kontribusi

1. Fork repository
2. Buat branch fitur baru
3. Commit perubahan
4. Push ke branch
5. Buat Pull Request

## Lisensi

MIT License
