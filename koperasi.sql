-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 24, 2025 at 05:50 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `koperasi`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_bayar_angsuran` (IN `p_id_pinjaman` INT, IN `p_jumlah` DECIMAL(15,2))   BEGIN
    DECLARE total_bayar DECIMAL(15,2);
    DECLARE total_pinjaman DECIMAL(15,2);

    -- catat pembayaran
    INSERT INTO tabel_angsuran (id_pinjaman, tanggal_bayar, jumlah_bayar)
    VALUES (p_id_pinjaman, CURDATE(), p_jumlah);

    -- masuk ke kas
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (CURDATE(), 'Angsuran', 'masuk', p_jumlah, CONCAT('Angsuran Pinjaman ID: ', p_id_pinjaman));

    -- hitung total bayar
    SELECT SUM(jumlah_bayar) INTO total_bayar
    FROM tabel_angsuran WHERE id_pinjaman = p_id_pinjaman;

    -- ambil total pinjaman
    SELECT jumlah INTO total_pinjaman
    FROM tabel_pinjaman WHERE id_pinjaman = p_id_pinjaman;

    -- update status pinjaman
    IF total_bayar >= total_pinjaman THEN
        UPDATE tabel_status_pinjaman SET status='Lunas'
        WHERE id_pinjaman = p_id_pinjaman;
    ELSE
        UPDATE tabel_status_pinjaman SET status='Aktif'
        WHERE id_pinjaman = p_id_pinjaman;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_hitung_shu` (IN `p_tahun` YEAR)   BEGIN
    DECLARE v_pendapatan DECIMAL(15,2);
    DECLARE v_biaya DECIMAL(15,2);
    DECLARE v_shu DECIMAL(15,2);

    SELECT IFNULL(SUM(jumlah),0) INTO v_pendapatan
    FROM tabel_kas
    WHERE YEAR(tanggal)=p_tahun AND jenis='masuk';

    SELECT IFNULL(SUM(jumlah),0) INTO v_biaya
    FROM tabel_kas
    WHERE YEAR(tanggal)=p_tahun AND jenis='keluar';

    SET v_shu = v_pendapatan - v_biaya;

    INSERT INTO tabel_shu (tahun, pendapatan, biaya, shu_bersih)
    VALUES (p_tahun, v_pendapatan, v_biaya, v_shu);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tambah_pinjaman` (IN `p_id_anggota` INT, IN `p_jumlah` DECIMAL(15,2), IN `p_bunga` DECIMAL(5,2), IN `p_tenor` INT)   BEGIN
    DECLARE new_id INT;

    INSERT INTO tabel_pinjaman (id_anggota, tanggal_pinjaman, jumlah, bunga, tenor)
    VALUES (p_id_anggota, CURDATE(), p_jumlah, p_bunga, p_tenor);

    SET new_id = LAST_INSERT_ID();

    -- Buat status pinjaman awal = Aktif
    INSERT INTO tabel_status_pinjaman (id_pinjaman, angsuran_ke, status)
    VALUES (new_id, 0, 'Aktif');

    -- Catat di kas (keluar)
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (CURDATE(), 'Pinjaman', 'keluar', p_jumlah, CONCAT('Pinjaman ID: ', new_id));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `total_sales` (IN `compareid` VARCHAR(10))   BEGIN
    DECLARE total_sales BIGINT;

    
    SELECT SUM(jumlah) 
    INTO total_sales
    FROM sales
    WHERE company_id = compareid;

    SELECT CONCAT('Total sales for ', compareid, ' is ', total_sales) AS hasil;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `total_simpanan` (IN `p_id_anggota` INT)   BEGIN
    SELECT a.nama, SUM(s.jumlah) AS total_simpanan
    FROM tabel_simpanan s
    JOIN tabel_anggota a ON s.id_anggota = a.id_anggota
    WHERE s.id_anggota = p_id_anggota
    GROUP BY a.nama;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_anggota`
--

