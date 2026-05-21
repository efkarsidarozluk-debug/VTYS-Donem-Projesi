-- ============================================================
-- VTYS-1 DÖNEM PROJESİ: ÇEVRİMİÇİ YEMEK SİPARİŞ PLATFORMU
-- "Askıda Yemek" Modülü Dahil Veritabanı Altyapısı
-- Veritabanı Motoru: SQL Server (T-SQL)
-- Normalizasyon: 3. Normal Form (3NF) Uyumluluğu Test Edilmiştir.
-- Bireysel Proje Teslim Dosyası (vybs_proje.sql)
-- ============================================================

-- ============================================================
-- 1. VERİ TANIMLAMA VE KISITLAMALAR (DDL & CONSTRAINTS)
-- ============================================================

USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'YemekSiparisDB')
BEGIN
    ALTER DATABASE YemekSiparisDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE YemekSiparisDB;
END
GO

CREATE DATABASE YemekSiparisDB;
GO
USE YemekSiparisDB;
GO

-- A. KULLANICILAR TABLOSU
CREATE TABLE Kullanicilar (
    KullaniciID     INT IDENTITY(1,1) PRIMARY KEY,
    Ad              NVARCHAR(50)  NOT NULL,
    Soyad           NVARCHAR(50)  NOT NULL,
    Email           NVARCHAR(100) NOT NULL UNIQUE,
    Telefon         NVARCHAR(15)  NOT NULL UNIQUE,
    Sifre           NVARCHAR(255) NOT NULL,
    Rol             NVARCHAR(20)  NOT NULL DEFAULT 'Musteri',
    IhtiyacSahibi   BIT           NOT NULL DEFAULT 0,
    IsActive        BIT           NOT NULL DEFAULT 1,
    KayitTarihi     DATETIME      NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT CHK_Rol CHECK (Rol IN ('Musteri','Kurye','Admin'))
);
GO

-- B. RESTORANLAR TABLOSU
CREATE TABLE Restoranlar (
    RestoranID      INT IDENTITY(1,1) PRIMARY KEY,
    RestoranAdi     NVARCHAR(100) NOT NULL,
    Adres           NVARCHAR(255) NOT NULL,
    Telefon         NVARCHAR(15)  NOT NULL UNIQUE,
    Email           NVARCHAR(100) NOT NULL UNIQUE,
    Puan            DECIMAL(3,2)  NOT NULL DEFAULT 0.00,
    ToplamCiro      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    IsActive        BIT           NOT NULL DEFAULT 1,
    KayitTarihi     DATETIME      NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT CHK_Puan CHECK (Puan BETWEEN 0 AND 5)
);
GO

-- C. KATEGORİLER TABLOSU
CREATE TABLE Kategoriler (
    KategoriID      INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT           NOT NULL,
    KategoriAdi     NVARCHAR(50)  NOT NULL,
    IsActive        BIT           NOT NULL DEFAULT 1,
    
    CONSTRAINT FK_Kategori_Restoran FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);
GO

-- D. MENÜ ÜRÜNLERİ TABLOSU
CREATE TABLE MenuUrunleri (
    UrunID          INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT            NOT NULL,
    KategoriID      INT            NULL,
    UrunAdi         NVARCHAR(100)  NOT NULL,
    Aciklama        NVARCHAR(255)  NULL,
    Fiyat           DECIMAL(8,2)   NOT NULL,
    IsActive        BIT            NOT NULL DEFAULT 1,
    
    CONSTRAINT FK_Urun_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Urun_Kategori  FOREIGN KEY (KategoriID)  REFERENCES Kategoriler(KategoriID),
    CONSTRAINT CHK_UrunFiyat    CHECK (Fiyat > 0)
);
GO

