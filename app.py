from flask import Flask, render_template

import signal
import os
app = Flask(__name__)

@app.route("/")
def hello():
    return render_template("index.html", message="Hello World!222")

@app.route("/health")
def health():
    return "SUCCESS", 200

@app.route("/oom")
def oom():
    data = []
    while True:
        data.append('x' * 10 * 1024 * 1024)  # 10MB씩 무한 할당

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
