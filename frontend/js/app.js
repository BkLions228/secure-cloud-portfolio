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