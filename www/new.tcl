# /packages/batch-importer/www/new.tcl
#
# Copyright (C) 2003-2007 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    New page is basic...
    @author all@devcon.project-open.com
} {
    filename
    package_id:integer
    {return_url ""}
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" batch-importer.New "Import Info"]
set context_bar [im_context_bar $page_title]

set form_id "form"

ad_form \
    -name $form_id \
    -mode edit \
    -export "return_url" \
    -form {
	{package_id:integer(hidden)}
	{filename:text(text) {label "[lang::message::lookup {} batch-importer.Filename Filename]"} {html {size 80}} }
	{output_lines:text(textarea) {label "[lang::message::lookup {} batch-importer.Output Output]"} {html {rows 40 cols 80} }}
    }

ad_form -extend -name $form_id \
    -select_query {

	select	*
	from	batch_importer_files
	where	filename = :filename
		and package_id = :package_id

    } -on_request {

	db_1row job_info "
		select	*
		from	batch_importer_files
		where	filename = :filename
			and package_id = :package_id
	"

	set output_lines "[join $output "\n"]"

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }

