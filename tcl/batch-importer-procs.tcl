
ad_proc -public batch_importer_scheduler {
} {
    this runs every 60 seconds
} {
    db_foreach batch_importers "
        select 
            v.package_id AS package_id,
            v.attr_value AS polling_interval
        from 
            apm_parameters p ,apm_parameter_values v 
        where p.package_key='batch-importer' 
            and p.parameter_id=v.parameter_id 
            and parameter_name='polling_interval'
    " {

        set its_time [db_string last_run "
            SELECT
               NOW()-last_run >= INTERVAL :polling_interval
            FROM 
               batch_importers
            WHERE 
               package_id=:package_id
        " -default "never"]

	if { $its_time=="never"} {
	    db_dml insert_batch_importer "
            INSERT INTO batch_importers 
                (package_id,last_run) 
            VALUES (:package_id,NOW())
            "
	    batch_importer_check_directory $package_id
	} elseif { $its_time=="t" } {
	    db_dml update_last_run "
                UPDATE batch_importers 
                SET last_run=NOW() 
                WHERE package_id=:package_id
            "
	batch_importer_check_directory $package_id
	}
    }
}

ad_proc -public batch_importer_check_directory {
    package_id
} {
    check the directory for new files
} {
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
	set p($name) $value
    }

    foreach filename [glob -nocomplain -- "$p(directory)/$p(regex)"] {
	if {[db_string look_for_filename "
            SELECT count(*) 
            FROM batch_importer_files 
            WHERE filename=:filename
                AND package_id=:package_id"]>0} {
	    continue
	}
	ns_log Debug "batch-importer: $filename"
	set output [eval "$p(action)"]
	db_dml new_import "
            INSERT INTO batch_importer_files
                (package_id,filename,import_time,output) 
            VALUES
                (:package_id,:filename,NOW(),:output)
        "

	if {[regexp $p(error_regex) $output]} {
	    ns_log Debug "batch-importer: error match, sending to $p(error_email)"
	    batch_importer_send_error_mail $package_id $p(error_email) $filename $output 
	}
    }
}

ad_proc -public batch_importer_send_error_mail {
    package_id
    to
    filename
    output
} {
    if {$to==""} {
	return
    }

    set msg "
Batch Importer \#$package_id encountered an error match while importing the
file \"$filename\". The output was:

$output
"

    ns_sendmail $to "error@example.com" "Error while importing:$filename" $msg
}

    
    






    