import asyncio
import aiohttp
from bs4 import BeautifulSoup
import telebot
import os
from datetime import datetime
import tracemalloc
import time

# Чтение url из файла, также установка директории поумолчанию где лежит основной файл
file_path = os.path.join(os.path.dirname(__file__), "url.txt")
with open(file_path, "r") as file:
    urls = file.read().split(",")
# Устанавливаем заголовки для HTTP-запросов.
# Эти заголовки могут быть использованы для подделки данных о браузере и платформе.
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "authority": "store.playstation.com",
    "sec-ch-ua-platform": '"Windows"',
}
# Устанавливаем токен и ID чата для отправки сообщений через Telegram Bot API.
# Здесь приведены значения по умолчанию, которые можно заменить своими данными.
bot_token = "5654523027:AAGA-9KmyDaMQGUA4Y-8YlW4RBjz5-IXzhw"
chat_id = "431390376"


# Функция fetch выполняет асинхронный HTTP-запрос с использованием aiohttp. Она отправляет GET-запрос на указанный URL с заданными заголовками и возвращает текст ответа.
async def fetch(session, url):
    async with session.get(url, headers=headers) as response:
        return await response.text()


# Функция process_url обрабатывает каждый URL. Она создает новую сессию aiohttp.
# ClientSession, выполняет запрос с помощью функции fetch, парсит HTML-код с помощью BeautifulSoup и извлекает заголовок и цену (если они присутствуют).
# Затем она формирует сообщение с текущей датой и временем, заголовком и ценой, и отправляет его через Telegram Bot API.
async def process_url(url):
    async with aiohttp.ClientSession() as session:
        html = await fetch(session, url)
        soup = BeautifulSoup(html, "html.parser")
        title_element = soup.find("h1")
        price_element = soup.find("span", class_="psw-t-title-m")
        title = title_element.text.strip() if title_element else "Title not found"
        price = price_element.text.strip() if price_element else "Price not found"

        return f"Title: {title}\nPrice: {price}"



async def main():
    tracemalloc.start()
    async with aiohttp.ClientSession() as session:
        tasks = []
        results = []  # Список для хранения результатов обработки каждого URL
        for url in urls:
            url = url.strip()
            task = asyncio.ensure_future(process_url(url))
            tasks.append(task)

        results = await asyncio.gather(*tasks)

    # Добавляем текущую дату и время в начало строки
    current_datetime = datetime.now().strftime("Current time: %d.%m.%Y\n%H:%M \n\n")
    message = current_datetime + "\n\n\n".join(results)

    # Отправляем сообщение через Telegram Bot API
    bot = telebot.TeleBot(bot_token)
    bot.send_message(chat_id, message, parse_mode="HTML")

    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics("lineno")
    print("[ Top 10 Memory Usage ]")
    for stat in top_stats[:10]:
        print(stat)
    time.sleep(5)
    os.system("cls" if os.name == "nt" else "clear")




loop = asyncio.get_event_loop()
loop.run_until_complete(main())