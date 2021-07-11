DELETE FROM versionTable;
LOAD DATA LOCAL INFILE 'C:\\temp\\version.txt' INTO TABLE versionTable;