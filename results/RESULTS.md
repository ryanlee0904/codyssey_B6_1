# 쿼리 실행 결과

### 샘플 데이터 행 수

```text
 table_name | row_count 
------------+-----------
 member     |        12
 category   |        10
 product    |        20
 orders     |        15
 order_item |        27
 review     |        17
(6 rows)
```

### Q01. 서울에 사는 회원을 가입일이 빠른 순서로 조회한다 (WHERE + ORDER BY)

- 범주: **기본 조회**
- 쿼리/결과 파일: `results/Q01.txt`, 캡처: `results/Q01.png`

```sql
SELECT member_id, name, email, grade, created_at
FROM member
WHERE city = '서울'
ORDER BY created_at ASC;
```

실행 결과

```text
 member_id |  name  |        email        | grade  | created_at 
-----------+--------+---------------------+--------+------------
         2 | 이지영 | lee.jiyoung@shop.kr | VIP    | 2024-11-02
         6 | 강유나 | kang.yuna@shop.kr   | GOLD   | 2025-02-27
         1 | 김민수 | kim.minsu@shop.kr   | GOLD   | 2025-03-12
        10 | 송미나 | song.mina@shop.kr   | BRONZE | 2026-09-30
        12 | 신하나 | shin.hana@shop.kr   | BRONZE | 2026-11-01
(5 rows)
```

### Q02. 가격이 가장 비싼 상품 5개를 조회한다 (ORDER BY DESC + LIMIT)

- 범주: **기본 조회**
- 쿼리/결과 파일: `results/Q02.txt`, 캡처: `results/Q02.png`

```sql
-- [PostgreSQL 전용] LIMIT 은 PostgreSQL/MySQL 문법. 표준 SQL 로는 FETCH FIRST 5 ROWS ONLY
SELECT product_id, name, price, stock
FROM product
ORDER BY price DESC
LIMIT 5;
```

실행 결과

```text
 product_id |       name       |  price  | stock 
------------+------------------+---------+-------
          2 | 노트북 14인치    | 1290000 |    15
         16 | 무선 청소기      |  349000 |    20
         19 | 원목 책상        |  279000 |    10
          1 | 무선 이어폰 프로 |  189000 |    50
         18 | 접이식 덤벨 세트 |  159000 |    30
(5 rows)
```

### Q03. 상품명에 '무선'이 들어간 상품을 검색해 저렴한 순으로 보여준다 (LIKE 검색)

- 범주: **기본 조회**
- 쿼리/결과 파일: `results/Q03.txt`, 캡처: `results/Q03.png`

```sql
SELECT product_id, name, price
FROM product
WHERE name LIKE '%무선%'
ORDER BY price ASC;
```

실행 결과

```text
 product_id |       name       | price  
------------+------------------+--------
          3 | 무선 마우스      |  29000
          1 | 무선 이어폰 프로 | 189000
         16 | 무선 청소기      | 349000
(3 rows)
```

### Q04. 2026년 10월 주문 중 취소되지 않은 주문을 금액이 큰 순으로 조회한다 (범위 조건 + 복합 WHERE)

- 범주: **기본 조회**
- 쿼리/결과 파일: `results/Q04.txt`, 캡처: `results/Q04.png`

```sql
SELECT order_id, member_id, status, total_amount, ordered_at
FROM orders
WHERE ordered_at >= TIMESTAMP '2026-10-01 00:00:00'
  AND ordered_at <  TIMESTAMP '2026-11-01 00:00:00'
  AND status <> 'CANCELLED'
ORDER BY total_amount DESC;
```

실행 결과

```text
 order_id | member_id |  status   | total_amount |     ordered_at      
----------+-----------+-----------+--------------+---------------------
       10 |         8 | SHIPPING  |       159000 | 2026-10-27 21:05:00
        7 |         6 | DELIVERED |       157000 | 2026-10-11 13:45:00
        5 |         4 | DELIVERED |       127000 | 2026-10-02 11:00:00
        8 |         2 | SHIPPING  |       118000 | 2026-10-19 08:30:00
        9 |         7 | DELIVERED |        88500 | 2026-10-22 19:10:00
(5 rows)
```

