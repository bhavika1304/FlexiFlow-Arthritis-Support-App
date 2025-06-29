# app/main.py

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.recommender import recommend_exercises, update_model, linucb_model
from app.firebase_config import db
from datetime import datetime, timezone, timedelta
import pickle
import os
import uuid

# -------------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------
MODEL_PATH = "model_store/linucb_model.pkl"

def save_model(model):
    os.makedirs("model_store", exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)

def load_model():
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return None

loaded_model = load_model()
if loaded_model is not None:
    linucb_model.A = loaded_model.A
    linucb_model.b = loaded_model.b
    print("✅ LinUCB Model loaded successfully from storage!")

# -------------------------------
# 📦 Models
class Context(BaseModel):
    user_id: str
    pain_level: int
    mood: str
    joint: str
    arthritis_type: str

class FeedbackPayload(BaseModel):
    context: Context
    exercise_id: int
    reward: float

class PainLog(BaseModel):
    user_id: str
    pain_level: int
    notes: str

class DietLog(BaseModel):
    user_id: str
    food: str
    meal_time: str
    comments: str

class MedicineLog(BaseModel):
    user_id: str
    medicine_name: str
    dose: str
    comments: str

class CommunityPost(BaseModel):
    user_id: str
    message: str
    username: str  # ✅ Add this
    email: str

# -------------------------------
# 📍 Exercise Recommendation APIs
@app.post("/recommend")
def recommend(context: Context):
    context_dict = context.model_dump()
    recommendations = recommend_exercises(context_dict)

    now = datetime.now(timezone.utc)
    formatted_now = now.strftime("%Y-%m-%d %H:%M")

    exercise_list = [
        {
            "title": exercise.get("name", "Unknown Exercise"),  # FIXED HERE
            "recommended_at": formatted_now,
        }
        for exercise in recommendations
    ]

    user_ref = db.collection("Users").document(context.user_id)
    user_doc = user_ref.get()

    if user_doc.exists:
        previous_recommendations = user_doc.to_dict().get("saved_recommendations", [])
        updated_recommendations = previous_recommendations + exercise_list

        user_ref.update({
            "saved_recommendations": updated_recommendations
        })
    else:
        print("❌ User document not found for user_id:", context.user_id)

    # (Optional logging)
    for exercise in recommendations:
        data = {
            "recommendation_id": str(uuid.uuid4()),
            "user_id": context.user_id,
            "exercise_name": exercise.get("title", "Unknown"),
            "recommended_at": now,
            "generated_by": "eular"
        }
        db.collection("Exercise_Recommendation").add(data)

    return {"recommendations": recommendations}

@app.post("/feedback")
def submit_feedback(payload: FeedbackPayload):
    context_dict = payload.context.model_dump()
    update_model(
        context=context_dict,
        user_id=context_dict["user_id"],
        action_index=payload.exercise_id,
        reward=payload.reward,
        model_version="linucb-v1"
    )
    save_model(linucb_model)
    return {"message": "Feedback received. Model updated and saved."}

# -------------------------------
# 📍 Pain Logging APIs
@app.post("/log_pain")
def log_pain(pain: PainLog):
    data = {
        "log_id": str(uuid.uuid4()),
        "user_id": pain.user_id,
        "pain_level": pain.pain_level,
        "notes": pain.notes,
        "logged_at": datetime.now(timezone.utc),
    }
    db.collection("Pain_Log").add(data)
    return {"message": "Pain log submitted successfully."}

@app.get("/get_pain_logs")
def get_pain_logs(user_id: str = Query(...)):
    logs = db.collection("Pain_Log")\
        .where("user_id", "==", user_id)\
        .order_by("logged_at", direction="DESCENDING")\
        .limit(10)\
        .stream()

    pain_log_list = []
    for log in logs:
        pain_log_list.append(log.to_dict())

    return {"logs": pain_log_list}

# -------------------------------
# 📍 Diet Logging API
@app.post("/log_diet")
def log_diet(diet: DietLog):
    data = {
        "log_id": str(uuid.uuid4()),
        "user_id": diet.user_id,
        "food": diet.food,
        "meal_time": diet.meal_time,
        "comments": diet.comments,
        "logged_at": datetime.now(timezone.utc),
    }
    db.collection("Diet_Log").add(data)
    return {"message": "Diet log submitted successfully."}