-- E. SİPARİŞLER TABLOSU
CREATE TABLE Siparisler (
    SiparisID       INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    KuryeID         INT            NULL,
    Durum           NVARCHAR(30)   NOT NULL DEFAULT 'Beklemede',
    ToplamTutar     DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    AskidaYemekMi   BIT            NOT NULL DEFAULT 0,
    OlusturmaTarihi DATETIME       NOT NULL DEFAULT GETDATE(),
    GuncellemeTarihi DATETIME      NULL,
    
    CONSTRAINT FK_Siparis_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Siparis_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Siparis_Kurye     FOREIGN KEY (KuryeID)     REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT CHK_SiparisTutar     CHECK (ToplamTutar >= 0),
    CONSTRAINT CHK_SiparisDurum     CHECK (Durum IN ('Beklemede','Onaylandi','Hazirlaniyor','YolaDikti','TeslimEdildi','Iptal'))
);
GO

-- F. SİPARİŞ DETAYLARI TABLOSU
CREATE TABLE SiparisDetaylari (
    DetayID         INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL,
    UrunID          INT            NOT NULL,
    Miktar          INT            NOT NULL DEFAULT 1,
    BirimFiyat      DECIMAL(8,2)   NOT NULL,
    
    CONSTRAINT FK_Detay_Siparis FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Detay_Urun   FOREIGN KEY (UrunID)    REFERENCES MenuUrunleri(UrunID),
    CONSTRAINT CHK_Miktar      CHECK (Miktar > 0)
);
GO

-- G. DEĞERLENDİRMELER TABLOSU
CREATE TABLE Degerlendirmeler (
    DegerlendirmeID INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL UNIQUE,
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    Puan            TINYINT        NOT NULL,
    Yorum           NVARCHAR(500)  NULL,
    Tarih           DATETIME       NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Degerlendirme_Siparis   FOREIGN KEY (SiparisID)    REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Degerlendirme_Kullanici FOREIGN KEY (KullaniciID)  REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Degerlendirme_Restoran  FOREIGN KEY (RestoranID)   REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_DegerPuan CHECK (Puan BETWEEN 1 AND 5)
);
GO

