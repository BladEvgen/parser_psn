import asyncio
import aiohttp
from bs4 import BeautifulSoup
import telebot
import os
from datetime import datetime
import tracemalloc
import time
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

bot_token = os.getenv('bot_token')
chat_id = os.getenv('chat_id')

# Read URLs from a file and store them in a list
file_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "url", "url.txt")
with open(file_path, "r") as file:
    urls = file.read().split(",")

# Set headers for HTTP requests
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "authority": "store.playstation.com",
    "sec-ch-ua-platform": '"Windows"',
}

# Function to perform an asynchronous HTTP request using aiohttp
async def fetch(session, url):
    try:
        async with session.get(url, headers=headers) as response:
            return await response.text()
    except aiohttp.ClientError as e:
        print(f"An error occurred during the request: {e}")
        return None

# Function to process each URL asynchronously
async def process_url(url):
    try:
        async with aiohttp.ClientSession() as session:
            html = await fetch(session, url)
            if html is not None:
                soup = BeautifulSoup(html, "html.parser")
                title_element = soup.find("h1")
                price_element = soup.find("span", class_="psw-t-title-m")
                title = title_element.text.strip() if title_element else "Title not found"
                price = price_element.text.strip() if price_element else "Price not found"
                return f"Title: {title}\nPrice: {price}"
            else:
                return "Error occurred during the request."
    except Exception as e:
        print(f"An error occurred during the processing of the URL: {e}")
        return None

# Main function to run the program
async def main():
    # Start tracking memory allocation
    tracemalloc.start()
    try:
        async with aiohttp.ClientSession() as session:
            tasks = []
            results = []
            for url in urls:
                url = url.strip()
                task = asyncio.ensure_future(process_url(url))
                tasks.append(task)

            # Gather results from all the tasks
            results = await asyncio.gather(*tasks)

        # Get the current date and time
        current_datetime = datetime.now().strftime("Current time: %d.%m.%Y\n%H:%M \n\n")
        message = current_datetime + "\n\n\n".join(results)

        # Send the message using Telegram Bot API
        bot = telebot.TeleBot(bot_token)
        bot.send_message(chat_id, message, parse_mode="HTML")

        # Take a snapshot of memory allocation
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics("lineno")
        print("[ Top 10 Memory Usage ]")
        for stat in top_stats[:10]:
            print(stat)
        time.sleep(5)
        os.system("cls" if os.name == "nt" else "clear")
    except Exception as e:
        print(f"An error occurred during the execution of the program: {e}")

# Run the main function using the asyncio event loop
loop = asyncio.get_event_loop()
loop.run_until_complete(main())
