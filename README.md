  <h1>PlayStation Store Site Parser</h1>
  <p>Here will be versions of the PlayStation Store site parser. This script receives the <code>Title</code> and <code>Price</code> of the game and sends them to Telegram through the bot. To change the list of games for which prices will be monitored, use <code>url.txt</code>. Add links to it in the following format:</p>
  <ul>
    <li>https://playstation.com/example/1,</li>
    <li>https://playstation.com/example/2,</li>
    <li>https://playstation.com/example/n</li>
  </ul>

  <p>Versions that are considered more working (in my understanding) will be located in the <code>works</code> folder. The rest, in the <code>progress</code> folder, there will be versions with different ideas and testing versions.</p>

  <p><code>.env</code> file must be located before the <code>parse</code> folder.</p>

  <h2>Installation</h2>
  <ol>
    <li>Clone the repository to your local machine:
      <pre><code>git clone &lt;repository-url&gt;</code></pre>
    </li>
    <li>Navigate to the project directory:
      <pre><code>cd parser_psn</code></pre>
    </li>
        <li>Create a new environment:
      <pre><code>python3 -m venv env</code></pre>
    </li>
    <li>Install the required dependencies:
      <pre><code>pip install -r requirements.txt</code></pre>
    </li>
  </ol>

  <h2>Configuration</h2>
  <ol>
    <li>Create a <code>.env</code> file in the project's root directory.</li>
    <li>Open the <code>.env</code> file and add the following configuration variables:
      <pre><code>bot_token=&lt;your-telegram-bot-token&gt;
chat_id=&lt;your-telegram-chat-id&gt;</code></pre>
      Replace <code>&lt;your-telegram-bot-token&gt;</code> with the token of your Telegram bot, and <code>&lt;your-telegram-chat-id&gt;</code> with the ID of the chat or channel where you want to receive the parsed information.
    </li>
  </ol>

  <h2>Usage</h2>
  <ol>
    <li>Edit the <code>url.txt</code> file in the <code>url</code> folder and add the URLs of the PlayStation Store pages you want to monitor. Each URL should be on a separate line.</li>
    <li>Run the parser script using the following command:
      <pre><code>python3 parser.py</code></pre>
      This will start the parser, which will fetch the title and price of each game from the provided URLs.
    </li>
    <li>The parsed information will be sent to your Telegram chat or channel using the configured bot. You can check your chat or channel to view the received messages.</li>
  </ol>

  <h2>Scheduling Automatic Execution</h2>
  <p>To schedule the parser script for automatic execution at specific intervals, you can use a task scheduler like cron (on Linux) or Task Scheduler (on Windows). Here's an example of how to set up a cron job for the parser:</p>
  <ol>
    <li>Open the crontab file:
      <pre><code>crontab -e</code></pre>
    </li>
    <li>Add a new line to schedule the parser script. For example, to run the script every 8 hours, add the following line:
      <pre><code>0 */8 * * * cd /path/to/parser_psn &amp;&amp; /path/to/env/bin/python3.11 parser.py</code></pre>
      Replace <code>/path/to/parser_psn</code> with the actual path to the project directory.
    </li>
    <li>Save and exit the crontab file. The parser will now run automatically according to the scheduled interval.</li>
  </ol>