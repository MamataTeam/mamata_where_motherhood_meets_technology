from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import json

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/get-week/{week_number}")
def get_week_info(week_number: int):
    with open("C:\\Users\\DELL\\Downloads\\pregnancy_weeks_info.json", "r") as file:
        data = json.load(file)
    for week in data:
        if week["week"] == week_number:
            return week
    return {"error": "Week not found"}
