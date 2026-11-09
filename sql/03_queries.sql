-- =====================================================================
-- 03_queries.sql : 핵심 SQL 쿼리 (총 20개)
--   기본 조회 4 / 조인 4 / 집계 4 / 서브쿼리 2 / 수정·삭제 3 / 인덱스 1 / 제약조건 검증 2
--
-- 표기 규칙
--   * 각 쿼리는 "-- [Qnn] 범주 | 무엇을 확인하는 쿼리인지" 한 줄로 시작한다.
--     (run_queries.py 가 이 줄을 기준으로 쿼리를 나눠 실행하고 결과를 저장한다)
--   * 표준 SQL 이 아닌 PostgreSQL 전용 문법에는 [PostgreSQL 전용] 주석을 붙였다.
--   * Q15~Q17 은 데이터를 변경하므로, 처음 상태로 돌리려면 01 -> 02 스크립트를 다시 실행한다.
-- =====================================================================


-- [Q01] 기본 조회 | 서울에 사는 회원을 가입일이 빠른 순서로 조회한다 (WHERE + ORDER BY)
SELECT member_id, name, email, grade, created_at
FROM member
WHERE city = '서울'
ORDER BY created_at ASC;


-- [Q02] 기본 조회 | 가격이 가장 비싼 상품 5개를 조회한다 (ORDER BY DESC + LIMIT)
-- [PostgreSQL 전용] LIMIT 은 PostgreSQL/MySQL 문법. 표준 SQL 로는 FETCH FIRST 5 ROWS ONLY
SELECT product_id, name, price, stock
FROM product
ORDER BY price DESC
LIMIT 5;


-- [Q03] 기본 조회 | 상품명에 '무선'이 들어간 상품을 검색해 저렴한 순으로 보여준다 (LIKE 검색)
SELECT product_id, name, price
FROM product
WHERE name LIKE '%무선%'
ORDER BY price ASC;


-- [Q04] 기본 조회 | 2026년 10월 주문 중 취소되지 않은 주문을 금액이 큰 순으로 조회한다 (범위 조건 + 복합 WHERE)
SELECT order_id, member_id, status, total_amount, ordered_at
FROM orders
WHERE ordered_at >= TIMESTAMP '2026-10-01 00:00:00'
  AND ordered_at <  TIMESTAMP '2026-11-01 00:00:00'
  AND status <> 'CANCELLED'
ORDER BY total_amount DESC;


-- [Q05] 조인 | 주문 목록에 주문한 회원의 이름과 등급을 붙여서 최신 주문순으로 보여준다 (INNER JOIN 2개 테이블)
SELECT o.order_id, m.name AS member_name, m.grade, o.status, o.total_amount, o.ordered_at
FROM orders o
INNER JOIN member m ON m.member_id = o.member_id
ORDER BY o.ordered_at DESC;


-- [Q06] 조인 | 회원 '김민수'가 산 모든 상품을 주문·상품·카테고리 정보와 함께 조회한다 (INNER JOIN 5개 테이블)
SELECT o.order_id,
       CAST(o.ordered_at AS DATE)    AS order_date,
       c.name                        AS category,
       p.name                        AS product,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price   AS line_total
FROM member m
INNER JOIN orders o      ON o.member_id   = m.member_id
INNER JOIN order_item oi ON oi.order_id   = o.order_id
INNER JOIN product p     ON p.product_id  = oi.product_id
INNER JOIN category c    ON c.category_id = p.category_id
WHERE m.name = '김민수'
ORDER BY o.ordered_at, oi.order_item_id;


-- [Q07] 조인 | 한 번도 주문하지 않은 회원을 찾는다 (LEFT JOIN + IS NULL)
SELECT m.member_id, m.name, m.city, m.created_at
FROM member m
LEFT JOIN orders o ON o.member_id = m.member_id
WHERE o.order_id IS NULL
ORDER BY m.member_id;


-- [Q08] 조인 | 모든 상품의 리뷰 수와 평균 평점을 리뷰가 없는 상품까지 포함해 보여준다 (LEFT JOIN)
SELECT p.product_id,
       p.name                        AS product,
       COUNT(r.review_id)            AS review_count,
       ROUND(AVG(r.rating), 2)       AS avg_rating
