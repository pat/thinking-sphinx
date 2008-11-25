DROP TABLE IF EXISTS `betas`;

CREATE TABLE `betas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `betas` (name) values ('one');
insert into `betas` (name) values ('two');
insert into `betas` (name) values ('three');
insert into `betas` (name) values ('four');
insert into `betas` (name) values ('five');
insert into `betas` (name) values ('six');
insert into `betas` (name) values ('seven');
insert into `betas` (name) values ('eight');
insert into `betas` (name) values ('nine');
insert into `betas` (name) values ('ten');