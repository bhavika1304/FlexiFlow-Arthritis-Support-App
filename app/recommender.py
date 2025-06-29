import pandas as pd
import numpy as np
from datetime import datetime, timedelta, timezone
import uuid
from app.model import LinUCB
from app.firebase_config import db

# ------------------ Load Exercise Pool ------------------
exercise_df = pd.read_csv('data/refined_arthritis_exercise_pool.csv')

# ------------------ Initialize LinUCB ------------------
linucb_model = LinUCB(
    alpha=1.0,
    num_actions=len(exercise_df),
    context_dim=14
)

feedback_count = 0

# ------------------ Utilities ------------------

def context_to_vector(context):
    features = [context["pain_level"] / 10.0]

    moods = ["happy", "neutral", "sad"]
    for m in moods:
        features.append(1 if context["mood"] == m else 0)

    joints = ["knee", "wrist", "hip", "shoulder", "hand", "ankle", "foot", "elbow", "neck", "spine"]
    for j in joints:
        features.append(1 if context["joint"] == j else 0)

    return np.array(features).reshape(-1, 1)

def get_recent_pain_logs(user_id):
    """
    Fetch user's pain logs from last 7 days
    """
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    logs = db.collection("Pain_Log")\
        .where("user_id", "==", user_id)\
        .where("logged_at", ">=", seven_days_ago)\
        .stream()

    pain_levels = []
    for log in logs:
        data = log.to_dict()
        if "pain_level" in data:
            pain_levels.append(data["pain_level"])

    return pain_levels

def eular_recommend(context, top_k=5):
    """
    Fallback rule-based recommendation (easy exercises matching joint/type)
    """
    filtered = exercise_df[
        (exercise_df['joint'] == context['joint']) &
        (exercise_df['arthritis_type'].str.contains(context['arthritis_type'])) &
        (exercise_df['difficulty'] == 'easy')
    ]

    if filtered.empty:
        filtered = exercise_df[exercise_df['difficulty'] == 'easy']

    return filtered.sample(n=min(top_k, len(filtered))).to_dict(orient='records')

# ------------------ Core Recommendation ------------------

def recommend_exercises(context, top_k=5):
    """
    Recommend exercises considering user's past pain logs
    """
    global feedback_count

    user_id = context.get("user_id", "anonymous")

    # Step 1: Fetch pain logs
    recent_pain_levels = get_recent_pain_logs(user_id)
    high_pain = any(level >= 7 for level in recent_pain_levels)

    print(f"✅ User {user_id} | Pain logs fetched: {len(recent_pain_levels)}")
    print(f"⚡ High pain detected? {high_pain}")

    # Step 2: Pick recommendation method
    if feedback_count < 5:
        recommendations = eular_recommend(context, top_k)
        generated_by = "eular"
    else:
        context_vector = context_to_vector(context)
        top_indices = linucb_model.recommend(context_vector, top_k)
        recommendations = exercise_df.iloc[top_indices].to_dict(orient='records')
        generated_by = "linucb-v1"

    # Step 3: If high pain detected, keep only easy exercises
    if high_pain:
        print("🛡️ Adjusting recommendations for high pain (easy exercises only)")
        recommendations = [ex for ex in recommendations if ex.get("difficulty", "") == "easy"]

    # Step 4: Log recommendation
    log_recommendation_to_firebase(user_id, recommendations, generated_by)

    return recommendations

def update_model(context, user_id, action_index, reward, model_version):
    """
    Update LinUCB model with feedback
    """
    global feedback_count
    context_vector = context_to_vector(context)
    linucb_model.update(context_vector, action_index, reward)
    feedback_count += 1

    log_feedback_to_firebase(user_id, context, action_index, reward, model_version)

# ------------------ Firestore Logging ------------------

def log_recommendation_to_firebase(user_id, exercises, generated_by):
    for ex in exercises:
        data = {
            "recommendation_id": str(uuid.uuid4()),
            "user_id": user_id,
            "exercise_name": ex["name"],
            "generated_by": generated_by,
            "recommended_at": datetime.now(timezone.utc)
        }
        db.collection("Exercise_Recommendation").add(data)

def log_feedback_to_firebase(user_id, context, exercise_id, reward, model_version):
    log = {
        "entry_id": str(uuid.uuid4()),
        "user_id": user_id,
        "input_data": context,
        "output_data": {"exercise_id": exercise_id, "reward": reward},
        "model_version": model_version,
        "logged_at": datetime.now(timezone.utc)
    }
    db.collection("AI_Model_Log").add(log)
