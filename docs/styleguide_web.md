# ExecPrompt Web Style Guide

## Overview
This style guide translates the cyberpunk/futurism aesthetic of ExecPrompt to web technologies (HTML, CSS, JavaScript). Build websites with the same distinctive terminal-inspired look and feel as the ExecPrompt Flutter app, perfect for creating a cohesive brand presence for DayOfGeek.com applications.

**Brand Identity:** DayOfGeek.com  
**Design Philosophy:** Cyberpunk Terminal / Retro-Futurism  
**Target:** Marketing sites, documentation, web applications  
**Framework Agnostic:** Works with vanilla HTML/CSS, React, Vue, Svelte, etc.

---

## Table of Contents
1. [Color Palettes](#color-palettes)
2. [Typography](#typography)
3. [CSS Architecture](#css-architecture)
4. [Component Library](#component-library)
5. [Layout System](#layout-system)
6. [Animations & Effects](#animations--effects)
7. [Responsive Design](#responsive-design)
8. [Code Examples](#code-examples)

---

## Color Palettes

### CSS Custom Properties Setup

Define your theme using CSS custom properties (CSS variables) for easy theming:

```css
:root {
  /* P1 Green - Classic Terminal */
  --bg-primary: #0A0F0A;
  --bg-surface: #0F1A0F;
  --bg-surface-light: #162016;
  --color-primary: #33FF33;
  --color-primary-dim: #1A8A1A;
  --color-text: #33FF33;
  --color-text-dim: #1A6B1A;
  --color-accent: #66FF66;
  --color-error: #FF3333;
  --color-border: #1A3A1A;
  --color-user: #1A2F1A;
  --color-bot: #0F1A0F;
  --color-input: #0F1A0F;
  
  /* Typography */
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
  --font-size-h1: 18px;
  --font-size-h2: 16px;
  --font-size-h3: 14px;
  --font-size-body: 13px;
  --font-size-caption: 12px;
  --font-size-small: 11px;
  --font-size-tiny: 10px;
  --font-size-micro: 9px;
  
  /* Spacing */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 12px;
  --space-lg: 16px;
  --space-xl: 24px;
  
  /* Borders */
  --border-width: 1px;
  --border-radius: 0;
}
```

### Alternative Theme Palettes

#### P3 Amber (Warm Terminal)
```css
:root[data-theme="amber"] {
  --bg-primary: #0F0A00;
  --bg-surface: #1A1200;
  --bg-surface-light: #241A00;
  --color-primary: #FFB300;
  --color-primary-dim: #8A6200;
  --color-text: #FFB300;
  --color-text-dim: #8A7A33;
  --color-accent: #FFD54F;
  --color-error: #FF5252;
  --color-border: #3A2A00;
  --color-user: #2A1F00;
  --color-bot: #1A1200;
  --color-input: #1A1200;
}
```

#### P4 White (Cool Modern)
```css
:root[data-theme="white"] {
  --bg-primary: #0A0A0F;
  --bg-surface: #12121A;
  --bg-surface-light: #1A1A24;
  --color-primary: #E0E0FF;
  --color-primary-dim: #7A7A8A;
  --color-text: #E0E0FF;
  --color-text-dim: #7A7A9A;
  --color-accent: #FFFFFF;
  --color-error: #FF4444;
  --color-border: #2A2A3A;
  --color-user: #1A1A2A;
  --color-bot: #12121A;
  --color-input: #12121A;
}
```

#### Neon Cyan (Cyberpunk Edge)
```css
:root[data-theme="cyan"] {
  --bg-primary: #050A0F;
  --bg-surface: #0A1520;
  --bg-surface-light: #0F1F2F;
  --color-primary: #00FFFF;
  --color-primary-dim: #007A7A;
  --color-text: #00FFFF;
  --color-text-dim: #337A7A;
  --color-accent: #FF00FF;
  --color-error: #FF3366;
  --color-border: #0A2A3A;
  --color-user: #0A1F2A;
  --color-bot: #0A1520;
  --color-input: #0A1520;
}
```

#### Synthwave (80s Retro)
```css
:root[data-theme="synthwave"] {
  --bg-primary: #0F0A1A;
  --bg-surface: #1A1030;
  --bg-surface-light: #241640;
  --color-primary: #FF66FF;
  --color-primary-dim: #8A3A8A;
  --color-text: #E0B0FF;
  --color-text-dim: #8A6AAA;
  --color-accent: #00FFFF;
  --color-error: #FF3333;
  --color-border: #2A1A3A;
  --color-user: #2A1040;
  --color-bot: #1A1030;
  --color-input: #1A1030;
}
```

### Theme Switching

```javascript
// JavaScript theme switcher
function setTheme(themeName) {
  document.documentElement.setAttribute('data-theme', themeName);
  localStorage.setItem('theme', themeName);
}

// Load saved theme
const savedTheme = localStorage.getItem('theme') || 'green';
setTheme(savedTheme);
```

---

## Typography

### Font Loading

**Google Fonts (Recommended):**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
```

**Self-Hosted (Alternative):**
```css
@font-face {
  font-family: 'JetBrains Mono';
  src: url('/fonts/JetBrainsMono-Regular.woff2') format('woff2');
  font-weight: 400;
  font-display: swap;
}

@font-face {
  font-family: 'JetBrains Mono';
  src: url('/fonts/JetBrainsMono-Bold.woff2') format('woff2');
  font-weight: 700;
  font-display: swap;
}
```

### Base Typography Styles

```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: var(--font-mono);
  font-size: var(--font-size-body);
  line-height: 1.5;
  color: var(--color-text);
  background-color: var(--bg-primary);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

h1, h2, h3, h4, h5, h6 {
  font-weight: 700;
  color: var(--color-primary);
  line-height: 1.2;
  margin-bottom: var(--space-sm);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

h1 { font-size: var(--font-size-h1); }
h2 { font-size: var(--font-size-h2); }
h3 { font-size: var(--font-size-h3); }

p {
  margin-bottom: var(--space-md);
  color: var(--color-text);
}

a {
  color: var(--color-accent);
  text-decoration: underline;
  transition: opacity 0.2s;
}

a:hover {
  opacity: 0.8;
}

code, pre {
  font-family: var(--font-mono);
  font-size: var(--font-size-caption);
  background-color: var(--bg-surface);
  color: var(--color-accent);
}

code {
  padding: 2px 4px;
}

pre {
  padding: var(--space-md);
  border: var(--border-width) solid var(--color-border);
  overflow-x: auto;
  margin-bottom: var(--space-md);
}
```

---

## CSS Architecture

### Base Reset & Global Styles

```css
/* cyberterm-reset.css */
*, *::before, *::after {
  box-sizing: border-box;
}

html {
  font-size: 16px;
  -webkit-text-size-adjust: 100%;
}

body {
  margin: 0;
  min-height: 100vh;
  overflow-x: hidden;
}

img, picture, video, canvas, svg {
  display: block;
  max-width: 100%;
}

button, input, textarea, select {
  font: inherit;
  color: inherit;
}

button {
  cursor: pointer;
  border: none;
  background: none;
}

input, textarea {
  border: none;
  outline: none;
}

/* Remove default list styles */
ul, ol {
  list-style: none;
}

/* Selection color */
::selection {
  background-color: var(--color-primary);
  color: var(--bg-primary);
}
```

### Utility Classes

```css
/* cyberterm-utils.css */

/* Text utilities */
.text-primary { color: var(--color-primary); }
.text-dim { color: var(--color-text-dim); }
.text-accent { color: var(--color-accent); }
.text-error { color: var(--color-error); }

.text-bold { font-weight: 700; }
.text-upper { text-transform: uppercase; }
.text-mono { font-family: var(--font-mono); }

/* Spacing utilities */
.mt-xs { margin-top: var(--space-xs); }
.mt-sm { margin-top: var(--space-sm); }
.mt-md { margin-top: var(--space-md); }
.mt-lg { margin-top: var(--space-lg); }
.mt-xl { margin-top: var(--space-xl); }

.mb-xs { margin-bottom: var(--space-xs); }
.mb-sm { margin-bottom: var(--space-sm); }
.mb-md { margin-bottom: var(--space-md); }
.mb-lg { margin-bottom: var(--space-lg); }
.mb-xl { margin-bottom: var(--space-xl); }

.p-xs { padding: var(--space-xs); }
.p-sm { padding: var(--space-sm); }
.p-md { padding: var(--space-md); }
.p-lg { padding: var(--space-lg); }
.p-xl { padding: var(--space-xl); }

/* Display utilities */
.hidden { display: none; }
.flex { display: flex; }
.inline-flex { display: inline-flex; }
.grid { display: grid; }

/* Flex utilities */
.flex-col { flex-direction: column; }
.flex-row { flex-direction: row; }
.items-center { align-items: center; }
.justify-center { justify-content: center; }
.justify-between { justify-content: space-between; }
.gap-sm { gap: var(--space-sm); }
.gap-md { gap: var(--space-md); }
```

---

## Component Library

### Buttons

```css
/* Terminal-style buttons */
.btn {
  display: inline-block;
  padding: var(--space-sm) var(--space-md);
  font-family: var(--font-mono);
  font-size: var(--font-size-body);
  font-weight: 700;
  text-align: center;
  text-transform: uppercase;
  border: var(--border-width) solid;
  border-radius: var(--border-radius);
  cursor: pointer;
  transition: opacity 0.2s;
  user-select: none;
}

.btn:hover:not(:disabled) {
  opacity: 0.8;
}

.btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.btn-primary {
  background-color: var(--color-primary);
  color: var(--bg-primary);
  border-color: var(--color-primary);
}

.btn-secondary {
  background-color: transparent;
  color: var(--color-primary);
  border-color: var(--color-border);
}

.btn-ghost {
  background-color: transparent;
  color: var(--color-primary);
  border-color: transparent;
}

/* Terminal action button [XX] */
.btn-action {
  padding: 2px 6px;
  font-size: var(--font-size-tiny);
  font-weight: 700;
  color: var(--color-primary-dim);
  border: none;
  background: none;
}

.btn-action:hover {
  color: var(--color-primary);
}
```

**HTML Example:**
```html
<button class="btn btn-primary">Execute</button>
<button class="btn btn-secondary">Cancel</button>
<button class="btn-action">[CP]</button>
```

### Cards & Containers

```css
.card {
  background-color: var(--bg-surface);
  border: var(--border-width) solid var(--color-border);
  border-radius: var(--border-radius);
  padding: var(--space-md);
}

.card-header {
  padding: var(--space-sm) var(--space-md);
  border-bottom: var(--border-width) solid var(--color-border);
  font-size: var(--font-size-small);
  font-weight: 700;
  color: var(--color-primary);
  text-transform: uppercase;
}

.card-body {
  padding: var(--space-md);
}

.card-footer {
  padding: var(--space-sm) var(--space-md);
  border-top: var(--border-width) solid var(--color-border);
  font-size: var(--font-size-small);
  color: var(--color-text-dim);
}
```

**HTML Example:**
```html
<div class="card">
  <div class="card-header">▸ System Info</div>
  <div class="card-body">
    <p>Content goes here</p>
  </div>
  <div class="card-footer">Last updated: 12:34:56</div>
</div>
```

### Message Bubbles

```css
.message-bubble {
  margin: var(--space-xs) 0;
  background-color: var(--color-bot);
  border-left: 2px solid var(--color-primary);
  border-top: 0.5px solid var(--color-border);
  border-bottom: 0.5px solid var(--color-border);
}

.message-bubble.user {
  background-color: var(--color-user);
  border-left-color: var(--color-accent);
}

.message-header {
  display: flex;
  align-items: center;
  padding: 6px 10px;
  border-bottom: 0.5px solid var(--color-border);
  font-size: var(--font-size-tiny);
}

.message-tag {
  font-weight: 700;
  color: var(--color-primary);
  margin-right: var(--space-sm);
}

.message-bubble.user .message-tag {
  color: var(--color-accent);
}

.message-time {
  color: var(--color-text-dim);
  font-size: var(--font-size-micro);
}

.message-actions {
  margin-left: auto;
  display: flex;
  gap: 6px;
}

.message-content {
  padding: 10px;
  font-size: var(--font-size-body);
  line-height: 1.5;
}
```

**HTML Example:**
```html
<div class="message-bubble">
  <div class="message-header">
    <span class="message-tag">[SYS]</span>
    <span class="message-time">12:34:56</span>
    <div class="message-actions">
      <button class="btn-action">[CP]</button>
    </div>
  </div>
  <div class="message-content">
    System response content here
  </div>
</div>

<div class="message-bubble user">
  <div class="message-header">
    <span class="message-tag">[USR]</span>
    <span class="message-time">12:34:50</span>
  </div>
  <div class="message-content">
    User message content here
  </div>
</div>
```

### Input Fields

```css
.input-group {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  padding: var(--space-sm);
  background-color: var(--bg-surface);
  border-top: var(--border-width) solid var(--color-border);
}

.input-prompt {
  font-size: 14px;
  font-weight: 700;
  color: var(--color-primary);
  user-select: none;
}

.terminal-input {
  flex: 1;
  padding: 10px;
  font-family: var(--font-mono);
  font-size: var(--font-size-body);
  color: var(--color-text);
  background-color: var(--color-input);
  border: var(--border-width) solid var(--color-border);
  border-radius: var(--border-radius);
  transition: border-color 0.2s;
}

.terminal-input:focus {
  border-color: var(--color-primary);
  border-width: 2px;
  outline: none;
}

.terminal-input::placeholder {
  color: var(--color-text-dim);
}

.terminal-input:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

textarea.terminal-input {
  resize: vertical;
  min-height: 40px;
}
```

**HTML Example:**
```html
<div class="input-group">
  <span class="input-prompt">&gt;</span>
  <input 
    type="text" 
    class="terminal-input" 
    placeholder="Enter command..."
  />
  <button class="btn btn-primary">[↵]</button>
</div>
```

### Navigation Bar

```css
.navbar {
  display: flex;
  align-items: center;
  padding: var(--space-sm) var(--space-lg);
  background-color: var(--bg-primary);
  border-bottom: var(--border-width) solid var(--color-border);
}

.navbar-brand {
  font-size: var(--font-size-h2);
  font-weight: 700;
  color: var(--color-primary);
  text-decoration: none;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.navbar-menu {
  display: flex;
  gap: var(--space-lg);
  margin-left: auto;
}

.navbar-link {
  font-size: var(--font-size-body);
  color: var(--color-text);
  text-decoration: none;
  transition: color 0.2s;
}

.navbar-link:hover,
.navbar-link.active {
  color: var(--color-primary);
}
```

**HTML Example:**
```html
<nav class="navbar">
  <a href="/" class="navbar-brand">DAYOFGEEK</a>
  <div class="navbar-menu">
    <a href="/apps" class="navbar-link">Apps</a>
    <a href="/docs" class="navbar-link">Docs</a>
    <a href="/about" class="navbar-link">About</a>
  </div>
</nav>
```

### Dialogs/Modals

```css
.modal-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  width: 90%;
  max-width: 500px;
  background-color: var(--bg-surface);
  border: var(--border-width) solid var(--color-primary);
  border-radius: var(--border-radius);
}

.modal-header {
  padding: var(--space-md);
  border-bottom: var(--border-width) solid var(--color-border);
  font-size: var(--font-size-h3);
  font-weight: 700;
  color: var(--color-primary);
  text-transform: uppercase;
}

.modal-body {
  padding: var(--space-md);
  color: var(--color-text-dim);
  font-size: var(--font-size-caption);
}

.modal-footer {
  padding: var(--space-md);
  border-top: var(--border-width) solid var(--color-border);
  display: flex;
  gap: var(--space-sm);
  justify-content: flex-end;
}
```

**HTML Example:**
```html
<div class="modal-overlay">
  <div class="modal">
    <div class="modal-header">▸ Confirm Action</div>
    <div class="modal-body">
      Are you sure you want to proceed?
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary">[CANCEL]</button>
      <button class="btn btn-primary">[CONFIRM]</button>
    </div>
  </div>
</div>
```

### Lists

```css
.list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.list-item {
  padding: var(--space-sm) var(--space-md);
  border-bottom: var(--border-width) solid var(--color-border);
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  transition: background-color 0.2s;
}

.list-item:hover {
  background-color: var(--bg-surface-light);
}

.list-item:last-child {
  border-bottom: none;
}

.list-icon {
  color: var(--color-primary-dim);
  font-size: var(--font-size-h3);
}

.list-content {
  flex: 1;
}

.list-title {
  font-size: var(--font-size-body);
  color: var(--color-text);
  margin-bottom: 2px;
}

.list-subtitle {
  font-size: var(--font-size-small);
  color: var(--color-text-dim);
}

.list-action {
  color: var(--color-primary-dim);
}
```

**HTML Example:**
```html
<ul class="list">
  <li class="list-item">
    <span class="list-icon">▸</span>
    <div class="list-content">
      <div class="list-title">Item Title</div>
      <div class="list-subtitle">Item description</div>
    </div>
    <span class="list-action">→</span>
  </li>
</ul>
```

---

## Layout System

### Grid System

```css
.container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--space-lg);
}

.container-fluid {
  width: 100%;
  padding: 0 var(--space-lg);
}

.row {
  display: flex;
  flex-wrap: wrap;
  margin: 0 calc(var(--space-sm) * -1);
}

.col {
  flex: 1;
  padding: 0 var(--space-sm);
}

.col-6 { flex: 0 0 50%; max-width: 50%; padding: 0 var(--space-sm); }
.col-4 { flex: 0 0 33.333%; max-width: 33.333%; padding: 0 var(--space-sm); }
.col-3 { flex: 0 0 25%; max-width: 25%; padding: 0 var(--space-sm); }

@media (max-width: 768px) {
  .col-6, .col-4, .col-3 {
    flex: 0 0 100%;
    max-width: 100%;
  }
}
```

### Section Layout

```css
.section {
  padding: var(--space-xl) 0;
}

.section-header {
  margin-bottom: var(--space-lg);
}

.section-title {
  font-size: var(--font-size-h1);
  color: var(--color-primary);
  margin-bottom: var(--space-sm);
  text-transform: uppercase;
}

.section-subtitle {
  font-size: var(--font-size-body);
  color: var(--color-text-dim);
}
```

---

## Animations & Effects

### Blinking Cursor

```css
@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.2; }
}

.cursor {
  display: inline-block;
  color: var(--color-primary);
  font-weight: 700;
  animation: blink 0.53s ease-in-out infinite;
}
```

**HTML:**
```html
<span class="cursor">█</span>
```

### Loading Spinner

```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
```

### Scanline Effect (Optional)

```css
/* Add a subtle CRT scanline effect */
.scanlines {
  position: relative;
  overflow: hidden;
}

.scanlines::before {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 2px,
    rgba(0, 0, 0, 0.1) 2px,
    rgba(0, 0, 0, 0.1) 4px
  );
  pointer-events: none;
  z-index: 1;
}
```

### Glow Effect (Optional)

```css
/* Text glow for cyberpunk feel */
.text-glow {
  text-shadow: 
    0 0 5px currentColor,
    0 0 10px currentColor;
}

/* Button glow on hover */
.btn-primary:hover {
  box-shadow: 
    0 0 10px var(--color-primary),
    0 0 20px var(--color-primary);
}
```

---

## Responsive Design

### Breakpoints

```css
/* Mobile first approach */
:root {
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
}

/* Small devices */
@media (min-width: 640px) {
  /* Styles for small+ screens */
}

/* Medium devices */
@media (min-width: 768px) {
  /* Styles for medium+ screens */
}

/* Large devices */
@media (min-width: 1024px) {
  /* Styles for large+ screens */
}

/* Extra large devices */
@media (min-width: 1280px) {
  /* Styles for XL screens */
}
```

### Mobile Navigation

```css
.navbar-toggle {
  display: none;
  font-size: var(--font-size-h2);
  color: var(--color-primary);
  background: none;
  border: none;
  cursor: pointer;
}

@media (max-width: 768px) {
  .navbar-menu {
    position: fixed;
    top: 0;
    right: -100%;
    width: 80%;
    max-width: 300px;
    height: 100vh;
    background-color: var(--bg-surface);
    border-left: var(--border-width) solid var(--color-border);
    flex-direction: column;
    padding: var(--space-xl);
    gap: var(--space-md);
    transition: right 0.3s;
    z-index: 999;
  }
  
  .navbar-menu.active {
    right: 0;
  }
  
  .navbar-toggle {
    display: block;
  }
}
```

---

## Code Examples

### Complete Page Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DayOfGeek - Cyberpunk Terminal</title>
  
  <!-- JetBrains Mono Font -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
  
  <!-- Styles -->
  <link rel="stylesheet" href="cyberterm.css">
</head>
<body>
  <!-- Navigation -->
  <nav class="navbar">
    <a href="/" class="navbar-brand">DAYOFGEEK</a>
    <button class="navbar-toggle" id="navToggle">☰</button>
    <div class="navbar-menu" id="navMenu">
      <a href="#" class="navbar-link active">Home</a>
      <a href="#" class="navbar-link">Apps</a>
      <a href="#" class="navbar-link">Docs</a>
      <a href="#" class="navbar-link">About</a>
    </div>
  </nav>

  <!-- Main Content -->
  <main class="container">
    <section class="section">
      <div class="section-header">
        <h1 class="section-title">▸ Welcome to DayOfGeek</h1>
        <p class="section-subtitle">
          Cyberpunk applications for the modern developer
        </p>
      </div>

      <div class="row">
        <div class="col-6">
          <div class="card">
            <div class="card-header">▸ Featured App</div>
            <div class="card-body">
              <h3>ExecPrompt</h3>
              <p>Terminal-style AI chat interface</p>
              <button class="btn btn-primary">Launch</button>
            </div>
          </div>
        </div>
        
        <div class="col-6">
          <div class="card">
            <div class="card-header">▸ System Status</div>
            <div class="card-body">
              <ul class="list">
                <li class="list-item">
                  <span class="list-icon">▸</span>
                  <div class="list-content">
                    <div class="list-title">All systems operational</div>
                    <div class="list-subtitle">Last checked: 12:34:56</div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Terminal Chat Example -->
    <section class="section">
      <div class="section-header">
        <h2 class="section-title">▸ Chat Interface</h2>
      </div>
      
      <div class="card">
        <div id="messages">
          <div class="message-bubble user">
            <div class="message-header">
              <span class="message-tag">[USR]</span>
              <span class="message-time">12:34:50</span>
            </div>
            <div class="message-content">
              Hello, system!
            </div>
          </div>
          
          <div class="message-bubble">
            <div class="message-header">
              <span class="message-tag">[SYS]</span>
              <span class="message-time">12:34:52</span>
              <div class="message-actions">
                <button class="btn-action">[CP]</button>
              </div>
            </div>
            <div class="message-content">
              Greetings. How can I assist you?
              <span class="cursor">█</span>
            </div>
          </div>
        </div>
        
        <div class="input-group">
          <span class="input-prompt">&gt;</span>
          <input 
            type="text" 
            class="terminal-input" 
            placeholder="Enter command..."
            id="chatInput"
          />
          <button class="btn btn-primary">[↵]</button>
        </div>
      </div>
    </section>
  </main>

  <!-- Footer -->
  <footer style="text-align: center; padding: var(--space-xl); border-top: var(--border-width) solid var(--color-border);">
    <p class="text-dim">© 2026 DayOfGeek.com - Cyberpunk Terminal Design</p>
  </footer>

  <script src="app.js"></script>
</body>
</html>
```

### JavaScript Utilities

```javascript
// app.js

// Theme Switcher
function setTheme(themeName) {
  document.documentElement.setAttribute('data-theme', themeName);
  localStorage.setItem('theme', themeName);
}

// Load saved theme
const savedTheme = localStorage.getItem('theme') || 'green';
setTheme(savedTheme);

// Mobile navigation toggle
const navToggle = document.getElementById('navToggle');
const navMenu = document.getElementById('navMenu');

if (navToggle) {
  navToggle.addEventListener('click', () => {
    navMenu.classList.toggle('active');
  });
}

// Close mobile menu when clicking outside
document.addEventListener('click', (e) => {
  if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
    navMenu.classList.remove('active');
  }
});

// Terminal input example
const chatInput = document.getElementById('chatInput');
const messagesContainer = document.getElementById('messages');

if (chatInput) {
  chatInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter' && chatInput.value.trim()) {
      addMessage('user', chatInput.value);
      chatInput.value = '';
      
      // Simulate system response
      setTimeout(() => {
        addMessage('system', 'Processing your request...');
      }, 500);
    }
  });
}

function addMessage(role, content) {
  const isUser = role === 'user';
  const tag = isUser ? 'USR' : 'SYS';
  const time = new Date().toLocaleTimeString('en-US', { hour12: false });
  
  const messageHTML = `
    <div class="message-bubble ${isUser ? 'user' : ''}">
      <div class="message-header">
        <span class="message-tag">[${tag}]</span>
        <span class="message-time">${time}</span>
        ${!isUser ? '<div class="message-actions"><button class="btn-action">[CP]</button></div>' : ''}
      </div>
      <div class="message-content">${content}</div>
    </div>
  `;
  
  if (messagesContainer) {
    messagesContainer.insertAdjacentHTML('beforeend', messageHTML);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }
}

// Copy to clipboard functionality
document.addEventListener('click', (e) => {
  if (e.target.classList.contains('btn-action') && e.target.textContent === '[CP]') {
    const messageContent = e.target.closest('.message-bubble')
      .querySelector('.message-content').textContent;
    navigator.clipboard.writeText(messageContent).then(() => {
      console.log('Copied to clipboard');
    });
  }
});
```

---

## Framework Integration

### React Example

```jsx
// Button.jsx
export const Button = ({ variant = 'primary', children, ...props }) => {
  return (
    <button className={`btn btn-${variant}`} {...props}>
      {children}
    </button>
  );
};

// MessageBubble.jsx
export const MessageBubble = ({ role, content, timestamp }) => {
  const isUser = role === 'user';
  const tag = isUser ? 'USR' : 'SYS';
  
  return (
    <div className={`message-bubble ${isUser ? 'user' : ''}`}>
      <div className="message-header">
        <span className="message-tag">[{tag}]</span>
        <span className="message-time">{timestamp}</span>
        {!isUser && (
          <div className="message-actions">
            <button className="btn-action">[CP]</button>
          </div>
        )}
      </div>
      <div className="message-content">{content}</div>
    </div>
  );
};
```

### Vue Example

```vue
<!-- Button.vue -->
<template>
  <button :class="`btn btn-${variant}`" v-bind="$attrs">
    <slot></slot>
  </button>
</template>

<script>
export default {
  props: {
    variant: {
      type: String,
      default: 'primary'
    }
  }
}
</script>

<!-- MessageBubble.vue -->
<template>
  <div :class="['message-bubble', { user: isUser }]">
    <div class="message-header">
      <span class="message-tag">[{{ tag }}]</span>
      <span class="message-time">{{ timestamp }}</span>
      <div v-if="!isUser" class="message-actions">
        <button class="btn-action">[CP]</button>
      </div>
    </div>
    <div class="message-content">{{ content }}</div>
  </div>
</template>

<script>
export default {
  props: ['role', 'content', 'timestamp'],
  computed: {
    isUser() {
      return this.role === 'user';
    },
    tag() {
      return this.isUser ? 'USR' : 'SYS';
    }
  }
}
</script>
```

---

## Best Practices

### DO:
✅ Use JetBrains Mono for all text  
✅ Keep borders sharp (border-radius: 0)  
✅ Maintain flat design (no shadows)  
✅ Use CSS custom properties for theming  
✅ Keep backgrounds very dark  
✅ Use high contrast text  
✅ Add terminal-style labels [XX]  
✅ Use ▸ and ▾ for expand/collapse  
✅ Implement keyboard shortcuts  
✅ Test on multiple screen sizes  

### DON'T:
❌ Mix multiple font families  
❌ Use rounded corners  
❌ Add box shadows or depth  
❌ Use gradients  
❌ Mix warm and cool colors  
❌ Use low contrast  
❌ Ignore accessibility  
❌ Forget mobile responsiveness  
❌ Use colored icons (monochrome only)  
❌ Add excessive animations  

---

## Performance Tips

1. **Font Loading:** Use `font-display: swap` for better perceived performance
2. **Critical CSS:** Inline critical styles for above-the-fold content
3. **Minimize Repaints:** Use CSS transforms for animations instead of position/size changes
4. **Lazy Load Images:** Implement lazy loading for images below the fold
5. **CSS Compression:** Minify CSS in production
6. **Use CSS Variables:** They're faster than Sass variables at runtime

---

## Accessibility

```css
/* Focus styles */
*:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Skip to content link */
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: var(--color-primary);
  color: var(--bg-primary);
  padding: var(--space-sm);
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}

/* Screen reader only */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

**HTML:**
```html
<a href="#main" class="skip-link">Skip to main content</a>
```

---

## Resources

- **Font:** [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- **Icons:** Use simple text symbols (▸, ▾, ■, █, etc.) or monochrome SVG
- **Color Tool:** [Coolors.co](https://coolors.co/) for palette generation
- **CSS Reset:** [Modern CSS Reset](https://github.com/hankchizljaw/modern-css-reset)
- **Accessibility:** [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## Credits

**Design System:** ExecPrompt by DayOfGeek.com  
**Aesthetic:** Cyberpunk / Retro-Futurism / Terminal  
**License:** Style guide provided as-is for creating consistent DayOfGeek web properties

---

*Last Updated: February 2026*  
*Version: 1.0*
