from typing import List, Optional, Dict, Any
import logging
import re
from data_access import EventRepository, BookingRepository
from models import Event, Booking

class EventService:
    """Business logic for event management"""
    
    def __init__(self):
        self.event_repository = EventRepository()
    
    def get_all_events(self) -> List[Dict[str, Any]]:
        """Get all events with business logic applied"""
        try:
            events = self.event_repository.get_all_events()
            return [event.to_dict() for event in events]
        except Exception as e:
            logging.error(f"Error retrieving events: {e}")
            raise Exception("Failed to retrieve events")
    
    def get_event_by_id(self, event_id: int) -> Optional[Dict[str, Any]]:
        """Get a specific event by ID"""
        try:
            if event_id <= 0:
                raise ValueError("Event ID must be positive")
            
            event = self.event_repository.get_event_by_id(event_id)
            return event.to_dict() if event else None
        except ValueError as e:
            logging.error(f"Invalid event ID: {e}")
            raise
        except Exception as e:
            logging.error(f"Error retrieving event {event_id}: {e}")
            raise Exception("Failed to retrieve event")

class BookingService:
    """Business logic for booking management"""
    
    def __init__(self):
        self.booking_repository = BookingRepository()
        self.event_repository = EventRepository()
    
    def create_booking(self, event_id: int, user_email: str) -> Dict[str, Any]:
        """Create a new booking with validation"""
        try:
            # Validate input
            if not self._validate_event_id(event_id):
                raise ValueError("Invalid event ID")
            
            if not self._validate_email(user_email):
                raise ValueError("Invalid email address")
            
            # Check if event exists
            event = self.event_repository.get_event_by_id(event_id)
            if not event:
                raise ValueError("Event not found")
            
            # Create booking
            success = self.booking_repository.create_booking(event_id, user_email)
            if not success:
                raise Exception("Failed to create booking")
            
            return {
                "message": "Booking confirmed",
                "event_title": event.title,
                "user_email": user_email
            }
            
        except ValueError as e:
            logging.error(f"Validation error: {e}")
            raise
        except Exception as e:
            logging.error(f"Error creating booking: {e}")
            raise Exception("Booking failed")
    
    def get_all_bookings(self) -> List[Dict[str, Any]]:
        """Get all bookings"""
        try:
            bookings = self.booking_repository.get_all_bookings()
            return [booking.to_dict() for booking in bookings]
        except Exception as e:
            logging.error(f"Error retrieving bookings: {e}")
            raise Exception("Failed to retrieve bookings")
    
    def get_user_bookings(self, user_email: str) -> List[Dict[str, Any]]:
        """Get bookings for a specific user"""
        try:
            if not self._validate_email(user_email):
                raise ValueError("Invalid email address")
            
            bookings = self.booking_repository.get_bookings_by_email(user_email)
            return [booking.to_dict() for booking in bookings]
        except ValueError as e:
            logging.error(f"Validation error: {e}")
            raise
        except Exception as e:
            logging.error(f"Error retrieving user bookings: {e}")
            raise Exception("Failed to retrieve user bookings")
    
    def _validate_event_id(self, event_id: int) -> bool:
        """Validate event ID"""
        return isinstance(event_id, int) and event_id > 0
    
    def _validate_email(self, email: str) -> bool:
        """Validate email format"""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return isinstance(email, str) and re.match(email_pattern, email) is not None 