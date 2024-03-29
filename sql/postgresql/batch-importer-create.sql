-- /packages/batch-importer/sql/postgresql/batch-importer-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author christof.damian@project-open.com


-----------------------------------------------------------
-- Batch-Importer
--
-- Schedule batch imports every interval.


CREATE TABLE batch_importers (
	package_id	INTEGER PRIMARY KEY,
	last_run	timestamp
);



CREATE TABLE batch_importer_files (
	package_id	INTEGER,
	filename	VARCHAR(255),
	import_time	TIMESTAMP,
	output	TEXT
);

CREATE INDEX batch_importer_files_package_and_filename 
ON batch_importer_files (package_id,filename);


