from fastapi import FastAPI
from app.main import app as main_app

app = FastAPI()

# Mount the app from app/main.py
app.mount("/", main_app)
