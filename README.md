# FlexiFlow-Arthritis-Support-App

# FlexiFlow 🧘‍♀️  
**AI-Powered Personalized Support System for Arthritis Management**

---

## 🌟 Overview

**FlexiFlow** is a cross-platform mobile and web application designed to assist individuals with arthritis in managing their daily routines, exercises, medication, and symptoms through a personalized and adaptive AI-driven system.

The platform combines **behavioral tracking**, **EULAR-based clinical logic**, and a **LinUCB contextual bandit model** to deliver **real-time, user-specific exercise recommendations**. It further improves adherence through **smart notifications**, **gamification**, and a **supportive community forum**.

---

## 🚀 Features

- 🤖 **AI-Powered Exercise Recommendation System**  
  Cold-start with EULAR guidelines, followed by adaptive recommendations using LinUCB contextual bandits.

- 🔔 **Smart Notifications and Reminders**  
  Categorized as Upcoming, Due, Missed, and Overdue with real-time alerts.

- 🧩 **Gamification**  
  Badges and streaks to increase motivation and adherence.

- 📱 **Cross-Platform App**  
  Built with Flutter for Android, iOS, and Web.

- 🔒 **Secure Authentication and Real-Time Sync**  
  Powered by Firebase Auth & Firestore.

- 💬 **Community Forum**  
  In-app community with offensive content filtering.

- 📈 **Health Logging**  
  Logs for Pain, Medication, Diet, and Exercise Progress.

---

## 🏗️ Tech Stack

| Component | Technology |
|----------|------------|
| Frontend | Flutter |
| Backend | FastAPI |
| AI Model | LinUCB + EULAR |
| Database | Firebase Firestore |
| Auth | Firebase Authentication |
| Hosting | Firebase (Web), Render (API), Android APK |

---

## 📐 System Architecture

![System Architecture](./diagrams/system_architecture.png)

---

## ⚙️ Installation & Setup

### 1. **Clone the repository**

```bash
git clone https://github.com/your-username/FlexiFlow.git
cd FlexiFlow
```
### 2. **Frontend Setup (Flutter)**
Install Flutter
Run:
```bash
flutter pub get
flutter run
```

### 3. **Backend Setup (FastAPI)**
Create a Python environment:
```bash
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\activate on Windows
pip install -r requirements.txt
```
Start FastAPI server:
```bash
uvicorn main:app --reload
```
### 4. **Firebase Configuration**
Setup Firebase project.
Add google-services.json and firebase_options.dart to Flutter project.
Use firebase-adminsdk.json in backend for server access.

---

## 🧠 AI Recommendation Engine
Cold Start: Uses clinical EULAR rules based on arthritis type and severity.

Adaptive Phase:
Implements LinUCB contextual bandit with:
Context = [pain level, joint affected, past adherence, etc.]
Reward = engagement or feedback score.
Real-time update using feedback loop.

```python
p_ta = θᵀx + α * sqrt(xᵀA⁻¹x)
```

## 🔐 Folder Structure

```bash
FlexiFlow/
│
├── frontend/                # Flutter App
│   └── lib/
│       ├── pages/
│       ├── components/
│       └── main.dart
│
├── backend/
│   ├── main.py              # FastAPI entry
│   ├── linucb_model.py      # AI model logic
│   └── utils/
│
├── saved_models/            # Serialized LinUCB model
├── model_store/             # Persistent data
└── diagrams/                # ERD, UML, Architecture PNGs
```

--- 

## 🧪 Testing
Functional Testing: Postman & Swagger for backend API endpoints.
Performance Testing: UI tested on low-end Android & web (Flutter).
Responsiveness: Transition < 1s; API < 500ms.
AI Evaluation: EULAR baseline transitions into behavior-aware personalized outputs.

--- 

## ✅ Doctor's Review
Reviewed by Dr. Veena (MBBS, MD - Rheumatologist)
### Feedback Highlights:
Appreciated the AI system for personalization.
Suggested tracking Patient Global Assessment, blood reports, inflammation, and stiffness.
Recommended weekly assessments and low-impact exercise emphasis.

---

## 📊 Results
✅ Functional modules passed all tests.
⚡ Fast performance across Android and Web.
🤖 AI system effectively personalized recommendations over time.
🎮 Gamification improved user consistency.
📱 UI praised for accessibility and ease of use.

---

## 🔭 Future Scope
Integration with wearables for real-time motion tracking.
In-app chatbot and video-guided routines.
Teleconsultation support and EHR integration.
Offline access and multi-language support.

---

## 👥 Contributors
Bhavika Gandham
Nagasarapu Sarayu Krishna
Trisha Vijayekkumaran
