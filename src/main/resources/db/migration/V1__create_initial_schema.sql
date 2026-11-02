
-- LocalConnector V1: Initial database schema
-- Flyway migration: V1__create_initial_schema.sql


-- 1. Locations: country, state, district, and city hierarchy.
CREATE TABLE locations (
                           id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           country_code CHAR(2) NOT NULL,
                           name VARCHAR(120) NOT NULL,
                           location_type VARCHAR(20) NOT NULL,
                           parent_id BIGINT,
                           parent_location_type VARCHAR(20),
                           created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT uq_locations_id_type
                               UNIQUE (id, location_type, country_code),

                           CONSTRAINT fk_locations_parent
                               FOREIGN KEY (parent_id, parent_location_type, country_code)
                                   REFERENCES locations(id, location_type, country_code),

                           CONSTRAINT chk_locations_type
                               CHECK (
                                   location_type IN ('COUNTRY', 'STATE', 'DISTRICT', 'CITY')
                                   ),

                           CONSTRAINT chk_locations_country_code
                               CHECK (country_code ~ '^[A-Z]{2}$'),

                           CONSTRAINT chk_locations_hierarchy
                               CHECK (
                                   (location_type = 'COUNTRY'
                                       AND parent_id IS NULL
                                       AND parent_location_type IS NULL)
                                       OR
                                   (location_type = 'STATE'
                                       AND parent_id IS NOT NULL
                                       AND parent_location_type = 'COUNTRY')
                                       OR
                                   (location_type = 'DISTRICT'
                                       AND parent_id IS NOT NULL
                                       AND parent_location_type = 'STATE')
                                       OR
                                   (location_type = 'CITY'
                                       AND parent_id IS NOT NULL
                                       AND parent_location_type = 'DISTRICT')
                                   )
);

CREATE INDEX idx_locations_parent_id
    ON locations(parent_id);

CREATE INDEX idx_locations_country_type
    ON locations(country_code, location_type);


-- 2. Users: authentication and account status.
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(254) NOT NULL,
    normalized_email VARCHAR(254) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    account_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_users_normalized_email UNIQUE (normalized_email),

    CONSTRAINT chk_users_role
        CHECK (role IN ('USER', 'ADMIN')),

    CONSTRAINT chk_users_account_status
        CHECK (
            account_status IN (
                'ACTIVE',
                'SUSPENDED',
                'DISABLED',
                'PENDING_DELETION'
            )
        )
);


-- 3. Profiles: information intended for profile and discovery features.
CREATE TABLE profiles (
    user_id UUID PRIMARY KEY,
    display_name VARCHAR(80) NOT NULL,
    bio VARCHAR(500),
    photo_key VARCHAR(500),
    original_location_id BIGINT NOT NULL,
    current_location_id BIGINT NOT NULL,
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_profiles_user
        FOREIGN KEY (user_id) REFERENCES users(id),

    CONSTRAINT fk_profiles_original_location
        FOREIGN KEY (original_location_id) REFERENCES locations(id),

    CONSTRAINT fk_profiles_current_location
        FOREIGN KEY (current_location_id) REFERENCES locations(id),

    CONSTRAINT chk_profiles_visibility
        CHECK (visibility IN ('PUBLIC', 'CONNECTIONS_ONLY', 'PRIVATE'))
);

CREATE INDEX idx_profiles_current_location
    ON profiles(current_location_id);

CREATE INDEX idx_profiles_original_location
    ON profiles(original_location_id);
