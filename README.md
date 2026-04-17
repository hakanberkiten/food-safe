# Food-Safe

Food-Safe is an AI-assisted food label analysis project. The backend accepts a product label image, extracts ingredients from the label, retrieves toxicology context from reference documents, and produces a personalized risk summary based on a user profile.

This repository currently contains:

- a FastAPI backend in `backend/`
- a Flutter frontend in `flutter/`
- PDF reference documents used for RAG ingestion in `backend/knowledge/reference_docs/`

## What This Project Does

The backend follows a `Vision -> RAG -> Reasoning` pipeline:

1. Vision reads the uploaded food label image and extracts structured ingredient data.
2. RAG looks for toxicology context in ingested PDF reference documents stored in Chroma.
3. Reasoning combines extracted ingredients, retrieved evidence, and user profile data into a risk report.

If no vector results are available, the backend falls back to a very small seed file at `backend/knowledge/ecodes.json`.

## Repository Layout

```text
food-safe/
├─ README.md
├─ docker-compose.yml
├─ backend/
│  ├─ .env.example
│  ├─ requirements.txt
│  ├─ ingest_reference_docs.py
│  ├─ app/
│  │  ├─ main.py
│  │  ├─ api/
│  │  ├─ core/
│  │  ├─ models/
│  │  ├─ schemas/
│  │  ├─ services/
│  │  └─ workflows/
│  └─ knowledge/
│     ├─ ecodes.json
│     └─ reference_docs/
├─ flutter/
└─ notebooks/
```

## Quick Start

If you only want to get the backend running locally, follow these steps.

### 1. Create a virtual environment

From the repository root:

```bash
cd /Users/ems/Desktop/food-safe/backend
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install backend dependencies

```bash
pip install -r requirements.txt
```

### 3. Create `backend/.env`

```bash
cp .env.example .env
```

At minimum, review and update:

```env
GEMINI_API_KEY=your_google_ai_studio_key
SECRET_KEY=replace-with-a-long-random-secret
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@your-supabase-host:5432/postgres
CHROMA_USE_CLOUD=false
```

Important notes:

- If `backend/.env` is missing, the app logs a warning and falls back to a local SQLite database at `backend/food_safe.db`.
- That fallback is useful for local startup, but it is not the intended production database setup.
- If your database password contains special characters, URL-encode it inside `DATABASE_URL`.

### 4. Optional but recommended: ingest the PDF knowledge base

The repository already includes PDF files under `backend/knowledge/reference_docs/`, but they are not queried automatically just because they exist on disk. They must first be ingested into Chroma.

Run:

```bash
cd /Users/ems/Desktop/food-safe/backend
./.venv/bin/python ingest_reference_docs.py --reset
```

This command:

- reads all PDF files in `backend/knowledge/reference_docs/`
- extracts text page by page
- chunks the text
- uploads the chunks into the configured Chroma collection

If you skip this step, RAG will rely much more heavily on `backend/knowledge/ecodes.json`, which is only a tiny fallback dataset.

### 5. Start the backend

```bash
cd /Users/ems/Desktop/food-safe/backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

Once the server is up:

- API root: [http://localhost:8000](http://localhost:8000)
- Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)

## Local Development Modes

### Option A: minimal local setup

Use the SQLite fallback and skip Supabase while working on API behavior or UI integration.

Recommended when:

- you are new to the repo
- you only need the server to boot
- you want to test endpoints without team cloud credentials

### Option B: full team-like setup

Use:

- a real `DATABASE_URL`
- your shared or local Chroma configuration
- a valid `GEMINI_API_KEY`
- a fresh PDF ingestion run

Recommended when:

- you need realistic toxicology retrieval
- you are testing end-to-end AI output quality
- you want parity with the rest of the team

## Environment Variables

The main settings live in `backend/.env`. Start from `backend/.env.example`.

Common variables:

