# import time
# import requests
# from lxml import etree
# from selenium import webdriver
# from selenium.webdriver.chrome.service import Service
# from selenium.webdriver.common.by import By
# from selenium.webdriver.chrome.options import Options
# from webdriver_manager.chrome import ChromeDriverManager
# import telebot

# url = "https://store.playstation.com/en-tr/product/EP4497-PPSA04027_00-00000000000000N1"
# headers = {
#     "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
#     "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
#     "authority": "store.playstation.com",
#     "sec-ch-ua-mobile": "?1",
#     "sec-ch-ua-platform": '"Windows"',
# }

# # Configure Chrome options and set the user agent
# chrome_options = Options()
# chrome_options.add_argument("--headless")  # Run in headless mode (without opening a browser window)
# chrome_options.add_argument(f"user-agent={headers['User-Agent']}")

# # Setup the Chrome driver service
# webdriver_service = Service(ChromeDriverManager().install())

# # Create a new instance of the Chrome driver
# driver = webdriver.Chrome(service=webdriver_service, options=chrome_options)

# # Navigate to the URL
# driver.get(url)

# # Wait for the page to load (adjust the sleep time if needed)
# time.sleep(5)

# # Take a screenshot of the webpage
# screenshot_path = "screenshot.png"
# driver.save_screenshot(screenshot_path)

# # Parse the HTML content
# html_content = driver.page_source
# html_tree = etree.HTML(html_content)

# # Find the element using XPath
# xpath_expression = "/html/body/div[3]/main/div/div[1]/div[3]/div[2]/div/div/div/div[2]/div/div/div/div/label[1]/div[2]/span/span/span"
# element = html_tree.xpath(xpath_expression)
# xpath_expression_1 = "/html/body/div[3]/main/div/div[1]/div[3]/div[2]/div/div/div/div[1]/div/div/div/h1"
# element_1 = html_tree.xpath(xpath_expression_1)

# # Extract the value
# if element:
#     value = element[0].text
#     title = element_1[0].text
#     print("Title:", title)
#     print("Value:", value)

#     # Initialize the Telegram bot
#     bot_token = "5654523027:AAGA-9KmyDaMQGUA4Y-8YlW4RBjz5-IXzhw"
#     chat_id = "682832406"
#     bot = telebot.TeleBot(bot_token)

#     # Send the value via Telegram
#     message = f"Title: {title}\nValue: {value}"
#     bot.send_message(chat_id, message)
# else:
#     print("Element not found.")

# # Quit the browser
# driver.quit()


