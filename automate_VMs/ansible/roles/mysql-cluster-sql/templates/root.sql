ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass';

CREATE DATABAE testing;
USE testing;
CREATE table test1(testColumn, int);
GRANT ALL PRIVILEGES ON testing.* to 'testuser'@'%' IDENTIFIED BY 'password';

FLUSH PRIVILEGES;
