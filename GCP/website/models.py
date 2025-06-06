from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime

@dataclass
class Event:
    """Event data model"""
    id: int
    title: str
    date: str
    location: str
    description: Optional[str] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'title': self.title,
            'date': self.date,
            'location': self.location,
            'description': self.description
        }

@dataclass
class Booking:
    """Booking data model"""
    id: int
    event_id: int
    user_email: str
    timestamp: datetime
    event_title: Optional[str] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'event_id': self.event_id,
            'user_email': self.user_email,
            'timestamp': self.timestamp.isoformat() if isinstance(self.timestamp, datetime) else str(self.timestamp),
            'event_title': self.event_title
        } 