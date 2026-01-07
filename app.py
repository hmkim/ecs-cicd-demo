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

@app.route("/error")
def error():
    return "Internal Server Error", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
