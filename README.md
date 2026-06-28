# 🍽️ Sukran-App (SaaS Smart QR Menu & AI Ordering System)

[![License: MIT](https://shields.io)](https://opensource.org)
[![Technology](https://shields.io)](#)

[TR] Sukran-App; restoranlar ve kafeler için geliştirilmiş, arka planda yerel yapay zeka modelleriyle (Ollama/Qwen) güçlendirilmiş, yüksek performanslı ve ölçeklenebilir bir SaaS Akıllı QR Menü ve Sipariş Yönetim platformudur.

[EN] Sukran-App is a high-performance, scalable SaaS Smart QR Menu and Order Management platform developed for restaurants and cafes, powered by local AI models (Ollama/Qwen) in the backend.

---

## 🚀 Teknolojik Yığın (Tech Stack & Ecosystem)

Bu proje, modern yazılım mimarileri (Domain-Driven Design - DDD) kullanılarak cross-platform mimaride uçtan uca tek bir mühendis tarafından geliştirilmiştir:

*   **Backend & Core API:** C# (.NET Core Web API) - Robust, event-driven microservices architecture.
*   **Mobile App (Client & QR Interface):** Dart (Flutter) - Cross-platform mobile architecture.
*   **Admin Panel & Web Management:** JavaScript / TypeScript (React / Vue) - Dynamic SaaS dashboard.
*   **AI Integration:** Ollama (Qwen 2.5/3.5 LLM models) - Local AI orchestration for smart recommendations and structured JSON outputs.

---

## 🛠️ Mimari Yaklaşımlar (Architectural Patterns)

*   **Domain-Driven Design (DDD):** Karmaşık iş mantıklarını ve veri modellerini (Sipariş, Menü, Restoran Konfigürasyonları) ayrıştırmak için katmanlı temiz mimari (Clean Architecture).
*   **Event-Driven & Microservices Ready:** Gelecekteki yüksek trafik yüklerini (SaaS ölçeklemesinde anlık binlerce QR okuma ve sipariş isteği) kaldırabilecek asenkron veri akışları.
*   **Local LLM Integration:** Harici API bağımlılıklarını (ve fahiş token maliyetlerini) sıfırlamak amacıyla backend katmanına gömülü lokal **Ollama (Qwen)** entegrasyonu. Sistem, kullanıcı komutlarını akıllıca analiz ederek yapılandırılmış (structured) JSON verileri üretir.

---

## ⚠️ Önemli Sistem Gereksinimleri (Critical Infrastructure Notice)

Bu proje, sıradan paylaşımlı (shared) web hosting paketlerinde **ÇALIŞTIRILAMAZ**. Ağır veritabanı şemaları, mikroservis yapıları ve arka plandaki yerel dil modeli (LLM) işlem yükü sebebiyle projenin stabil çalışması için minimum aşağıdaki donanım gereksinimleri şarttır:

*   **İşlemci (CPU):** Minimum 4-8 vCPU (Yapay zeka çıkarımları için optimize edilmiş)
*   **Bellek (RAM):** Minimum 16 GB RAM (Ollama ve Qwen modellerinin bellekte kilitlenmeden çalışması için)
*   **Depolama (SSD):** NVMe tabanlı hızlı disk yapısı.

> **Not:** Yetersiz altyapı ve yetersiz sunucu (hosting) seçimi durumunda sistemin kilitlenmesi, siparişlerin düşmemesi, veritabanı tıkanmaları veya `Out of Memory (OOM)` hataları tamamen kaçınılmazdır. Bu durum yazılım mimarisiyle ilgili değil, tamamen donanım bütçesi yetersizliğiyle ilgilidir.

---

## 📂 Klasör Yapısı (Project Structure)

```text
├── android/               # Flutter native android configuration
├── assets/ branding/      # Visual assets, branding and icons
├── backend/               # C# .NET Core backend & microservices code
├── lib/                   # Flutter core framework logic (Dart)
└── web/                   # Web-based SaaS panel (JavaScript/React)
```

---

## 📜 Lisans (License)

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details. 
*Bu proje açık kaynak topluluğuna bir katkı olarak MIT lisansı ile dağıtılmaktadır. Herkes serbestçe kullanabilir ve geliştirebilir, ancak yetersiz sunucu altyapılarından kaynaklanan çökmelerden yazılımcı yasal veya manevi olarak sorumlu tutulamaz.*

---
**Developer:** [Mahmut Sibal](https://github.com/MahmutSibal)  
**Organization:** YıldızTech
