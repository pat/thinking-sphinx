DROP TABLE IF EXISTS `animals`;

CREATE TABLE `animals` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `animals` (name, type) values ('rogue', 'Cat');
insert into `animals` (name, type) values ('nat', 'Cat');
insert into `animals` (name, type) values ('molly', 'Cat');
insert into `animals` (name, type) values ('jasper', 'Cat');
insert into `animals` (name, type) values ('moggy', 'Cat');