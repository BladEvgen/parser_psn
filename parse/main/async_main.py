import os
import asyncio
import aiosqlite
from aiogram import Bot
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from aiogram.enums import ParseMode
from asyncio.exceptions import TimeoutError
from aiohttp import ClientSession, ClientError
from aiohttp.client_exceptions import ServerTimeoutError

dotenv_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"
)
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

BOT_TOKEN = os.getenv("bot_token")
CHAT_ID = os.getenv("chat_id")

file_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "url", "url.txt")
with open(file_path, "r", encoding="utf-8") as file:
    URLS = file.read().split(",")

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"
        " Chrome/113.0.0.0 Safari/537.36"
    ),
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "authority": "store.playstation.com",
    "sec-ch-ua-platform": '"Windows"',
}

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "db", "price.db")

RETRY_LIMIT = 3
TIMEOUT = 10  


class Database:
    """Database interface for managing price records."""

    def __init__(self, db_path: str):
        self.db_path = db_path

    async def create_table(self) -> None:
        """Create the database table if it does not exist."""
        async with aiosqlite.connect(self.db_path) as conn:
            await conn.execute(
                """
                CREATE TABLE IF NOT EXISTS prices (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT,
                    current_price TEXT,
                    previous_price TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            await conn.commit()

    async def insert_price(self, title: str, current_price: str, previous_price: str | None) -> None:
        """Insert a new price into the database."""
        async with aiosqlite.connect(self.db_path) as conn:
            await conn.execute(
                """
                INSERT INTO prices (title, current_price, previous_price) 
                VALUES (?, ?, ?)
                """,
                (title, current_price, previous_price),
            )
            await conn.commit()

    async def get_latest_price(self, title: str) -> tuple[str, str | None] | None:
        """Get the latest price from the database."""
        async with aiosqlite.connect(self.db_path) as conn:
            cursor = await conn.execute(
                """
                SELECT current_price, previous_price FROM prices WHERE title = ?
                ORDER BY timestamp DESC LIMIT 1
                """,
                (title,),
            )
            result = await cursor.fetchone()
            await cursor.close()
        return result


class PriceChecker:
    """Price Checker class interface."""

    def __init__(self, urls: list[str], bot_token: str, chat_id: str):
        self.urls = urls
        self.bot_token = bot_token
        self.chat_id = chat_id
        self.db = Database(DB_PATH)
        self.bot = Bot(token=bot_token)

    async def fetch(self, session: ClientSession, url: str) -> str | None:
        """Perform an asynchronous HTTP request with retries."""
        for attempt in range(RETRY_LIMIT):
            try:
                async with session.get(url, headers=HEADERS, timeout=TIMEOUT) as response:
                    response.raise_for_status()
                    return await response.text()
            except (ClientError, ServerTimeoutError, TimeoutError) as error:
                print(f"Attempt {attempt + 1}/{RETRY_LIMIT} failed: {error}")
                if attempt + 1 == RETRY_LIMIT:
                    return None

    async def process_url(self, session: ClientSession, url: str) -> tuple[str, str] | None:
        """Process each URL asynchronously."""
        try:
            html = await self.fetch(session, url)
            if html:
                soup = BeautifulSoup(html, "html.parser")
                title = (
                    soup.find("h1").get_text(strip=True)
                    if soup.find("h1")
                    else "Title not found"
                )
                price = (
                    soup.find("span", class_="psw-t-title-m").get_text(strip=True)
                    if soup.find("span", class_="psw-t-title-m")
                    else "Price not found"
                )
                return title, price
            return None
        except Exception as error:
            print(f"An error occurred during the processing of the URL: {error}")
            return None

    async def send_message(self, message: str) -> None:
        """Send a message through the Telegram Bot API."""
        try:
            await self.bot.send_message(self.chat_id, message, parse_mode=ParseMode.HTML)
        except Exception as error:
            print(f"Failed to send message: {error}")

    async def main(self) -> None:
        """Main function to run the program."""
        try:
            await self.db.create_table()

            async with ClientSession() as session:
                tasks = [
                    self.process_url(session, url.strip()) for url in self.urls
                ]

                results = await asyncio.gather(*tasks)

                for result in results:
                    if result:
                        title, price = result
                        latest_price = await self.db.get_latest_price(title)
                        if latest_price:
                            previous_price = latest_price[0]
                            if previous_price != price:
                                await self.db.insert_price(
                                    title, price, previous_price
                                )
                                message = (
                                    f"Title: {title}\nCurrent Price: {price}\nPrevious Price: {previous_price}"
                                )
                                await self.send_message(message)
                        else:
                            await self.db.insert_price(title, price, None)
                            message = f"Title: {title}\nCurrent Price: {price}"
                            await self.send_message(message)

        except Exception as error:
            print(f"An error occurred during the execution of the program: {error}")


if __name__ == "__main__":
    if not os.path.exists(DB_PATH):
        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    price_checker = PriceChecker(URLS, BOT_TOKEN, CHAT_ID)
    asyncio.run(price_checker.main())