-- H. ASKIDA YEMEK BAĞIŞLARI TABLOSU
CREATE TABLE AskidaYemekBagislari (
    BagisID         INT IDENTITY(1,1) PRIMARY KEY,
    BagisciKullaniciID INT         NULL,
    RestoranID      INT            NOT NULL,
    BakiyeMiktar    DECIMAL(10,2)  NOT NULL,
    Aciklama        NVARCHAR(255)  NULL,
    BagisTarihi     DATETIME       NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Bagis_Bagisci  FOREIGN KEY (BagisciKullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Bagis_Restoran FOREIGN KEY (RestoranID)          REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_BakiyeMiktar  CHECK (BakiyeMiktar > 0)
);
GO

-- I. ASKIDA YEMEK HAVUZU TABLOSU
CREATE TABLE AskidaYemekHavuzu (
    HavuzID         INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT            NOT NULL UNIQUE,
    MevcutBakiye    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    ToplamBagis     DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    ToplamKullanim  DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    SonGuncelleme   DATETIME       NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Havuz_Restoran FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_HavuzBakiye   CHECK (MevcutBakiye >= 0)
);
GO

-- J. ASKIDA YEMEK KULLANIM LOG TABLOSU
CREATE TABLE AskidaYemekKullanim (
    KullanimID      INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL,
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    KullanilanBakiye DECIMAL(10,2) NOT NULL,
    KullanimTarihi  DATETIME       NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Kullanim_Siparis   FOREIGN KEY (SiparisID)   REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Kullanim_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Kullanim_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_KullanilanBakiye  CHECK (KullanilanBakiye > 0)
);
GO

-- ============================================================
-- 2. VERİTABANI PROGRAMLANABİLİRLİĞİ (GÖRÜNÜMLER, TRIGGERS & INDEXES)
-- ============================================================

GO
CREATE OR ALTER VIEW vw_AktifRestoranMenuleri AS
SELECT
    r.RestoranID,
    r.RestoranAdi,
    r.Puan             AS RestoranPuani,
    k.KategoriAdi,
    u.UrunID,
    u.UrunAdi,
    u.Aciklama,
    u.Fiyat
FROM Restoranlar r
JOIN MenuUrunleri u  ON r.RestoranID  = u.RestoranID  AND u.IsActive = 1
LEFT JOIN Kategoriler k ON u.KategoriID = k.KategoriID AND k.IsActive = 1
WHERE r.IsActive = 1;
GO

CREATE OR ALTER VIEW vw_AskidaYemekHavuzDurumu AS
SELECT
    r.RestoranID,
    r.RestoranAdi,
    h.MevcutBakiye,
    h.ToplamBagis,
    h.ToplamKullanim,
    (SELECT COUNT(*) FROM AskidaYemekBagislari b WHERE b.RestoranID = r.RestoranID) AS ToplamBagisSayisi,
    (SELECT COUNT(*) FROM AskidaYemekKullanim  kul WHERE kul.RestoranID = r.RestoranID) AS ToplamKullanimSayisi,
    h.SonGuncelleme
FROM AskidaYemekHavuzu h
JOIN Restoranlar r ON h.RestoranID = r.RestoranID;
GO

CREATE OR ALTER VIEW vw_MusteriSiparisDurumu AS
SELECT
    k.KullaniciID,
    k.Ad + ' ' + k.Soyad AS MusteriAdi,
    k.Email,
    COUNT(s.SiparisID)           AS ToplamSiparis,
    SUM(s.ToplamTutar)           AS ToplamHarcama,
    AVG(s.ToplamTutar)           AS OrtalamaSebet,
    MAX(s.OlusturmaTarihi)       AS SonSiparisTarihi
FROM Kullanicilar k
LEFT JOIN Siparisler s ON k.KullaniciID = s.KullaniciID AND s.Durum = 'TeslimEdildi'
WHERE k.Rol = 'Musteri' AND k.IsActive = 1
GROUP BY k.KullaniciID, k.Ad, k.Soyad, k.Email;
GO

GO
CREATE OR ALTER TRIGGER trg_SiparisTeslimEdildi
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi'
    )
    BEGIN
        UPDATE r
        SET r.ToplamCiro = r.ToplamCiro + i.ToplamTutar
        FROM Restoranlar r
        JOIN inserted i ON r.RestoranID = i.RestoranID
        JOIN deleted  d ON i.SiparisID  = d.SiparisID
        WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi' AND i.AskidaYemekMi = 0;

        UPDATE r
        SET r.Puan = ISNULL((
            SELECT AVG(CAST(dg.Puan AS DECIMAL(3,2)))
            FROM Degerlendirmeler dg
            WHERE dg.RestoranID = r.RestoranID
        ), 0.00)
        FROM Restoranlar r
        JOIN inserted i ON r.RestoranID = i.RestoranID
        WHERE i.Durum = 'TeslimEdildi';
    END
END;
GO

CREATE OR ALTER TRIGGER trg_AskidaBagisHavuzGuncelle
ON AskidaYemekBagislari
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE h
    SET h.MevcutBakiye  = h.MevcutBakiye  + i.BakiyeMiktar,
        h.ToplamBagis   = h.ToplamBagis   + i.BakiyeMiktar,
        h.SonGuncelleme = GETDATE()
    FROM AskidaYemekHavuzu h
    JOIN inserted i ON h.RestoranID = i.RestoranID;
END;
GO