### Q05. 주문 목록에 주문한 회원의 이름과 등급을 붙여서 최신 주문순으로 보여준다 (INNER JOIN 2개 테이블)

- 범주: **조인**
- 쿼리/결과 파일: `results/Q05.txt`, 캡처: `results/Q05.png`

```sql
SELECT o.order_id, m.name AS member_name, m.grade, o.status, o.total_amount, o.ordered_at
FROM orders o
INNER JOIN member m ON m.member_id = o.member_id
ORDER BY o.ordered_at DESC;
```

실행 결과

```text
 order_id | member_name | grade  |  status   | total_amount |     ordered_at      
----------+-------------+--------+-----------+--------------+---------------------
       15 | 강유나      | GOLD   | CANCELLED |        99000 | 2026-11-07 17:55:00
       14 | 김민수      | GOLD   | PAID      |       101400 | 2026-11-06 09:20:00
       13 | 송미나      | BRONZE | DELIVERED |        78000 | 2026-11-04 15:40:00
       12 | 임도현      | BRONZE | DELIVERED |       216000 | 2026-11-02 12:15:00
       11 | 박준호      | SILVER | PAID      |       329000 | 2026-11-01 10:00:00
       10 | 한아라      | SILVER | SHIPPING  |       159000 | 2026-10-27 21:05:00
        9 | 윤서준      | BRONZE | DELIVERED |        88500 | 2026-10-22 19:10:00
        8 | 이지영      | VIP    | SHIPPING  |       118000 | 2026-10-19 08:30:00
        7 | 강유나      | GOLD   | DELIVERED |       157000 | 2026-10-11 13:45:00
        6 | 정현우      | BRONZE | CANCELLED |       349000 | 2026-10-05 16:20:00
        5 | 최소라      | SILVER | DELIVERED |       127000 | 2026-10-02 11:00:00
        4 | 김민수      | GOLD   | DELIVERED |       168000 | 2026-09-28 20:41:00
        3 | 박준호      | SILVER | DELIVERED |        79000 | 2026-09-15 09:05:00
        2 | 이지영      | VIP    | DELIVERED |      1290000 | 2026-09-07 14:30:00
        1 | 김민수      | GOLD   | DELIVERED |       218000 | 2026-09-03 10:12:00
(15 rows)
```

### Q06. 회원 '김민수'가 산 모든 상품을 주문·상품·카테고리 정보와 함께 조회한다 (INNER JOIN 5개 테이블)

- 범주: **조인**
- 쿼리/결과 파일: `results/Q06.txt`, 캡처: `results/Q06.png`

```sql
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
```

실행 결과

```text
 order_id | order_date | category |     product      | quantity | unit_price | line_total 
----------+------------+----------+------------------+----------+------------+------------
        1 | 2026-09-03 | 전자기기 | 무선 이어폰 프로 |        1 |     189000 |     189000
        1 | 2026-09-03 | 전자기기 | 무선 마우스      |        1 |      29000 |      29000
        4 | 2026-09-28 | 신발     | 러닝화 에어      |        1 |     129000 |     129000
        4 | 2026-09-28 | 스포츠   | 요가 매트        |        1 |      39000 |      39000
       14 | 2026-11-06 | 식품     | 콜드브루 원액    |        4 |      15900 |      63600
       14 | 2026-11-06 | 식품     | 유기농 견과 믹스 |        2 |      18900 |      37800
(6 rows)
```

### Q07. 한 번도 주문하지 않은 회원을 찾는다 (LEFT JOIN + IS NULL)

- 범주: **조인**
- 쿼리/결과 파일: `results/Q07.txt`, 캡처: `results/Q07.png`

```sql
SELECT m.member_id, m.name, m.city, m.created_at
FROM member m
LEFT JOIN orders o ON o.member_id = m.member_id
WHERE o.order_id IS NULL
ORDER BY m.member_id;
```

실행 결과

```text
 member_id |  name  | city | created_at 
-----------+--------+------+------------
        11 | 오태양 | 수원 | 2026-10-15
        12 | 신하나 | 서울 | 2026-11-01
(2 rows)
```

### Q08. 모든 상품의 리뷰 수와 평균 평점을 리뷰가 없는 상품까지 포함해 보여준다 (LEFT JOIN)

