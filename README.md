# ATLAS — FAA AVS Portfolio Rationalization

Research repository for the FAA Aviation Safety (AVS) Certification & Registry portfolio rationalization initiative.

## Portfolio Systems

| System | Description | Status |
|--------|-------------|--------|
| **RMS** | Registry Modernization System — NATURAL/ADABAS mainframe, 174M TIFF images | Being replaced by CARES |
| **MedXPress/MSS** | Medical Support Systems — 6 subsystems (MedXPress, AMCS, DIWS, CPDSS, CHAPS, DSS) | Active, fragmented |
| **IACRA** | Integrated Airman Certification & Rating Application — temporary repository | Being absorbed into CARES Phase 2 |
| **DMS** | Designee Management System — 13 designee categories, ~10K designees | Modernizing in place |
| **CARES** | Civil Aviation Registration Electronic Services — cloud-based replacement | Phase 1 live, FOC Fall 2027 |

## Repository Structure

```
research/
├── README.md                          — Research index
├── portfolio-overview/                — Cross-portfolio analysis
│   ├── overview.md                    — System comparison table
│   ├── deep-research-report.md        — Comprehensive portfolio analysis
│   ├── rationalization-research-pack.md — Engineering-depth tech details
│   └── link-inventory.md             — Verified public documentation links
├── rms/                              — Registry Modernization System
│   ├── tech-profile.md               — Tech stack, data elements, integrations
│   └── docs/                         — Downloaded reference documents
├── medxpress-mss/                    — Medical Support Systems
│   ├── tech-profile.md
│   └── docs/                         — User guides, AME guides, document taxonomy
├── iacra/                            — Airman Certification Application
│   ├── tech-profile.md
│   └── docs/                         — User guides, training materials
├── dms/                              — Designee Management System
│   ├── tech-profile.md
│   └── docs/                         — User manuals, policy orders, deployment notices
├── cares/                            — CARES Replacement Platform
│   ├── tech-profile.md
│   └── docs/                         — Sign-up guides, PIAs
└── cross-cutting/                    — Integration analysis
    ├── integration-map.md            — Anti-patterns, identity sprawl, AI opportunities
    ├── tech-profile.md               — Cross-system dependencies
    └── docs/                         — Shared service documentation
```

## Goal

Build an integrated modernized application by rationalizing business functions and technical functions across the 4 legacy systems to reduce tech debt and improve user experience for applicants, examiners, and FAA operators.

## Key Documents

The 10 highest-value reference documents are listed in `research/portfolio-overview/link-inventory.md`.
