tkMOO-light-plugins
===================

New tkMOO-light plugins and updates/changes to some AWNS originals.

[tkMOO-light](http://www.awns.com/tkMOO-light)  support
[MCP/2.1](http://www.moo.mud.org/mcp2/) and comes with several
[plugins](http://www.awns.com/tkMOO-light/plugins/).

Plugins
---

> **`client-info.tcl`**
> 
> Implements **`dns-com-vmoo-client`** which sends some client info to the MOO.
> It lets the MOO server to know the client name and version, and the window horizontal and vertical size.
> 
> **`mmedia.tcl`**
> 
> Tries to implement **`dns-com-vmoo-mmedia`** specially playing sounds and
> showing a small image. It depends on `rose2.1.tcl` plugin from AWNS.
> 
> You should install the [Snack](http://www.speech.kth.se/snack/download.html)
> TCL extention to support sound and the
> [TkPNG](http://www.muonics.com/FreeStuff/TkPNG/) to support images.

AWNS plugins update
-------------------

> **`ping.tcl`**
> 
> Implements **`dns-com-awns-ping`**. A small change so it works well with
> other plugins that need to update the statusbar too.
> 
> **`rose2.1.tcl`**
> 
> Rose needs `visual.tcl` and visually shows your surroundings and let you move.
> Now it checks the TCL version so it can use a correct `tkDarken`.

