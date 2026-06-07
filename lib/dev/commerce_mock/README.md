# Commerce Mock Module

Temporary offline mock layer for Phase 2 commerce work.

- Toggle via `CommerceMockConfig.enabled`
- Simulates latency with `CommerceMockConfig.requestDelay`
- Uses envelope-shaped payloads and existing DTO `fromJson` parsing
- Covers checkout, orders, and shipment tracking

Remove this module once real commerce APIs are implemented in later phases.
