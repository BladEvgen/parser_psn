import asyncio
import os
from datetime import datetime
import aiosqlite
import aiohttp
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from aiogram import Bot, types
from aiogram.dispatcher import Dispatcher
from aiogram.types import ParseMode

dotenv_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

BOT_TOKEN = os.getenv("bot_token")
CHAT_ID = os.getenv("chat_id")

# Read URLs from a file and store them in a list
file_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "url", "url.txt")
with open(file_path, "r", encoding="utf-8") as file:
    URLS = file.read().split(",")

# Set headers for HTTP requests
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "authority": "store.playstation.com",
    "sec-ch-ua-platform": '"Windows"',
}

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "db", "price.db")


class Database:
    """class Database interface"""

    def __init__(self, db_path):
        self.db_path = db_path

    async def create_table(self):
        """Create the database table if it does not exist"""
        async with aiosqlite.connect(self.db_path) as conn:
            cursor = await conn.cursor()
            await cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS prices (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT,
                    current_price REAL,
                    previous_price REAL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """
            )
            await conn.commit()

    async def insert_price(self, title, current_price, previous_price):
        """Insert a new price into the database"""
        async with aiosqlite.connect(self.db_path) as conn:
            cursor = await conn.cursor()
            await cursor.execute(
                """
                INSERT INTO prices (title, current_price, previous_price) VALUES (?, ?, ?)
            """,
                (title, current_price, previous_price),
            )
            await conn.commit()

    async def get_latest_price(self, title):
        """Get the latest price from the database"""
        async with aiosqlite.connect(self.db_path) as conn:
            cursor = await conn.cursor()
            await cursor.execute(
                """
                SELECT current_price, previous_price FROM prices WHERE title = ?
                ORDER BY timestamp DESC LIMIT 1
            """,
                (title,),
            )
            result = await cursor.fetchone()
        return result


class PriceChecker:
    """Price Checker class interface"""

    def __init__(self, urls, bot_token, chat_id):
        self.urls = urls
        self.bot_token = bot_token
        self.chat_id = chat_id
        self.db = Database(DB_PATH)
        self.bot = Bot(token=bot_token)
        self.dp = Dispatcher(self.bot)

    async def fetch(self, session, url):
        """
        Perform an asynchronous HTTP request using aiohttp.

        Args:
            session (aiohttp.ClientSession): The aiohttp client session.
            url (str): The URL to fetch.

        Returns:
            str: The response text.
        """
        try:
            async with session.get(url, headers=HEADERS) as response:
                return await response.text()
        except aiohttp.ClientError as error:
            print(f"An error occurred during the request: {error}")
            return None

    async def process_url(self, url):
        """
        Process each URL asynchronously.

        Args:
            url (str): The URL to process.

        Returns:
            str: The processed result.
        """
        try:
            async with aiohttp.ClientSession() as session:
                html = await self.fetch(session, url)
                if html is not None:
                    soup = BeautifulSoup(html, "html.parser")
                    title_element = soup.find("h1")
                    price_element = soup.find("span", class_="psw-t-title-m")
                    title = (
                        title_element.text.strip()
                        if title_element
                        else "Title not found"
                    )
                    price = (
                        price_element.text.strip()
                        if price_element
                        else "Price not found"
                    )
                    return title, price
                else:
                    return "Error occurred during the request."
        except Exception as error:
            print(f"An error occurred during the processing of the URL: {error}")
            return None

    async def send_message(self, message):
        """Send a message through the Telegram Bot API"""
        await self.bot.send_message(self.chat_id, message, parse_mode=ParseMode.HTML)

    async def main(self):
        """
        Main function to run the program.
        """
        try:
            await self.db.create_table()

            tasks = []
            for url in self.urls:
                url = url.strip()
                task = asyncio.create_task(self.process_url(url))
                tasks.append(task)

            # Gather results from all the tasks
            results = await asyncio.gather(*tasks)

            # Get the current date and time
            current_time = datetime.now().strftime("Current time: %d.%m.%Y\n%H:%M \n\n")

            for result in results:
                title, price = result
                latest_price = await self.db.get_latest_price(title)
                if latest_price is not None:
                    previous_price = latest_price[0]
                    if previous_price != price:
                        await self.db.insert_price(title, price, previous_price)
                        message = f"Title: {title}\nCurrent Price: {price}\nPrevious Price: {previous_price}"
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
    loop = asyncio.get_event_loop()
    loop.run_until_complete(price_checker.main())
