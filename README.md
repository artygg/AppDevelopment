# AppDevelopment – Location-Based Quiz & Mine Game

A full-stack Swift + Go demo project: players capture real-world POIs by answering auto-generated quizzes (powered by OpenAI), then **plant mines** to slow down rivals.  
▶ iOS client (SwiftUI)   ▶ REST + WS backend (Go + PostgreSQL).

---

## Features
| Module | Highlights |
|--------|------------|
| **Quizzes** | 7 Qs per POI, first 3 place-specific. Auto-generated via ChatGPT (GPT-3.5). |
| **Capture** | Answer ≥ 1 question correctly faster than current holder to take over. |
| **Mines** | Owners can mark quiz questions → **5 s** timer (“mine”). |
| **Leaderboard** | Server-side aggregate of captures. |
| **Live Updates** | WebSocket broadcasts on new places & captures. |
| **Image Feed** | Optional photo upload per POI. |

---


## Tech Stack
| Layer | Tech |
|-------|------|
| **iOS client** | Swift 5.9, SwiftUI, MapKit, Combine |
| **Backend** | Go 1.22, `net/http`, Gorilla WS |
| **DB** | PostgreSQL 15, JSONB |
| **AI** | OpenAI Chat Completions API |
| **Infra** | Docker (optional), make, go modules |

---

## Quick Start

```bash
# 1 ─ Clone
git clone https://github.com/artygg/AppDevelopment.git
cd AppDevelopment

# 2 ─ Backend env
cp backend/.env.sample backend/.env
#                ↑ fill in OPENAI_API_KEY & PG creds

# 3 ─ DB up
docker compose up -d db       # → postgres:15 @ localhost:5432

# 4 ─ Migrate
cd backend
make migrate                  # runs sqlc / goose migrations

# 5 ─ Run server
go run ./cmd/api              # listens at http://localhost:8080

# 6 ─ iOS app
open ios/AppDevelopment.xcodeproj
#   ▶⌘R on Simulator or device (iOS 17+)

# 7 ─ Play!

```

---

**Environment Variables**

| var              | example                 | required | notes                   |
| ---------------- | ----------------------- | -------- | ----------------------- |
| `OPENAI_API_KEY` | `sk-...`                | ✅        | ChatGPT quiz generation |
| `DB_HOST`        | `localhost`             | ✅        | Postgres host           |
| `DB_PORT`        | `5432`                  | ✅        |                         |
| `DB_USER`        | `postgres`              | ✅        |                         |
| `DB_PASSWORD`    | `postgres`              | ✅        |                         |
| `DB_NAME`        | `app_dev`               | ✅        |                         |
| `WS_ORIGIN`      | `http://localhost:5173` | ❌        | CORS / WS origin check  |


---

**PostgreSQL & Migrations**

# create user & db
createuser -s postgres        # if not yet
createdb -O postgres app_dev

# run migrations
make migrate

---

**Running the Backend**

| command            | action                              |
| ------------------ | ----------------------------------- |
| `go run ./cmd/api` | start HTTP + WS server on **:8080** |

---

**Running the iOS App**

1. Xcode 15+.

2. Scheme AppDevelopment → Run.

3. Ensure Info.plist has NSAppTransportSecurity / NSAllowsArbitraryLoads = YES (dev only) for local HTTP.


---













