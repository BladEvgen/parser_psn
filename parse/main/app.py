from fastapi import FastAPI, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import RedirectResponse
import os
import sqlite3

app = FastAPI()
templates = Jinja2Templates(directory="templates")

db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "url", "url.db")

with sqlite3.connect(db_path) as conn:
    cursor = conn.cursor()
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS urls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE
        )
    """
    )


@app.get("/", response_class=RedirectResponse)
async def read_item(request: Request):
    with sqlite3.connect(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT url FROM urls")
        content = [row[0] for row in cursor.fetchall()]
    return templates.TemplateResponse(
        "index.html", {"request": request, "file_content": content}
    )


@app.post("/add_url/", response_class=RedirectResponse)
async def add_url(url: str = Form(...)):
    try:
        url = url.strip()

        with sqlite3.connect(db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT INTO urls (url) VALUES (?)", (url,))
            conn.commit()

        return RedirectResponse(url="/", status_code=303)
    except sqlite3.IntegrityError as e:
        print(f"URL {url} is not unique. Skipping")
        return RedirectResponse(url="/", status_code=303)
    except Exception as e:
        return {"error": str(e)}
