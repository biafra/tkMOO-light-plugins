#
#       tkMOO
#       ~/.tkMOO-lite/plugins/client-info.tcl
#	*** ALFA VERSION *** come here often !!!
#
#       v0.8
#        
#	This plugin implements the package "dns-com-vmoo-client" with
#	the following messages:
#
#		dns-com-vmoo-client-info
#
#	It's missing "dns-com-vmoo-client-disconnect"
#
#	http://www.vmoo.com/support/moo/mcp-specs/#vgm-client
#
#   Biafra @ MOOsaico   

client.register clientinfo start 55

variable ocols 80
variable orows 24

proc clientinfo.start {} {
    mcp21.register dns-com-vmoo-client 1.0 \
        dns-com-vmoo-client-info clientinfo.info 
    mcp21.register dns-com-vmoo-client 1.0 \
        dns-com-vmoo-client-screensize clientinfo.screensize
    mcp21.register_internal clientinfo mcp_negotiate_end
    # update moo with client geometry
    clientinfo.screensize
    # last stuff
    bind . <Configure> { clientinfo.screensize }
}

proc clientinfo.info {} {
  # do nothing
}

proc clientinfo.screensize {} {
    global ocols orows

    set actual_geometry [wm geometry .]

    regexp {([0-9]+)x([0-9]+)} $actual_geometry \
        match cols rows
    if { $ocols != $cols || $orows != $rows} {
        set ocols $cols
        set orows $rows
        mcp21.server_notify dns-com-vmoo-client-screensize [list [list cols $cols] [list rows $rows] ]
    }
}

proc clientinfo.mcp_negotiate_end {} {
    global ocols

    set overlap [mcp21.report_overlap]
    set version [util.assoc $overlap dns-com-vmoo-client]
    set tkmooversion [util.version]

    if { ($version != {}) && ([lindex $version 1] == 1.0) } {
       mcp21.server_notify dns-com-vmoo-client-info [list [list name tkMOO-light] [list text-version "$tkmooversion" ] [list internal-version 0] ]
       #set ocols 1
       clientinfo.screensize
    }
}

