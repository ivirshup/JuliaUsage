# Things that are real dumb about the package manager

* Even if you know what you're doing, it's pretty sure you're not
  * It should allow force removing + force checkout + force update
  * It shouldn't stop everything for a minor issue.
* It should be able to have multiple versions of a thing installed
  * The beauty of having it be a git repo is that you have every version available
  * But then you don't have precompiled versions of everything.
  * If a package requires a precompiled version of another package other than the latest one
    could the required package could just include the version it needs in it's compiled file
    * Unless there are changing binary dependencies too.
* Fucking relative paths for everything.
  * Could probably just set PKG_DIR environment variable with getter/setter methods
  * How does compilation deal with module variables elements?
* GODDAMN ACCESSOR METHODS
* Consistent use of types
