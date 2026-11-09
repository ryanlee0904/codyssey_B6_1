-- =====================================================================
-- 01_schema.sql : 전자상거래(E-Commerce) 데이터베이스 스키마 생성
-- 대상 DB : PostgreSQL 16 (표준 SQL 위주로 작성)
-- 실행 순서 : 01_schema.sql -> 02_sample_data.sql -> 03_queries.sql
--
-- 테이블 구성 (6개)
--   member      회원
--   category    상품 카테고리
--   product     상품                (category 1 : N product)
--   orders      주문                (member   1 : N orders)
--   order_item  주문 상세(주문 품목) (orders 1 : N order_item, product 1 : N order_item)
--   review      상품 리뷰           (member 1 : N review,     product 1 : N review)
-- =====================================================================

-- 재실행을 위해 자식 테이블부터 역순으로 삭제
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS member;

-- ---------------------------------------------------------------------
-- 1) member : 회원 (부모 테이블)
-- ---------------------------------------------------------------------
CREATE TABLE member (
    member_id   INTEGER      PRIMARY KEY,
    email       VARCHAR(100) NOT NULL UNIQUE,            -- 로그인 ID, 중복 불가
    name        VARCHAR(50)  NOT NULL,
    phone       VARCHAR(20)  UNIQUE,
    city        VARCHAR(30)  NOT NULL,
    grade       VARCHAR(10)  NOT NULL DEFAULT 'BRONZE',
    created_at  DATE         NOT NULL,
    CONSTRAINT ck_member_grade CHECK (grade IN ('BRONZE', 'SILVER', 'GOLD', 'VIP'))
);

-- ---------------------------------------------------------------------
-- 2) category : 상품 카테고리 (부모 테이블)
-- ---------------------------------------------------------------------
CREATE TABLE category (
    category_id  INTEGER     PRIMARY KEY,
    name         VARCHAR(50) NOT NULL UNIQUE,
    description  VARCHAR(200)
);

-- ---------------------------------------------------------------------
-- 3) product : 상품  (category 1 : N product)
-- ---------------------------------------------------------------------
CREATE TABLE product (
    product_id   INTEGER      PRIMARY KEY,
    category_id  INTEGER      NOT NULL,
    name         VARCHAR(100) NOT NULL,
    price        INTEGER      NOT NULL,
    stock        INTEGER      NOT NULL DEFAULT 0,
    created_at   DATE         NOT NULL,
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id) REFERENCES category (category_id),
    CONSTRAINT ck_product_price CHECK (price > 0),
    CONSTRAINT ck_product_stock CHECK (stock >= 0)
);

-- ---------------------------------------------------------------------
-- 4) orders : 주문  (member 1 : N orders)
--    ※ ORDER 는 SQL 예약어이므로 테이블 이름을 orders 로 지정
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id      INTEGER      PRIMARY KEY,
    member_id     INTEGER      NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'PAID',
    total_amount  INTEGER      NOT NULL DEFAULT 0,
    ordered_at    TIMESTAMP    NOT NULL,
    CONSTRAINT fk_orders_member
        FOREIGN KEY (member_id) REFERENCES member (member_id),
    CONSTRAINT ck_orders_status
        CHECK (status IN ('PAID', 'SHIPPING', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT ck_orders_total CHECK (total_amount >= 0)
);

-- ---------------------------------------------------------------------
-- 5) order_item : 주문 상세 (orders 1 : N order_item, product 1 : N order_item)
--    주문이 삭제되면 그 주문의 상세 품목도 함께 삭제(ON DELETE CASCADE)
-- ---------------------------------------------------------------------
CREATE TABLE order_item (
    order_item_id  INTEGER  PRIMARY KEY,
    order_id       INTEGER  NOT NULL,
    product_id     INTEGER  NOT NULL,
    quantity       INTEGER  NOT NULL,
    unit_price     INTEGER  NOT NULL,          -- 주문 당시 가격(상품 가격이 바뀌어도 보존)
    CONSTRAINT fk_order_item_orders
        FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_product
        FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_order_item_order_product UNIQUE (order_id, product_id),
    CONSTRAINT ck_order_item_quantity CHECK (quantity > 0),
    CONSTRAINT ck_order_item_unit_price CHECK (unit_price > 0)
);

-- ---------------------------------------------------------------------
-- 6) review : 상품 리뷰 (member 1 : N review, product 1 : N review)
-- ---------------------------------------------------------------------
CREATE TABLE review (
    review_id   INTEGER      PRIMARY KEY,
    member_id   INTEGER      NOT NULL,
    product_id  INTEGER      NOT NULL,
    rating      INTEGER      NOT NULL,
    content     VARCHAR(500),
    created_at  DATE         NOT NULL,
    CONSTRAINT fk_review_member
        FOREIGN KEY (member_id) REFERENCES member (member_id),
    CONSTRAINT fk_review_product
        FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT uq_review_member_product UNIQUE (member_id, product_id),  -- 한 회원은 상품당 리뷰 1개
    CONSTRAINT ck_review_rating CHECK (rating BETWEEN 1 AND 5)
);