- `GEMINI_API_KEY`: required for Google GenAI calls
- `VISION_MODEL`: preferred model for ingredient extraction
- `VISION_FALLBACK_MODEL`: fallback if the preferred vision model is unavailable
- `REASONING_MODEL`: preferred model for reasoning
- `REASONING_FALLBACK_MODEL`: fallback if the preferred reasoning model is unavailable
- `DATABASE_URL`: PostgreSQL connection string, or leave `.env` missing to use local SQLite fallback
- `SECRET_KEY`: JWT signing secret
- `CHROMA_USE_CLOUD`: `true` for Chroma Cloud, `false` for local persistent Chroma
- `CHROMA_API_KEY`, `CHROMA_TENANT`, `CHROMA_DATABASE`: required when using Chroma Cloud
- `CHROMA_COLLECTION`: collection name for RAG chunks
- `CHROMA_PERSIST_DIRECTORY`: local Chroma storage directory when cloud mode is disabled
- `MARKET_API_BASE_URL`: optional external market API base URL

## Backend API Overview

Main routes currently mounted by the backend:

- `POST /api/analyze/`
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `GET /api/profile/`
- `POST /api/profile/`
- `GET /api/history/scans`
- `GET /api/history/saved-products`
- `POST /api/history/save-product`
- `GET /api/history/stats`
- `GET /api/shared/{token}`

### Most important endpoint

`POST /api/analyze/` accepts a food label image and returns:

- extracted label information
- risk summary
- top risky ingredients
- personalized considerations
- execution metadata describing model selection and fallback behavior

Accepted image types:

- `image/jpeg`
- `image/png`
- `image/webp`

## How RAG Works Here

There are two knowledge layers:

1. Primary layer: Chroma collection populated from PDF files by `backend/ingest_reference_docs.py`
2. Fallback layer: `backend/knowledge/ecodes.json`

This matters because new contributors often assume that placing PDFs in `reference_docs/` is enough. It is not. The PDFs must be ingested before the app can retrieve from them.

## Common First-Day Pitfalls

### The app starts, but retrieval feels weak

Usually means the PDF ingestion step was skipped and the system is falling back to `ecodes.json`.

### The app crashes on database connection

Check `backend/.env` first. If the file exists but contains an invalid remote `DATABASE_URL`, startup will fail. If the file is missing entirely, the app now logs a warning and uses local SQLite instead.

### The AI stages are using fallback models

Look at:

- backend logs
- `execution_metadata` in API responses

This usually means the preferred Gemma model is unavailable for the configured key and the code has switched to the configured Gemini fallback.

### PDF files exist, but nothing is retrieved from them

Run:

```bash
cd /Users/ems/Desktop/food-safe/backend
./.venv/bin/python ingest_reference_docs.py --reset
```

## Docker

The repository includes a `docker-compose.yml` with services for:

- `backend`
- `frontend`

Current compose behavior expects `backend/.env` to exist because the backend service mounts it with `env_file`.

Start with:

```bash
docker compose up --build
```

Backend port:

- `8000`

Frontend port:

- `3000`

## Frontend Notes

The Flutter app lives in `flutter/`. Its local README is still the default Flutter template, so the backend README should be treated as the primary source of truth for now.

If you are working on the frontend, start by getting the backend running first.

## Suggested Onboarding Flow

For a new teammate, the safest sequence is:

1. Create and activate `backend/.venv`.
2. Install `backend/requirements.txt`.
3. Copy `backend/.env.example` to `backend/.env`, or intentionally rely on the SQLite fallback for the first boot.
4. Start the backend and confirm `/docs` loads.
5. Run PDF ingestion.
6. Test `POST /api/analyze/` with a sample label image.
7. Only then move on to Supabase, Chroma Cloud, or frontend integration.

## Security

- Do not commit real secrets into the repository.
- Keep `backend/.env` local.
- Rotate any credential immediately if it was accidentally exposed.

## Current Status

What is already in place:

- FastAPI backend
- SQLAlchemy models and auth flows
- image analysis workflow
- PDF ingestion script
- Chroma-backed retrieval path
- fallback seed knowledge base
- Flutter client scaffold

What still needs polish:

- stronger seed knowledge coverage
- more robust ingredient normalization
- clearer frontend setup documentation
- more production-grade observability and operations docs

## License

No explicit license is defined yet in this repository.
