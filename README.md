# icatcomponents

A CLI tool for managing ICAT components.

## Usage

See `icatcomponents -h` for a full list of commands and their arguments

## Building

Building the project requires the nim compiler, the nimble package manager (usually included with the compiler), and OpenSSL. Build with `nimble build -d:ssl` to dynamically link OpenSSL, or `--dynlibOverride:ssl` to statically link it.

## asdf

 - A component is available if it's in the [icatproject releases repo](repo.icatproject.org/repo/org/icatproject/)
 - A component is installed if there's a folder for it in the installs folder
 - A component is deployed if it's in the glassfish domain applications folder
