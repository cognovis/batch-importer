
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
            and parameter_name='BatchImportPollingInterval'
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
    {-debug_level 2}
    package_id
} {
    check the directory for new files
} {
    set errors {}

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

    set regex $p(BatchImportFileRegex)
    if {$debug_level <= 0} { lappend errors "Note: Checking glob -nocomplain -directory $p(BatchImportIncomingDirectory) -type f $regex" }
    set files [glob -nocomplain -directory $p(BatchImportIncomingDirectory) -type f $regex]
    if {$debug_level <= 0} { lappend errors "Note: Found files: $files" }

    foreach filename $files {

	# Check if the filename has already been processed
	set exists_p [db_string look_for_filename "
            SELECT count(*) 
            FROM batch_importer_files 
            WHERE filename=:filename
                AND package_id=:package_id
	"]
	if {$exists_p > 0} { 
	    if {$debug_level <= 0} { lappend errors "Note: File '$filename' has already been processed" }
	    continue 
	}

	if {$debug_level <= 0} { lappend errors "Note: Processing '$filename'" }
	set output [eval $p(BatchImportAction) $filename]
	db_dml new_import "
            INSERT INTO batch_importer_files
                (package_id,filename,import_time,output) 
            VALUES
                (:package_id,:filename,NOW(),:output)
        "

	if {[regexp $p(BatchImportErrorRegex) $output]} {
	    ns_log Debug "batch-importer: error match, sending to $p(BatchImportErrorEmail)"
	    batch_importer_send_error_mail $package_id $p(BatchImportErrorEmail) $filename $output 
	}
    }
    return $errors
}

ad_proc -public batch_importer_send_error_mail {
    package_id
    to
    filename
    output
} {
    if {$to==""} { return }

    set user_id [ad_get_user_id]
    set from [db_string from "select im_mail_from_user_id(:user_id)" -default ""]

    set msg "
Batch Importer \#$package_id encountered an error match while importing the
file \"$filename\". The output was:

$output
"

    ns_sendmail $to "error@example.com" "Error while importing:$filename" $msg
}

    
    






    