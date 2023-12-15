import os
import requests
import sqlite3
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from telegram import Update
from telegram.ext import Updater, CommandHandler, CallbackContext

dotenv_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"
)
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

BOT_TOKEN = os.getenv("bot_token")

db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "url", "url.db")

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "authority": "store.playstation.com",
    "sec-ch-ua-platform": '"Windows"',
}


class PriceChecker:
    def __init__(self):
        self.urls = self.get_urls_from_db()

    def get_urls_from_db(self):
        urls = []
        with sqlite3.connect(db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT url FROM urls")

            urls = [row[0] for row in cursor.fetchall()]
        return urls

    def fetch(self, url):
        try:
            response = requests.get(url, headers=HEADERS)
            response.raise_for_status()
            return response.text
        except requests.RequestException as error:
            print(f"An error occurred during the request: {error}")
            return None

    def process_url(self, url):
        try:
            html = self.fetch(url)
            if html is not None:
                soup = BeautifulSoup(html, "html.parser")
                title_element = soup.find("h1")
                price_element = soup.find("span", class_="psw-t-title-m")
                title = (
                    title_element.text.strip() if title_element else "Title not found"
                )
                price = (
                    price_element.text.strip() if price_element else "Price not found"
                )
                return title, price
            else:
                return "Error occurred during the request."
        except Exception as error:
            print(f"An error occurred during the processing of the URL: {error}")
            return None

    def send_message(self, context: CallbackContext, message, chat_id):
        context.bot.send_message(chat_id, message, parse_mode="HTML")

    def main(self, context: CallbackContext, chat_id):
        try:
            for url in self.urls:
                url = url.strip()
                result = self.process_url(url)

                title, price = result
                message = f"Title: {title}\nCurrent Price: {price}"
                self.send_message(context, message, chat_id)
        except Exception as error:
            print(f"An error occurred during the execution of the program: {error}")


def handle_start(update: Update, context: CallbackContext):
    chat_id = update.message.chat_id
    start_message = (
        "Hi, I'm the PSN parser bot!\n\n"
        "You can find the full instructions and the source code on GitHub:\n"
        "[GitHub Repository](https://github.com/BladEvgen/parser_psn)\n\n"
        "To use me, just send the command:\n\n(please wait some time and I'll try to send the message with the response)\n\n"
        "/check\n\n"
        "I'll send you the current prices for the already added URLs.\n"
        "Please note that prices are for Turkey PSN and include both Ps5 and Ps4 games."
    )
    context.bot.send_message(chat_id, start_message, parse_mode="Markdown")


def handle_check(update: Update, context: CallbackContext):
    chat_id = update.message.chat_id
    price_checker = PriceChecker()
    context.user_data["price_checker"] = price_checker
    price_checker.main(context, chat_id)


if __name__ == "__main__":
    updater = Updater(token=BOT_TOKEN, use_context=True)
    dp = updater.dispatcher

    dp.add_handler(CommandHandler("start", handle_start))
    dp.add_handler(CommandHandler("check", handle_check))

    updater.start_polling()
    updater.idle()
