
This is a bare-bones implementation of what's described in [MIT AI
Memo
1564](ftp://publications.ai.mit.edu/ai-publications/pdf/AIM-1564.pdf).

There are a number of embarrassments, requiring a number of apologies.

* No secure interface is provided: not via TCP/IP, command line, or
  any other mode.  From the scheme 48 command line, you still have
  access to the configuration environment via comma-commands, from
  which you can do anything.  This could be repaired by creating a
  restricted configuration environment - scheme 48 is certainly 
  capable of doing that.
* Reification uses scheme 48 configuration environment reification
  (config-package), which seems an awful kludge.  There should be a
  more direct way to do it that doesn't haul in so much of scheme
  48's programming environment infrastructure.
* There is a server module, but it is disabled because it depends on
  some HTTP client and server code of mine that is really substandard.
  (See the Psyche repository if you must.)
* 'sharp-sharp' is a global resource that is not properly managed.

To run:

1. Start up a scheme 48 command processor
2. ``,config ,load w7-config.scm``
3. ``,config (define-structure scratch (export) (open usual-w7-features))``
4. ``,in scratch``

Welcome to jail!
