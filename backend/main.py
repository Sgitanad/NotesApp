import os
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
import models, schemas
from database import SessionLocal, engine
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN_BACKEND"),          # ← CHANGED
    integrations=[FastApiIntegration()],
    send_default_pii=True,                         # ← ADDED
    traces_sample_rate=1.0,
    environment="production",
)

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Notes API", version="1.0.0")

# Configure CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Root endpoint
@app.get("/")
def read_root():
    return {"message": "Notes API is running", "version": "1.0.0"}

# Sentry test route — REMOVE AFTER TESTING          # ← ADDED
@app.get("/sentry-debug")
async def trigger_error():
    division_by_zero = 1 / 0

# Create a new note
@app.post("/notes/", response_model=schemas.Note)
def create_note(note: schemas.NoteCreate, db: Session = Depends(get_db)):
    db_note = models.Note(
        title=note.title,
        content=note.content,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note

# Get all notes
@app.get("/notes/", response_model=List[schemas.Note])
def read_notes(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    notes = db.query(models.Note).order_by(models.Note.updated_at.desc()).offset(skip).limit(limit).all()
    return notes

# Get a single note by ID
@app.get("/notes/{note_id}", response_model=schemas.Note)
def read_note(note_id: int, db: Session = Depends(get_db)):
    note = db.query(models.Note).filter(models.Note.id == note_id).first()
    if note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return note

# Update a note
@app.put("/notes/{note_id}", response_model=schemas.Note)
def update_note(note_id: int, note: schemas.NoteUpdate, db: Session = Depends(get_db)):
    db_note = db.query(models.Note).filter(models.Note.id == note_id).first()
    if db_note is None:
        raise HTTPException(status_code=404, detail="Note not found")

    if note.title is not None:
        db_note.title = note.title
    if note.content is not None:
        db_note.content = note.content

    db_note.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_note)
    return db_note

# Delete a note
@app.delete("/notes/{note_id}")
def delete_note(note_id: int, db: Session = Depends(get_db)):
    note = db.query(models.Note).filter(models.Note.id == note_id).first()
    if note is None:
        raise HTTPException(status_code=404, detail="Note not found")

    db.delete(note)
    db.commit()
    return {"message": "Note deleted successfully"}
