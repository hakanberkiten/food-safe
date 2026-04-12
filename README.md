# Gemma 4 Food-Safe AI

AI destekli, kişiselleştirilmiş gıda toksikoloji ajanı. Bu proje, ürün etiket fotoğraflarını analiz eder, içindekiler listesini yapılandırılmış veriye dönüştürür, bilimsel kaynaklarla RAG üzerinden çapraz sorgular ve kullanıcının sağlık profiline göre risk raporu üretir.

Bu repo, **The Gemma 4 Good Hackathon** için geliştirilen backend ve RAG altyapısını içerir.

## Problem

Market ürünlerinin arka yüzündeki içerik listeleri çoğu kullanıcı için:

- zor okunur
- teknik terimlerle doludur
- sağlık durumuna göre yorumlanması zordur
- güvenilir bilimsel kaynaklarla ilişkilendirilmez

Food-Safe AI bu problemi üç adımda çözer:

1. Etiket fotoğrafını okur.
2. İçerikleri bilimsel dökümanlarla eşleştirir.
3. Kullanıcının sağlık profiline göre kişiselleştirilmiş risk analizi üretir.

## Çözüm Özeti

Sistem, `Vision -> RAG -> Reasoning` akışıyla çalışır:

```mermaid
flowchart LR
    A["Etiket Fotoğrafı"] --> B["Vision Stage<br/>JSON ingredient extraction"]
    B --> C["RAG Stage<br/>Chroma + PDF toxicology retrieval"]
    C --> D["Reasoning Stage<br/>Risk synthesis"]
    E["Kullanıcı Profili"] --> D
    D --> F["Risk Raporu"]
    D --> G["Sağlıklı Alternatifler"]
```

## Öne Çıkan Özellikler

- Multimodal etiket analizi
- Yapılandırılmış ingredient extraction
- Chroma destekli gerçek RAG akışı
- FDA / WHO tarzı PDF kaynaklardan retrieval
- Supabase PostgreSQL altyapısı
- Gemma-first, Gemini-fallback model yönlendirmesi
- Fallback kullanıldığında log ve response metadata takibi
- Kullanıcı profiline göre kişiselleştirilmiş risk değerlendirmesi
- High-risk durumda sağlıklı alternatif öneri akışı

## Mimari

### 1. Vision

Etiket görseli Google GenAI üzerinden çalıştırılır ve düz metin yerine yapılandırılmış JSON elde edilir.

Örnek hedef çıktı:

```json
{
  "product_name": "Example Product",
  "ingredients": ["E211", "maltodextrin", "aspartame"],
  "claims": ["sugar free"],
  "allergens": ["milk"],
  "cross_contamination_warnings": ["may contain nuts"],
  "detected_language": "tr",
  "raw_text": "Tam OCR çıktısı"
}
```

### 2. RAG

PDF bilimsel dökümanları chunk’lanır ve Chroma koleksiyonuna yüklenir. Sorgu sırasında her ingredient için benzer toksikoloji parçaları getirilir.

Şu anda iki katmanlı yapı var:

- Birincil kaynak: Chroma Cloud / Chroma local collection
- Fallback kaynak: `backend/knowledge/ecodes.json`

### 3. Reasoning

Reasoning aşaması şu girdileri birleştirir:

- Vision çıktısı
- RAG ile dönen toksikoloji kanıtları
- Kullanıcı sağlık profili

Sonuçta:

- genel risk seviyesi
- ingredient bazlı değerlendirme
- bilimsel dayanaklar
- önerilen sonraki adımlar
- gerekirse alternatif ürün önerileri

üretilir.

## Model Stratejisi

Sistem önce Gemma modelini dener. Eğer ilgili model senin Google AI Studio key’in için erişilebilir değilse otomatik olarak Gemini fallback devreye girer.

Bu bilgi iki yerde görünür:

- backend log’larında warning olarak
- API response içindeki `execution_metadata` alanında

Bu sayede ekip fallback olup olmadığını sessizce kaçırmaz.

## Teknoloji Yığını

- Backend: FastAPI
- ORM: SQLAlchemy
- Database: Supabase PostgreSQL
- AI SDK: Google GenAI SDK
- Vector DB: Chroma
- Embedding / retrieval altyapısı: Chroma collection query
- PDF parsing: `pypdf`
- Auth: JWT
- Deployment-ready config: `.env` + Pydantic Settings

## Proje Yapısı

```text
food-safe/
├─ README.md
├─ requirements.txt
└─ backend/
   ├─ .env.example
   ├─ requirements.txt
   ├─ ingest_reference_docs.py
   ├─ app/
   │  ├─ main.py
   │  ├─ api/
   │  │  ├─ analyze.py
   │  │  ├─ auth.py
   │  │  ├─ history.py
   │  │  ├─ profile.py
   │  │  └─ shared.py
   │  ├─ core/
   │  │  ├─ config.py
   │  │  ├─ database.py
   │  │  └─ security.py
   │  ├─ models/
   │  ├─ schemas/
   │  │  └─ food_safe.py
   │  ├─ services/
   │  │  ├─ google_ai.py
   │  │  ├─ vision.py
   │  │  ├─ rag.py
   │  │  ├─ reasoning.py
   │  │  ├─ market.py
   │  │  ├─ gemma_service.py
   │  │  └─ rag_service.py
   │  └─ workflows/
   │     └─ agent_workflow.py
   └─ knowledge/
      ├─ ecodes.json
      └─ reference_docs/
```

