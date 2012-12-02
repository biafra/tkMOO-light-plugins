#
# This plugin implements a subset of the package "dns-com-vmoo-mmedia"
# with the following messages:
#
#   C->S:   dns-com-vmoo-mmedia-accept
#   C->S:   dns-com-vmoo-mmedia-ack-stage
#   C->S:   dns-com-vmoo-mmedia-ack-done
#   S->C:   dns-com-vmoo-mmedia-play
#   S->C:   dns-com-vmoo-mmedia-show
#
# It depends on plugin "rose2.1.tcl" to display images (-show)
#
# You should install the snack extention
# http://www.speech.kth.se/snack/download.html
# and
# http://www.muonics.com/FreeStuff/TkPNG/
#
# mmedia v0.1 - 2007.04.05 
#
# Biafra @ MOOsaico

# we need to wait for mcp21 to setup
client.register mmedia start 61

#puts stderr $::tcl_pkgPath
#puts stderr $::auto_path
#puts stderr $env(TKMOO_LIB_DIR)
#puts stderr $tkmooLibrary

variable snd
variable screen

variable pluginsdir
variable show_http 1
variable autoupdate_frame
variable autoupdate_unlit
variable httplog stderr

if { [info procs plugin.plugins_dir] != {} } {
    set pluginsdir [plugin.plugins_dir]
    if { $pluginsdir == "" } {
        puts stderr "Can't get de plugins directory!!"
    }
}
lappend ::auto_path $pluginsdir/lib

file mkdir $pluginsdir/lib
file mkdir $pluginsdir/screen
file mkdir $pluginsdir/sounds

catch { package require http 2.4 } e
catch { package require registry } e

if { [catch { package require snack } e ] } {
    window.displayCR "You must install package \"snack\" to get mmedia support" window_highlight
	window.displayCR "   Get it from http://www.speech.kth.se/snack/download.html" window_highlight
	window.displayCR "   Install it in $pluginsdir/lib/" window_highlight
}

#if {$::tcl_platform(platform) == "unix" } {
if { [catch { package require tkpng } e ] } {
    window.displayCR "You must install package \"tkpng\" to get mmedia support" window_highlight
    window.displayCR "   Get it from http://www.muonics.com/FreeStuff/TkPNG/ (for Windows use 0.5)" window_highlight
	window.displayCR "   Install it in $pluginsdir/lib/" window_highlight
}
#}

proc httpcopy { url file {chunk 4096} } {
    global show_http

    set savefile [open $file w]
    set token [::http::geturl $url -channel $savefile \
           -progress httpProgress -blocksize $chunk]
    close $savefile
    after 1000 autoupdate.show_clean

    upvar #0 $token state
    set max 0
    foreach {name value} $state(meta) {
       if {[string length $name] > $max} {
          set max [string length $name]
       }
       if {[regexp -nocase ^location$ $name]} {
          # Handle URL redirects
          #puts stderr "Location:$value"
          return [httpcopy [string trim $value] $file $chunk]
       }
    }

    return $token
}
proc httpProgress {token total current} {
    global autoupdate_frame autoupdate_unlit show_http httplog

    if { $show_http == 1 } {
        upvar #0 $token state
        set width [expr {40 * $current / $total}]
        for {set i 1} {($i <= $width) && ($i <= 30)} {incr i} {
            $autoupdate_frame.r.$i configure -bg blue
        }
        for {} {$i <= 30} {incr i} {
            $autoupdate_frame.r.$i configure -bg $autoupdate_unlit
        }
    }

}


proc mmedia.start {} {
    global screen
    global pluginsdir

    mcp21.register dns-com-vmoo-mmedia 2.0 \
	dns-com-vmoo-mmedia-play mmedia.play
    mcp21.register dns-com-vmoo-mmedia 2.0 \
	dns-com-vmoo-mmedia-show mmedia.show 
    mcp21.register_internal mmedia mcp_negotiate_end
    snack::sound snd
}

proc mmedia.mcp_negotiate_end {} {
    mcp21.server_notify dns-com-vmoo-mmedia-accept [list [list conspeed 0] [list protocols alias,http,local ] [list methods music,play,preload,show] [list insert ""] [list music wav,aif,mp3] [list play wav] [list show png,gif] ]
#    mcp21.server_notify dns-com-vmoo-mmedia-accept [list [list conspeed 0] [list protocols alias,http,local ] [list methods music,play,preload,show] [list insert ""] [list music wav,aif,mp3] [list play wav,aif,mp3] [list show wav,aif,mp3,gif,jpg,png,bmp] ]
#    mcp21.server_notify dns-com-vmoo-mmedia-accept [list [list conspeed 0] [list protocols local ] [list methods play] [list insert ""] [list music wav] [list play avi,wav] [list show gif,jpg,png,bmp] ]
}

proc mmedia.play {} {
    global pluginsdir
    set ackid [request.get current ack-id]
    set uri [request.get current file]
    regsub ^(.*)\/ $uri "" file
    httpcopy $uri  $pluginsdir/sounds/$file
    snd configure -file $pluginsdir/sounds/$file
    snd play
    mcp21.server_notify dns-com-vmoo-mmedia-ack-stage [list [list ack-id $ackid] [list method play] [list stage 0] ]
    mcp21.server_notify dns-com-vmoo-mmedia-ack-stage [list [list ack-id $ackid] [list method play] [list stage 200] ]
    mcp21.server_notify dns-com-vmoo-mmedia-ack-done [list [list ack-id $ackid] [list method play] [list stage 1000] [list reason 1000]]
}

proc mmedia.show {} {
	global pluginsdir

	catch {canvas .rose2.s -height 90 -width 160 -bg white -highlightthickness 0 -bd 0} e
	pack .rose2.s -side right

    window.repack

    set ackid [request.get current ack-id]
	set uri [request.get current file]
	regsub ^(.*)\/ $uri "" file
	httpcopy $uri  $pluginsdir/screen/$file
    catch { set screen [image create photo -format "png" -file $pluginsdir/screen/$file] } e
    catch {
      set i [.rose2.s create image 80 45 -image $screen]
      .rose2.s itemconfigure $i -image $screen
      canvas .rose2.s -activeimage $screen
      pack .rose2.s
    } e
}
