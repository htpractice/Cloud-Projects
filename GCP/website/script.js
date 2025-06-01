document.addEventListener("DOMContentLoaded", () => {
  const staticEvents = [
    {
      title: "Coldplay Concert",
      date: "2025-01-20",
      location: "Mumbai, India",
    },
    {
      title: "Comedy Night",
      date: "2025-01-25",
      location: "Delhi, India",
    },
    {
      title: "Art Exhibition",
      date: "2025-02-10",
      location: "Bangalore, India",
    },
  ];

  const eventList = document.querySelector(".event-list");

  function renderEvents(events) {
    eventList.innerHTML = "";
    events.forEach(event => {
      const eventCard = document.createElement("div");
      eventCard.classList.add("event-card");
      // Use event.id if available, else fallback to event.title
      const eventId = event.id || event.title;
      eventCard.innerHTML = `
        <h3>${event.title}</h3>
        <p>Date: ${event.date}</p>
        <p>Location: ${event.location}</p>
        <button onclick="bookTicket('${eventId}')">Book Now</button>
      `;
      eventList.appendChild(eventCard);
    });
  }

  // Try to fetch events from API, fallback to static events if failed
  fetch("/api/events")
    .then(res => res.ok ? res.json() : Promise.reject())
    .then(events => {
      if (Array.isArray(events) && events.length > 0) {
        renderEvents(events);
      } else {
        renderEvents(staticEvents);
      }
    })
    .catch(() => {
      renderEvents(staticEvents);
    });
});

function bookTicket(eventId) {
  fetch("/api/book", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ event_id: eventId, user_email: "user@example.com" }),
  })
    .then(res => res.json())
    .then(msg => alert(msg.message))
    .catch(() => alert("Booking failed. Please try again."));
}
