🍔 Çevrimiçi Yemek Sipariş Platformu Veritabanı Tasarımı

Bu proje, Veritabanı Yönetim Sistemleri (VTYS-1) dersi dönem projesi kapsamında geliştirilmiştir. Gerçek dünya senaryolarına uygun, ölçeklenebilir ve 3. Normal Form'a (3NF) tam uyumlu bir ilişkisel veritabanı (RDBMS) mimarisi tasarlanmıştır.

## 📌 Proje Amacı ve Kapsamı
Sistem; müşteri, restoran, kurye, menü ve sipariş detayları gibi klasik bir yemek sipariş platformunun tüm temel gereksinimlerini barındırmaktadır. Geleneksel yapıya ek olarak projede **"Askıda Yemek"** sosyal sorumluluk modülü kurgulanmıştır.

### 🌟 Özel Modül: "Askıda Yemek" Havuzu
Projede, hayırsever müşterilerin kimliğini gizleyerek (anonim) veya açıkça bağış yapabileceği bir havuz sistemi tasarlanmıştır. 
* Her restoranın kendi "Askıda Yemek Havuzu" bulunmaktadır.
* İhtiyaç sahibi olarak doğrulanmış müşteriler, bu havuzda bakiye olduğu sürece ücretsiz sipariş verebilmektedir.
* Bakiye düşme, ciro hesaplama ve havuz güncellemeleri tamamen **SQL Trigger'ları** ile otomatize edilmiştir.

## 🛠️ Kullanılan Teknolojiler ve Veritabanı Nesneleri
* **Veritabanı Motoru:** Microsoft SQL Server (T-SQL)
* **Veri Tanımlama (DDL):** Primary Key, Foreign Key (Referential Integrity), UNIQUE, NOT NULL
* **Kısıtlamalar (Constraints):** CHECK kısıtlamaları (Örn: Fiyat > 0, Puan BETWEEN 0 AND 5)
* **Tetikleyiciler (Triggers):** Sipariş teslim edildiğinde ciro artıran ve askıda yemek bakiyesini düşüren otomatik işlemler.
* **Görünümler (Views):** Karmaşık JOİN işlemlerini basitleştiren sanal tablolar (Örn: `vw_AskidaYemekHavuzDurumu`).
* **İleri Düzey Sorgular:** GROUP BY, HAVING, INNER/LEFT JOIN ve NOT EXISTS içeren analitik alt sorgular.

## 🤖 Yapay Zeka (AI) Beyanı ve Dürüstlük Raporu
Bu projenin geliştirilme sürecinde yapay zeka araçları "asistan" rolünde kullanılmıştır:
* **Tasarım ve Mimari:** "Askıda Yemek" modülünün mantıksal kurgusu ve tablolar arası (Foreign Key) ilişkiler yapay zeka asistanları ile tartışılarak geliştirilmiştir.
* **Mock Data (Test Verisi):** Sistemin analitik sorgularını test edebilmek amacıyla gereken 90+ sipariş hareketi ve rastgele test verileri, SQL `WHILE` döngüsü yardımıyla AI araçlarına ürettirilmiştir.
* **Sorumluluk:** Üretilen tüm T-SQL kodları, kısıtlamalar ve tetikleyiciler tarafımca satır satır incelenmiş, test edilmiş ve çalışma mantığı tamamen anlaşılmıştır. Projenin mimari sorumluluğu bana aittir.

## 🚀 Kurulum
1. `vybs_proje.sql` dosyasını indirin.
2. SQL Server Management Studio (SSMS) veya Azure Data Studio üzerinden açın.
3. Kodu çalıştırarak (Execute) `YemekSiparisDB` veritabanını ve tüm test verilerini tek seferde oluşturabilirsiniz.
