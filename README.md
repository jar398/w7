
This is a bare-bones implementation of what's described in [MIT AI
Memo
1564](ftp://publications.ai.mit.edu/ai-publications/pdf/AIM-1564.pdf).
There's nothing of substance here; all the heavy lifting is done by
scheme 48.  So if you want to know what W7 is, the answer is that it's
a subset of Scheme 48, with a bit of shim added.

This code is mostly untested and probably both incomplete and wrong.

There are a number of embarrassments, requiring a number of apologies.

* No secure interface is provided: not via TCP/IP, command line, or
  any other mode.  From the Scheme 48 command line, you still have
  access to the configuration environment via comma-commands, from
  which you can do anything.  This could be repaired by creating a
  restricted configuration environment - Scheme 48 is certainly 
  capable of doing that.
* Reification uses Scheme 48 configuration environment reification
  (config-package), which seems an awful kludge.  There should be a
  more direct way to do it that doesn't haul in so much of Scheme
  48's programming environment infrastructure.
* There is a server module, but it is disabled because it depends on
  some HTTP client and server code of mine that is really substandard.
  (See the Psyche repository if you must.)
* 'sharp-sharp' is a global resource that is not properly managed.

To run:

1. Start up a Scheme 48 command processor
2. ``,config ,load w7-config.scm``
3. ``,config (define-structure scratch (export) (open usual-w7-features))``
4. ``,in scratch``

Welcome to jail!