# -------------------------------
# 📍 Medicine Logging API
@app.post("/log_medicine")
def log_medicine(med: MedicineLog):
    data = {
        "log_id": str(uuid.uuid4()),
        "user_id": med.user_id,
        "medicine_name": med.medicine_name,
        "dose": med.dose,
        "comments": med.comments,
        "logged_at": datetime.now(timezone.utc),
    }
    db.collection("Medicine_Log").add(data)
    return {"message": "Medicine log submitted successfully."}

# -------------------------------
# 📍 View Progress API
@app.get("/view_progress")
def view_progress(
    user_id: str = Query(...),
    mode: str = Query("week"),
    range: str = Query("this")
):
    now = datetime.now(timezone.utc)

    if mode == "week":
        start_of_week = now - timedelta(days=now.weekday())
        if range == "this":
            start_date = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)
            end_date = now
        else:
            last_week_end = start_of_week - timedelta(seconds=1)
            start_date = (start_of_week - timedelta(days=7)).replace(hour=0, minute=0, second=0, microsecond=0)
            end_date = last_week_end
    elif mode == "month":
        if range == "this":
            start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = now
        else:
            first_of_this_month = now.replace(day=1)
            last_month_end = first_of_this_month - timedelta(seconds=1)
            start_date = last_month_end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = last_month_end
    else:
        return {"error": "Invalid mode. Use 'week' or 'month'."}

    logs = db.collection("Pain_Log")\
        .where("user_id", "==", user_id)\
        .where("logged_at", ">=", start_date)\
        .where("logged_at", "<=", end_date)\
        .order_by("logged_at", direction="ASCENDING")\
        .stream()

    pain_levels = []
    daily_logs = []

    for log in logs:
        data = log.to_dict()
        pain_level = data.get("pain_level", 0)
        mood = data.get("notes", "neutral")

        timestamp = data.get("logged_at")
        if timestamp and isinstance(timestamp, datetime):
            logged_date = timestamp.astimezone(timezone.utc).strftime("%Y-%m-%d")
        else:
            logged_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        pain_levels.append(pain_level)

        daily_logs.append({
            "date": logged_date,
            "pain_level": pain_level,
            "mood": mood
        })

    avg_pain = sum(pain_levels) / len(pain_levels) if pain_levels else 0.0

    return {
        "average_pain": avg_pain,
        "daily_logs": daily_logs
    }

# -------------------------------
# 📍 Community APIs 🔥
@app.post("/community/post")
def post_message(post: CommunityPost):
    bad_words = [
        "badword1", "badword2", "stupid", "idiot", "fool", "dumb", "trash",
        "ugly", "hate", "disgusting", "kill", "die", "useless", "worst",
        "loser", "annoying", "worthless", "nonsense", "angry", "crap",
        "sucks", "hurt", "attack", "abuse", "violence", "fat",
        "pathetic", "creep", "nasty", "garbage", "bastard", "moron", "scum",
        "curse", "shit", "fuck", "damn", "bitch", "asshole", "piss", "screw"
    ]

    if any(bad_word in post.message.lower() for bad_word in bad_words):
        return {"error": "Your post contains inappropriate language. Please revise and try again."}

    data = {
        "message_id": str(uuid.uuid4()),
        "user_id": post.user_id,
        "username": post.username,
        "email": post.email,
        "message": post.message,
        "posted_at": datetime.now(timezone.utc),
    }
    db.collection("Community_Posts").add(data)
    return {"message": "Post submitted successfully."}

@app.get("/community/messages")
def get_messages():
    posts = db.collection("Community_Posts")\
        .order_by("posted_at", direction="DESCENDING")\
        .limit(50)\
        .stream()

    post_list = []
    for post in posts:
        post_list.append(post.to_dict())

    return {"posts": post_list}

# -------------------------------
# 📍 Reset Progress APIs 🔥
@app.delete("/reset_pain_logs")
def reset_pain_logs(user_id: str = Query(...)):
    logs = db.collection("Pain_Log").where("user_id", "==", user_id).stream()
    for log in logs:
        db.collection("Pain_Log").document(log.id).delete()
    return {"message": "Pain logs deleted."}

@app.delete("/reset_diet_logs")
def reset_diet_logs(user_id: str = Query(...)):
    logs = db.collection("Diet_Log").where("user_id", "==", user_id).stream()
    for log in logs:
        db.collection("Diet_Log").document(log.id).delete()
    return {"message": "Diet logs deleted."}

@app.delete("/reset_medicine_logs")
def reset_medicine_logs(user_id: str = Query(...)):
    logs = db.collection("Medicine_Log").where("user_id", "==", user_id).stream()
    for log in logs:
        db.collection("Medicine_Log").document(log.id).delete()
    return {"message": "Medicine logs deleted."}
