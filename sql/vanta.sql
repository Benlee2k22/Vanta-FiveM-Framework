CREATE TABLE IF NOT EXISTS `vanta_players` (
  `citizenid` varchar(50) NOT NULL,
  `license` varchar(80) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'Unknown',
  `money` longtext NOT NULL,
  `charinfo` longtext NOT NULL,
  `job` longtext NOT NULL,
  `metadata` longtext NOT NULL,
  `position` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`),
  UNIQUE KEY `uq_vanta_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
