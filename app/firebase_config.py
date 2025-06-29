import os
from dotenv import load_dotenv
from firebase_admin import credentials, firestore, initialize_app

# Load the environment variables from the .env file
load_dotenv()

# Get the Firebase key path from the environment variable
key_path = os.environ.get("FIREBASE_KEY_PATH")
if not key_path:
    raise ValueError("Missing FIREBASE_KEY_PATH environment variable.")

# Initialize Firebase with the credentials
cred = credentials.Certificate(key_path)
initialize_app(cred)

# Firestore client
db = firestore.client()
