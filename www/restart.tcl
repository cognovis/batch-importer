# /packages/batch-importer/www/restart.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { filename:multiple "" }
    return_url
}


set user_id [ad_maybe_redirect_for_registration]
if {0 == [llength $filename]} { ad_returnredirect $return_url }

# Convert the list of selected files into a "file_id in (1,2,3,4...)" clause
#
set file_in_clause "and filename in ('"
lappend file_list 0
append file_in_clause [join $filename "', '"]
append file_in_clause "')\n"

ns_log Notice "restart: file_in_clause=$file_in_clause"

set sql "
	delete from batch_importer_files
	where	1=1
		$file_in_clause
"
db_dml del_files $sql

ad_returnredirect $return_url

