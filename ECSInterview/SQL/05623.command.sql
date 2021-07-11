DELETE FROM versionTable;
INSERT INTO versiontable (version) SELECT VERSION();
