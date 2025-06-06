-- LookMyShow Database Schema for Three-Tier Architecture (Manual Deployment)
-- Data Tier: MySQL database schema

-- Create database (if not exists)
CREATE DATABASE IF NOT EXISTS eventsdb;
USE eventsdb;

-- Events table
CREATE TABLE IF NOT EXISTS events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    location VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_date (date),
    INDEX idx_location (location)
);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('confirmed', 'cancelled') DEFAULT 'confirmed',
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    INDEX idx_user_email (user_email),
    INDEX idx_event_id (event_id),
    INDEX idx_timestamp (timestamp)
);

-- Insert sample events data
INSERT INTO events (title, date, location, description) VALUES
('Coldplay Concert', '2025-01-20', 'Mumbai, India', 'Experience the magic of Coldplay live in concert'),
('Comedy Night', '2025-01-25', 'Delhi, India', 'A night full of laughter with top comedians'),
('Art Exhibition', '2025-02-10', 'Bangalore, India', 'Contemporary art exhibition featuring local artists'),
('Tech Conference', '2025-02-15', 'Pune, India', 'Annual technology conference with industry leaders'),
('Music Festival', '2025-03-01', 'Goa, India', 'Three-day music festival featuring multiple genres')
ON DUPLICATE KEY UPDATE 
    title = VALUES(title),
    date = VALUES(date),
    location = VALUES(location),
    description = VALUES(description);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_events_title_date ON events(title, date);
CREATE INDEX IF NOT EXISTS idx_bookings_email_event ON bookings(user_email, event_id);

-- Show tables and sample data
SHOW TABLES;
SELECT 'Events in database:' as info;
SELECT * FROM events;
SELECT 'Sample bookings:' as info;
SELECT COUNT(*) as total_bookings FROM bookings; 