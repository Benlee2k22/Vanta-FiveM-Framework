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

CREATE TABLE IF NOT EXISTS `vanta_bank_transactions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `action` varchar(24) NOT NULL,
  `amount` bigint NOT NULL,
  `description` varchar(160) NOT NULL DEFAULT '',
  `reference` varchar(32) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_vanta_bank_citizen` (`citizenid`, `id`),
  KEY `idx_vanta_bank_reference` (`reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vanta_inventories` (
  `citizenid` varchar(50) NOT NULL,
  `items` longtext NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