- 범주: **조인**
- 쿼리/결과 파일: `results/Q08.txt`, 캡처: `results/Q08.png`

```sql
SELECT p.product_id,
       p.name                        AS product,
       COUNT(r.review_id)            AS review_count,
       ROUND(AVG(r.rating), 2)       AS avg_rating
FROM product p
LEFT JOIN review r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name
ORDER BY review_count DESC, p.product_id;
```

실행 결과

```text
 product_id |      product       | review_count | avg_rating 
------------+--------------------+--------------+------------
          1 | 무선 이어폰 프로   |            2 |       4.50
          9 | SQL 첫걸음         |            2 |       4.50
         14 | 선크림 SPF50       |            2 |       4.50
          2 | 노트북 14인치      |            1 |       5.00
          3 | 무선 마우스        |            1 |       4.00
          5 | 오버핏 후드티      |            1 |       4.00
          6 | 데님 청바지        |            1 |       2.00
          7 | 러닝화 에어        |            1 |       4.00
         10 | 파이썬 완벽 가이드 |            1 |       4.00
         11 | 유기농 견과 믹스   |            1 |       5.00
         12 | 콜드브루 원액      |            1 |       3.00
         13 | 수분 크림          |            1 |       5.00
         17 | 요가 매트          |            1 |       3.00
         20 | 고양이 스크래쳐    |            1 |       5.00
          4 | 기계식 키보드      |            0 |           
          8 | 가죽 로퍼          |            0 |           
         15 | 대용량 텀블러      |            0 |           
         16 | 무선 청소기        |            0 |           
         18 | 접이식 덤벨 세트   |            0 |           
         19 | 원목 책상          |            0 |           
(20 rows)
```

### Q09. 카테고리별 상품 수, 평균 가격, 총 재고를 구한다 (COUNT + AVG + SUM + GROUP BY)

- 범주: **집계**
- 쿼리/결과 파일: `results/Q09.txt`, 캡처: `results/Q09.png`

```sql
SELECT c.name                   AS category,
       COUNT(p.product_id)      AS product_count,
       ROUND(AVG(p.price), 0)   AS avg_price,
       SUM(p.stock)             AS total_stock
FROM category c
INNER JOIN product p ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY avg_price DESC;
```

실행 결과

```text
 category | product_count | avg_price | total_stock 
----------+---------------+-----------+-------------
 전자기기 |             4 |    399250 |         245
 가구     |             1 |    279000 |          10
 생활용품 |             2 |    187000 |         120
 신발     |             2 |    114000 |          65
 스포츠   |             2 |     99000 |         105
 패션의류 |             2 |     54000 |         150
 도서     |             2 |     28500 |         350
 반려동물 |             1 |     27000 |          60
 뷰티     |             2 |     26500 |         200
 식품     |             2 |     17400 |         480
(10 rows)
```

### Q10. 취소 주문을 뺀 회원별 총 구매액을 구하고 20만 원 이상인 우수 회원만 보여준다 (SUM + GROUP BY + HAVING)

- 범주: **집계**
- 쿼리/결과 파일: `results/Q10.txt`, 캡처: `results/Q10.png`

```sql
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
```

실행 결과

```text
 member_id |  name  | order_count | total_spent 
-----------+--------+-------------+-------------
         2 | 이지영 |           2 |     1408000
         1 | 김민수 |           3 |      487400
         3 | 박준호 |           2 |      408000
         9 | 임도현 |           1 |      216000
(4 rows)
```

### Q11. 월별 주문 건수와 매출(취소 제외), 주문당 평균 금액을 구한다 (COUNT + SUM + AVG + GROUP BY)

- 범주: **집계**
- 쿼리/결과 파일: `results/Q11.txt`, 캡처: `results/Q11.png`

```sql
SELECT EXTRACT(YEAR  FROM ordered_at)  AS order_year,
       EXTRACT(MONTH FROM ordered_at)  AS order_month,
       COUNT(*)                        AS order_count,
       SUM(total_amount)               AS revenue,
       ROUND(AVG(total_amount), 0)     AS avg_order_amount
FROM orders
WHERE status <> 'CANCELLED'
GROUP BY EXTRACT(YEAR FROM ordered_at), EXTRACT(MONTH FROM ordered_at)
ORDER BY order_year, order_month;
```

