# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

## [0.3.0] - 2025-10-31

### Added
- Sprint 2: Creative Caching and Unified Ad Serving APIs
  - **Creative Caching API** (`get_asset` method)
    - Pre-fetch creative assets for 30-hour window
    - Bandwidth optimization for poor connectivity scenarios
    - Full display area configuration support
    - Optional device attributes, latitude, longitude
    - Comprehensive validation for all parameters
  - **Unified Ad Serving API** (`get_loop` method)
    - Loop-based content scheduling for digital signage
    - Combines direct content, programmatic ads, and loop content
    - Returns slots (advertisement/content/programmatic) and assets
    - Support for metadata inclusion (order/advertiser info)
    - Future scheduling up to 10 days
  - **Loop Tracking** (`submit_loop_tracking` method)
    - Convenience method for tracking URL submission
    - Automatic display_time parameter appending
    - Offline-friendly (tracking URLs don't expire)
  - **46 new test examples** (164 total)
    - 21 tests for Creative Caching API
    - 25 tests for Unified Ad Serving API
  - **98.17% code coverage** (215/219 lines covered)
  - **100% YARD documentation** for all new APIs

### Changed
- Updated Client to include three API modules:
  - API::AdServing (Sprint 1)
  - API::CreativeCaching (Sprint 2)
  - API::UnifiedServing (Sprint 2)
- Enhanced Connection class with GET request support
- Updated RuboCop configuration:
  - Increased RSpec/ExampleLength to 25
  - Added RSpec/MultipleMemoizedHelpers: 10
  - Added Metrics/CyclomaticComplexity exceptions

### Technical Details
- Modular API architecture fully realized
- All three major Vistar Media APIs implemented:
  1. Ad Serving API (request_ad, submit_proof_of_play)
  2. Creative Caching API (get_asset)
  3. Unified Ad Serving API (get_loop, submit_loop_tracking)
- Production-ready for real-world digital signage deployments
- Comprehensive workflow support:
  - Basic ad serving workflow
  - Creative caching with pre-fetch
  - Loop-based playlist building
  - Hybrid loop with programmatic slots

## [0.2.0] - 2025-10-31

### Added
- Sprint 1: Core Vistar Media API Client Implementation
  - Complete error hierarchy (Error, AuthenticationError, APIError, ConnectionError)
  - Client class with credential validation and configuration
  - HTTP connection management with Faraday
  - Custom error handler middleware with intelligent error parsing
  - Automatic retry logic with exponential backoff (3 retries, 429/5xx status codes)
  - `request_ad` method for programmatic ad requests
  - `submit_proof_of_play` method for ad display confirmation
  - Comprehensive parameter validation with descriptive error messages
  - Optional debug logging via VISTAR_DEBUG environment variable
  - Full test coverage: 118 test examples, 98.73% code coverage
  - 100% YARD documentation coverage (8 files, 5 modules, 7 classes, 11 methods)

### Changed
- Refactored to modular architecture for extensibility
  - Connection class for HTTP client abstraction
  - API::Base module for shared API functionality
  - API::AdServing module for ad serving endpoints
  - Client class uses composition pattern (reduced from 238 to 89 lines)
- Updated README with:
  - Architecture documentation
  - Comprehensive API method documentation
  - Error handling guide
  - Extension guide for adding new API modules
- Improved error messages with HTTP status codes and response bodies

### Technical Details
- Faraday-based HTTP client with middleware stack
- JSON request/response encoding and parsing
- Method delegation pattern for backward compatibility
- WebMock integration for comprehensive API testing
- RuboCop compliant code style

## [0.1.0] - 2025-10-31

### Added
- Initial project scaffolding
- Basic gem structure with Bundler
- MIT License
- Documentation structure
- Sprint 0: Production infrastructure setup
  - Production-grade RuboCop configuration
  - RSpec with SimpleCov integration (95% coverage target)
  - GitHub Actions CI/CD pipeline
  - Complete gemspec with all dependencies
  - Development environment setup (.env, bin/setup, bin/console)
  - Release and contribution documentation

[Unreleased]: https://github.com/Sentia/vistar_client/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Sentia/vistar_client/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Sentia/vistar_client/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Sentia/vistar_client/releases/tag/v0.1.0