## Kurulum

### 1. Bağımlılıkları yükle

Proje kök dizininde:

```bash
pip install -r requirements.txt
```

### 2. Ortam değişkenlerini ayarla

`backend/.env` dosyası oluştur. Hızlı başlangıç için:

```bash
cp backend/.env.example backend/.env
```

Sonra `backend/.env` içinde en az şu alanları doldur:

```env
GEMINI_API_KEY=your_google_ai_studio_key

VISION_MODEL=gemma-4-31b-it
VISION_FALLBACK_MODEL=gemini-2.5-flash
REASONING_MODEL=gemma-4-31b-it
REASONING_FALLBACK_MODEL=gemini-2.5-flash

DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.isjomprfajsyjdpqjwhk.supabase.co:5432/postgres
SECRET_KEY=your_long_random_secret

CHROMA_USE_CLOUD=true
CHROMA_API_KEY=your_chroma_cloud_api_key
CHROMA_TENANT=your_chroma_tenant_id
CHROMA_DATABASE=Safe-Foods
CHROMA_COLLECTION=food-safe-toxicology
CHROMA_TOP_K=3
```

Notlar:

- `DATABASE_URL` içindeki şifre özel karakter içeriyorsa URL-encode edilmelidir.
- `.env` dosyası commit edilmemelidir.
- Ekipteki herkes aynı Supabase ve Chroma bilgilerini kullanmalıdır.

### 3. Veritabanını başlat

```bash
cd backend
python3 -c "from app.core.database import init_db; init_db()"
```

### 4. RAG index oluştur

PDF kaynaklarını `backend/knowledge/reference_docs/` içine koyduktan sonra:

```bash
cd backend
python3 ingest_reference_docs.py --reset
```

Bu komut:

- PDF dosyalarını okur
- sayfa bazlı metin çıkarır
- chunk’lara böler
- Chroma koleksiyonuna upload eder

### 5. Backend’i çalıştır

```bash
cd backend
uvicorn app.main:app --reload
```

API:

- `http://localhost:8000`
- Swagger docs: `http://localhost:8000/docs`

## API Akışı

Ana analiz endpoint’i:

- `POST /api/analyze/`

Beklenen giriş:

- ürün etiketi görseli
- opsiyonel kullanıcı oturumu / profil bilgisi

Örnek response yapısı:

```json
{
  "scan_id": 1,
  "share_token": "example-token",
  "result": {
    "extracted_label": {
      "product_name": "Sample Product",
      "ingredients": ["E250", "glucose syrup"],
      "claims": ["sugar free"],
      "allergens": [],
      "cross_contamination_warnings": [],
      "detected_language": "en",
      "raw_text": "..."
    },
    "retrieved_evidence": [
      {
        "ingredient": "E250",
        "normalized_name": "e250",
        "summary": "Scientific chunk summary",
        "risk_level": "high",
        "profile_flags": [],
        "evidence": ["..."],
        "sources": [{"title": "WHO document", "organization": "WHO", "citation": "..."}]
      }
    ],
    "risk_report": {
      "overall_risk": "high",
      "status": "HIGH_RISK",
      "summary": "High-risk outcome triggered by E250.",
      "personalized_considerations": [],
      "ingredient_assessments": [],
      "safer_alternatives": [],
      "scientific_basis": [],
      "next_steps": []
    },
    "execution_metadata": [
      {
        "stage": "vision",
        "provider": "google-genai",
        "preferred_model": "gemma-4-31b-it",
        "actual_model": "gemini-2.5-flash",
        "fallback_model": "gemini-2.5-flash",
        "fallback_used": true,
        "success": true,
        "notes": ["Gemini fallback path activated."]
      }
    ]
  }
}
```

## Ekip İçin Operasyon Notları

- `backend/.env` her geliştiricide lokal tutulmalı
- Supabase ve Chroma erişimleri ekip içinde senkron olmalı
- PDF kaynakları güncellendiğinde `ingest_reference_docs.py --reset` tekrar çalıştırılmalı
- Fallback tetiklenirse önce log’lara ve `execution_metadata` alanına bakılmalı

## Mevcut Durum

Tamamlananlar:

- Modüler backend mimarisi
- Supabase PostgreSQL bağlantısı
- Google GenAI entegrasyonu
- Gemma-first / Gemini-fallback akışı
- Chroma Cloud konfigürasyonu
- PDF ingestion scripti
- Fallback knowledge base

Geliştirilmeye açık alanlar:

- daha güçlü toxicology classification mantığı
- daha iyi ingredient normalization
- production-grade observability
- frontend / mobile istemci entegrasyonu
- gerçek market API bağlantısı

## Güvenlik Notu

Bu repoda bulunan gerçek API anahtarları, DB şifreleri ve cloud credential’lar paylaşılmamalı. Eğer bir secret yanlışlıkla paylaşıldıysa:

1. İlgili key’i hemen rotate et
2. `.env` dışındaki dosyalarda secret kalmadığını kontrol et
3. Gerekirse yeni credential üret

## Kısa Demo Akışı

1. Kullanıcı ürün etiketi yükler
2. Sistem ingredient JSON çıkarır
3. Chroma’dan bilimsel kanıtları getirir
4. Profil bazlı risk raporu üretir
5. Yüksek risk varsa alternatif önerir

## Lisans

Hackathon prototipi. Lisans kararı ekip tarafından netleştirilebilir.
