# ExecPrompt Documentation

Welcome to the ExecPrompt documentation repository! This folder contains all technical documentation, design guides, and development resources for the ExecPrompt project and the DayOfGeek.com brand.

## 📚 Table of Contents

### Style Guides
Design systems and styling guidelines for creating consistent DayOfGeek applications:

- **[Flutter Style Guide](styleguide_flutter.md)** - Comprehensive guide for building Flutter apps with ExecPrompt's cyberpunk/futurism aesthetic
- **[Web Style Guide](styleguide_web.md)** - Complete CSS/HTML/JS guide for creating websites with the same look and feel

### Development Documentation
Core development resources and technical specifications:

- **[Development Guide](DEVELOPMENT.md)** - Development setup, coding standards, and contribution guidelines
- **[Implementation Details](IMPLEMENTATION.md)** - Architectural decisions and implementation notes
- **[Build Status](BUILD_STATUS.md)** - Current build status and known issues
- **[Tech Stack](techstack.md)** - Technology choices and rationale

### Planning & Research
Project planning documents and research materials:

- **[Development Plan (2026-02-11)](20260211_devplan.md)** - Detailed development roadmap
- **[RC Development Plan](rc_devplan.md)** - Release candidate planning
- **[Project Summary](PROJECT_SUMMARY.md)** - High-level project overview
- **[Research Notes](research.md)** - API research and technical investigation

### Enhancement Documentation
Feature enhancement tracking and implementation:

- **[Enhancements](enhancements.md)** - Planned feature enhancements
- **[Enhancement Implementations](enhancement_implementations.md)** - Implementation details for enhancements
- **[Gap Remediation](gap_remediation.md)** - Identified gaps and remediation plans
- **[Ollama Gap Analysis](ollama_gap_analysis.md)** - Analysis of Ollama API coverage

## 🎨 Design Philosophy

ExecPrompt embodies a **cyberpunk/retro-futurism** aesthetic inspired by:
- Classic CRT terminal displays (phosphor green, amber, cyan)
- 1980s synthwave and cyberpunk culture
- Monospaced typography and command-line interfaces
- High-contrast, flat design with zero rounded corners
- Terminal-style interaction patterns

### Key Visual Elements
- **Font:** JetBrains Mono (monospace)
- **Shapes:** Sharp rectangles, no rounded corners
- **Colors:** Dark backgrounds with bright, glowing accents
- **Borders:** 1px solid lines, no shadows
- **Typography:** All-caps labels, terminal-style tags [XX]
- **Animations:** Minimal, purposeful (blinking cursor, scanlines)

## 🏢 Brand: DayOfGeek.com

ExecPrompt is the flagship application for the DayOfGeek.com brand, establishing a consistent design language that will be used across all future products and web properties.

**Brand Values:**
- **Technical Excellence** - Developer-focused, precision-engineered
- **Cyberpunk Aesthetic** - Futuristic, terminal-inspired design
- **Open & Transparent** - Clear documentation, open processes
- **Performance First** - Fast, efficient, lightweight

## 🚀 Quick Links

### For Developers
Start here if you're building applications:
1. Read the [Flutter Style Guide](styleguide_flutter.md) for mobile apps
2. Review the [Development Guide](DEVELOPMENT.md) for coding standards
3. Check the [Tech Stack](techstack.md) for technology decisions

### For Designers
Start here if you're working on UI/UX:
1. Review the [Flutter Style Guide](styleguide_flutter.md) for design principles
2. Check the [Web Style Guide](styleguide_web.md) for web design patterns
3. Study the color palettes and typography systems

### For Web Developers
Start here if you're building websites:
1. Start with the [Web Style Guide](styleguide_web.md)
2. Implement the CSS architecture and component library
3. Use the provided code examples and templates

### For Project Managers
Start here for project overview:
1. Read the [Project Summary](PROJECT_SUMMARY.md)
2. Review the [Development Plan](20260211_devplan.md)
3. Check the [Build Status](BUILD_STATUS.md)

## 📖 Documentation Standards

All documentation in this folder follows these standards:

### Markdown Formatting
- Use proper heading hierarchy (H1 → H2 → H3)
- Include a table of contents for long documents
- Use code blocks with language specification
- Add horizontal rules (`---`) for section breaks

### Code Examples
- Provide complete, runnable examples
- Include both Flutter and web examples where applicable
- Comment complex logic
- Show both DO and DON'T patterns

### Structure
```
docs/
├── styleguide_flutter.md      # Flutter style guide
├── styleguide_web.md          # Web style guide
├── DEVELOPMENT.md             # Dev guidelines
├── IMPLEMENTATION.md          # Architecture docs
├── README.md                  # This file
└── [other docs...]
```

## 🔄 Keeping Documentation Updated

When making changes to the codebase:
1. Update relevant documentation files
2. Add new patterns to style guides if introducing new components
3. Update the tech stack document when adding dependencies
4. Keep code examples in sync with actual implementation

## 🎯 Design Patterns

### Terminal-Style Components

**Message Tags:** `[USR]` `[SYS]`  
**Action Buttons:** `[CP]` `[ED]` `[RT]` `[RM]`  
**Section Headers:** `▸ SECTION NAME`  
**Collapse Indicators:** `▾` (expanded) `▸` (collapsed)  
**Input Prompt:** `> `  
**Cursor:** `█` (blinking block)

### Color Themes

Five official themes, all following the same structure:
1. **P1 Green** - Classic terminal green (#33FF33)
2. **P3 Amber** - Warm amber/gold (#FFB300)
3. **P4 White** - Cool blue-white (#E0E0FF)
4. **Neon Cyan** - Electric cyan with magenta (#00FFFF / #FF00FF)
5. **Synthwave** - Purple and pink (#FF66FF / #00FFFF)

### Spacing System

Based on 4px increments:
- **xs:** 4px
- **sm:** 8px
- **md:** 12px
- **lg:** 16px
- **xl:** 24px

## 📝 License

All documentation is provided as-is for creating consistent applications under the DayOfGeek.com brand. The style guides and design patterns are free to use for any DayOfGeek projects.

## 🤝 Contributing to Documentation

When contributing to documentation:
1. Follow the existing style and format
2. Test all code examples
3. Update the table of contents
4. Keep examples platform-agnostic when possible
5. Use clear, concise language

## 📞 Contact

For questions about documentation or design standards:
- Open an issue on GitHub
- Tag with `documentation` or `design` label

---

**Last Updated:** February 2026  
**Maintained by:** DayOfGeek.com Team  
**Related:** [Main README](../README.md) | [Quick Start](../QUICKSTART.md)
