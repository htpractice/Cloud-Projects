import mysql.connector
from typing import List, Optional
import logging
from contextlib import contextmanager
from models import Event, Booking
from config import DATABASE_CONFIG

class DatabaseConnection:
    """Database connection manager for the data tier"""
    
    def __init__(self):
        self.config = DATABASE_CONFIG
        
    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = None
        try:
            conn = mysql.connector.connect(
                host=self.config.host,
                user=self.config.user,
                password=self.config.password,
                database=self.config.database,
                port=self.config.port
            )
            yield conn
        except mysql.connector.Error as e:
            logging.error(f"Database connection error: {e}")
            raise
        finally:
            if conn and conn.is_connected():
                conn.close()

class EventRepository:
    """Repository for Event data operations"""
    
    def __init__(self):
        self.db = DatabaseConnection()
    
    def get_all_events(self) -> List[Event]:
        """Retrieve all events from database"""
        with self.db.get_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT id, title, date, location FROM events ORDER BY date ASC")
            rows = cursor.fetchall()
            
            events = []
            for row in rows:
                events.append(Event(
                    id=row['id'],
                    title=row['title'],
                    date=str(row['date']),
                    location=row['location']
                ))
            return events
    
    def get_event_by_id(self, event_id: int) -> Optional[Event]:
        """Retrieve a specific event by ID"""
        with self.db.get_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT id, title, date, location FROM events WHERE id = %s", (event_id,))
            row = cursor.fetchone()
            
            if row:
                return Event(
                    id=row['id'],
                    title=row['title'],
                    date=str(row['date']),
                    location=row['location']
                )
            return None

class BookingRepository:
    """Repository for Booking data operations"""
    
    def __init__(self):
        self.db = DatabaseConnection()
    
    def create_booking(self, event_id: int, user_email: str) -> bool:
        """Create a new booking"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO bookings (event_id, user_email) VALUES (%s, %s)",
                    (event_id, user_email)
                )
                conn.commit()
                return True
        except mysql.connector.Error as e:
            logging.error(f"Error creating booking: {e}")
            return False
    
    def get_all_bookings(self) -> List[Booking]:
        """Retrieve all bookings with event information"""
        with self.db.get_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("""
                SELECT b.id, b.event_id, b.user_email, b.timestamp, e.title AS event_title
                FROM bookings b
                JOIN events e ON b.event_id = e.id
                ORDER BY b.timestamp DESC
            """)
            rows = cursor.fetchall()
            
            bookings = []
            for row in rows:
                bookings.append(Booking(
                    id=row['id'],
                    event_id=row['event_id'],
                    user_email=row['user_email'],
                    timestamp=row['timestamp'],
                    event_title=row['event_title']
                ))
            return bookings
    
    def get_bookings_by_email(self, user_email: str) -> List[Booking]:
        """Retrieve bookings for a specific user"""
        with self.db.get_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("""
                SELECT b.id, b.event_id, b.user_email, b.timestamp, e.title AS event_title
                FROM bookings b
                JOIN events e ON b.event_id = e.id
                WHERE b.user_email = %s
                ORDER BY b.timestamp DESC
            """, (user_email,))
            rows = cursor.fetchall()
            
            bookings = []
            for row in rows:
                bookings.append(Booking(
                    id=row['id'],
                    event_id=row['event_id'],
                    user_email=row['user_email'],
                    timestamp=row['timestamp'],
                    event_title=row['event_title']
                ))
            return bookings 