실행 결과

```text
 order_year | order_month | order_count | revenue | avg_order_amount 
------------+-------------+-------------+---------+------------------
       2026 |           9 |           4 | 1755000 |           438750
       2026 |          10 |           5 |  649500 |           129900
       2026 |          11 |           4 |  724400 |           181100
(3 rows)
```

### Q12. 상품별 판매 수량과 매출로 판매 랭킹을 매긴다 (SUM + GROUP BY + RANK 윈도 함수)

- 범주: **집계**
- 쿼리/결과 파일: `results/Q12.txt`, 캡처: `results/Q12.png`

```sql
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
```

실행 결과

```text
 sales_rank |      product       | sold_qty | sales_amount 
------------+--------------------+----------+--------------
          1 | 콜드브루 원액      |        6 |        95400
          2 | 유기농 견과 믹스   |        5 |        94500
          3 | 선크림 SPF50       |        4 |        84000
          4 | SQL 첫걸음         |        3 |        66000
          5 | 무선 이어폰 프로   |        2 |       378000
          5 | 오버핏 후드티      |        2 |        98000
          5 | 파이썬 완벽 가이드 |        2 |        70000
          5 | 수분 크림          |        2 |        64000
          5 | 무선 마우스        |        2 |        58000
          5 | 대용량 텀블러      |        2 |        50000
(10 rows)
```

### Q13. 전체 상품 평균 가격보다 비싼 상품을 조회한다 (WHERE 절 스칼라 서브쿼리)

- 범주: **서브쿼리**
- 쿼리/결과 파일: `results/Q13.txt`, 캡처: `results/Q13.png`

```sql
SELECT product_id, name, price,
       (SELECT ROUND(AVG(price), 0) FROM product) AS overall_avg_price
FROM product
WHERE price > (SELECT AVG(price) FROM product)
ORDER BY price DESC;
```

실행 결과

```text
 product_id |       name       |  price  | overall_avg_price 
------------+------------------+---------+-------------------
          2 | 노트북 14인치    | 1290000 |            147790
         16 | 무선 청소기      |  349000 |            147790
         19 | 원목 책상        |  279000 |            147790
          1 | 무선 이어폰 프로 |  189000 |            147790
         18 | 접이식 덤벨 세트 |  159000 |            147790
(5 rows)
```

### Q14. 평균 평점 4.5 이상인 '인기 상품'을 한 번이라도 산 회원을 찾는다 (IN 서브쿼리 중첩)

- 범주: **서브쿼리**
- 쿼리/결과 파일: `results/Q14.txt`, 캡처: `results/Q14.png`

```sql
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
```

실행 결과

```text
 member_id |  name  | grade  
-----------+--------+--------
         1 | 김민수 | GOLD
         2 | 이지영 | VIP
         3 | 박준호 | SILVER
         4 | 최소라 | SILVER
         7 | 윤서준 | BRONZE
         9 | 임도현 | BRONZE
        10 | 송미나 | BRONZE
(7 rows)
```

### Q15. 배송 중(SHIPPING)인 주문을 배송 완료(DELIVERED)로 바꾸고 결과를 확인한다 (UPDATE)

- 범주: **수정**
- 쿼리/결과 파일: `results/Q15.txt`, 캡처: `results/Q15.png`

```sql
UPDATE orders
SET status = 'DELIVERED'
WHERE status = 'SHIPPING';

SELECT order_id, member_id, status, ordered_at
FROM orders
WHERE order_id IN (8, 10)
ORDER BY order_id;
```

실행 결과

```text
UPDATE 2
 order_id | member_id |  status   |     ordered_at      
----------+-----------+-----------+---------------------
        8 |         2 | DELIVERED | 2026-10-19 08:30:00
       10 |         8 | DELIVERED | 2026-10-27 21:05:00
(2 rows)
```

### Q16. 결제 완료(PAID)된 주문의 수량만큼 상품 재고를 차감한다 (UPDATE + 상관 서브쿼리)

- 범주: **수정**
- 쿼리/결과 파일: `results/Q16.txt`, 캡처: `results/Q16.png`