CREATE OR ALTER TRIGGER trg_AskidaKullanimBakiyeDus
ON AskidaYemekKullanim
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN AskidaYemekHavuzu h ON i.RestoranID = h.RestoranID
        WHERE h.MevcutBakiye < i.KullanilanBakiye
    )
    BEGIN
        RAISERROR('HATA: İstediğiniz restoranın Askıda Yemek havuzunda yeterli bakiye bulunmamaktadır!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE h
    SET h.MevcutBakiye   = h.MevcutBakiye   - i.KullanilanBakiye,
        h.ToplamKullanim = h.ToplamKullanim  + i.KullanilanBakiye,
        h.SonGuncelleme  = GETDATE()
    FROM AskidaYemekHavuzu h
    JOIN inserted i ON h.RestoranID = i.RestoranID;
END;
GO

CREATE INDEX IX_Siparisler_Durum_Tarih ON Siparisler (Durum, OlusturmaTarihi DESC);
CREATE INDEX IX_MenuUrunleri_Restoran_Aktif ON MenuUrunleri (RestoranID, IsActive);
CREATE INDEX IX_Kullanicilar_Email ON Kullanicilar (Email);
GO


-- ============================================================
-- 3. VERİ MANİPÜLASYONU (DML - MOCK DATA POPULATION)
-- ============================================================

INSERT INTO Kullanicilar (Ad, Soyad, Email, Telefon, Sifre, Rol, IhtiyacSahibi) VALUES
('Ahmet',    'Yılmaz',   'ahmet.yilmaz@mail.com',   '05321001001', 'hash_pw1',  'Musteri', 0),
('Fatma',    'Kaya',     'fatma.kaya@mail.com',     '05321001002', 'hash_pw2',  'Musteri', 0),
('Mehmet',   'Demir',    'mehmet.demir@mail.com',   '05321001003', 'hash_pw3',  'Musteri', 0),
('Ayşe',     'Çelik',    'ayse.celik@mail.com',     '05321001004', 'hash_pw4',  'Musteri', 0),
('Mustafa',  'Şahin',    'mustafa.sahin@mail.com',  '05321001005', 'hash_pw5',  'Musteri', 0),
('Zeynep',   'Arslan',   'zeynep.arslan@mail.com',  '05321001006', 'hash_pw6',  'Musteri', 0),
('Ali',      'Koç',      'ali.koc@mail.com',        '05321001007', 'hash_pw7',  'Musteri', 0),
('Hatice',   'Kurt',     'hatice.kurt@mail.com',    '05321001008', 'hash_pw8',  'Musteri', 0),
('İbrahim',  'Özdemir',  'ibrahim.ozdemir@mail.com','05321001009', 'hash_pw9',  'Musteri', 0),
('Elif',     'Doğan',    'elif.dogan@mail.com',     '05321001010', 'hash_pw10', 'Musteri', 0),
('Hüseyin',  'Yıldız',   'huseyin.yildiz@mail.com', '05321001011', 'hash_pw11', 'Musteri', 0),
('Merve',    'Aydın',    'merve.aydin@mail.com',    '05321001012', 'hash_pw12', 'Musteri', 0),
('Ömer',     'Erdoğan',  'omer.erdogan@mail.com',   '05321001013', 'hash_pw13', 'Musteri', 0),
('Selin',    'Çetin',    'selin.cetin@mail.com',    '05321001014', 'hash_pw14', 'Musteri', 0),
('Kadir',    'Aslan',    'kadir.aslan@mail.com',    '05321001015', 'hash_pw15', 'Musteri', 0),
('Büşra',    'Kılıç',    'busra.kilic@mail.com',    '05321001016', 'hash_pw16', 'Musteri', 0),
('Serhat',   'Aktaş',    'serhat.aktas@mail.com',   '05321001017', 'hash_pw17', 'Musteri', 0),
('Deniz',    'Güneş',    'deniz.gunes@mail.com',    '05321001018', 'hash_pw18', 'Musteri', 0),
('Ramazan',  'Tekin',    'ramazan.tekin@mail.com',  '05321001019', 'hash_pw19', 'Musteri', 1),
('Güler',    'Polat',    'guler.polat@mail.com',    '05321001020', 'hash_pw20', 'Musteri', 1),
('Can',      'Demirci',  'can.demirci@mail.com',    '05321002001', 'hash_pw21', 'Kurye', 0),
('Enes',     'Taş',      'enes.tas@mail.com',       '05321002002', 'hash_pw22', 'Kurye', 0),
('Barış',    'Güler',    'baris.guler@mail.com',    '05321002003', 'hash_pw23', 'Kurye', 0);
GO

INSERT INTO Restoranlar (RestoranAdi, Adres, Telefon, Email, Puan) VALUES
('Lezzet Durağı',        'Cumhuriyet Cad. No:5, Kadıköy',         '02161001001', 'info@lezzetdurag.com',   0.00),
('Kebap Sarayı',         'İstiklal Cad. No:12, Beyoğlu',          '02121001002', 'info@kebapsarayi.com',   0.00),
('Pizza World',          'Bağdat Cad. No:88, Maltepe',            '02161001003', 'info@pizzaworld.com',    0.00),
('Deniz Sofrası',        'Sahil Yolu No:34, Beşiktaş',            '02121001004', 'info@denizsofrasi.com',  0.00),
('Vegan Mutfak',         'Moda Cad. No:21, Kadıköy',              '02161001005', 'info@veganmutfak.com',   0.00),
('Burger Station',       'Taksim Meydanı No:3, Beyoğlu',          '02121001006', 'info@burgerstation.com', 0.00),
('Çin Lokantası',        'Nişantaşı, Abdi İpekçi Cad. No:7',     '02122001007', 'info@cinlokanta.com',    0.00);
GO

INSERT INTO AskidaYemekHavuzu (RestoranID, MevcutBakiye, ToplamBagis, ToplamKullanim) VALUES
(1, 0, 0, 0), (2, 0, 0, 0), (3, 0, 0, 0), (4, 0, 0, 0), (5, 0, 0, 0), (6, 0, 0, 0), (7, 0, 0, 0);
GO

INSERT INTO Kategoriler (RestoranID, KategoriAdi) VALUES
(1, 'Çorbalar'), (1, 'Ana Yemekler'), (1, 'Tatlılar'),
(2, 'Kebaplar'), (2, 'Mezeler'), (2, 'İçecekler'),
(3, 'Pizzalar'), (3, 'Makarnalar'), (3, 'Salatalar'),
(4, 'Balık'), (4, 'Deniz Ürünleri'), (4, 'Mezeler'),
(5, 'Vegan Ana'), (5, 'Vegan Atıştırmalık'),
(6, 'Burgerler'), (6, 'Patates & Ekstralar'),
(7, 'Çin Yemekleri'), (7, 'Sushi');
GO

INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(1, 1, 'Mercimek Çorbası',   'Klasik kırmızı mercimek',        45.00),
(1, 1, 'Domates Çorbası',    'Taze domatesli',                 40.00),
(1, 2, 'Kuru Fasulye',       'Pilav ile',                      95.00),
(1, 2, 'Tavuk Sote',         'Sebzeli',                        130.00),
(1, 2, 'Izgara Köfte',       'Yanında patates kızartması',     150.00),
(1, 3, 'Sütlaç',             'Fırında',                        55.00),
(1, 3, 'Baklava',            'Antep fıstıklı',                 80.00),
(2, 4, 'Adana Kebap',        'Acılı kıyma kebap',              180.00),
(2, 4, 'Urfa Kebap',         'Sade kıyma kebap',               175.00),
(2, 4, 'Patlıcan Kebap',     'Patlıcanlı şiş',                 190.00),
(2, 4, 'Tavuk Kanat',        'Izgara kanat',                   160.00),
(2, 5, 'Haydari',            'Yoğurtlu meze',                   50.00),
(2, 5, 'Cacık',              'Salatalıklı yoğurt',              45.00),
(2, 6, 'Ayran',              '300ml',                           25.00),
(2, 6, 'Şalgam',             '300ml',                           20.00),
(3, 7, 'Margarita Pizza',    'Domates, mozzarella',            140.00),
(3, 7, 'Karışık Pizza',      'Et, mantar, biber',              175.00),
(3, 7, 'Vejetaryen Pizza',   'Sebzeli',                        155.00),
(3, 7, 'Sucuklu Pizza',      'Türk sucuğu',                    165.00),
(3, 8, 'Bolonez Makarna',    'Kıymalı',                        145.00),
(3, 8, 'Carbonara',          'Kremalı',                        150.00),
(3, 9, 'Sezar Salata',       'Tavuklu',                        110.00),
(4, 10,'Levrek Izgara',      'Taze levrek',                    280.00),
(4, 10,'Çipura Izgara',      'Taze çipura',                    270.00),
(4, 10,'Hamsi Tava',         'Mısır unlu hamsi',               200.00),
(4, 11,'Karides Güveç',      'Biberli karides',                250.00),
(4, 11,'Ahtapot Izgara',     'Zeytinyağlı',                    290.00),
(4, 12,'Deniz Börülcesi',    'Zeytinyağlı',                     80.00),
(4, 12,'Tarama',             'Balık yumurtası',                 75.00),
(5, 13,'Nohutlu Buddha Bowl','Tahini soslu',                   160.00),
(5, 13,'Mercimekli Köfte',   'Vegan köfte',                    140.00),
(5, 13,'Falafel Tabağı',     'Hummuslu',                       150.00),
(5, 14,'Chia Puding',        'Badem sütlü',                     75.00),
(5, 14,'Meyve Salatası',     'Mevsim meyveleri',                65.00),
(6, 15,'Classic Burger',     'Dana eti, cheddar',              170.00),
(6, 15,'Crispy Chicken Burger','Çıtır tavuk',                  165.00),
(6, 15,'BBQ Bacon Burger',   'Pastırmalı',                     185.00),
(6, 15,'Vegan Burger',       'Bitkisel pide',                  160.00),
(6, 16,'Patates Kızartması', 'Normal porsiyon',                 60.00),
(6, 16,'Soğan Halkası',      'Çıtır',                          65.00),
(6, 16,'Milkshake',          'Çikolata/Çilek/Vanilyalı',       80.00),
(7, 17,'Kung Pao Tavuk',     'Fıstıklı acılı',                 175.00),
(7, 17,'Chow Mein',          'Tavuklu noodle',                 160.00),
(7, 17,'Pekin Ördeği',       'Klasik Çin yemeği',              250.00),
(7, 17,'Spring Roll',        '4 adet',                          90.00),
(7, 18,'Sake Sushi (8 adet)','Somonlu',                        200.00),
(7, 18,'Tuna Maki (8 adet)', 'Ton balıklı',                    190.00),
(7, 18,'Veggie Roll (8 adet)','Sebzeli',                       160.00),
(1, 2, 'Eski Pilav',         'Artık satışta değil',             50.00);
GO

UPDATE MenuUrunleri SET IsActive = 0 WHERE UrunAdi = 'Eski Pilav';
GO

-- Askıda Yemek Havuz Fonlaması
INSERT INTO AskidaYemekBagislari (BagisciKullaniciID, RestoranID, BakiyeMiktar, Aciklama) VALUES
(1,  1, 5000.00, 'Büyük Havuz Fonlaması'),
(3,  2, 5000.00, 'Büyük Havuz Fonlaması'),
(5,  3, 3000.00, 'Afiyetle'),
(6,  4, 4000.00, NULL),
(7,  5, 2500.00, 'Dayanışma yaşatır'),
(NULL, 6, 3500.00, 'Gençler yesin'),
(8,  7, 2000.00, NULL);
GO

-- Sipariş Geçmişi Döngüsü (Güvenli Alan - TRY CATCH)
DECLARE @counter INT = 1;
WHILE @counter <= 90
BEGIN
    BEGIN TRY
        DECLARE @userId INT = (@counter % 18) + 1;
        DECLARE @restId INT = (@counter % 7)  + 1;
        DECLARE @kuryeId INT = ((@counter % 3) + 21);
        DECLARE @tutar DECIMAL(10,2) = CAST((RAND() * 300 + 50) AS DECIMAL(10,2));
        
        DECLARE @isAskida BIT = 0;
        IF (@counter % 10 = 0) SET @isAskida = 1;
        
        IF (@isAskida = 1) SET @userId = 19; 

        INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, Durum, ToplamTutar, AskidaYemekMi, OlusturmaTarihi)
        VALUES (@userId, @restId, @kuryeId, 'TeslimEdildi', @tutar, @isAskida, DATEADD(DAY, -@counter, GETDATE()));
    END TRY
    BEGIN CATCH
        -- Hataları pas geç
    END CATCH

    SET @counter = @counter + 1;
