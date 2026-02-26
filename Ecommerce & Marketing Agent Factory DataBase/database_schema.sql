-- ============================================================================
-- AGENT FACTORY E-COMMERCE SYSTEM - COMPLETE DATABASE SCHEMA
-- PostgreSQL 15+ Compatible
-- ============================================================================

-- ============================================================================
-- SECTION 1: USER MANAGEMENT SCHEMA
-- ============================================================================

-- Roles table for RBAC
CREATE TABLE roles (
    role_id             SERIAL PRIMARY KEY,
    role_name           VARCHAR(100) NOT NULL UNIQUE,
    role_description    TEXT,
    permissions         JSONB NOT NULL DEFAULT '{}',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_role_name CHECK (role_name ~ '^[A-Z_]+$')
);

-- Users table
CREATE TABLE users (
    user_id             BIGSERIAL PRIMARY KEY,
    email               VARCHAR(255) NOT NULL UNIQUE,
    username            VARCHAR(100) UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    phone               VARCHAR(20),
    role_id             INTEGER NOT NULL REFERENCES roles(role_id) DEFAULT 3,
    avatar_url          VARCHAR(500),
    email_verified      BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at       TIMESTAMP WITH TIME ZONE,
    last_login_ip       INET,
    preferences         JSONB NOT NULL DEFAULT '{}',
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$' OR username IS NULL)
);

-- User role assignments (many-to-many)
CREATE TABLE user_roles (
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id             INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by         BIGINT REFERENCES users(user_id),
    expires_at          TIMESTAMP WITH TIME ZONE,
    
    PRIMARY KEY (user_id, role_id)
);

-- User addresses
CREATE TABLE addresses (
    address_id          BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    address_type        VARCHAR(20) NOT NULL DEFAULT 'shipping',
    recipient_name      VARCHAR(200) NOT NULL,
    address_line1       VARCHAR(200) NOT NULL,
    address_line2       VARCHAR(200),
    city                VARCHAR(100) NOT NULL,
    state               VARCHAR(100),
    postal_code         VARCHAR(20) NOT NULL,
    country             CHAR(2) NOT NULL DEFAULT 'US',
    phone               VARCHAR(20),
    is_default          BOOLEAN NOT NULL DEFAULT FALSE,
    latitude            DECIMAL(10, 8),
    longitude           DECIMAL(11, 8),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_address_type CHECK (address_type IN ('shipping', 'billing', 'both')),
    CONSTRAINT chk_country_code CHECK (country ~ '^[A-Z]{2}$')
);

-- User sessions
CREATE TABLE sessions (
    session_id          VARCHAR(128) PRIMARY KEY,
    user_id             BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    device_info         JSONB NOT NULL DEFAULT '{}',
    ip_address          INET,
    user_agent          TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_session_expiry CHECK (expires_at > created_at)
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    token_id            BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash          VARCHAR(255) NOT NULL UNIQUE,
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at             TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_token_expiry CHECK (expires_at > CURRENT_TIMESTAMP)
);

