#!/bin/bash
yum update -y
yum install -y python3 git
pip3 install flask gunicorn
cd /home/ec2-user
# sample minimal app
cat > /home/ec2-user/app.py <<'PY'
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
PY

chown -R ec2-user:ec2-user /home/ec2-user
nohup python3 /home/ec2-user/app.py > /var/log/app.log 2>&1 &
