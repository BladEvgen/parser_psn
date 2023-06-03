import requests
from bs4 import BeautifulSoup
import telebot
import os
from datetime import datetime

def old_version():
    url = "https://store.playstation.com/en-tr/product/EP9000-PPSA01341_00-DEMONSSOULS00000"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
        "authority": "store.playstation.com",
        "sec-ch-ua-platform": '"Windows"',
    }

    bot_token = "5654523027:AAGA-9KmyDaMQGUA4Y-8YlW4RBjz5-IXzhw"
    chat_id = "682832406"

    try:
        # Send a request to the website
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise an exception if the request was unsuccessful

        soup = BeautifulSoup(response.content, "html.parser")

        # Extract the title and price using XPath
        title_element = soup.find("h1")
        price_element = soup.find("span", class_="psw-t-title-m")

        title = title_element.text.strip() if title_element else "Title not found"
        price = price_element.text.strip() if price_element else "Price not found"

        message = f"Title: {title}\nPrice: {price}"

        # Initialize the Telebot
        bot = telebot.TeleBot(bot_token)
        bot.send_message(chat_id, message)
    except Exception as e:
        print(f"An error occurred: {str(e)}")

def new_version():
    # Read the URL from url.txt file
    file_path = os.path.join(os.path.dirname(__file__), "url.txt")
    with open(file_path, "r") as file:
        urls = file.read().split(",")

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
        "authority": "store.playstation.com",
        "sec-ch-ua-platform": '"Windows"',
    }

    bot_token = "5654523027:AAGA-9KmyDaMQGUA4Y-8YlW4RBjz5-IXzhw"
    chat_id = "682832406"

    try:
        for url in urls:
            url = url.strip()  # Remove leading/trailing whitespaces

            # Send a request to the website
            response = requests.get(url, headers=headers)
            response.raise_for_status()  # Raise an exception if the request was unsuccessful

            soup = BeautifulSoup(response.content, "html.parser")

            # Extract the title and price using XPath
            title_element = soup.find("h1")
            price_element = soup.find("span", class_="psw-t-title-m")

            title = title_element.text.strip() if title_element else "Title not found"
            price = price_element.text.strip() if price_element else "Price not found"
            current_datetime = datetime.now().strftime("%H:%M %d.%m.%Y")

            message = f"Current time: {current_datetime}\nTitle: {title}\nPrice: {price}"

            # Initialize the Telebot
            bot = telebot.TeleBot(bot_token)
            bot.send_message(chat_id, message)

    except Exception as e:
        print(f"An error occurred: {str(e)}")