from flask import Flask, jsonify, request
import mysql.connector

app = Flask(__name__)

# Connect to Cloud SQL
db = mysql.connector.connect(
    host="104.198.208.198",  # or use Cloud SQL Proxy with 127.0.0.1
    user="root",
    password="M7rk|(`J&H1+*I>i",
    database="eventsdb"
)

@app.route("/api/events")
def get_events():
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM events")
    events = cursor.fetchall()
    return jsonify(events)

@app.route("/api/book", methods=["POST"])
def book_event():
    data = request.json
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO bookings (event_id, user_email) VALUES (%s, %s)",
        (data["event_id"], data["user_email"])
    )
    db.commit()
    return jsonify({"message": "Booking confirmed"}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

# Make sure to replace YOUR_DB_IP with the actual IP address of your Cloud SQL instance and youruser, yourpass with your actual database credentials.

# Ensure you have the necessary packages installed:
    # pip install Flask mysql-connector-python

# Ensure your Cloud SQL instance allows connections from your app and that you have created the necessary tables in your database.

# Also, consider using environment variables for sensitive info¯rmation like database credentials.