CREATE TABLE `tabel_anggota` (
  `id_anggota` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `tanggal_daftar` date DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_anggota`
--

INSERT INTO `tabel_anggota` (`id_anggota`, `nama`, `alamat`, `no_telp`, `tanggal_daftar`, `username`) VALUES
(1, 'Tha', 'Jl. Mawar No.1', '08123456789', '2025-09-15', 'Tha'),
(2, 'Bruder Thom', 'Jl. pangudi luhur No.2', '081298765432', '2025-09-15', 'Thom'),
(3, 'Theodora Trixci', 'Jl. Zaulus No.19', '082134567890', '2025-09-15', 'Trix'),
(4, 'Rose Virgini', 'Jl. Kenanga No.4', '083156789012', '2025-09-15', 'Gin'),
(5, 'Bonifasius', 'Jl. Flamboyan No.5', '085267890123', '2025-09-15', 'Boni');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_angsuran`
--

CREATE TABLE `tabel_angsuran` (
  `id_angsuran` int(11) NOT NULL,
  `id_pinjaman` int(11) DEFAULT NULL,
  `tanggal_bayar` date DEFAULT NULL,
  `jumlah_bayar` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_angsuran`
--

INSERT INTO `tabel_angsuran` (`id_angsuran`, `id_pinjaman`, `tanggal_bayar`, `jumlah_bayar`) VALUES
(1, 1, '2025-09-15', 250000.00),
(2, 1, '2025-09-15', 250000.00),
(3, 1, '2025-09-23', 250000.00),
(4, 1, '2025-09-23', 250000.00),
(5, 1, '2025-09-23', 250000.00),
(6, 1, '2025-09-23', 250000.00),
(7, 1, '2025-09-23', 250000.00),
(8, 1, '2025-09-23', 250000.00),
(9, 1, '2025-09-23', 250000.00);

--
-- Triggers `tabel_angsuran`
--
DELIMITER $$
CREATE TRIGGER `trg_after_insert_angsuran` AFTER INSERT ON `tabel_angsuran` FOR EACH ROW BEGIN
    DECLARE total_bayar DECIMAL(15,2);
    DECLARE total_pinjaman DECIMAL(15,2);

    -- masuk ke kas
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (NEW.tanggal_bayar, 'Angsuran', 'masuk', NEW.jumlah_bayar, CONCAT('Angsuran ID: ', NEW.id_angsuran));

    -- hitung total bayar
    SELECT SUM(jumlah_bayar) INTO total_bayar
    FROM tabel_angsuran WHERE id_pinjaman = NEW.id_pinjaman;

    -- ambil jumlah pinjaman
    SELECT jumlah INTO total_pinjaman
    FROM tabel_pinjaman WHERE id_pinjaman = NEW.id_pinjaman;

    -- update status pinjaman
    IF total_bayar >= total_pinjaman THEN
        UPDATE tabel_status_pinjaman SET status = 'Lunas'
        WHERE id_pinjaman = NEW.id_pinjaman;
    ELSE
        UPDATE tabel_status_pinjaman SET status = 'Aktif'
        WHERE id_pinjaman = NEW.id_pinjaman;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_denda`
--

CREATE TABLE `tabel_denda` (
  `id_denda` int(11) NOT NULL,
  `id_angsuran` int(11) DEFAULT NULL,
  `denda` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_denda`
--

INSERT INTO `tabel_denda` (`id_denda`, `id_angsuran`, `denda`) VALUES
(1, 1, 50000.00),
(2, 1, 50000.00);

--
-- Triggers `tabel_denda`
--
DELIMITER $$
CREATE TRIGGER `trg_after_insert_denda` AFTER INSERT ON `tabel_denda` FOR EACH ROW BEGIN
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (CURDATE(), 'Denda', 'masuk', NEW.denda, CONCAT('Denda dari angsuran ID: ', NEW.id_angsuran));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_before_insert_denda` BEFORE INSERT ON `tabel_denda` FOR EACH ROW BEGIN
    IF NEW.denda <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Denda tidak boleh nol atau negatif';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_jenis_simpanan`
--

CREATE TABLE `tabel_jenis_simpanan` (
  `id_jenis` int(11) NOT NULL,
  `nama_jenis` enum('wajib','wajib_khusus','sukarela') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_jenis_simpanan`
--

INSERT INTO `tabel_jenis_simpanan` (`id_jenis`, `nama_jenis`) VALUES
(1, 'wajib'),
(2, 'wajib_khusus'),
(3, 'sukarela');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_kas`
--

CREATE TABLE `tabel_kas` (
  `id_kas` int(11) NOT NULL,
  `tanggal` date DEFAULT NULL,
  `sumber` varchar(100) DEFAULT NULL,
  `jenis` enum('masuk','keluar') DEFAULT NULL,
  `jumlah` decimal(15,2) DEFAULT NULL,
  `keterangan` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_kas`
--

INSERT INTO `tabel_kas` (`id_kas`, `tanggal`, `sumber`, `jenis`, `jumlah`, `keterangan`) VALUES
(3, '2025-09-15', 'Simpanan', 'masuk', 500000.00, 'Simpanan Anggota ID: 1'),
(4, '2026-12-31', 'SHU', 'masuk', 9000000.00, 'Pencatatan SHU tahunan'),
(5, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 3'),
(6, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 3'),
(7, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 3'),
(8, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(9, '2025-12-31', 'SHU', 'masuk', -2000000.00, 'Pencatatan SHU tahunan'),
(10, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 4'),
(11, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 4'),
(12, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 4'),
(13, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(14, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 5'),
(15, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 5'),
(16, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 5'),
(17, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(18, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 6'),
(19, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 6'),
(20, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 6'),
(21, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(22, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 7'),
(23, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 7'),
(24, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 7'),
(25, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(26, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 8'),
(27, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 8'),
(28, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 8'),
(29, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1'),
(30, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 9'),
(31, '2025-09-23', 'Pinjaman', 'keluar', 1500000.00, 'Pinjaman ID: 9'),
(32, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran ID: 9'),
(33, '2025-09-23', 'Angsuran', 'masuk', 250000.00, 'Angsuran Pinjaman ID: 1');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_pinjaman`
--

CREATE TABLE `tabel_pinjaman` (
  `id_pinjaman` int(11) NOT NULL,
  `id_anggota` int(11) DEFAULT NULL,
  `tanggal_pinjaman` date DEFAULT NULL,
  `jumlah` decimal(15,2) DEFAULT NULL,
  `bunga` decimal(5,2) DEFAULT NULL,
  `tenor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_pinjaman`
--

INSERT INTO `tabel_pinjaman` (`id_pinjaman`, `id_anggota`, `tanggal_pinjaman`, `jumlah`, `bunga`, `tenor`) VALUES
(1, 2, '2025-09-15', 1000000.00, 5.00, 6),
(2, 3, '2025-09-15', 2000000.00, 4.50, 12),
(3, 2, '2025-09-23', 1500000.00, 5.00, 12),
(4, 2, '2025-09-23', 1500000.00, 5.00, 12),
(5, 2, '2025-09-23', 1500000.00, 5.00, 12),
(6, 2, '2025-09-23', 1500000.00, 5.00, 12),
(7, 2, '2025-09-23', 1500000.00, 5.00, 12),
(8, 2, '2025-09-23', 1500000.00, 5.00, 12),
(9, 2, '2025-09-23', 1500000.00, 5.00, 12);

--
-- Triggers `tabel_pinjaman`
--
DELIMITER $$
CREATE TRIGGER `trg_after_insert_pinjaman` AFTER INSERT ON `tabel_pinjaman` FOR EACH ROW BEGIN
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (NEW.tanggal_pinjaman, 'Pinjaman', 'keluar', NEW.jumlah, CONCAT('Pinjaman ID: ', NEW.id_pinjaman));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_before_insert_pinjaman` BEFORE INSERT ON `tabel_pinjaman` FOR EACH ROW BEGIN
    DECLARE tunggakan INT;
    SELECT COUNT(*) INTO tunggakan
    FROM tabel_status_pinjaman sp
    JOIN tabel_pinjaman p ON sp.id_pinjaman = p.id_pinjaman
    WHERE p.id_anggota = NEW.id_anggota AND sp.status = 'Tertunda';

    IF tunggakan >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pinjaman ditolak: anggota masih memiliki tunggakan > 3x';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_shu`
--

CREATE TABLE `tabel_shu` (
  `id_shu` int(11) NOT NULL,
  `tahun` year(4) DEFAULT NULL,
  `pendapatan` decimal(15,2) DEFAULT NULL,
  `biaya` decimal(15,2) DEFAULT NULL,
  `shu_bersih` decimal(15,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_shu`
--

INSERT INTO `tabel_shu` (`id_shu`, `tahun`, `pendapatan`, `biaya`, `shu_bersih`) VALUES
(5, '2026', 12000000.00, 3000000.00, 9000000.00),
(6, '2025', 1000000.00, 3000000.00, -2000000.00);

--
-- Triggers `tabel_shu`
--
DELIMITER $$
CREATE TRIGGER `trg_after_insert_shu` AFTER INSERT ON `tabel_shu` FOR EACH ROW BEGIN
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (
        STR_TO_DATE(CONCAT(NEW.tahun, '-12-31'), '%Y-%m-%d'),
        'SHU',
        'masuk',
        NEW.shu_bersih,
        'Pencatatan SHU tahunan'
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_before_insert_shu` BEFORE INSERT ON `tabel_shu` FOR EACH ROW BEGIN
    DECLARE cek INT;
    SELECT COUNT(*) INTO cek FROM tabel_shu WHERE tahun = NEW.tahun;

    IF cek > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SHU untuk tahun ini sudah dihitung';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_simpanan`
--

CREATE TABLE `tabel_simpanan` (
  `id_simpanan` int(11) NOT NULL,
  `id_anggota` int(11) DEFAULT NULL,
  `id_jenis` int(11) DEFAULT NULL,
  `jumlah` decimal(15,2) DEFAULT NULL,
  `tanggal` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_simpanan`
--

INSERT INTO `tabel_simpanan` (`id_simpanan`, `id_anggota`, `id_jenis`, `jumlah`, `tanggal`) VALUES
(1, 1, 1, 500000.00, '2025-09-15'),
(2, 2, 2, 250000.00, '2025-09-15'),
(3, 3, 3, 300000.00, '2025-09-15'),
(4, 4, 1, 500000.00, '2025-09-15'),
(5, 5, 3, 150000.00, '2025-09-15'),
(6, 1, 1, 1000.00, '2025-09-15'),
(7, 1, 1, 500000.00, '2025-09-15');

--
-- Triggers `tabel_simpanan`
--
DELIMITER $$
CREATE TRIGGER `trg_after_insert_simpanan` AFTER INSERT ON `tabel_simpanan` FOR EACH ROW BEGIN
    INSERT INTO tabel_kas (tanggal, sumber, jenis, jumlah, keterangan)
    VALUES (NEW.tanggal, 'Simpanan', 'masuk', NEW.jumlah, CONCAT('Simpanan Anggota ID: ', NEW.id_anggota));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_before_insert_simpanan` BEFORE INSERT ON `tabel_simpanan` FOR EACH ROW BEGIN
    IF NEW.jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Jumlah simpanan tidak boleh nol atau negatif';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_test_simpanan` AFTER INSERT ON `tabel_simpanan` FOR EACH ROW BEGIN
   INSERT INTO Tabel_Kas (tanggal, sumber, jenis, jumlah, keterangan)
   VALUES (CURDATE(), 'TEST', 'masuk', 12345, 'Cek trigger');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tabel_status_pinjaman`
--

CREATE TABLE `tabel_status_pinjaman` (
  `id_status` int(11) NOT NULL,
  `id_pinjaman` int(11) DEFAULT NULL,
  `angsuran_ke` int(11) DEFAULT NULL,
  `status` enum('Aktif','Lunas','Tertunda') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_status_pinjaman`
--

INSERT INTO `tabel_status_pinjaman` (`id_status`, `id_pinjaman`, `angsuran_ke`, `status`) VALUES
(1, 3, 0, 'Aktif'),
(2, 4, 0, 'Aktif'),
(3, 5, 0, 'Aktif'),
(4, 6, 0, 'Aktif'),
(5, 7, 0, 'Aktif'),
(6, 8, 0, 'Aktif'),
(7, 9, 0, 'Aktif');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_user`
--

CREATE TABLE `tabel_user` (
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','petugas','anggota') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_user`
--

INSERT INTO `tabel_user` (`username`, `password`, `role`) VALUES
('Boni', 'bonidana', 'anggota'),
('Gin', 'mbakrose', 'anggota'),
('Leca', 'lecalucu', 'admin'),
('Tha', 'retha', 'anggota'),
('Thom', 'Thomtua', 'anggota'),
('trix', 'trixciaja', 'anggota'),
('Yol', 'yola', 'petugas');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tabel_anggota`
--
ALTER TABLE `tabel_anggota`
  ADD PRIMARY KEY (`id_anggota`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `tabel_angsuran`
--
ALTER TABLE `tabel_angsuran`
  ADD PRIMARY KEY (`id_angsuran`),
  ADD KEY `id_pinjaman` (`id_pinjaman`);

--
-- Indexes for table `tabel_denda`
--
ALTER TABLE `tabel_denda`
  ADD PRIMARY KEY (`id_denda`),
  ADD KEY `id_angsuran` (`id_angsuran`);

--
-- Indexes for table `tabel_jenis_simpanan`
--
ALTER TABLE `tabel_jenis_simpanan`
  ADD PRIMARY KEY (`id_jenis`);

--
-- Indexes for table `tabel_kas`
--
ALTER TABLE `tabel_kas`
  ADD PRIMARY KEY (`id_kas`);

--
-- Indexes for table `tabel_pinjaman`
--
ALTER TABLE `tabel_pinjaman`
  ADD PRIMARY KEY (`id_pinjaman`),
  ADD KEY `id_anggota` (`id_anggota`);

--
-- Indexes for table `tabel_shu`
--
ALTER TABLE `tabel_shu`
  ADD PRIMARY KEY (`id_shu`),
  ADD UNIQUE KEY `tahun` (`tahun`);

--
-- Indexes for table `tabel_simpanan`
--
ALTER TABLE `tabel_simpanan`
  ADD PRIMARY KEY (`id_simpanan`),
  ADD KEY `id_anggota` (`id_anggota`),
  ADD KEY `id_jenis` (`id_jenis`);

--
-- Indexes for table `tabel_status_pinjaman`
--
ALTER TABLE `tabel_status_pinjaman`
  ADD PRIMARY KEY (`id_status`),
  ADD KEY `id_pinjaman` (`id_pinjaman`);

--
-- Indexes for table `tabel_user`
--
ALTER TABLE `tabel_user`
  ADD PRIMARY KEY (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tabel_anggota`
--
ALTER TABLE `tabel_anggota`
  MODIFY `id_anggota` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tabel_angsuran`
--
ALTER TABLE `tabel_angsuran`
  MODIFY `id_angsuran` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `tabel_denda`
--
ALTER TABLE `tabel_denda`
  MODIFY `id_denda` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tabel_jenis_simpanan`
--
ALTER TABLE `tabel_jenis_simpanan`
  MODIFY `id_jenis` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tabel_kas`
--
ALTER TABLE `tabel_kas`
  MODIFY `id_kas` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `tabel_pinjaman`
--
ALTER TABLE `tabel_pinjaman`
  MODIFY `id_pinjaman` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `tabel_shu`
--
ALTER TABLE `tabel_shu`
  MODIFY `id_shu` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `tabel_simpanan`
--
ALTER TABLE `tabel_simpanan`
  MODIFY `id_simpanan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `tabel_status_pinjaman`
--
ALTER TABLE `tabel_status_pinjaman`
  MODIFY `id_status` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tabel_anggota`
--
ALTER TABLE `tabel_anggota`
  ADD CONSTRAINT `tabel_anggota_ibfk_1` FOREIGN KEY (`username`) REFERENCES `tabel_user` (`username`);

--
-- Constraints for table `tabel_angsuran`
--
ALTER TABLE `tabel_angsuran`
  ADD CONSTRAINT `tabel_angsuran_ibfk_1` FOREIGN KEY (`id_pinjaman`) REFERENCES `tabel_pinjaman` (`id_pinjaman`);

--
-- Constraints for table `tabel_denda`
--
ALTER TABLE `tabel_denda`
  ADD CONSTRAINT `tabel_denda_ibfk_1` FOREIGN KEY (`id_angsuran`) REFERENCES `tabel_angsuran` (`id_angsuran`);

--
-- Constraints for table `tabel_pinjaman`
--
ALTER TABLE `tabel_pinjaman`
  ADD CONSTRAINT `tabel_pinjaman_ibfk_1` FOREIGN KEY (`id_anggota`) REFERENCES `tabel_anggota` (`id_anggota`);

--
-- Constraints for table `tabel_simpanan`
--
ALTER TABLE `tabel_simpanan`
  ADD CONSTRAINT `tabel_simpanan_ibfk_1` FOREIGN KEY (`id_anggota`) REFERENCES `tabel_anggota` (`id_anggota`),
  ADD CONSTRAINT `tabel_simpanan_ibfk_2` FOREIGN KEY (`id_jenis`) REFERENCES `tabel_jenis_simpanan` (`id_jenis`);

--
-- Constraints for table `tabel_status_pinjaman`
--
ALTER TABLE `tabel_status_pinjaman`
  ADD CONSTRAINT `tabel_status_pinjaman_ibfk_1` FOREIGN KEY (`id_pinjaman`) REFERENCES `tabel_pinjaman` (`id_pinjaman`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
