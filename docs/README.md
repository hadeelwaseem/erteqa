# Rendering Engine Documentation Index

Complete guide to all documentation for the Dynamic UI Rendering System.

---

## Documentation Structure

```
docs/
├── README.md                          ← START HERE (this file)
├── QUICK_START.md                     ← New? Read this first
├── RENDERING_ENGINE_GUIDE.md          ← Full developer guide  
├── API_REFERENCE.md                   ← API lookup
└── ARCHITECTURE.md                    ← Design decisions
```

---

## Which Document Should I Read?

### 🚀 I'm New Here!

**Start with**: [QUICK_START.md](QUICK_START.md)
- 5-minute overview
- Copy-paste renderer template
- Common patterns
- Get coding in 5 minutes

### 🔧 I Want to Build Something

**Read**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md)
- Complete architecture explanation
- Step-by-step: Add new component type
- Creating custom renderers
- Schema system details
- Property parsing guide
- Testing patterns
- Best practices
- Troubleshooting

### 📚 I Need API Reference

**Use**: [API_REFERENCE.md](API_REFERENCE.md)
- Class/method signatures
- Parameter descriptions
- Return types
- Code examples for each API
- Quick reference tables
- Common tasks

### 🏗️ I Want to Understand the Design

**Read**: [ARCHITECTURE.md](ARCHITECTURE.md)
- System architecture diagrams
- Design decision explanations
- Trade-offs made
- Future improvements
- Comparison with alternatives
- Design principles
- Performance & security

---

## Documentation Roadmap

| Document | Purpose | Audience | Time |
|----------|---------|----------|------|
| **QUICK_START.md** | Get up and running | Everyone | 5 min |
| **RENDERING_ENGINE_GUIDE.md** | Learn all details | Developers | 30 min |
| **API_REFERENCE.md** | Lookup during coding | Developers | 10 min |
| **ARCHITECTURE.md** | Understand design | Tech leads, Architects | 30 min |

---

## Common Tasks