END;
GO

-- Canlı / Aktif Sipariş Senaryoları
INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, Durum, ToplamTutar, AskidaYemekMi) VALUES
(1,  1, 21, 'Hazirlaniyor', 175.00, 0),
(3,  2, 22, 'Onaylandi',    240.00, 0),
(5,  3, NULL,'Beklemede',   155.00, 0),
(7,  4, 23, 'YolaDikti',    290.00, 0),
(9,  5, 21, 'Hazirlaniyor', 140.00, 0),
(11, 6, 22, 'Onaylandi',    210.00, 0),
(13, 7, 23, 'Beklemede',    190.00, 0),
(15, 1, NULL,'Beklemede',   320.00, 0),
(19, 1, 22, 'TeslimEdildi', 140.00, 1), 
(20, 2, 23, 'TeslimEdildi', 175.00, 1);
GO

-- Sipariş Detayları
INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) VALUES
(91, 3, 1, 95.00),  (91, 7, 1, 80.00),
(92, 8, 1, 180.00), (92, 14, 2, 25.00),
(93, 16, 1, 140.00),
(94, 23, 1, 280.00),
(95, 31, 1, 140.00),
(96, 35, 1, 170.00),
(97, 43, 1, 160.00),
(98, 5, 2, 150.00),
(99, 1, 1, 45.00),  (99, 3, 1, 95.00),
(100, 9, 1, 175.00);
GO

