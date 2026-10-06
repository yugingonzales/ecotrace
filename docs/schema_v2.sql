-- EcoTrace canonical schema v2
-- MySQL 8.0 / MariaDB 10.4+
-- Fresh-schema DDL. Existing legacy tables require a separate data migration.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS orgs (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(64) NOT NULL,
  name VARCHAR(160) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_orgs_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO roles (name) VALUES ('admin'), ('staff'), ('volunteer'), ('intern')
ON DUPLICATE KEY UPDATE name = VALUES(name);

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id INT UNSIGNED NOT NULL,
  username VARCHAR(80) NOT NULL,
  first_name VARCHAR(80) NOT NULL,
  middle_name VARCHAR(80) NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(32) NULL,
  status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
  last_login DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email), UNIQUE KEY uq_users_username (username),
  KEY ix_users_role (role_id), KEY ix_users_status (status),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS devices (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  token VARCHAR(512) NOT NULL,
  platform ENUM('android', 'ios', 'web', 'unknown') NOT NULL DEFAULT 'unknown',
  last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_devices_token (token), KEY ix_devices_user (user_id),
  CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS events (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  org_id INT UNSIGNED NULL,
  name VARCHAR(160) NOT NULL,
  description TEXT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  trees_per_user INT UNSIGNED NOT NULL DEFAULT 0,
  target_year VARCHAR(9) NULL,
  status ENUM('draft', 'active', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_events_org (org_id), KEY ix_events_status_dates (status, start_date, end_date),
  KEY ix_events_created_by (created_by), CONSTRAINT chk_events_dates CHECK (end_date >= start_date),
  CONSTRAINT fk_events_org FOREIGN KEY (org_id) REFERENCES orgs (id) ON DELETE SET NULL,
  CONSTRAINT fk_events_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS trees (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  org_id INT UNSIGNED NULL,
  code VARCHAR(16) NULL,
  zone VARCHAR(48) NULL,
  name VARCHAR(255) NULL,
  planted_at DATE NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  address VARCHAR(255) NULL,
  planter_name VARCHAR(120) NULL,
  description TEXT NULL,
  status ENUM('pending', 'verified', 'deceased', 'incident', 'unverified') NOT NULL DEFAULT 'pending',
  verification_count INT UNSIGNED NOT NULL DEFAULT 0,
  last_verified_at DATETIME NULL,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_trees_code (code), KEY ix_trees_org (org_id),
  KEY ix_trees_status (status), KEY ix_trees_zone_status (zone, status),
  KEY ix_trees_planted_at (planted_at), KEY ix_trees_coordinates (latitude, longitude),
  KEY ix_trees_created_by (created_by),
  CONSTRAINT fk_trees_org FOREIGN KEY (org_id) REFERENCES orgs (id) ON DELETE SET NULL,
  CONSTRAINT fk_trees_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS event_users (
  event_id INT UNSIGNED NOT NULL, user_id INT UNSIGNED NOT NULL,
  role ENUM('participant', 'organizer') NOT NULL DEFAULT 'participant',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (event_id, user_id), KEY ix_event_users_user (user_id),
  CONSTRAINT fk_event_users_event FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  CONSTRAINT fk_event_users_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS event_trees (
  event_id INT UNSIGNED NOT NULL, tree_id INT UNSIGNED NOT NULL,
  assigned_to INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (event_id, tree_id), KEY ix_event_trees_tree (tree_id),
  KEY ix_event_trees_assigned_to (assigned_to),
  CONSTRAINT fk_event_trees_event FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  CONSTRAINT fk_event_trees_tree FOREIGN KEY (tree_id) REFERENCES trees (id) ON DELETE CASCADE,
  CONSTRAINT fk_event_trees_assigned_to FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS verifications (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT, tree_id INT UNSIGNED NOT NULL,
  event_id INT UNSIGNED NULL, user_id INT UNSIGNED NOT NULL,
  status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  health_status VARCHAR(32) NULL, stage VARCHAR(32) NULL, height_cm DECIMAL(8,2) NULL,
  notes TEXT NULL, verified_at DATETIME NULL, reviewed_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_verifications_tree_date (tree_id, verified_at),
  KEY ix_verifications_event (event_id), KEY ix_verifications_user (user_id),
  KEY ix_verifications_status (status), KEY ix_verifications_reviewer (reviewed_by),
  CONSTRAINT fk_verifications_tree FOREIGN KEY (tree_id) REFERENCES trees (id) ON DELETE CASCADE,
  CONSTRAINT fk_verifications_event FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE SET NULL,
  CONSTRAINT fk_verifications_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_verifications_reviewer FOREIGN KEY (reviewed_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS incidents (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT, tree_id INT UNSIGNED NOT NULL,
  event_id INT UNSIGNED NULL, reported_by INT UNSIGNED NOT NULL, resolved_by INT UNSIGNED NULL,
  severity ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
  status ENUM('open', 'under_review', 'resolved', 'dismissed') NOT NULL DEFAULT 'open',
  description TEXT NOT NULL, occurred_at DATETIME NULL, resolved_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_incidents_tree_status (tree_id, status), KEY ix_incidents_event (event_id),
  KEY ix_incidents_reporter (reported_by), KEY ix_incidents_severity (severity),
  CONSTRAINT fk_incidents_tree FOREIGN KEY (tree_id) REFERENCES trees (id) ON DELETE CASCADE,
  CONSTRAINT fk_incidents_event FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE SET NULL,
  CONSTRAINT fk_incidents_reported_by FOREIGN KEY (reported_by) REFERENCES users (id),
  CONSTRAINT fk_incidents_resolved_by FOREIGN KEY (resolved_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS photos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT, tree_id INT UNSIGNED NOT NULL,
  verification_id INT UNSIGNED NULL, incident_id INT UNSIGNED NULL,
  uploaded_by INT UNSIGNED NOT NULL, uri VARCHAR(1024) NOT NULL,
  caption VARCHAR(255) NULL, taken_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_photos_tree (tree_id), KEY ix_photos_verification (verification_id),
  KEY ix_photos_incident (incident_id), KEY ix_photos_uploaded_by (uploaded_by),
  CONSTRAINT fk_photos_tree FOREIGN KEY (tree_id) REFERENCES trees (id) ON DELETE CASCADE,
  CONSTRAINT fk_photos_verification FOREIGN KEY (verification_id) REFERENCES verifications (id) ON DELETE CASCADE,
  CONSTRAINT fk_photos_incident FOREIGN KEY (incident_id) REFERENCES incidents (id) ON DELETE CASCADE,
  CONSTRAINT fk_photos_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