### Add a New Component Type
1. [QUICK_START.md](QUICK_START.md) → Read "Add a New Component Type (5 Steps)"
2. [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → Read "Adding a New Component Type" for details

### Create a Custom Renderer
1. [QUICK_START.md](QUICK_START.md) → Copy renderer template
2. [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → Read "Creating Custom Renderers"
3. [API_REFERENCE.md](API_REFERENCE.md) → Look up ComponentRenderer interface

### Test My Renderer
1. [QUICK_START.md](QUICK_START.md) → Read "Test a Renderer (2 Steps)"
2. [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → Read "Testing Patterns"

### Understand Why Design Was Chosen
1. [ARCHITECTURE.md](ARCHITECTURE.md) → Read relevant decision

### Fix a Problem
1. [QUICK_START.md](QUICK_START.md) → Check "Troubleshooting" table
2. [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → Read "Troubleshooting" section

### Look Up API
1. [API_REFERENCE.md](API_REFERENCE.md) → Use Ctrl+F to search

---

## System Overview

### What Is This System?

The **Dynamic UI Rendering Engine** converts JSON configuration files into Flutter widgets.

```
JSON Config (assets/config/*.json)
    ↓ Parse & Validate (VariantRepository)
ComponentConfig Tree
    ↓ ScreenRenderer (enum-based renderer map)
Renderer Strategy
    ↓ Recursive Build
Widget Tree
    ↓ Flutter Renders
UI on Screen
```

The parser supports two JSON formats:
- Simple screen format: `{ id, pageName, root }`
- Builder format: `{ schemaVersion, app, theme, navigation, pages }`

### Key Files

**Implementation** (What to modify):
- `lib/features/variantscreen/data/repos/variant_repository.dart` - JSON parsing and builder normalization
- `lib/engine/screen_renderer/screen_renderer.dart` - Recursive renderer orchestration
- `lib/engine/tree/renderers/*.dart` - Per-component renderers
- `lib/engine/tree/parsers/property_parsers.dart` - Property parsing helpers
- `lib/engine/validation/component_schemas.dart` - Schema definitions

**Configuration** (What to run):
- `assets/config/*.json` - UI definitions (simple or builder format)

**Data Models** (What you use):
- `lib/config/component_config.dart` - Component tree structure
- `lib/config/screen_config.dart` - Screen envelope
- `lib/core/enums/generic_component_type.dart` - Supported component types

---

## Phase Timeline

| Phase | Status | Features | Docs |
|-------|--------|----------|------|
| **Phase 1** | ✅ Complete | Tree renderer + core primitives | QUICK_START, GUIDE |
| **Phase 2** | ✅ Complete | Builder JSON parsing + schemas | ARCHITECTURE, GUIDE |
| **Phase 3** | ⏳ Planning | Actions, data binding, domain nodes | TBD |

---

## Quick Links by Role

### Software Engineer

1. **First Time**: [QUICK_START.md](QUICK_START.md)
2. **Need Details**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md)
3. **Lookup API**: [API_REFERENCE.md](API_REFERENCE.md)
4. **Review Code**: Source in `lib/engine/` and `lib/config/`

### Technical Lead

1. **System Overview**: [ARCHITECTURE.md](ARCHITECTURE.md)
2. **New Engineer Onboarding**: Point to [QUICK_START.md](QUICK_START.md)
3. **Code Review**: Check against patterns in [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) "Best Practices"

### Product Manager

1. **What Features Supported**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Architecture Overview"
2. **Can We Add Feature X?**: Ask engineer to read [ARCHITECTURE.md](ARCHITECTURE.md) "Future Improvements"

### QA / Test Engineer

1. **Understand System**: [QUICK_START.md](QUICK_START.md) + [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Test New Component**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Testing Patterns"

---

## Troubleshooting by Symptom

### UI Blank / Nothing Renders
- Check: [QUICK_START.md](QUICK_START.md) → "Troubleshooting"
- Read: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Troubleshooting"

### Component Not Found Error
- Problem: Type not registered
- Solution: [QUICK_START.md](QUICK_START.md) → "Add a New Component Type"

### Validation Warning in Console
- Meaning: JSON has unexpected properties
- Details: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Using the Schema System"
- Fix: Add property to schema or fix JSON

### Test Failing
- Approach: [QUICK_START.md](QUICK_START.md) → "Test a Renderer"
- Details: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Testing Patterns"

### API Class Not Found
- Lookup: [API_REFERENCE.md](API_REFERENCE.md)
- Check: Import statements

---

## Code Example Index

### Simple Renderer

**File**: [QUICK_START.md](QUICK_START.md) → "Template: Copy-Paste Your Renderer"

### Full Renderer with Child

**File**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Advanced: Renderer with State"

### Schema Definition

**File**: [QUICK_START.md](QUICK_START.md) → "Schema Definition Cheat Sheet"

### Property Parsing

**File**: [QUICK_START.md](QUICK_START.md) → "Property Parsers Cheat Sheet"

### Unit Test

**File**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Unit Test: Custom Renderer"

### Mock Renderer

**File**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Widget Test: Mock Renderer"

### ComponentRegistry Usage

**File**: [API_REFERENCE.md](API_REFERENCE.md) → "ComponentRegistry API"

---

## FAQ

### Q: Where do I start?

**A**: Read [QUICK_START.md](QUICK_START.md) - takes 5 minutes

### Q: How do I add a new component?

**A**: 
1. [QUICK_START.md](QUICK_START.md) → "Add a New Component Type"
2. Then [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) for details

### Q: What's the difference between Schema and Renderer?

**A**: [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Using the Schema System"

### Q: Can I test my renderer?

**A**: Yes! [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) → "Testing Patterns"

### Q: Why is validation lenient?

**A**: [ARCHITECTURE.md](ARCHITECTURE.md) → "Decision 3: Lenient Validation"

### Q: Can I override built-in renderers?

**A**: Yes! [QUICK_START.md](QUICK_START.md) → "Pattern 3: Mock a Renderer in Tests"

---

## Related Files (Source Code)

### Core Engine Files

| File | Purpose |
|------|---------|
| `lib/engine/registry/component_registry.dart` | Runtime component lookup |
| `lib/engine/screen_renderer/screen_renderer.dart` | Main widget builder |
| `lib/engine/component_renderer/component_renderer.dart` | Renderer interface |
| `lib/engine/validation/component_schema.dart` | Schema validation |
| `lib/engine/validation/component_schemas.dart` | Predefined schemas |
| `lib/engine/tree/parsers/property_parsers.dart` | Property converters |

### Example Renderers

| File | Component |
|------|-----------|
| `lib/engine/tree/renderers/text_renderer.dart` | Text (leaf) |
| `lib/engine/tree/renderers/button_renderer.dart` | Button (leaf) |
| `lib/engine/tree/renderers/image_renderer.dart` | Image (leaf) |
| `lib/engine/tree/renderers/column_renderer.dart` | Column (multi-child) |
| `lib/engine/tree/renderers/row_renderer.dart` | Row (multi-child) |
| `lib/engine/tree/renderers/container_renderer.dart` | Container (single-child) |
| `lib/engine/tree/renderers/scaffold_renderer.dart` | Scaffold (wrapper) |
| `lib/engine/tree/renderers/card_renderer.dart` | Card (wrapper) |
| `lib/engine/tree/renderers/spacer_renderer.dart` | Spacer (layout) |

### Data Models

| File | Model |
|------|-------|
| `lib/config/component_config.dart` | Component tree node |
| `lib/config/screen_config.dart` | Screen wrapper |
| `lib/core/enums/generic_component_type.dart` | Component types |

### Parser & Integration

| File | Purpose |
|------|---------|
| `lib/features/variantscreen/data/repos/variant_repository.dart` | JSON parser |
| `lib/features/variantscreen/presentation/manager/variant_cubit/` | State management |

### Tests

| Pattern | File |
|---------|------|
| Unit tests | `test/**/*_test.dart` |
| Widget tests | `test/**/*_widget_test.dart` |
| Integration | `integration_test/**/*_test.dart` |

---

## Feedback & Updates

This documentation will evolve as the system grows. If you find:

- **Errors or typos**: File an issue
- **Missing information**: Add to relevant doc
- **Confusing sections**: Rewrite for clarity
- **New patterns**: Add examples

---

## Next Steps

### For Users

1. Read [QUICK_START.md](QUICK_START.md)
2. Follow the 5-step guide to add a component
3. Refer to [API_REFERENCE.md](API_REFERENCE.md) as needed

### For Contributors

1. Read [QUICK_START.md](QUICK_START.md) + [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md)
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) to understand design
3. Follow patterns in [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) "Best Practices"
4. Test according to patterns in "Testing Patterns"

### For Code Reviewers

1. Check against [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) "Best Practices"
2. Verify [RENDERING_ENGINE_GUIDE.md](RENDERING_ENGINE_GUIDE.md) "Testing Patterns" are followed
3. Use [API_REFERENCE.md](API_REFERENCE.md) for correctness

---

## Version Info

**Documentation Version**: 2.0  
**System Version**: Phase 2 (Stabilization & Extensibility)  
**Last Updated**: April 2026  
**Status**: Production-Ready

---

## Document Ownership

| Document | Owner | Last Updated |
|----------|-------|--------------|
| QUICK_START.md | Architecture Team | Apr 2026 |
| RENDERING_ENGINE_GUIDE.md | Architecture Team | Apr 2026 |
| API_REFERENCE.md | Architecture Team | Apr 2026 |
| ARCHITECTURE.md | Architecture Team | Apr 2026 |

---

**Ready to get started? → [QUICK_START.md](QUICK_START.md)**

