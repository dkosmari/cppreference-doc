# cppreference-doc

This fork has better support for devhelp output.


## Installing

After cloning the repository:

1. `make download`

2. `make PREFIX=$HOME/.local install-devhelp`

The "download" step needs to be done whenever you want to fetch up-to-date pages from the
wiki, but it takes a long time.


## Uninstalling

Do `make PREFIX=$HOME/.local uninstall-devhelp uninstall-html`


## Known Issues

The QCH scripts don't seem to work.
