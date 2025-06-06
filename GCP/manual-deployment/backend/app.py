from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
from config import API_CONFIG, CORS_ORIGINS
from services import EventService, BookingService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Configure CORS
CORS(app, origins=CORS_ORIGINS)

# Initialize services
event_service = EventService()
booking_service = BookingService()

@app.route("/api/events", methods=["GET"])
def get_events():
    """Get all events - Application Tier endpoint"""
    try:
        events = event_service.get_all_events()
        return jsonify(events), 200
    except Exception as e:
        logger.error(f"Error in get_events: {e}")
        return jsonify({"error": "Failed to retrieve events"}), 500

@app.route("/api/events/<int:event_id>", methods=["GET"])
def get_event(event_id):
    """Get a specific event - Application Tier endpoint"""
    try:
        event = event_service.get_event_by_id(event_id)
        if event:
            return jsonify(event), 200
        else:
            return jsonify({"error": "Event not found"}), 404
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in get_event: {e}")
        return jsonify({"error": "Failed to retrieve event"}), 500

@app.route("/api/bookings", methods=["POST"])
def create_booking():
    """Create a new booking - Application Tier endpoint"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        event_id = data.get("event_id")
        user_email = data.get("user_email")
        
        if not event_id or not user_email:
            return jsonify({"error": "event_id and user_email are required"}), 400
        
        result = booking_service.create_booking(event_id, user_email)
        return jsonify(result), 201
        
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in create_booking: {e}")
        return jsonify({"error": "Booking failed"}), 500

@app.route("/api/bookings", methods=["GET"])
def get_bookings():
    """Get all bookings - Application Tier endpoint"""
    try:
        bookings = booking_service.get_all_bookings()
        return jsonify(bookings), 200
    except Exception as e:
        logger.error(f"Error in get_bookings: {e}")
        return jsonify({"error": "Failed to retrieve bookings"}), 500

@app.route("/api/bookings/user/<email>", methods=["GET"])
def get_user_bookings(email):
    """Get bookings for a specific user - Application Tier endpoint"""
    try:
        bookings = booking_service.get_user_bookings(email)
        return jsonify(bookings), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error in get_user_bookings: {e}")
        return jsonify({"error": "Failed to retrieve user bookings"}), 500

@app.route("/api/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "LookMyShow API"}), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    logger.info(f"Starting LookMyShow API on {API_CONFIG.host}:{API_CONFIG.port}")
    app.run(
        host=API_CONFIG.host,
        port=API_CONFIG.port,
        debug=API_CONFIG.debug
    ) 