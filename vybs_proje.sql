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
