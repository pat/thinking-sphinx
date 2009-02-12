DROP TABLE IF EXISTS `people`;

CREATE TABLE `people` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(50) NULL,
  `middle_initial` varchar(10) NULL,
  `last_name` varchar(50) NULL,
  `gender` varchar(10) NULL,
  `street_address` varchar(200) NULL,
  `city` varchar(100) NULL,
  `state` varchar(100) NULL,
  `postcode` varchar(10) NULL,
  `email` varchar(100) NULL,
  `birthday` datetime NULL,
  `team_id` int(11) NULL,
  `team_type` varchar(50) NULL,
  `type` varchar(50) NULL,
  `parent_id` varchar(50) NULL,
  `delta` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `friendships`;

CREATE TABLE `friendships` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` int(11) NOT NULL,
  `friend_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `football_teams`;

CREATE TABLE `football_teams` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `state` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `cricket_teams`;

CREATE TABLE `cricket_teams` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `state` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `contacts`;

CREATE TABLE `contacts` (
  `id` int(11) NOT NULL auto_increment,
  `phone_number` varchar(50) NOT NULL,
  `person_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `alphas`;

CREATE TABLE `alphas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `betas`;

CREATE TABLE `betas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `searches`;

CREATE TABLE `searches` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `tags`;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` int(11) NOT NULL,
  `football_team_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