-- Email verification tokens
CREATE TABLE email_verification_tokens (
    token_id            BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash          VARCHAR(255) NOT NULL UNIQUE,
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SECTION 2: PRODUCT CATALOG SCHEMA
-- ============================================================================

-- Product categories
CREATE TABLE categories (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(200) NOT NULL,
    category_slug       VARCHAR(200) NOT NULL UNIQUE,
    parent_category_id  INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
    description         TEXT,
    image_url           VARCHAR(500),
    display_order       INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_display_order CHECK (display_order >= 0)
);

-- Products table
CREATE TABLE products (
    product_id          BIGSERIAL PRIMARY KEY,
    sku                 VARCHAR(100) NOT NULL UNIQUE,
    product_name        VARCHAR(500) NOT NULL,
    product_slug        VARCHAR(500) NOT NULL UNIQUE,
    description         TEXT,
    short_description   VARCHAR(1000),
    category_id         INTEGER NOT NULL REFERENCES categories(category_id),
    brand               VARCHAR(200),
    manufacturer        VARCHAR(200),
    
    -- Pricing
    base_price          DECIMAL(12, 2) NOT NULL,
    sale_price          DECIMAL(12, 2),
    cost_price          DECIMAL(12, 2),
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    
    -- Inventory
    stock_quantity      INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,
    
    -- Product attributes
    weight              DECIMAL(10, 3),
    weight_unit         VARCHAR(10) DEFAULT 'kg',
    dimensions          JSONB,
    dimension_unit      VARCHAR(10) DEFAULT 'cm',
    
    -- Status
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_featured         BOOLEAN NOT NULL DEFAULT FALSE,
    is_digital          BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- SEO
    meta_title          VARCHAR(200),
    meta_description    VARCHAR(500),
    meta_keywords       TEXT[],
    
    -- Media
    primary_image_url   VARCHAR(500),
    image_urls          VARCHAR(500)[],
    
    -- Ratings
    avg_rating          DECIMAL(3, 2) DEFAULT 0,
    review_count        INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    published_at        TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_base_price CHECK (base_price >= 0),
    CONSTRAINT chk_sale_price CHECK (sale_price IS NULL OR sale_price >= 0),
    CONSTRAINT chk_sale_vs_base CHECK (sale_price IS NULL OR sale_price <= base_price),
    CONSTRAINT chk_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_threshold CHECK (low_stock_threshold >= 0),
    CONSTRAINT chk_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_avg_rating CHECK (avg_rating >= 0 AND avg_rating <= 5)
);

-- Product tags
CREATE TABLE tags (
    tag_id              SERIAL PRIMARY KEY,
    tag_name            VARCHAR(100) NOT NULL UNIQUE,
    tag_slug            VARCHAR(100) NOT NULL UNIQUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_tags (
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    tag_id              INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
    
    PRIMARY KEY (product_id, tag_id)
);

-- Product variants
CREATE TABLE product_variants (
    variant_id          BIGSERIAL PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    variant_name        VARCHAR(200) NOT NULL,
    variant_value       VARCHAR(200) NOT NULL,
    sku                 VARCHAR(100) UNIQUE,
    price_adjustment    DECIMAL(10, 2) NOT NULL DEFAULT 0,
    stock_quantity      INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_price_adjustment CHECK (price_adjustment >= 0)
);

-- Product images
CREATE TABLE product_images (
    image_id            BIGSERIAL PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    image_url           VARCHAR(500) NOT NULL,
    alt_text            VARCHAR(200),
    display_order       INTEGER NOT NULL DEFAULT 0,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_display_order_img CHECK (display_order >= 0)
);

-- Product reviews
CREATE TABLE product_reviews (
    review_id           BIGSERIAL PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    order_id            BIGINT REFERENCES orders(order_id),
    rating              INTEGER NOT NULL,
    title               VARCHAR(200),
    review_text         TEXT,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
    is_approved         BOOLEAN NOT NULL DEFAULT FALSE,
    helpful_count       INTEGER NOT NULL DEFAULT 0,
    not_helpful_count   INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5)
);

-- Product recommendations (pre-computed)
CREATE TABLE product_recommendations (
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    recommended_product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) NOT NULL,
    confidence_score    DECIMAL(5, 4) NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (product_id, recommended_product_id, recommendation_type),
    CONSTRAINT chk_confidence CHECK (confidence_score >= 0 AND confidence_score <= 1),
    CONSTRAINT chk_rec_type CHECK (recommendation_type IN ('similar', 'complementary', 'alternative', 'upsell', 'crossell'))
);

-- ============================================================================
-- SECTION 3: ORDER MANAGEMENT SCHEMA
-- ============================================================================

CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'processing', 'shipped',
    'out_for_delivery', 'delivered', 'cancelled', 'refunded', 'returned'
);

CREATE TYPE payment_status AS ENUM (
    'pending', 'authorized', 'captured', 'failed', 'refunded', 'partially_refunded'
);

-- Orders table
CREATE TABLE orders (
    order_id            BIGSERIAL PRIMARY KEY,
    order_number        VARCHAR(50) NOT NULL UNIQUE,
    user_id             BIGINT NOT NULL REFERENCES users(user_id),
    
    shipping_address_id BIGINT REFERENCES addresses(address_id),
    billing_address_id  BIGINT REFERENCES addresses(address_id),
    shipping_address_json JSONB NOT NULL,
    billing_address_json  JSONB NOT NULL,
    
    status              order_status NOT NULL DEFAULT 'pending',
    payment_status      payment_status NOT NULL DEFAULT 'pending',
    
    subtotal            DECIMAL(12, 2) NOT NULL,
    discount_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
    shipping_cost       DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_amount        DECIMAL(12, 2) NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    
    coupon_code         VARCHAR(50),
    discount_id         BIGINT REFERENCES discounts(discount_id),
    
    shipping_method     VARCHAR(100),
    tracking_number     VARCHAR(200),
    carrier             VARCHAR(100),
    
    customer_notes      TEXT,
    internal_notes      TEXT,
    
    ordered_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at        TIMESTAMP WITH TIME ZONE,
    shipped_at          TIMESTAMP WITH TIME ZONE,
    delivered_at        TIMESTAMP WITH TIME ZONE,
    cancelled_at        TIMESTAMP WITH TIME ZONE,
    
    source              VARCHAR(50) DEFAULT 'web',
    ip_address          INET,
    user_agent          TEXT,
    metadata            JSONB DEFAULT '{}',
    
    CONSTRAINT chk_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_discount CHECK (discount_amount >= 0),
    CONSTRAINT chk_tax CHECK (tax_amount >= 0),
    CONSTRAINT chk_shipping CHECK (shipping_cost >= 0),
    CONSTRAINT chk_total CHECK (total_amount >= 0),
    CONSTRAINT chk_currency_order CHECK (currency ~ '^[A-Z]{3}$')
);

