from flask import Flask, jsonify, request
app = Flask(__name__)
DATA = {}
@app.route("/", methods=["GET"])
def index():
    return "Hello from Python CRUD App", 200
@app.route("/items", methods=["GET","POST"])
def items():
    if request.method == "POST":
        payload = request.json or {}
        key = str(len(DATA)+1)
        DATA[key] = payload
        return {"id": key, "data": payload}, 201
    return DATA, 200
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
