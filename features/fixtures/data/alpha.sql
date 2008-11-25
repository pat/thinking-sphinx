DROP TABLE IF EXISTS `alphas`;

CREATE TABLE `alphas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `value` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `alphas` (name, value) values ('one',   1);
insert into `alphas` (name, value) values ('two',   2);
insert into `alphas` (name, value) values ('three', 3);
insert into `alphas` (name, value) values ('four',  4);
insert into `alphas` (name, value) values ('five',  5);
insert into `alphas` (name, value) values ('six',   6);
insert into `alphas` (name, value) values ('seven', 7);
insert into `alphas` (name, value) values ('eight', 8);
insert into `alphas` (name, value) values ('nine',  9);
insert into `alphas` (name, value) values ('ten',  10);