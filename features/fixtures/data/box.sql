DROP TABLE IF EXISTS `boxes`;

CREATE TABLE `boxes` (
  `id` int(11) NOT NULL auto_increment,
  `width`  int(11) NOT NULL,
  `length` int(11) NOT NULL,
  `depth`  int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `boxes` (`width`, `length`, `depth`) values ( 1,  1,  1);
insert into `boxes` (`width`, `length`, `depth`) values ( 2,  2,  2);
insert into `boxes` (`width`, `length`, `depth`) values ( 3,  3,  3);
insert into `boxes` (`width`, `length`, `depth`) values ( 4,  4,  4);
insert into `boxes` (`width`, `length`, `depth`) values ( 5,  5,  5);
insert into `boxes` (`width`, `length`, `depth`) values ( 6,  6,  6);
insert into `boxes` (`width`, `length`, `depth`) values ( 7,  7,  7);
insert into `boxes` (`width`, `length`, `depth`) values ( 8,  8,  8);
insert into `boxes` (`width`, `length`, `depth`) values ( 9,  9,  9);
insert into `boxes` (`width`, `length`, `depth`) values (10, 10, 10);