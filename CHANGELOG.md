# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- New `spool` command to spool console input and output to a file
- Write command history to `~/.birdwatcher_history` and load history on startup
  for persistent command history
- New module `statuses/word_list` to generate a simple word list from statuses
- Introduced new `Birdwatcher::WordList` class to process text into a word list

### Changed
- Refactored `statuses/word_cloud` module to use new `Birdwatcher::WordList` class

## [0.3.1]
### Added
- New module `reporting/json` to export data from an SQL query to a file in  JSON format
- New module `reporting/csv` to export data from an SQL query to a file in CSV format
- This changelog

### Changed
- `posted_at` column added to `urls` for better and easier ordering

### Fixed
- Make `status search` command case insensitive