-- Order items
CREATE TABLE order_items (
    order_item_id       BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id          BIGINT NOT NULL REFERENCES products(product_id),
    variant_id          BIGINT REFERENCES product_variants(variant_id),
    
    product_name        VARCHAR(500) NOT NULL,
    product_sku         VARCHAR(100) NOT NULL,
    variant_name        VARCHAR(200),
    
    unit_price          DECIMAL(12, 2) NOT NULL,
    quantity            INTEGER NOT NULL,
    discount_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_amount        DECIMAL(12, 2) NOT NULL,
    
    fulfilled_quantity  INTEGER NOT NULL DEFAULT 0,
    returned_quantity   INTEGER NOT NULL DEFAULT 0,
    
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_fulfilled CHECK (fulfilled_quantity >= 0),
    CONSTRAINT chk_returned CHECK (returned_quantity >= 0)
);

-- Order status history
CREATE TABLE order_status_history (
    history_id          BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    old_status          order_status,
    new_status          order_status NOT NULL,
    changed_by          BIGINT REFERENCES users(user_id),
    changed_by_agent    BIGINT REFERENCES agents(agent_id),
    reason              TEXT,
    changed_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Payments
CREATE TABLE payments (
    payment_id          BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_method      VARCHAR(50) NOT NULL,
    payment_gateway     VARCHAR(50) NOT NULL,
    transaction_id      VARCHAR(200) UNIQUE,
    
    amount              DECIMAL(12, 2) NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    
    status              payment_status NOT NULL DEFAULT 'pending',
    
    gateway_response    JSONB,
    error_message       TEXT,
    
    authorized_at       TIMESTAMP WITH TIME ZONE,
    captured_at         TIMESTAMP WITH TIME ZONE,
    failed_at           TIMESTAMP WITH TIME ZONE,
    refunded_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_payment_amount CHECK (amount >= 0)
);

-- Refunds
CREATE TABLE refunds (
    refund_id           BIGSERIAL PRIMARY KEY,
    payment_id          BIGINT NOT NULL REFERENCES payments(payment_id),
    order_id            BIGINT NOT NULL REFERENCES orders(order_id),
    refund_amount       DECIMAL(12, 2) NOT NULL,
    refund_reason       TEXT,
    refund_status       VARCHAR(50) NOT NULL DEFAULT 'pending',
    gateway_refund_id   VARCHAR(200),
    processed_by        BIGINT REFERENCES users(user_id),
    processed_at        TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_refund_amount CHECK (refund_amount > 0)
);

-- Discounts/Coupons
CREATE TABLE discounts (
    discount_id         BIGSERIAL PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,
    description         TEXT,
    discount_type       VARCHAR(20) NOT NULL,
    discount_value      DECIMAL(10, 2) NOT NULL,
    min_order_amount    DECIMAL(12, 2),
    max_discount_amount DECIMAL(12, 2),
    usage_limit         INTEGER,
    usage_count         INTEGER NOT NULL DEFAULT 0,
    per_user_limit      INTEGER DEFAULT 1,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    valid_from          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until         TIMESTAMP WITH TIME ZONE,
    applicable_products BIGINT[],
    applicable_categories INTEGER[],
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_discount_type CHECK (discount_type IN ('percentage', 'fixed', 'free_shipping')),
    CONSTRAINT chk_discount_value CHECK (discount_value >= 0),
    CONSTRAINT chk_usage CHECK (usage_count >= 0)
);

-- Shopping cart
CREATE TABLE cart_items (
    cart_item_id        BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    session_id          VARCHAR(128),
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    variant_id          BIGINT REFERENCES product_variants(variant_id),
    quantity            INTEGER NOT NULL DEFAULT 1,
    added_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_cart_quantity CHECK (quantity > 0),
    CONSTRAINT chk_cart_user_session CHECK (user_id IS NOT NULL OR session_id IS NOT NULL)
);

-- Wishlist
CREATE TABLE wishlist_items (
    wishlist_item_id    BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    added_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE (user_id, product_id)
);

-- ============================================================================
-- SECTION 4: CAMPAIGN & MARKETING SCHEMA
-- ============================================================================

CREATE TYPE campaign_status AS ENUM ('draft', 'scheduled', 'active', 'paused', 'completed', 'cancelled');
CREATE TYPE campaign_type AS ENUM ('email', 'sms', 'push_notification', 'social_media', 'paid_ads', 'content_marketing', 'multi_channel');

-- Campaigns table
CREATE TABLE campaigns (
    campaign_id         BIGSERIAL PRIMARY KEY,
    campaign_name       VARCHAR(200) NOT NULL,
    campaign_type       campaign_type NOT NULL,
    status              campaign_status NOT NULL DEFAULT 'draft',
    
    created_by          BIGINT NOT NULL REFERENCES users(user_id),
    team_id             BIGINT REFERENCES teams(team_id),
    
    subject             VARCHAR(500),
    preview_text        VARCHAR(200),
    template_id         BIGINT REFERENCES templates(template_id),
    content             JSONB,
    
    audience_definition JSONB NOT NULL DEFAULT '{}',
    segment_ids         BIGINT[],
    
    scheduled_at        TIMESTAMP WITH TIME ZONE,
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    
    budget_amount       DECIMAL(12, 2),
    spent_amount        DECIMAL(12, 2) DEFAULT 0,
    currency            CHAR(3) DEFAULT 'USD',
    
    sent_count          INTEGER NOT NULL DEFAULT 0,
    delivered_count     INTEGER NOT NULL DEFAULT 0,
    opened_count        INTEGER NOT NULL DEFAULT 0,
    clicked_count       INTEGER NOT NULL DEFAULT 0,
    converted_count     INTEGER NOT NULL DEFAULT 0,
    bounced_count       INTEGER NOT NULL DEFAULT 0,
    unsubscribed_count  INTEGER NOT NULL DEFAULT 0,
    
    send_rate_limit     INTEGER,
    timezone            VARCHAR(50) DEFAULT 'UTC',
    
    tags                TEXT[],
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_budget CHECK (budget_amount IS NULL OR budget_amount >= 0),
    CONSTRAINT chk_sent CHECK (sent_count >= 0)
);

-- Customer segments
CREATE TABLE segments (
    segment_id          BIGSERIAL PRIMARY KEY,
    segment_name        VARCHAR(200) NOT NULL,
    segment_type        VARCHAR(50) NOT NULL,
    definition          JSONB NOT NULL,
    user_count          INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    refresh_frequency   VARCHAR(20),
    last_refreshed_at   TIMESTAMP WITH TIME ZONE,
    created_by          BIGINT REFERENCES users(user_id),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_segment_type CHECK (segment_type IN ('static', 'dynamic', 'smart'))
);

-- Segment members
CREATE TABLE segment_members (
    segment_id          BIGINT NOT NULL REFERENCES segments(segment_id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    added_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by            BIGINT REFERENCES users(user_id),
    
    PRIMARY KEY (segment_id, user_id)
);

-- Email templates
CREATE TABLE templates (
    template_id         BIGSERIAL PRIMARY KEY,
    template_name       VARCHAR(200) NOT NULL,
    template_type       VARCHAR(50) NOT NULL,
    category            VARCHAR(100),
    subject             VARCHAR(500),
    html_content        TEXT,
    text_content        TEXT,
    variables           TEXT[],
    preview_image_url   VARCHAR(500),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    version             INTEGER NOT NULL DEFAULT 1,
    created_by          BIGINT REFERENCES users(user_id),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Campaign sends
CREATE TABLE campaign_sends (
    send_id             BIGSERIAL PRIMARY KEY,
    campaign_id         BIGINT NOT NULL REFERENCES campaigns(campaign_id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(user_id),
    email               VARCHAR(255),
    status              VARCHAR(50) NOT NULL DEFAULT 'pending',
    sent_at             TIMESTAMP WITH TIME ZONE,
    delivered_at        TIMESTAMP WITH TIME ZONE,
    opened_at           TIMESTAMP WITH TIME ZONE,
    clicked_at          TIMESTAMP WITH TIME ZONE,
    bounced_at          TIMESTAMP WITH TIME ZONE,
    bounce_reason       TEXT,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_campaign_send CHECK (email IS NOT NULL OR user_id IS NOT NULL)
);

-- Campaign clicks
CREATE TABLE campaign_clicks (
    click_id            BIGSERIAL PRIMARY KEY,
    send_id             BIGINT NOT NULL REFERENCES campaign_sends(send_id) ON DELETE CASCADE,
    url                 VARCHAR(2000) NOT NULL,
    clicked_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address          INET,
    user_agent          TEXT,
    device_type         VARCHAR(50),
    location            JSONB
);

-- A/B tests
CREATE TABLE ab_tests (
    ab_test_id          BIGSERIAL PRIMARY KEY,
    campaign_id         BIGINT NOT NULL REFERENCES campaigns(campaign_id) ON DELETE CASCADE,
    test_name           VARCHAR(200) NOT NULL,
    test_type           VARCHAR(50) NOT NULL,
    variants            JSONB NOT NULL,
    winner_criteria     VARCHAR(100) NOT NULL,
    sample_size         INTEGER,
    confidence_level    DECIMAL(5, 4) DEFAULT 0.95,
    winner_variant      INTEGER,
    status              VARCHAR(50) NOT NULL DEFAULT 'running',
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Customer journeys
CREATE TABLE journeys (
    journey_id          BIGSERIAL PRIMARY KEY,
    journey_name        VARCHAR(200) NOT NULL,
    journey_type        VARCHAR(50) NOT NULL,
    trigger_definition  JSONB,
    flow_definition     JSONB NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    entry_count         INTEGER NOT NULL DEFAULT 0,
    completion_count    INTEGER NOT NULL DEFAULT 0,
    created_by          BIGINT REFERENCES users(user_id),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Journey entries
CREATE TABLE journey_entries (
    entry_id            BIGSERIAL PRIMARY KEY,
    journey_id          BIGINT NOT NULL REFERENCES journeys(journey_id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    entered_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    current_step        INTEGER,
    completed_at        TIMESTAMP WITH TIME ZONE,
    exited_at           TIMESTAMP WITH TIME ZONE,
    exit_reason         VARCHAR(100),
    status              VARCHAR(50) NOT NULL DEFAULT 'active'
);

-- Journey step executions
CREATE TABLE journey_step_executions (
    execution_id        BIGSERIAL PRIMARY KEY,
    entry_id            BIGINT NOT NULL REFERENCES journey_entries(entry_id) ON DELETE CASCADE,
    step_id             INTEGER NOT NULL,
    step_type           VARCHAR(50) NOT NULL,
    status              VARCHAR(50) NOT NULL DEFAULT 'pending',
    executed_at         TIMESTAMP WITH TIME ZONE,
    result              JSONB,
    error_message       TEXT
);

-- ============================================================================
-- SECTION 5: AGENT MANAGEMENT SCHEMA
-- ============================================================================

-- Agent types
CREATE TABLE agent_types (
    type_id             SERIAL PRIMARY KEY,
    type_name           VARCHAR(100) NOT NULL UNIQUE,
    type_description    TEXT,
    default_config      JSONB NOT NULL DEFAULT '{}',
    capabilities        TEXT[],
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Agent instances
CREATE TABLE agents (
    agent_id            BIGSERIAL PRIMARY KEY,
    agent_name          VARCHAR(200) NOT NULL,
    type_id             INTEGER NOT NULL REFERENCES agent_types(type_id),
    
    status              VARCHAR(50) NOT NULL DEFAULT 'inactive',
    health_status       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    
    config              JSONB NOT NULL DEFAULT '{}',
    model_version       VARCHAR(50),
    
    tasks_completed     BIGINT NOT NULL DEFAULT 0,
    tasks_failed        BIGINT NOT NULL DEFAULT 0,
    avg_execution_time_ms INTEGER,
    last_task_at        TIMESTAMP WITH TIME ZONE,
    
    started_at          TIMESTAMP WITH TIME ZONE,
    stopped_at          TIMESTAMP WITH TIME ZONE,
    last_heartbeat_at   TIMESTAMP WITH TIME ZONE,
    
    created_by          BIGINT REFERENCES users(user_id),
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_agent_status CHECK (status IN ('inactive', 'starting', 'active', 'paused', 'stopping', 'error'))
);

-- Task definitions
CREATE TABLE tasks (
    task_id             BIGSERIAL PRIMARY KEY,
    task_name           VARCHAR(200) NOT NULL,
    task_type           VARCHAR(100) NOT NULL,
    description         TEXT,
    input_schema        JSONB,
    output_schema       JSONB,
    timeout_seconds     INTEGER DEFAULT 300,
    retry_policy        JSONB DEFAULT '{"max_retries": 3, "backoff": "exponential"}',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Task assignments
CREATE TABLE agent_tasks (
    task_id             BIGSERIAL PRIMARY KEY,
    task_name           VARCHAR(200) NOT NULL,
    task_type           VARCHAR(100) NOT NULL,
    
    agent_id            BIGINT REFERENCES agents(agent_id),
    assigned_by         BIGINT REFERENCES users(user_id),
    assigned_by_agent   BIGINT REFERENCES agents(agent_id),
    priority            INTEGER NOT NULL DEFAULT 5,
    
    status              VARCHAR(50) NOT NULL DEFAULT 'pending',
    progress            INTEGER NOT NULL DEFAULT 0,
    
    input_data          JSONB NOT NULL DEFAULT '{}',
    output_data         JSONB,
    error_message       TEXT,
    
    queued_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    expires_at          TIMESTAMP WITH TIME ZONE,
    
    retry_count         INTEGER NOT NULL DEFAULT 0,
    max_retries         INTEGER NOT NULL DEFAULT 3,
    next_retry_at       TIMESTAMP WITH TIME ZONE,
    
    correlation_id      VARCHAR(128),
    metadata            JSONB DEFAULT '{}',
    
    CONSTRAINT chk_priority CHECK (priority >= 1 AND priority <= 10),
    CONSTRAINT chk_progress CHECK (progress >= 0 AND progress <= 100),
    CONSTRAINT chk_retry CHECK (retry_count >= 0)
);

-- Agent execution logs
CREATE TABLE agent_execution_logs (
    log_id              BIGSERIAL PRIMARY KEY,
    task_id             BIGINT NOT NULL REFERENCES agent_tasks(task_id) ON DELETE CASCADE,
    agent_id            BIGINT NOT NULL REFERENCES agents(agent_id),
    
    log_level           VARCHAR(20) NOT NULL,
    message             TEXT NOT NULL,
    context             JSONB,
    error_stack         TEXT,
    
    logged_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    execution_step      VARCHAR(100),
    duration_ms         INTEGER
);

-- Agent performance metrics
CREATE TABLE agent_metrics (
    metric_id           BIGSERIAL PRIMARY KEY,
    agent_id            BIGINT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    metric_date         DATE NOT NULL,
    
    tasks_received      INTEGER NOT NULL DEFAULT 0,
    tasks_completed     INTEGER NOT NULL DEFAULT 0,
    tasks_failed        INTEGER NOT NULL DEFAULT 0,
    tasks_cancelled     INTEGER NOT NULL DEFAULT 0,
    
    avg_execution_time_ms INTEGER,
    min_execution_time_ms INTEGER,
    max_execution_time_ms INTEGER,
    p95_execution_time_ms INTEGER,
    p99_execution_time_ms INTEGER,
    
    success_rate        DECIMAL(5, 4),
    accuracy_score      DECIMAL(5, 4),
    
    avg_cpu_percent     DECIMAL(6, 2),
    avg_memory_mb       INTEGER,
    
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE (agent_id, metric_date),
    CONSTRAINT chk_success_rate CHECK (success_rate IS NULL OR (success_rate >= 0 AND success_rate <= 1))
);

-- Agent knowledge base
CREATE TABLE agent_knowledge (
    knowledge_id        BIGSERIAL PRIMARY KEY,
    agent_id            BIGINT REFERENCES agents(agent_id),
    knowledge_type      VARCHAR(50) NOT NULL,
    category            VARCHAR(100),
    content             JSONB NOT NULL,
    confidence          DECIMAL(5, 4) NOT NULL DEFAULT 1,
    source              VARCHAR(100),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    validated_by        BIGINT REFERENCES users(user_id),
    validated_at        TIMESTAMP WITH TIME ZONE,
    expires_at          TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_confidence CHECK (confidence >= 0 AND confidence <= 1)
);

-- ============================================================================
-- SECTION 6: INVENTORY & SUPPLY CHAIN SCHEMA
-- ============================================================================

-- Warehouses
CREATE TABLE warehouses (
    warehouse_id        SERIAL PRIMARY KEY,
    warehouse_name      VARCHAR(200) NOT NULL,
    warehouse_code      VARCHAR(50) NOT NULL UNIQUE,
    address_line1       VARCHAR(200) NOT NULL,
    address_line2       VARCHAR(200),
    city                VARCHAR(100) NOT NULL,
    state               VARCHAR(100),
    postal_code         VARCHAR(20) NOT NULL,
    country             CHAR(2) NOT NULL DEFAULT 'US',
    latitude            DECIMAL(10, 8),
    longitude           DECIMAL(11, 8),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    capacity            INTEGER,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Inventory levels
CREATE TABLE inventory (
    inventory_id        BIGSERIAL PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    variant_id          BIGINT REFERENCES product_variants(variant_id),
    warehouse_id        INTEGER NOT NULL REFERENCES warehouses(warehouse_id),
    
    quantity_on_hand    INTEGER NOT NULL DEFAULT 0,
    quantity_available  INTEGER NOT NULL DEFAULT 0,
    quantity_reserved   INTEGER NOT NULL DEFAULT 0,
    quantity_incoming   INTEGER NOT NULL DEFAULT 0,
    
    reorder_point       INTEGER NOT NULL DEFAULT 0,
    reorder_quantity    INTEGER NOT NULL DEFAULT 0,
    safety_stock        INTEGER NOT NULL DEFAULT 0,
    
    status              VARCHAR(50) NOT NULL DEFAULT 'normal',
    
    last_counted_at     TIMESTAMP WITH TIME ZONE,
    last_restocked_at   TIMESTAMP WITH TIME ZONE,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_quantity_on_hand CHECK (quantity_on_hand >= 0),
    CONSTRAINT chk_quantity_available CHECK (quantity_available >= 0),
    CONSTRAINT chk_quantity_reserved CHECK (quantity_reserved >= 0)
);

-- Inventory transactions
CREATE TABLE inventory_transactions (
    transaction_id      BIGSERIAL PRIMARY KEY,
    inventory_id        BIGINT NOT NULL REFERENCES inventory(inventory_id),
    transaction_type    VARCHAR(50) NOT NULL,
    
    quantity_before     INTEGER NOT NULL,
    quantity_change     INTEGER NOT NULL,
    quantity_after      INTEGER NOT NULL,
    
    reference_type      VARCHAR(50),
    reference_id        BIGINT,
    
    reason              TEXT,
    performed_by        BIGINT REFERENCES users(user_id),
    performed_by_agent  BIGINT REFERENCES agents(agent_id),
    notes               TEXT,
    metadata            JSONB DEFAULT '{}',
    
    transaction_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_quantity_change CHECK (quantity_change != 0)
);

-- Purchase orders
CREATE TABLE purchase_orders (
    po_id               BIGSERIAL PRIMARY KEY,
    po_number           VARCHAR(50) NOT NULL UNIQUE,
    supplier_id         BIGINT REFERENCES suppliers(supplier_id),
    
    status              VARCHAR(50) NOT NULL DEFAULT 'draft',
    items               JSONB NOT NULL DEFAULT '[]',
    
    subtotal            DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
    shipping_cost       DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_amount        DECIMAL(12, 2) NOT NULL DEFAULT 0,
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    
    expected_delivery   DATE,
    actual_delivery     DATE,
    shipping_method     VARCHAR(100),
    tracking_number     VARCHAR(200),
    
    warehouse_id        INTEGER NOT NULL REFERENCES warehouses(warehouse_id),
    
    ordered_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    received_at         TIMESTAMP WITH TIME ZONE,
    cancelled_at        TIMESTAMP WITH TIME ZONE,
    
    created_by          BIGINT REFERENCES users(user_id),
    notes               TEXT,
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Suppliers
CREATE TABLE suppliers (
    supplier_id         BIGSERIAL PRIMARY KEY,
    supplier_name       VARCHAR(200) NOT NULL,
    contact_name        VARCHAR(200),
    email               VARCHAR(255),
    phone               VARCHAR(20),
    address_line1       VARCHAR(200),
    city                VARCHAR(100),
    country             CHAR(2),
    website             VARCHAR(500),
    
    avg_lead_time_days  INTEGER,
    reliability_score   DECIMAL(5, 4),
    
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_preferred        BOOLEAN NOT NULL DEFAULT FALSE,
    
    payment_terms       VARCHAR(100),
    currency            CHAR(3) DEFAULT 'USD',
    
    metadata            JSONB DEFAULT '{}',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Demand forecasts
CREATE TABLE demand_forecasts (
    forecast_id         BIGSERIAL PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    warehouse_id        INTEGER REFERENCES warehouses(warehouse_id),
    
    forecast_date       DATE NOT NULL,
    forecast_horizon    INTEGER NOT NULL,
    forecast_type       VARCHAR(50) NOT NULL,
    
    predicted_demand    INTEGER NOT NULL,
    confidence_lower    INTEGER,
    confidence_upper    INTEGER,
    confidence_level    DECIMAL(5, 4) DEFAULT 0.95,
    
    model_version       VARCHAR(50),
    model_features      JSONB,
    
    actual_demand       INTEGER,
    forecast_error      DECIMAL(10, 2),
    
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE (product_id, warehouse_id, forecast_date, forecast_type)
);

-- Inventory alerts
CREATE TABLE inventory_alerts (
    alert_id            BIGSERIAL PRIMARY KEY,
    inventory_id        BIGINT NOT NULL REFERENCES inventory(inventory_id),
    alert_type          VARCHAR(50) NOT NULL,
    severity            VARCHAR(20) NOT NULL DEFAULT 'medium',
    message             TEXT NOT NULL,
    current_value       INTEGER,
    threshold_value     INTEGER,
    is_acknowledged     BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by     BIGINT REFERENCES users(user_id),
    acknowledged_at     TIMESTAMP WITH TIME ZONE,
    resolved_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_severity CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);

-- ============================================================================
-- SECTION 7: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_users_created ON users(created_at DESC);

-- Products indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug ON products(product_slug);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_featured ON products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_products_price ON products(base_price);
CREATE INDEX idx_products_rating ON products(avg_rating DESC) WHERE avg_rating > 0;
CREATE INDEX idx_products_category_active ON products(category_id, is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_search ON products USING GIN(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));

-- Orders indexes
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_created ON orders(ordered_at DESC);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Order items indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Campaigns indexes
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_type ON campaigns(campaign_type);
CREATE INDEX idx_campaigns_created ON campaigns(created_at DESC);
CREATE INDEX idx_campaigns_active ON campaigns(status) WHERE status = 'active';

-- Agent indexes
CREATE INDEX idx_agents_type ON agents(type_id);
CREATE INDEX idx_agents_status ON agents(status);
CREATE INDEX idx_agents_health ON agents(health_status);
CREATE INDEX idx_agent_tasks_agent ON agent_tasks(agent_id);
CREATE INDEX idx_agent_tasks_status ON agent_tasks(status);
CREATE INDEX idx_agent_tasks_priority ON agent_tasks(priority, status) WHERE status IN ('pending', 'queued');

-- Inventory indexes
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX idx_inventory_status ON inventory(status);
CREATE INDEX idx_inventory_low_stock ON inventory(status) WHERE status IN ('low_stock', 'out_of_stock');

-- Sessions indexes
CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_sessions_active ON sessions(is_active) WHERE is_active = TRUE;

-- Audit indexes
CREATE INDEX idx_order_status_history_order ON order_status_history(order_id, changed_at DESC);
CREATE INDEX idx_inventory_transactions_inventory ON inventory_transactions(inventory_id, transaction_at DESC);
CREATE INDEX idx_agent_execution_logs_task ON agent_execution_logs(task_id, logged_at DESC);

-- ============================================================================
-- SECTION 8: SEED DATA
-- ============================================================================

-- Insert default roles
INSERT INTO roles (role_name, role_description, permissions) VALUES
('ADMIN', 'System Administrator', '{"all": true}'),
('MARKETING_MANAGER', 'Marketing Team Lead', '{"campaigns": ["read", "write", "delete"], "analytics": ["read"], "agents": ["read"]}'),
('USER', 'Regular Customer', '{"profile": ["read", "write"], "orders": ["read", "write"], "cart": ["read", "write"]}'),
('SUPPORT_AGENT', 'Customer Support Representative', '{"tickets": ["read", "write"], "orders": ["read"], "users": ["read"]}'),
('SYSTEM', 'System Service Account', '{"all": true}');

-- Insert default agent types
INSERT INTO agent_types (type_name, type_description, capabilities) VALUES
('SUPERVISOR', 'Main Marketing Supervisor Agent', '{"orchestration": true, "task_assignment": true, "monitoring": true}'),
('CUSTOMER_SUPPORT', 'Customer Support Automation Agent', '{"nlp": true, "ticket_classification": true, "auto_response": true}'),
('RECOMMENDATION', 'Product Recommendation Agent', '{"collaborative_filtering": true, "content_based": true, "hybrid": true}'),
('AD_OPTIMIZATION', 'Advertisement Optimization Agent', '{"bid_management": true, "audience_targeting": true, "creative_optimization": true}'),
('INVENTORY_PREDICTION', 'Inventory Demand Prediction Agent', '{"forecasting": true, "demand_planning": true, "alerting": true}'),
('CAMPAIGN_AUTOMATION', 'Campaign Automation Agent', '{"segmentation": true, "journey_orchestration": true, "multi_channel": true}');

-- ============================================================================
-- SECTION 9: TRIGGERS FOR AUDIT & MAINTENANCE
-- ============================================================================

-- Trigger function for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for updating product review statistics
CREATE OR REPLACE FUNCTION update_product_review_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE products SET
            avg_rating = (SELECT AVG(rating) FROM product_reviews WHERE product_id = NEW.product_id AND is_approved = TRUE),
            review_count = (SELECT COUNT(*) FROM product_reviews WHERE product_id = NEW.product_id AND is_approved = TRUE)
        WHERE product_id = NEW.product_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products SET
            avg_rating = (SELECT AVG(rating) FROM product_reviews WHERE product_id = OLD.product_id AND is_approved = TRUE),
            review_count = (SELECT COUNT(*) FROM product_reviews WHERE product_id = OLD.product_id AND is_approved = TRUE)
        WHERE product_id = OLD.product_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_product_reviews_trigger
    AFTER INSERT OR UPDATE OR DELETE ON product_reviews
    FOR EACH ROW EXECUTE FUNCTION update_product_review_stats();

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
