########################################################################
#
#  getOpt -- similar as getopt_long_only(3)
#
# (C) 2017 Jianhong Yin <yin-jianhong@163.com>
#
# $Revision: 1.0 $, $Date: 2017/02/24 10:57:22 $
########################################################################
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

namespace eval ::getOpt {
	namespace export getOptions getUsage
}

set ::getOpt::flag(NOTOPT)  1
set ::getOpt::flag(KNOWN)   2
set ::getOpt::flag(NEEDARG) 3
set ::getOpt::flag(UNKNOWN) 4
set ::getOpt::flag(END)     5
set ::getOpt::flag(AGAIN)   6

proc ::getOpt::getOptObj {optList optName} {
	foreach {optNameList optAttr} $optList {
		if {$optName in $optNameList} {
			return [list [lindex $optNameList 0] $optAttr]
		}
	}
	return ""
}

proc ::getOpt::argparse {optionList argvVar optVar optArgVar} {
	upvar $argvVar  argv
	upvar $optVar optName
	upvar $optArgVar optArg

	set result $::getOpt::flag(UNKNOWN)
	set optName ""
	set optArg ""

	if {[llength $argv] == 0} {
		return $::getOpt::flag(END)
	}

	set rarg [lindex $argv 0]
	if {$rarg in {-}} {
		set optArg $rarg
		set argv [lrange $argv 1 end]
		return $::getOpt::flag(NOTOPT)
	}
	if {$rarg in {--}} {
		set argv [lrange $argv 1 end]
		return $::getOpt::flag(END)
	}

	set argv [lrange $argv 1 end]
	switch -glob -- $rarg {
		"-*" -
		"--*" {
			set opttype long
			set optName [string range $rarg 1 end]
			if [string equal [string range $optName 0 0] "-"] {
				set optName [string range $rarg 2 end]
			} else {
				set opttype short
			}

			set idx [string first "=" $optName 1]
			if {$idx != -1} {
				set toptName [string range $optName 0 [expr $idx-1]]
				lassign [getOptObj $optionList $toptName] toptFind toptAttr
				if {$toptFind != ""} {
					set _val [string range $optName [expr $idx+1] end]
					set optName [string range $optName 0 [expr $idx-1]]
				}
			}

			lassign [getOptObj $optionList $optName] optFind optAttr
			if {$optFind != ""} {
				set optName $optFind
				set result $::getOpt::flag(KNOWN)
				set argtype n
				if [dict exists $optAttr arg] {
					set argtype [dict get $optAttr arg]
				}
				switch -exact -- $argtype {
					"o" {
						if [info exists _val] {
							set optArg $_val
						}
					}
					"y" -
					"m" {
						if [info exists _val] {
							set optArg $_val
						} elseif {[llength $argv] != 0 &&
							[lindex $argv 0] != "--"} {
							set optArg [lindex $argv 0]
							set argv [lrange $argv 1 end]
						} else {
							set result $::getOpt::flag(NEEDARG)
						}
					}
				}
			} elseif {![info exists _val] && $opttype in {short} && [string length $optName] > 1} {
				# expand short args
				set insertArgv [list]
				while {[string length $optName]!=0} {
					set x [string range $optName 0 0]
					set optName [string range $optName 1 end]

					if {$x in {= - { } \\ \' \"}} break

					lassign [getOptObj $optionList $x] _x optAttr
					if {$_x == ""} {
						lappend insertArgv  -$x
						continue
					}

					# get option type
					set xtype n
					if [dict exists $optAttr arg] {
						set xtype [dict get $optAttr arg]
					}
					if {[dict exists $optionList $x link]} {
						set x_link [dict get $optionList $x link]
						lassign [getOptObj $optionList $x_link] _x_link optAttr
						if {$_x_link != ""} {
							if [dict exists $optAttr arg] {
								set xtype [dict get $optAttr arg]
							}
						} else {
							lappend insertArgv  -$x
							continue
						}
					}

					switch -exact -- $xtype {
						"n" { lappend insertArgv  -$x }
						"o" {
							lappend insertArgv  -$x=$optName
							break
						}
						"y" -
						"m" {
							lappend insertArgv  -$x
							continue
						}
					}
				}
				set argv [concat $insertArgv $argv]
				return $::getOpt::flag(AGAIN)
			} else {
				set result $::getOpt::flag(UNKNOWN)
			}
		}
		default {
			set optArg $rarg
			set result $::getOpt::flag(NOTOPT)
		}
	}

	return $result
}

proc ::getOpt::getOptions {optLists argv validOptionVar invalidOptionVar notOptionVar {forwardOptionVar ""}} {
	upvar $validOptionVar validOption
	upvar $invalidOptionVar invalidOption
	upvar $notOptionVar notOption
	upvar $forwardOptionVar forwardOption

	#clear out var
	array unset validOption *
	array unset invalidOption *
	set notOption [list]

	set optList "[concat {*}[dict values $optLists]]"
	set opt ""
	set optarg ""
	set nargv $argv
	#set argc [llength $nargv]

	while {1} {
		set prefix {-}
		set curarg [lindex $nargv 0]
		if [string equal [string range $curarg 0 1] "--"] {
			set prefix {--}
		}

		set ret [argparse $optList nargv opt optarg]

		if {$ret == $::getOpt::flag(AGAIN)} {
			continue
		} elseif {$ret == $::getOpt::flag(NOTOPT)} {
			if {[lindex $optarg 0] == {--}} {
				set notOption [concat $notOption $optarg]
			} else {
				lappend notOption $optarg
			}
		} elseif {$ret == $::getOpt::flag(KNOWN)} {
			#known options
			set argtype n
			lassign [getOptObj $optList $opt] _optFind optAttr
			if [dict exists $optAttr arg] {
				set argtype [dict get $optAttr arg]
			}

			set forward {}
			if [dict exists $optAttr forward] {
				set forward y
			}

			if {$forward == "y"} {
				switch -exact -- $argtype {
					"n" {lappend forwardOption "$prefix$opt"}
					default {lappend forwardOption "$prefix$opt=$optarg"}
				}
				continue
			}

			switch -exact -- $argtype {
				"m" {lappend validOption($opt) $optarg}
				"n" {incr validOption($opt) 1}
				default {set validOption($opt) $optarg}
			}
		} elseif {$ret == $::getOpt::flag(NEEDARG)} {
			set invalidOption($opt) "option -$opt need argument"
		} elseif {$ret == $::getOpt::flag(UNKNOWN)} {
			#unknown options
			set invalidOption($opt) "unkown options"
		} elseif {$ret == $::getOpt::flag(END)} {
			#end of nargv or get --
			set notOption [concat $notOption $nargv]
			break
		}
	}

	return 0
}

proc ::getOpt::genOptdesc {optNameList} {
	# print options as GNU style:
	# -o, --long-option	<abstract>
	set shortOpt {}
	set longOpt {}

	foreach k $optNameList {
		if {[string length $k] == 1} {
			lappend shortOpt -$k
		} else {
			lappend longOpt --$k
		}
	}
	set optdesc [join "$shortOpt $longOpt" ", "]
}

proc ::getOpt::getUsage {optLists {out "stdout"}} {

	foreach {group optDict} $optLists {

	#ignore hide options
	foreach key [dict keys $optDict] {
		if [dict exists $optDict $key hide] {
			dict unset optDict $key
		}
	}

	puts $out "$group"

	#generate usage list
	foreach opt [dict keys $optDict] {
		set pad 26
		set argdesc ""
		set optdesc [genOptdesc $opt]

		set argtype n
		if [dict exists $optDict $opt arg] {
			set argtype [dict get $optDict $opt arg]
		}
		switch -exact $argtype {
			"o" {set argdesc {[arg]}; set flag(o) yes}
			"y" {set argdesc {<arg>}; set flag(y) yes}
			"m" {set argdesc {{arg}}; set flag(m) yes}
		}

		set opthelp {nil #no help found for this options}
		if [dict exists $optDict $opt help] {
			set opthelp [dict get $optDict $opt help]
		}

		set opt_length [string length "$optdesc $argdesc"]
		set help_length [string length "$opthelp"]

		if {$opt_length > $pad-4 && $help_length > 8} {
			puts $out [format "    %-${pad}s\n %${pad}s    %s" "$optdesc $argdesc" {} $opthelp]
		} else {
			puts $out [format "    %-${pad}s %s" "$optdesc $argdesc" $opthelp]
		}
	}
	}

	unset optDict

	puts $out "\nComments:"
	if [info exist flag] {
		puts $out {    *  [arg] means arg is optional, need use --opt=arg to specify an argument}
		puts $out {       <arg> means arg is required, and -f a -f b will get the latest 'b'}
		puts $out {       {arg} means arg is required, and -f a -f b will get a list 'a b'}

		puts $out {}
		puts $out {    *  if arg is required, '--opt arg' is same as '--opt=arg'}
		puts $out {}
	}
	puts $out {    *  '-opt' will be treated as:}
	puts $out {           '--opt'    if 'opt' is defined;}
	puts $out {           '-o -p -t' if 'opt' is undefined;}
	puts $out {           '-o -p=t'  if 'opt' is undefined and '-p' need an argument;}
	puts $out {}
}