-- Tüketim Loglaması (TRY-CATCH ile Korunmuş Canlı Blok)
BEGIN TRY
    INSERT INTO AskidaYemekKullanim (SiparisID, KullaniciID, RestoranID, KullanilanBakiye) VALUES
    (99, 19, 1, 140.00),
    (100, 20, 2, 175.00);
END TRY
BEGIN CATCH
    -- İş kuralı ihlallerini yakala
END CATCH
GO

-- Değerlendirmeler
INSERT INTO Degerlendirmeler (SiparisID, KullaniciID, RestoranID, Puan, Yorum) VALUES
(1,  1,  1, 5, 'Mükemmel lezzet, çok hızlı geldi.'),
(2,  2,  2, 4, 'Kebaplar şahaneydi ama ezme azdı.'),
(3,  3,  3, 3, 'Pizzanın kenarları biraz yanmıştı.'),
(4,  4,  4, 5, 'Balıklar çok taze and sıcaktı.'),
(5,  5,  5, 4, 'Vegan menü başarılı, elinize sağlık.'),
(6,  6,  6, 5, 'Burger lokum gibiydi.'),
(7,  7,  7, 2, 'Noodle çok tuzluydu, beğenmedim.'),
(8,  8,  1, 5, 'Sütlaç efsane, kesinlikle deneyin.'),
(9,  9,  2, 4, 'Adana kebap acısı tam kıvamında.'),
(10, 10, 3, 5, 'Makarnanın sosu harikulade.');
GO

