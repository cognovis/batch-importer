ad_page_contract {

    Batch Importer Status Page

} {
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set package_id [ad_conn package_id]

set last_run [db_string get_last_run "
    SELECT last_run 
    FROM batch_importers 
    WHERE package_id=:package_id" -default "never"]

set parameters ""

db_foreach batch_importer_parameters "
      select 
         p.parameter_name AS name,
         v.attr_value AS value
      from 
         apm_parameters p ,apm_parameter_values v 
      where p.package_key='batch-importer' 
          and p.parameter_id=v.parameter_id 
          and v.package_id=:package_id
    " {
	append parameters "<tr><td>$name</td><td>$value</td></tr>\n"
    }


db_multirow file_list file_list "
    Select
	filename,import_time,output
    from
        batch_importer_files
    where
        package_id=:package_id
    order by import_time desc
    limit 10
            "
    
template::list::create \
	-name file_list \
	-elements {
	    import_time {
		label "Import Time"
	    }
	    filename {
		label "Filename"
	    }
	    output {
		label "Output"
	    }
	} 