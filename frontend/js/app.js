"use strict";

const menuToggle = document.querySelector(".menu-toggle");
const navigationMenu = document.querySelector("#navigation-menu");
const navigationLinks = document.querySelectorAll("#navigation-menu a");
const currentYear = document.querySelector("#current-year");

if (currentYear) {
    currentYear.textContent = new Date().getFullYear();
}

if (menuToggle && navigationMenu) {
    menuToggle.addEventListener("click", () => {
        const isOpen = navigationMenu.classList.toggle("is-open");

        menuToggle.setAttribute("aria-expanded", String(isOpen));
    });
}

navigationLinks.forEach((link) => {
    link.addEventListener("click", () => {
        navigationMenu?.classList.remove("is-open");
        menuToggle?.setAttribute("aria-expanded", "false");
    });
});

// -----------------------------------------------------------------------------
// Visitor Analytics
// -----------------------------------------------------------------------------

const visitorCount = document.querySelector("#visitor-count");

const VISITOR_API_URL =
    "https://sqk3sg1oj5.execute-api.us-east-1.amazonaws.com/dev/visitor";

/**
 * Increment the portfolio page-view counter and display the current count.
 *
 * The visitor analytics API uses an atomic DynamoDB update through the
 * serverless backend. A backend failure must not prevent the portfolio
 * from loading normally.
 */
async function updateVisitorCount() {
    if (!visitorCount) {
        return;
    }

    visitorCount.textContent = "Loading...";

    try {
        const response = await fetch(VISITOR_API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            }
        });

        if (!response.ok) {
            throw new Error(`Visitor API returned HTTP ${response.status}`);
        }

        const data = await response.json();

        if (
            typeof data.count !== "number" ||
            !Number.isInteger(data.count) ||
            data.count < 0
        ) {
            throw new Error("Visitor API returned an invalid count.");
        }

        visitorCount.textContent = data.count.toLocaleString();
    } catch (error) {
        console.error("Unable to retrieve visitor count:", error);

        visitorCount.textContent = "Unavailable";
    }
}

updateVisitorCount();