```sql
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
```

실행 결과

```text
 product_id |       name       | stock_before 
------------+------------------+--------------
         11 | 유기농 견과 믹스 |          300
         12 | 콜드브루 원액    |          180
         15 | 대용량 텀블러    |          100
         19 | 원목 책상        |           10
(4 rows)

UPDATE 4
 product_id |       name       | stock_after 
------------+------------------+-------------
         11 | 유기농 견과 믹스 |         298
         12 | 콜드브루 원액    |         176
         15 | 대용량 텀블러    |          98
         19 | 원목 책상        |           9
(4 rows)
```

### Q17. 취소된 주문을 삭제하고, ON DELETE CASCADE 로 주문 상세도 함께 지워지는지 확인한다 (DELETE)

- 범주: **삭제**
- 쿼리/결과 파일: `results/Q17.txt`, 캡처: `results/Q17.png`

```sql
SELECT 'before' AS step,
       (SELECT COUNT(*) FROM orders)     AS orders_cnt,
       (SELECT COUNT(*) FROM order_item) AS order_item_cnt;

DELETE FROM orders
WHERE status = 'CANCELLED';

SELECT 'after' AS step,
       (SELECT COUNT(*) FROM orders)     AS orders_cnt,
       (SELECT COUNT(*) FROM order_item) AS order_item_cnt;
```

실행 결과

```text
  step  | orders_cnt | order_item_cnt 
--------+------------+----------------
 before |         15 |             27
(1 row)

DELETE 2
 step  | orders_cnt | order_item_cnt 
-------+------------+----------------
 after |         13 |             25
(1 row)
```

### Q18. 회원별 주문 조회가 잦은 orders.member_id 에 인덱스를 만들고 실행 계획에서 사용되는지 확인한다 (CREATE INDEX)

- 범주: **인덱스**
- 쿼리/결과 파일: `results/Q18.txt`, 캡처: `results/Q18.png`

```sql
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
```

실행 결과

```text
NOTICE:  index "idx_orders_member_id" does not exist, skipping
DROP INDEX
CREATE INDEX
SET
                                     QUERY PLAN                                     
------------------------------------------------------------------------------------
 Index Scan using idx_orders_member_id on orders  (cost=0.14..8.15 rows=1 width=66)
   Index Cond: (member_id = 1)
(2 rows)

RESET
```

### Q19. 존재하지 않는 회원(999번)으로 주문을 넣으면 FK 가 막는지 확인한다 (오류가 나야 정상)

- 범주: **제약조건 검증**
- 쿼리/결과 파일: `results/Q19.txt`, 캡처: `results/Q19.png`

```sql
INSERT INTO orders (order_id, member_id, status, total_amount, ordered_at)
VALUES (100, 999, 'PAID', 10000, TIMESTAMP '2026-11-09 10:00:00');
```

실행 결과

```text
ERROR:  insert or update on table "orders" violates foreign key constraint "fk_orders_member"
DETAIL:  Key (member_id)=(999) is not present in table "member".
```

### Q20. 이미 있는 이메일(UNIQUE)과 이름 누락(NOT NULL)으로 회원을 넣으면 거부되는지 확인한다 (오류가 나야 정상)

- 범주: **제약조건 검증**
- 쿼리/결과 파일: `results/Q20.txt`, 캡처: `results/Q20.png`

```sql
INSERT INTO member (member_id, email, name, phone, city, grade, created_at)
VALUES (13, 'kim.minsu@shop.kr', '김중복', '010-9999-0013', '서울', 'BRONZE', DATE '2026-11-09');

INSERT INTO member (member_id, email, name, phone, city, grade, created_at)
VALUES (14, 'no.name@shop.kr', NULL, '010-9999-0014', '서울', 'BRONZE', DATE '2026-11-09');
```

실행 결과

```text
ERROR:  duplicate key value violates unique constraint "member_email_key"
DETAIL:  Key (email)=(kim.minsu@shop.kr) already exists.
ERROR:  null value in column "name" of relation "member" violates not-null constraint
DETAIL:  Failing row contains (14, no.name@shop.kr, null, 010-9999-0014, 서울, BRONZE, 2026-11-09).
```
