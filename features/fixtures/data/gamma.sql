DROP TABLE IF EXISTS `gammas`;

CREATE TABLE `gammas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `gammas` (name) values ('one');
insert into `gammas` (name) values ('two');
insert into `gammas` (name) values ('three');
insert into `gammas` (name) values ('four');
insert into `gammas` (name) values ('five');
insert into `gammas` (name) values ('six');
insert into `gammas` (name) values ('seven');
insert into `gammas` (name) values ('eight');
insert into `gammas` (name) values ('nine');
insert into `gammas` (name) values ('ten');