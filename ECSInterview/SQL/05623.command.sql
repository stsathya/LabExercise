DELETE FROM versionTable;
LOAD DATA LOCAL INFILE 'C:\\SQL\\version.txt' INTO TABLE versionTable;