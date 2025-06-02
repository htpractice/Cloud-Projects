document.addEventListener("DOMContentLoaded", () => {
  const staticEvents = [
    {
      id: 1,
      title: "Coldplay Concert",
      date: "2025-01-20",
      location: "Mumbai, India",
    },
    {
      id: 2,
      title: "Comedy Night",
      date: "2025-01-25",
      location: "Delhi, India",
    },
    {
      id: 3,
      title: "Art Exhibition",
      date: "2025-02-10",
      location: "Bangalore, India",
    },
  ];

  const eventList = document.querySelector(".event-list");

  function renderEvents(events) {
    eventList.innerHTML = "";
    events.forEach(event => {
      const eventId = event.id || event.title; // fallback for static
      eventCard = document.createElement("div");
      eventCard.classList.add("event-card");
      eventCard.innerHTML = `
        <h3>${event.title}</h3>
        <p>Date: ${event.date}</p>
        <p>Location: ${event.location}</p>
        <button onclick="bookTicket('${event.title}', '${eventId}')">Book Now</button>
      `;
      eventList.appendChild(eventCard);
    });
  }

  // Try to load from server
  fetch("http://YOUR_VM_IP/events.php")
    .then(res => res.ok ? res.json() : Promise.reject())
    .then(events => Array.isArray(events) && events.length ? renderEvents(events) : renderEvents(staticEvents))
    .catch(() => renderEvents(staticEvents));
});

function bookTicket(eventTitle, eventId) {
  const email = prompt(`Enter your email to book: ${eventTitle}`);
  fetch("http://YOUR_VM_IP/book.php", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ event_id: eventId, user_email: email })
  })
  .then(res => res.json())
  .then(data => alert(data.message))
  .catch(err => alert("Booking failed."));
}
// Replace YOUR_VM_IP with the actual IP address of your VM
function fetchBookings() {
  fetch("http://YOUR_VM_IP/list_bookings.php")
    .then(res => res.ok ? res.json() : Promise.reject())
    .then(bookings => {
      const bookingList = document.querySelector(".booking-list");
      if (!bookingList) return;

      if (bookings.length === 0) {
        bookingList.innerHTML = "<p>No bookings yet.</p>";
        return;
      }

      bookingList.innerHTML = bookings.map(b => `
        <div class="booking-card">
          <strong>${b.event_title}</strong><br>
          <em>${b.user_email}</em><br>
          <small>${b.timestamp}</small>
        </div>
      `).join("");
    })
    .catch(() => {
      document.querySelector(".booking-list").innerHTML = "<p>Error loading bookings.</p>";
    });
}

fetchBookings(); // Call it after page load
// Call this function to fetch bookings when needed
// This function can be called on a button click or periodically to refresh the booking list
// Ensure to replace YOUR_VM_IP with the actual IP address of your VM