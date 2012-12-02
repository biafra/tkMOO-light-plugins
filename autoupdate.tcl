# autoupdate.tcl
#     - tkMOO-light plugin
#
# (c) 2005 by biafra at MOOsaico
#
# v0.10 2007.04.05 check for http.tcl and warn
# v0.9  2006.10.19 add -timeout to ::http::geturl
# v0.8  2005.11.01 none is the default proxy setting
# v0.7  2005.04.03 get alfa packages if it's a tester
# v0.6  2005.03.22 none / manual / system-default proxy settings
# v0.5  2005.03.21 manual proxy settings
# v0.4  2005.03.20 local and server plugin file versions with updates
# v0.3  progress bar in windows (not shown)
# v0.2  progress bar in linux (ok)
# v0.1  httpget from file
# v0.0  inicial release
#
# This is a plugin "auto-updater". It will check a server for
# new versions and download them accordingly.
#
# It will read a autoupdate.txt file with a special syntax:
#
# version;localfile-name;url-to-download
#
# ex:
#
# 0.10a;autoupdate.tcl;http://clients.moosaico.com/tkmoo/autoupdate.tcl
# 0.8;client-info.tcl;http://clients.moosaico.com/tkmoo/client-info.tcl
# 0.0;subwindow.tcl;http://www.awns.com/tkMOO-light/plugins/subwindow.tcl
#
# Requires "http". So if you're using a windows binary with
# an old tcl interpreter you'll have to copy "http.tcl" to your
# tkMOO-light plugins directory.
#
# The httpd stuff probably should have been homed with its own plugin
#
# As I've started to program in tcl two weeks ago please send me
# your comments or better pieces of code :)
#
# TODO: use HTTP_PROXY on *nix
# TODO: define global URLs for autoupdate.txt files

client.register autoupdate start 80
client.register autoupdate client_connected

catch { package require registry } e

variable pluginsdir
variable show_http 1
variable autoupdate_frame
variable autoupdate_unlit
variable httplog stderr
variable autoupdateurl http://clients.moosaico.com/tkmoo/autoupdate.txt
variable autoupdateurlalfa http://clients.moosaico.com/tkmoo/alfatester.txt

if { [info procs plugin.plugins_dir] != {} } {
    set pluginsdir [plugin.plugins_dir]
    if { $pluginsdir == "" } {
        puts stderr "Can't get de plugins directory!!"
    }
}
file mkdir $pluginsdir/lib

#if { [catch { package require http 2.4 } e ] } {
#    window.displayCR "You must install package \"http\" to get remote support" window_highlight
#	window.displayCR "   Get it from http://moosaico.com/clients/http.tcl" window_highlight
#	window.displayCR "   Install it in $pluginsdir/lib/" window_highlight
#}