FROM product p
LEFT JOIN review r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name
ORDER BY review_count DESC, p.product_id;


-- [Q09] 집계 | 카테고리별 상품 수, 평균 가격, 총 재고를 구한다 (COUNT + AVG + SUM + GROUP BY)
SELECT c.name                   AS category,
       COUNT(p.product_id)      AS product_count,
       ROUND(AVG(p.price), 0)   AS avg_price,
       SUM(p.stock)             AS total_stock
FROM category c
INNER JOIN product p ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY avg_price DESC;


-- [Q10] 집계 | 취소 주문을 뺀 회원별 총 구매액을 구하고 20만 원 이상인 우수 회원만 보여준다 (SUM + GROUP BY + HAVING)
SELECT m.member_id,
       m.name,
       COUNT(o.order_id)     AS order_count,
       SUM(o.total_amount)   AS total_spent
FROM member m
INNER JOIN orders o ON o.member_id = m.member_id
WHERE o.status <> 'CANCELLED'
GROUP BY m.member_id, m.name
HAVING SUM(o.total_amount) >= 200000
ORDER BY total_spent DESC;


-- [Q11] 집계 | 월별 주문 건수와 매출(취소 제외), 주문당 평균 금액을 구한다 (COUNT + SUM + AVG + GROUP BY)
SELECT EXTRACT(YEAR  FROM ordered_at)  AS order_year,
       EXTRACT(MONTH FROM ordered_at)  AS order_month,
       COUNT(*)                        AS order_count,
       SUM(total_amount)               AS revenue,
       ROUND(AVG(total_amount), 0)     AS avg_order_amount
FROM orders
WHERE status <> 'CANCELLED'
GROUP BY EXTRACT(YEAR FROM ordered_at), EXTRACT(MONTH FROM ordered_at)
ORDER BY order_year, order_month;


-- [Q12] 집계 | 상품별 판매 수량과 매출로 판매 랭킹을 매긴다 (SUM + GROUP BY + RANK 윈도 함수)
-- RANK() OVER 는 SQL:2003 표준 윈도 함수 (PostgreSQL/MySQL 8/Oracle 공통 지원)
SELECT RANK() OVER (ORDER BY SUM(oi.quantity) DESC)  AS sales_rank,
       p.name                                        AS product,
       SUM(oi.quantity)                              AS sold_qty,
       SUM(oi.quantity * oi.unit_price)              AS sales_amount
FROM order_item oi
INNER JOIN orders o  ON o.order_id   = oi.order_id
INNER JOIN product p ON p.product_id = oi.product_id
WHERE o.status <> 'CANCELLED'
GROUP BY p.product_id, p.name
ORDER BY sales_rank, sales_amount DESC
LIMIT 10;  -- [PostgreSQL 전용] LIMIT (표준: FETCH FIRST 10 ROWS ONLY)


-- [Q13] 서브쿼리 | 전체 상품 평균 가격보다 비싼 상품을 조회한다 (WHERE 절 스칼라 서브쿼리)
SELECT product_id, name, price,
       (SELECT ROUND(AVG(price), 0) FROM product) AS overall_avg_price
FROM product
WHERE price > (SELECT AVG(price) FROM product)
ORDER BY price DESC;


-- [Q14] 서브쿼리 | 평균 평점 4.5 이상인 '인기 상품'을 한 번이라도 산 회원을 찾는다 (IN 서브쿼리 중첩)
SELECT DISTINCT m.member_id, m.name, m.grade
FROM member m
INNER JOIN orders o      ON o.member_id = m.member_id
INNER JOIN order_item oi ON oi.order_id = o.order_id
WHERE oi.product_id IN (
        SELECT r.product_id
        FROM review r
        GROUP BY r.product_id
        HAVING AVG(r.rating) >= 4.5
      )
ORDER BY m.member_id;


-- [Q15] 수정 | 배송 중(SHIPPING)인 주문을 배송 완료(DELIVERED)로 바꾸고 결과를 확인한다 (UPDATE)
UPDATE orders
SET status = 'DELIVERED'
WHERE status = 'SHIPPING';

