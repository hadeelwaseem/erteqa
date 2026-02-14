# Architecture Overview  
## Flutter-Based Dynamic Mobile App Generator

---

## 1. Project Identity

This project is a **Flutter-based dynamic mobile application generator**, not a traditional Flutter application.

Flutter is used strictly as a **runtime rendering platform**, not as a place where application structure, screens, or UI flows are hardcoded.  
The system generates **fully functional, standalone Flutter mobile applications** from **configuration-driven definitions**, rather than from manually authored UI code per application.

In this architecture:

- Applications, screens, UI components, and themes are treated as **data**, not as fixed Flutter widget trees.
- Flutter’s responsibility is limited to **interpreting and rendering** definitions produced by the system.
- A single Flutter codebase is capable of producing **multiple merchant-specific applications** without duplication, branching, or per-merchant customization in code.

---

## 2. Problem Statement

Traditional mobile app builders and template-based generators suffer from inherent structural limitations:

- Templates are static and rigid.
- Customization is shallow and tightly coupled to UI code.
- Scaling beyond a few variants requires duplicated projects or branches.
- Core changes must be manually propagated across multiple applications.

These limitations result in poor scalability, fragile customization, and long-term maintenance issues.

This project addresses these problems by introducing a **data-driven, component-based generation architecture**, where:

- UI structure is defined **declaratively**, not hardcoded.
- Components are **reused and reconfigured**, not rewritten.
- A single core system generates **many distinct applications**.
- Core updates propagate automatically without merge conflicts.

This enables:

- **Reusability** — shared components and layouts across apps.
- **Customization** — structural and visual differences driven by configuration.
- **Scalability** — growth in generated applications without architectural decay.
- **Maintainability** — centralized, controlled evolution of the system.

---

## 3. High-Level Architectural Model

The system is deliberately layered to enforce **strict separation of concerns** and prevent architectural drift.

### 3.1 Config Layer — *Definition*

The Config layer defines **what the application is**.

It consists of **pure declarative data models** representing:

- Application identity
- Screens
- Components
- Themes
- Structural variability

Characteristics:

- Contains no Flutter UI code
- Contains no rendering or execution logic
- Acts as the **single source of truth** for application definition

The Config layer expresses *intent*, not behavior.

---

### 3.2 Engine Layer — *Interpretation*

The Engine layer defines **how configuration becomes a running UI**.

Responsibilities include:

- Reading configuration objects
- Resolving templates and abstractions
- Mapping component definitions to renderers
- Orchestrating screen composition and rendering flow

This layer:

- Interprets configuration semantics
- Produces Flutter widget trees dynamically
- Contains the core logic that makes the system a **generator**, not a static application
- Does **not** contain business or domain logic

---

### 3.3 Core / Shared Layer — *Primitives*

The Core layer provides **stable, reusable primitives** and cross-cutting utilities.

It includes:

- Stateless UI widgets (buttons, inputs, scaffolds)
- Shared enums, utilities, and tokens
- Platform-level concerns (e.g., theming primitives)

Core widgets are:

- Configuration-agnostic
- Stateless or minimally stateful
- Unaware of templates, JSON, or configuration structure

They exist solely to render themselves when instructed.

---

### 3.4 Features Layer — *Business Domains*

The Features layer contains **isolated business domains** (e.g., authentication, user profiles).

Features:

- Own their data, state, and domain logic
- Use Core widgets for UI
- Do **not** participate in UI generation
- Do **not** depend on Engine internals

This prevents business logic from leaking into rendering or generation layers.

---

## 4. Conceptual Build Process

The system operates in two distinct phases: **Definition** and **Execution**.

### 4.1 Definition Phase (Configuration)

Configuration defines:

- Application identity (name, bundle ID)
- Available screens
- Component composition per screen
- Visual properties and styles
- Theme values

This phase is:

- Fully declarative
- Free of rendering or execution concerns
- Focused solely on describing *what exists*

---

### 4.2 Execution Phase (Engine + Flutter)

At runtime:

1. The Engine reads the configuration.
2. Templates and abstractions are resolved.
3. Component definitions are mapped to renderers.
4. Renderers assemble Flutter widget trees using Core widgets.
5. Flutter renders the resulting UI.

Flutter widgets remain:

- Dumb
- Reusable
- Stateless or minimally stateful
- Unaware of configuration or generation mechanics

All interpretation logic resides in the Engine.

---

## 5. Explicit Non-Goals

This project is **explicitly not**:

- A static Flutter application
- A UI-only page builder
- A hardcoded template system
- A system where business logic lives in UI widgets
- A collection of duplicated Flutter projects

Any assumption that screens or flows are manually coded per application is invalid.

---

## 6. Core Design Principles

The architecture is governed by the following non-negotiable principles:

- **Data-Driven UI**  
  Application structure is defined as data, not code.

- **Strict Separation of Definition and Execution**  
  Configuration defines *what exists*; the Engine defines *how it is rendered*.

- **No Business Logic in Rendering Layers**  
  Rendering is deterministic and configuration-based.

- **Scalability Over Short-Term Convenience**  
  Architectural clarity and longevity take precedence over quick solutions.

- **Single Codebase, Multiple Applications**  
  All generated applications derive from one controlled core system.

---

## 7. Architectural Boundary Enforcement

All contributors, tools, and automated systems must respect these boundaries:

- Config layer must remain pure and Flutter-agnostic.
- Engine layer owns interpretation and rendering orchestration.
- Core widgets must remain static and configuration-agnostic.
- Features must not depend on Engine internals.

Violating these boundaries breaks the generator model and is considered architecturally invalid.

---

## 8. Data Binding Contract

Runtime content is bound to components via a simple resolution rule:

- **`dataKey`** — Key used to look up runtime data in `dataContext`. The screen builds `dataContext` from a DataProvider, Cubit/Repo, or API.

- **Renderer resolution** — If `dataKey` is present and `dataContext` contains it, use the value from `dataContext`. Otherwise, fall back to `config.properties`.

- **Static content** — Use `properties` directly (e.g. `text`, `fontSize`). No `dataKey` required.

- **Dynamic content** — Use `dataKey` binding. The screen populates `dataContext` with backend/API data; renderers resolve by key.

JSON config defines layout and bindings; the Feature layer supplies runtime data. The Engine stays unaware of data sources.

---

## 9. Purpose of This Document

This document exists to ensure that:

- The project is understood as a **generator**, not a traditional app.
- Architectural intent is preserved over time.
- Incorrect assumptions are proactively avoided.
- Automated tools (including AI assistants) operate within correct constraints.

Any suggestion or change that contradicts these principles should be treated as invalid unless explicitly justified and approved.

---

**End of Architecture Document**