proc httpcopy { url file {chunk 4096} } {
    global show_http

    set savefile [open $file w]
    set token [::http::geturl $url -channel $savefile \
           -progress httpProgress -blocksize $chunk -timeout 5000]
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
    #incr max
    #foreach {name value} $state(meta) {
    #   puts [format "%-*s %s" $max $name: $value]
    #}

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

proc autoupdate.start {} {
    global autoupdate_frame show_http

    preferences.register autoupdate {Statusbar Settings} {
        { {directive ShowHTTP}
            {type boolean}
            {default On}
            {display "Show HTTP use"} }
        { {directive AUProxyDefault}
            {type choice-menu}
            {default none}
            {choices {none system-default manual}}
            {display "Use Proxy"} }
        { {directive AUProxyAddress}
            {type string}
            {default ""}
            {display "Proxy host"} }
        { {directive AUProxyPort}
            {type string}
            {default ""}
            {display "Proxy port"} }
    }
    preferences.register autoupdate {Special Forces} {
        { {directive AUalfa}
            {type boolean}
            {default Off}
            {display "Get Alfa Packages"} }
    }

    set autoupdate_frame 0
    set show_http 1
    window.menu_tools_add "Show HTTP on/off" autoupdate.show_toggle
    
    set use [worlds.get_generic Off {} {} ShowHTTP]
    if { [string tolower $use] == "on" } {
        autoupdate.show_create
    }
    autoupdate.update
}

proc autoupdate.client_connected {} {
    set use [worlds.get_generic Off {} {} ShowHTTP]
    if { [string tolower $use] == "on" } {
        autoupdate.show_create
    }
    return [modules.module_deferred]
}

proc autoupdate.show_toggle {} {
    global autoupdate_frame show_http

    if { $show_http == 1 } {
        set show_http 0
        catch { window.delete_statusbar_item $autoupdate_frame }
    } else {
        set show_http 1
        autoupdate.show_create
    }   
}

proc autoupdate.show_clean {} {
    global autoupdate_frame autoupdate_unlit show_http

    if { $show_http == 1 } {
        for {set i 1} {$i <= 30} {incr i} {
            $autoupdate_frame.r.$i configure -bg $autoupdate_unlit
        }
    }
}

proc autoupdate.show_create {} {
    global autoupdate_frame autoupdate_unlit

    if { [winfo exists $autoupdate_frame] == 1 } { return };
    set autoupdate_frame [window.create_statusbar_item]
    set a $autoupdate_frame
    frame $a -bd 1 -relief sunken -bg pink

    frame $a.r -bd 0 -highlightthickness 0 \
               -width 30 -height 10 \
               -bg pink
    pack $a.r -fill y -expand 1 -padx 2

    for {set i 1} {$i <= 30} {incr i} {
        frame $a.r.$i \
            -bd 1 -highlightthickness 0 \
            -width 1 -height 10 -relief raised \
            -bg pink
        pack configure $a.r.$i -side left
    } 

    pack $a -fill y -expand 0 -side right

    set autoupdate_unlit [$a.r.1 cget -bg]

    window.repack
}

proc autoupdate.update {} {
    global pluginsdir httplog autoupdateurl autoupdateurlalfa

    puts stderr "<update>"

    window.displayCR " % Checking for plugin updates. Restart tkMOO-light if there are new ones."
    set tkmooversion [util.version]
    ::http::config -useragent "tkMOO-light/$tkmooversion ($::tcl_platform(platform); $::tcl_platform(os) $::tcl_platform(osVersion))"
    #exec cmd.exe /c mkdir media
    set url $autoupdateurl
    set urlalfa $autoupdateurlalfa

    catch { ::http::config -proxyfilter "autoupdate.pfilter" } e

    autoupdate.get_them $url "autoupdate.txt"
    set AUalfa [worlds.get_generic Off {} {} AUalfa]
    if { [string tolower $AUalfa] == "on" } {
        window.displayCR " % checking alfa plugins"
        autoupdate.get_them $urlalfa "alfatester.txt"
    }
    window.displayCR " % End plugin check."
    puts stderr "</update>"
}

proc autoupdate.get_them {url aufilename} {
    global pluginsdir

    array set lfiles [autoupdate.get_local_file $aufilename]

    set httplog [open $pluginsdir/http-log.txt a]

    catch { set token [::http::geturl $url -timeout 5000] } e
    upvar #0 $token state

    foreach { fileline } [split $state(body) "\n"] {
        if {([string index $fileline 0] != "#") && ($fileline != "")} {
            set pacversion ""
            set paclocal ""
            set pacurl ""
            catch {
                regexp {(.*);(.*);(.*$)} $fileline _ pacversion paclocal pacurl a b c}
            if { ($pacversion == "") || ($paclocal == "") || ($pacurl == "") } {
                puts stderr "Syntax error in $aufilename"
            } else {
                # it seams tcl8.3 doesn't have -exact
                if { ([array names lfiles $paclocal] == "") || ($lfiles($paclocal) != $pacversion) } {
                    httpcopy $pacurl $pluginsdir/$paclocal
                    window.display "   $paclocal" window_highlight
                    puts $httplog "$pacurl"
                }
            }
        }
    }
    close $httplog
    catch { file copy -force $pluginsdir/$aufilename
                             $pluginsdir/$aufilename.old }
    set f [open "$pluginsdir/$aufilename" w]
    puts $f $state(body)
    close $f
    window.displayCR
}

proc autoupdate.get_local_file {filename} {
    puts stderr "<local_files>"
    global pluginsdir

    set pac {}
    if { [catch { set f [open "$pluginsdir/$filename" "r"] } e] } {
        puts stderr "</local_files>"
        return $pac
    }
    while {[gets $f line] >= 0} {
        if {([string index $line 0] != "#") && ($line != "")} { 
            set pacversion ""
            set paclocal ""
            set pacurl ""
            catch {
                regexp {(.*);(.*);(.*$)} $line _ pacversion paclocal pacurl a b c }
                lappend pac $paclocal $pacversion
        }
    }
    catch { close $f }
    puts stderr "</local_files>"
    return $pac
}

proc autoupdate.pfilter {host} {
    global tcl_platform

    set aupdefault [worlds.get_generic {} {} {} AUProxyDefault]
    set auphost [worlds.get_generic {} {} {} AUProxyAddress]
    set aupport [worlds.get_generic {} {} {} AUProxyPort]

    if { $aupdefault == "none" } {
        return [list {}]
    } elseif { $aupdefault == "manual" } {
        if { ($auphost != "") && ($aupport != "") } {
            return [list $auphost $aupport]
        }
    } elseif { $aupdefault == "system-default" } {
        if { $tcl_platform(platform) == "windows" } {
            set pok [registry get "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings" "ProxyEnable"]
            # if { $pok == 1} {
            # At least in win2k with IE5 the ProxyEnable is not set. Great! :/
                set pserver [registry get "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings" "ProxyServer"]
                set s [split $pserver :]
                set phost [lindex $s 0]
                set pport [lindex $s 1]
                if { ($phost != "") && ($pport != "") } {
                    return [list $phost $pport]
                }               
           # }
        }
    }
    return [list {}]
}

