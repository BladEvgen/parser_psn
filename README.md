<head>
  <meta charset="UTF-8">
  <title>PlayStation Store Site Parser</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
    }

    h1 {
      font-size: 24px;
      margin-bottom: 10px;
    }

    p {
      margin-bottom: 10px;
    }

    ol {
      margin-bottom: 20px;
    }

    li {
      margin-bottom: 5px;
    }

    code {
      font-family: Consolas, monospace;
      background-color: #f1f1f1;
      padding: 2px;
    }

    pre {
      font-family: Consolas, monospace;
      background-color: #f1f1f1;
      padding: 10px;
      overflow: auto;
    }
  </style>
</head>
<body>
  <h1>PlayStation Store Site Parser</h1>
  <p>Here will be versions of the PlayStation Store site parser. This script receives the <code>Title</code> and <code>Price</code> of the game and sends them to Telegram through the bot. To change the list of games for which prices will be monitored, use <code>url.txt</code>. Add links to it in the following format:</p>
  <ol>
    <li>https://playstation.com/example/1,</li>
    <li>https://playstation.com/example/2,</li>
    <li>https://playstation.com/example/n</li>
  </ol>

  <p>Versions that are considered more working (in my understanding) will be located in the <code>works</code> folder. The rest, in the <code>progress</code> folder, there will be versions with different ideas and testing versions.</p>

  <p><code>.env</code> file must be located before the <code>parse</code> folder.</p>
