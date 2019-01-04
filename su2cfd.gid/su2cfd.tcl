#################################################
#      GiD-Tcl procedures invoked by GiD        #
#################################################
proc GiD_Event_InitProblemtype { dir } {
    su2cfd::SetDir $dir ;#store to use it later
    su2cfd::ModifyMenus
    gid_groups_conds::open_conditions menu
    su2cfd::CreateWindow  ;#create a window as Tcl example (random surface creation)       
}

proc GiD_Event_ChangedLanguage { language } {
    su2cfd::ModifyMenus ;#to customize again the menu re-created for the new language
}
 
proc GiD_Event_AfterWriteCalculationFile { filename errorflag } {   
    if { ![info exists gid_groups_conds::doc] } {
        WarnWin [= "Error: data not OK"]
        return
    }    
    set err [catch { su2cfd::WriteCalculationFile $filename } ret]
    if { $err } {       
        WarnWin [= "Error when preparing data for analysis (%s)" $::errorInfo]
        set ret -cancel-
    }
    return $ret
}

#################################################
#      namespace implementing procedures        #
#################################################
namespace eval su2cfd { 
    variable problemtype_dir 
}

proc su2cfd::SetDir { dir } {  
    variable problemtype_dir
    set problemtype_dir $dir
}

proc su2cfd::GetDir { } {  
    variable problemtype_dir
    return $problemtype_dir
}

proc su2cfd::ModifyMenus { } {   
    if { [GidUtils::IsTkDisabled] } {  
        return
    }          
    foreach menu_name {Conditions Interval "Interval Data" "Local axes"} {
        GidChangeDataLabel $menu_name ""
    }       
    GidAddUserDataOptions --- 1    
    GidAddUserDataOptions [= "Data tree"] [list GidUtils::ToggleWindow CUSTOMLIB] 2
    set x_path {/*/container[@n="Properties"]/container[@n="materials"]}
    GidAddUserDataOptions [= "Import/export materials"] [list gid_groups_conds::import_export_materials .gid $x_path] 3
    GiDMenu::UpdateMenus
}

######################################################################
#  auxiliary procs invoked from the tree (see .spd xml description)
proc su2cfd::GetMaterialsList { domNode args } {    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set image material
    set result [list]
    foreach dom_material [$dom_materials childNodes] {
        set name [$dom_material @name] 
        lappend result [list 0 $name $name $image 1]
    }
    return [join $result ,]
}

proc su2cfd::EditDatabaseList { domNode dict boundary_conds args } {
    set has_container ""
    set database materials    
    set title [= "User defined"]      
    set list_name [$domNode @n]    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set primary_level material
    if { [dict exists $dict $list_name] } {
        set xps $x_path
        append xps [format_xpath {/blockdata[@n=%s and @name=%s]} $primary_level [dict get $dict $list_name]]
    } else { 
        set xps "" 
    }
    set domNodes [gid_groups_conds::edit_tree_parts_window -accepted_n $primary_level -select_only_one 1 $boundary_conds $title $x_path $xps]          
    set dict ""
    if { [llength $domNodes] } {
        set domNode [lindex $domNodes 0]
        if { [$domNode @n] == $primary_level } {      
            dict set dict $list_name [$domNode @name]
        }
    }
    return [list $dict ""]
}
