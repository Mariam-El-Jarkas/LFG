# 🎮 LFG Connect — Mobile Gaming Session Scheduler

**LFG Connect** helps gamers organize multiplayer sessions, manage their game collections, and connect with friends — all from a mobile-first experience.

Plan your next gaming night, track your library, and see what your friends are playing in one seamless app.

---

## 📖 Project Description

**LFG Connect** is a full-stack mobile application built with **Flutter**, designed for gamers who want to easily organize local multiplayer sessions with friends.

The app allows users to:
- Build and manage personal game collections
- Connect with friends via email
- Schedule gaming sessions
- RSVP to events in real time

This project addresses the common coordination challenges of gaming nights by offering a **mobile-first solution** optimized for on-the-go planning. The architecture is designed with scalability in mind, supporting future real-time updates, notifications, and platform integrations.

---

## ✨ Features

### 🎮 Core Features
- 👤 **Secure Authentication** — Email & password login
- 🎮 **Personal Game Library** — Add, delete owned games
- 👥 **Friend Network** — Connect with gamers using email
- 📅 **Session Planning** — Create and manage gaming events
- ✅ **RSVP System** — Track attendance for sessions
- 📱 **Mobile-Optimized UI** — Smooth navigation and layouts

### 🧑‍💻 User Experience
- 🏠 **Dashboard** — Overview of upcoming sessions
- 🔄 **Pull-to-Refresh** — Instantly update content
- 📊 **Profile Stats** — Sessions, games, and friends overview
- 🎨 **Modern UI** — Clean, gaming-inspired design
- 📍 **Location Support** — Specify session locations

### ⚙️ Technical Features
- 🔐 **Session Persistence** — Stay logged in across launches
- 🌐 **REST API Integration** — JSON-based communication
- 📲 **Offline Support** — Planned
- 🔔 **Push Notifications** — Planned

---

## 🧠 Tech Stack

### 📱 Frontend (Mobile)
| Technology | Purpose | Version |
|---------|--------|--------|
| **Flutter** | Cross-platform mobile framework | 3.x |
| **Dart** | Programming language | 3.x |
| **HTTP** | API communication | ^1.1.0 |
| **SharedPreferences** | Local session storage | ^2.2.2 |
| **Provider** | State management | ^6.1.1 |

### 🖥️ Backend (Server)
| Technology | Purpose |
|---------|--------|
| **PHP** | Server-side API logic |
| **MySQL** | Relational database |
| **REST API** | JSON communication |
| **InfinityFree** | Hosting provider |

### 🗄️ Database Schema
- **users** — User accounts and profiles  
- **games** — Game catalog  
- **user_games** — User ↔ game relationships  
- **friends** — Friend connections  
- **sessions** — Gaming events  
- **session_attendees** — RSVP tracking  

---

## 🗂️ Project Structure

*To be added*

---
## 🚀 Live Deployment

**Backend API:**  https://lfg.infinityfree.me/api/

**Frontend / App Deployment**
The mobile app is currently available via:
- **Web Build:** [Open in browser](https://lfg.infinityfree.me/)
- **Android APK:** Direct installation
- **App Stores:** Coming soon

---
## 🎮 User Flow

1. **Register** — Create an account  
2. **Login** — Access your profile  
3. **Add Games** — Build your library  
4. **Find Friends** — Connect with gamers  
5. **Create Session** — Schedule an event  
6. **RSVP** — Confirm attendance  
7. **Manage** — Update profile and sessions  

---

## 🔮 Future Roadmap

### 🚀 Short Term
- 🔔 Push notifications
- 🌙 Dark mode
- 📸 Game cover images
- 🔍 Search for games and friends

### 📈 Medium Term
- 💬 In-app messaging
- 📊 Playtime tracking
- ⭐ Session ratings
- 🗺️ Map integration

### 🌍 Long Term
- 📱 App Store deployment
- 🎮 Steam / Xbox / PSN integration
- 👥 Group chat
- 📅 Calendar sync

---

## 👨‍💻 Author

**Developer:** Mariam El Jarkas  
**Course:** CSCI410  
**University:** Lebanese International University (LIU)  
**Instructor:** Dr. Mhmd Kadri  
---

## 📸 Screenshots

*Coming soon*

---

🎮 **Ready to level up your gaming sessions? LFG Connect has you covered.**
---

## ⚙️ Installation & Setup

### 📱 Frontend Setup
```bash
### 🗄️ frontend Setup
# Clone the repository
git clone https://github.com/Mariam-El-Jarkas/lfg-connect.git

# Navigate into the project
cd lfg-connect

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for web
flutter build web --release

