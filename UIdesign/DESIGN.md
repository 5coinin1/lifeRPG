# Design System Strategy: The Illuminated Archive

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Illuminated Archive."** 

We are moving away from the "dungeon-crawl" aesthetics of traditional dark-mode RPG interfaces and pivoting toward the scholarly elegance of a sun-drenched scriptorium. This system bridges the gap between 16-bit nostalgia and high-end editorial design. By combining the precision of **Space Grotesk** with a strict **0px border radius**, we create a "Digital Brutalist" manuscript. 

The design breaks the "template" look through **intentional sharp-edged layering** and **asymmetric information density**. We treat the screen not as a mobile app, but as a living document where pixel-perfect precision meets the warmth of ancient parchment.

---

## 2. Colors: Ink, Gold, and Earth
Our palette is rooted in natural pigments: iron-gall ink (`on_surface`), gold leaf (`secondary`), and cured vellum (`surface`).

### The "No-Softness" Rule
Standard UI relies on rounded corners to feel "friendly." This system rejects that. Every element is a hard-edged polygon. Softness is achieved exclusively through the **warmth of the color palette**, never through geometry.

### Surface Hierarchy & Nesting
Depth is achieved through "Tonal Stacking" rather than shadows:
*   **Base Layer:** `surface` (#fcf9f0) — The main "tabletop" or desk.
*   **Primary Containers:** `surface_container_low` (#f6f3ea) — Used for secondary sidebars.
*   **Active Elements:** `surface_container_highest` (#e5e2da) — Used for active menu selections or focused content.
*   **The Inset Rule:** To create a "pressed" look (common in classic RPG menus), use `surface_dim` for the background of a scrollable area to make it feel recessed into the parchment.

### Signature Textures & Gradients
While the system is largely flat, use a **Subtle Linear Gradient** (Primary to Primary Container) for high-level quest headers or Boss HP bars. This provides a "metallic" or "liquid" soul to the UI that flat colors cannot replicate.

---

## 3. Typography: The Modern Scribe
We use **Space Grotesk** exclusively. Its quirky, technical terminals mimic the precision of a master calligrapher’s nib while maintaining perfect legibility.

*   **Display (lg/md):** Use for Level Up screens or Chapter titles. These should be tracked tightly (-0.02em) to feel like a printed header.
*   **Headline (sm/md):** Your primary navigation headers. Use `on_surface` to mimic heavy ink.
*   **Body (lg/md):** High-contrast ink on parchment. Ensure `on_surface` is used against `surface` for maximum readability.
*   **Label (sm):** Used for "Micro-stats" (e.g., +15 ATK). These should often be paired with the `secondary` (Gold) color to denote value and rarity.

---

## 4. Elevation & Depth: Tonal Layering
Traditional structural lines (1px borders) are largely forbidden for sectioning. We define boundaries through **Hard Color Shifts**.

*   **The Layering Principle:** Instead of a drop shadow, a "floating" modal is defined by being `surface_container_lowest` (#ffffff) with a **Sharp 2px Stroke** using `on_surface`. This creates a "sticker" effect common in high-end indie RPGs.
*   **The "Ghost Border" Fallback:** If a divider is required for dense data tables, use `outline_variant` at **20% opacity**. It should be felt, not seen.
*   **Pixel-Perfect Accents:** Use `primary` (#77574d) as a "thick" 4px bottom-border on active tabs to simulate the physical thickness of stacked paper.

---

## 5. Components

### Buttons
*   **Primary:** Background `primary`, Text `on_primary`. Hard 90-degree corners. On hover, shift to `primary_container`.
*   **Secondary (The Gold Standard):** Background `secondary`, Text `on_secondary`. Used for "Confirm," "Buy," or "Equip."
*   **Tertiary:** No background. `on_surface` text with a 2px bottom border that appears only on hover.

### Bars (Health/Mana/XP)
*   **Health:** `error` (#ba1a1a) vs `error_container`.
*   **Mana:** `tertiary` (#1b6d24) vs `tertiary_container`. 
*   *Note:* All bars must have a 2px `on_surface` border to maintain the "inked" manuscript aesthetic.

### Cards & Lists
*   **Forbid Divider Lines:** Use `surface_container_low` for the card background and `surface_container_high` for the header of the card.
*   **Interaction:** On hover, a list item should shift to `secondary_fixed` (light gold) to provide a "highlighted text" effect.

### Input Fields
*   **Styling:** A simple `surface_dim` background with a heavy 2px bottom-stroke of `on_surface`.
*   **Focus State:** The bottom-stroke changes to `secondary` (Gold), and the label (Space Grotesk Bold) shifts to `primary`.

### RPG-Specific Components
*   **The "Loot Box":** A container using `surface_container_lowest` with a double-border (a 1px `outline` nested inside a 4px `on_surface` border).
*   **Stat Tags:** Selection chips using `primary_fixed` with `on_primary_fixed` text. Sharp corners only.

---

## 6. Do's and Don'ts

### Do:
*   **Use Asymmetry:** Place stats on the right and descriptions on the left with uneven gutter widths to mimic a hand-laid manuscript.
*   **Lean into High Contrast:** Use `on_surface` (#1c1c17) for all critical text. It should feel like dark ink on light paper.
*   **Embrace the Grid:** Everything should align to a 4px or 8px pixel grid to honor the 16-bit inspiration.

### Don't:
*   **No Border Radius:** Never use `border-radius`. If a button looks "too sharp," adjust the padding, not the corners.
*   **No Standard Grays:** Avoid neutral grays. Every "neutral" in this system is tinted with yellow or brown (`surface_variant`, `outline`) to maintain the "warm stone/parchment" temperature.
*   **No Blurred Shadows:** If you need a shadow for a floating "Inventory" window, use a **Hard Offset Shadow** (e.g., `4px 4px 0px 0px rgba(28, 28, 23, 0.2)`) to mimic 16-bit sprite shadows.