# Change log

## [v0.9.0] - 2017-08-18

### Changed
* Change SystemPager to stop using fork, instead execute pager in subprocess
  and make it portable across platforms including Windows
* Change SystemPager to work on jruby
* Change NullPager to only print to stdout on tty device
* Change Pager to select SystemPager when paging command exists
* Remove jruby? checks from pager selection

## [v0.8.0] - 2017-07-14

### Added
* Add :command option to SystemPager to enforce choice of pagination tool
* Add Error type for specific error notifications

### Changed
* Change SystemPager to prevent initialization if pager isn't supported

### Fixed
* Fix BasicPager to take terminal width into account when displaying page break messages
* Fix SystemPager on Windows by detecting fork implementation

## [v0.7.1] - 2017-04-09

### Fixed
* Fix SystemPager raises error when executable is blank string by Jacob Evelyn (@JacobEvelyn)

## [v0.7.0] - 2017-03-20

### Changed
* Change files loading
* Update tty-which dependency

## [v0.6.0] - 2017-03-19

### Changed
* Change SystemPager to support piped git pagers by @JacobEvelyn

## [v0.5.0] - 2016-12-19

### Changed
* Change to call TTY::Which#exist? new api
* Change to send fork message directly to SystemPager
* Update tty-which
* Update verse dependency

## [v0.4.0] - 2016-02-06

### Changed
* Update tty-screen dependency

## [v0.3.0] - 2015-09-20

### Changed
* Change to use new tty-screen dependency

## [v0.2.0] - 2015-06-27

### Changed
* Change SystemPager to correctly paginate inside a process.

[v0.9.0]: https://github.com/peter-murach/tty-prompt/compare/v0.8.0...v0.9.0
[v0.8.0]: https://github.com/peter-murach/tty-prompt/compare/v0.7.1...v0.8.0
[v0.7.1]: https://github.com/peter-murach/tty-prompt/compare/v0.7.0...v0.7.1
[v0.7.0]: https://github.com/peter-murach/tty-prompt/compare/v0.6.0...v0.7.0
[v0.6.0]: https://github.com/peter-murach/tty-prompt/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/peter-murach/tty-prompt/compare/v0.4.0...v0.5.0
[v0.4.0]: https://github.com/peter-murach/tty-prompt/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/peter-murach/tty-prompt/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/peter-murach/tty-prompt/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/peter-murach/tty-prompt/compare/v0.1.0
