// Configuration for API endpoints - UPDATE THIS WITH YOUR VM'S IP
const VM_IP = 'YOUR_VM_EXTERNAL_IP'; // Replace with your VM's external IP
const API_BASE_URL = `http://${VM_IP}:5000/api`;

// Presentation Tier - Event Management
class EventManager {
    constructor() {
        this.eventList = document.querySelector(".event-list");
        this.bookingList = document.querySelector(".booking-list");
    }

    async loadEvents() {
        try {
            const response = await fetch(`${API_BASE_URL}/events`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const events = await response.json();
            this.renderEvents(events);
        } catch (error) {
            console.error('Error loading events:', error);
            this.showError('Failed to load events. Please check if the API server is running.');
        }
    }

    renderEvents(events) {
        if (!this.eventList) return;
        
        this.eventList.innerHTML = "";
        
        if (!events || events.length === 0) {
            this.eventList.innerHTML = "<p>No events available at the moment.</p>";
            return;
        }

        events.forEach(event => {
            const eventCard = document.createElement("div");
            eventCard.classList.add("event-card");
            eventCard.innerHTML = `
                <h3>${this.escapeHtml(event.title)}</h3>
                <p><strong>Date:</strong> ${this.escapeHtml(event.date)}</p>
                <p><strong>Location:</strong> ${this.escapeHtml(event.location)}</p>
                <button onclick="eventManager.bookTicket(${event.id}, '${this.escapeHtml(event.title)}')" 
                        class="book-btn">Book Now</button>
            `;
            this.eventList.appendChild(eventCard);
        });
    }

    async bookTicket(eventId, eventTitle) {
        const email = prompt(`Enter your email to book: ${eventTitle}`);
        if (!email || !this.validateEmail(email)) {
            alert('Please enter a valid email address.');
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/bookings`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    event_id: eventId,
                    user_email: email
                })
            });

            const result = await response.json();
            
            if (response.ok) {
                alert(`Success! ${result.message}`);
                this.loadBookings(); // Refresh bookings
            } else {
                alert(`Error: ${result.error || 'Booking failed'}`);
            }
        } catch (error) {
            console.error('Error booking ticket:', error);
            alert('Booking failed. Please check if the API server is running.');
        }
    }

    async loadBookings() {
        try {
            const response = await fetch(`${API_BASE_URL}/bookings`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const bookings = await response.json();
            this.renderBookings(bookings);
        } catch (error) {
            console.error('Error loading bookings:', error);
            if (this.bookingList) {
                this.bookingList.innerHTML = "<p>Error loading bookings.</p>";
            }
        }
    }

    renderBookings(bookings) {
        if (!this.bookingList) return;

        if (!bookings || bookings.length === 0) {
            this.bookingList.innerHTML = "<p>No bookings yet.</p>";
            return;
        }

        this.bookingList.innerHTML = bookings.map(booking => `
            <div class="booking-card">
                <strong>${this.escapeHtml(booking.event_title)}</strong><br>
                <em>${this.escapeHtml(booking.user_email)}</em><br>
                <small>Booked on: ${new Date(booking.timestamp).toLocaleDateString()}</small>
            </div>
        `).join("");
    }

    validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    showError(message) {
        if (this.eventList) {
            this.eventList.innerHTML = `<p class="error">${message}</p>`;
        }
    }
}

// Initialize when DOM is loaded
let eventManager;
document.addEventListener("DOMContentLoaded", () => {
    eventManager = new EventManager();
    eventManager.loadEvents();
    eventManager.loadBookings();
}); 