SELECT order_id, member_id, status, ordered_at
FROM orders
WHERE order_id IN (8, 10)
ORDER BY order_id;


-- [Q16] 수정 | 결제 완료(PAID)된 주문의 수량만큼 상품 재고를 차감한다 (UPDATE + 상관 서브쿼리)
SELECT product_id, name, stock AS stock_before
FROM product
WHERE product_id IN (SELECT oi.product_id
                     FROM order_item oi
                     INNER JOIN orders o ON o.order_id = oi.order_id
                     WHERE o.status = 'PAID')
ORDER BY product_id;

UPDATE product
SET stock = stock - (
        SELECT SUM(oi.quantity)
        FROM order_item oi
        INNER JOIN orders o ON o.order_id = oi.order_id
        WHERE o.status = 'PAID'
          AND oi.product_id = product.product_id
    )
WHERE product_id IN (
        SELECT oi.product_id
        FROM order_item oi
        INNER JOIN orders o ON o.order_id = oi.order_id
        WHERE o.status = 'PAID'
    );

SELECT product_id, name, stock AS stock_after
FROM product
WHERE product_id IN (SELECT oi.product_id
                     FROM order_item oi
                     INNER JOIN orders o ON o.order_id = oi.order_id
                     WHERE o.status = 'PAID')
ORDER BY product_id;


-- [Q17] 삭제 | 취소된 주문을 삭제하고, ON DELETE CASCADE 로 주문 상세도 함께 지워지는지 확인한다 (DELETE)
SELECT 'before' AS step,
       (SELECT COUNT(*) FROM orders)     AS orders_cnt,
       (SELECT COUNT(*) FROM order_item) AS order_item_cnt;

DELETE FROM orders
WHERE status = 'CANCELLED';

SELECT 'after' AS step,
       (SELECT COUNT(*) FROM orders)     AS orders_cnt,
       (SELECT COUNT(*) FROM order_item) AS order_item_cnt;


-- [Q18] 인덱스 | 회원별 주문 조회가 잦은 orders.member_id 에 인덱스를 만들고 실행 계획에서 사용되는지 확인한다 (CREATE INDEX)
-- 적용 이유: orders.member_id 는 "내 주문 내역" 조회와 member JOIN 에 매번 쓰이는 FK 컬럼이라,
--            인덱스가 없으면 주문 전체를 훑어야(Full Scan) 하므로 인덱스로 해당 회원 행만 바로 찾게 한다.
-- [PostgreSQL 전용] DROP INDEX IF EXISTS (재실행용) / SET enable_seqscan / EXPLAIN 은 PostgreSQL 문법.
--   행이 수십 개뿐이면 옵티마이저가 순차 스캔을 고르므로, 실습에서는 enable_seqscan 을 잠시 끄고 인덱스 사용을 확인한다.
DROP INDEX IF EXISTS idx_orders_member_id;
CREATE INDEX idx_orders_member_id ON orders (member_id);

SET enable_seqscan = off;
EXPLAIN
SELECT order_id, status, total_amount
FROM orders
WHERE member_id = 1;
RESET enable_seqscan;


-- [Q19] 제약조건 검증 | 존재하지 않는 회원(999번)으로 주문을 넣으면 FK 가 막는지 확인한다 (오류가 나야 정상)
INSERT INTO orders (order_id, member_id, status, total_amount, ordered_at)
VALUES (100, 999, 'PAID', 10000, TIMESTAMP '2026-11-09 10:00:00');


-- [Q20] 제약조건 검증 | 이미 있는 이메일(UNIQUE)과 이름 누락(NOT NULL)으로 회원을 넣으면 거부되는지 확인한다 (오류가 나야 정상)
INSERT INTO member (member_id, email, name, phone, city, grade, created_at)
VALUES (13, 'kim.minsu@shop.kr', '김중복', '010-9999-0013', '서울', 'BRONZE', DATE '2026-11-09');

INSERT INTO member (member_id, email, name, phone, city, grade, created_at)
VALUES (14, 'no.name@shop.kr', NULL, '010-9999-0014', '서울', 'BRONZE', DATE '2026-11-09');
